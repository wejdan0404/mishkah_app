import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/auth_tokens.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _client = http.Client();

  /// Returns the decoded `data` field on success. Throws [ApiException] on failure.
  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
    String locale = 'ar',
  }) {
    return _send(
      () =>
          _client.get(_uri(path, query), headers: _headers(auth: auth, locale: locale)),
      auth: auth,
      locale: locale,
      retry: (h) => _client.get(_uri(path, query), headers: h),
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    bool auth = true,
    String locale = 'ar',
  }) {
    final encoded = body == null ? null : utf8.encode(jsonEncode(body));
    return _send(
      () => _client.post(
        _uri(path),
        headers: _headers(auth: auth, locale: locale),
        body: encoded,
      ),
      auth: auth,
      locale: locale,
      retry: (h) => _client.post(_uri(path), headers: h, body: encoded),
    );
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool auth = true,
    String locale = 'ar',
  }) {
    final encoded = body == null ? null : utf8.encode(jsonEncode(body));
    return _send(
      () => _client.patch(
        _uri(path),
        headers: _headers(auth: auth, locale: locale),
        body: encoded,
      ),
      auth: auth,
      locale: locale,
      retry: (h) => _client.patch(_uri(path), headers: h, body: encoded),
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? body,
    bool auth = true,
    String locale = 'ar',
  }) {
    final encoded = body == null ? null : utf8.encode(jsonEncode(body));
    return _send(
      () => _client.delete(
        _uri(path),
        headers: _headers(auth: auth, locale: locale),
        body: encoded,
      ),
      auth: auth,
      locale: locale,
      retry: (h) => _client.delete(_uri(path), headers: h, body: encoded),
    );
  }

  /// Stream a POST request as a raw response (used for SSE).
  /// Caller is responsible for parsing the stream.
  Future<http.StreamedResponse> postStream(
    String path, {
    required Map<String, dynamic> body,
    String locale = 'ar',
  }) async {
    Future<http.StreamedResponse> sendOnce() {
      final req = http.Request('POST', _uri(path))
        ..headers.addAll(
          _headers(auth: true, locale: locale, accept: 'text/event-stream'),
        )
        ..body = jsonEncode(body);
      return _client.send(req);
    }

    var res = await sendOnce();
    if (res.statusCode != 401) return res;

    // 401 → refresh + retry once
    await res.stream.drain<void>();
    final refreshed = await _tryRefresh();
    if (!refreshed) {
      throw const ApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Authentication required.',
      );
    }
    res = await sendOnce();
    return res;
  }

  /// POST a single file as `multipart/form-data`. Mirrors the auth +
  /// 401-refresh + `data`-unwrap behaviour of [post], but lets
  /// [http.MultipartRequest] set the multipart Content-Type (with boundary)
  /// itself — so we attach the bearer header without a JSON Content-Type.
  /// Returns the decoded `data` field on success; throws [ApiException].
  Future<dynamic> postMultipart(
    String path, {
    required String filePath,
    String fileField = 'file',
    Map<String, String> fields = const {},
    String locale = 'ar',
  }) async {
    Future<http.Response> sendOnce(String? token) async {
      final req = http.MultipartRequest('POST', _uri(path))
        ..headers['Accept'] = 'application/json'
        ..headers['Accept-Language'] = locale
        ..fields.addAll(fields)
        ..files.add(await http.MultipartFile.fromPath(fileField, filePath));
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      final streamed = await _client.send(req);
      return http.Response.fromStream(streamed);
    }

    var res = await sendOnce(TokenStorage.instance.accessToken);
    if (res.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        res = await sendOnce(TokenStorage.instance.accessToken);
      }
    }
    return _decode(res);
  }

  // -------- internals --------

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(ApiEndpoints.baseUrl);
    return base.replace(
      path: path,
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  Map<String, String> _headers({
    required bool auth,
    required String locale,
    String accept = 'application/json',
  }) {
    final headers = <String, String>{
      'Accept': accept,
      'Content-Type': 'application/json; charset=utf-8',
      'Accept-Language': locale,
    };
    if (auth) {
      final token = TokenStorage.instance.accessToken;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _send(
    Future<http.Response> Function() initial, {
    required bool auth,
    required String locale,
    required Future<http.Response> Function(Map<String, String>) retry,
  }) async {
    var res = await initial();
    if (res.statusCode == 401 && auth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        res = await retry(_headers(auth: true, locale: locale));
      }
    }
    // Consent self-heal: a freshly-signed-in user whose baseline consents
    // never persisted (transient failure at register, or an account created
    // before consent versioning) gets a 403 CONSENT_REQUIRED on every gated
    // endpoint — mood check-in, /me/journey, /focus/today — which the
    // services swallow into empty state. Rather than leave the user stuck,
    // post the baseline consents once and retry the original request.
    if (res.statusCode == 403 && auth && _isConsentRequired(res)) {
      final healed = await _ensureBaselineConsents(locale);
      if (healed) {
        res = await retry(_headers(auth: true, locale: locale));
      }
    }
    return _decode(res);
  }

  bool _isConsentRequired(http.Response res) {
    if (res.bodyBytes.isEmpty) return false;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        return err is Map<String, dynamic> && err['code'] == 'CONSENT_REQUIRED';
      }
    } catch (_) {
      // not JSON — treat as not-consent
    }
    return false;
  }

  bool _ensuringConsents = false;
  Completer<bool>? _consentCompleter;

  /// Post the three default-required consent scopes (privacy / terms /
  /// data_processing) at version 1.0 so the next request clears the
  /// EnsureConsent gate. Idempotent server-side (firstOrCreate), and
  /// de-duped here so a burst of simultaneous 403s only fires one heal.
  Future<bool> _ensureBaselineConsents(String locale) async {
    if (_ensuringConsents && _consentCompleter != null) {
      return _consentCompleter!.future;
    }
    _ensuringConsents = true;
    _consentCompleter = Completer<bool>();
    try {
      for (final scope in const ['privacy', 'terms', 'data_processing']) {
        final res = await _client.post(
          _uri(ApiEndpoints.consent),
          headers: _headers(auth: true, locale: locale),
          body: utf8.encode(jsonEncode({'scope': scope, 'version': '1.0'})),
        );
        // A non-2xx on the consent POST itself (e.g. 401) means we can't
        // heal — bail so we don't loop.
        if (res.statusCode < 200 || res.statusCode >= 300) {
          _consentCompleter!.complete(false);
          return false;
        }
      }
      _consentCompleter!.complete(true);
      return true;
    } catch (_) {
      _consentCompleter!.complete(false);
      return false;
    } finally {
      _ensuringConsents = false;
    }
  }

  bool _refreshing = false;
  Completer<bool>? _refreshCompleter;

  Future<bool> _tryRefresh() async {
    if (_refreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _refreshing = true;
    _refreshCompleter = Completer<bool>();
    try {
      final refresh = TokenStorage.instance.refreshToken;
      if (refresh == null) {
        _refreshCompleter!.complete(false);
        return false;
      }
      final res = await _client.post(
        _uri(ApiEndpoints.refresh),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: utf8.encode(jsonEncode({'refresh_token': refresh})),
      );
      if (res.statusCode != 200) {
        await TokenStorage.instance.clear();
        _refreshCompleter!.complete(false);
        return false;
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final data = (decoded as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final tokensJson = (data['tokens'] ?? data) as Map<String, dynamic>;
      final tokens = AuthTokens.fromJson(tokensJson);
      await TokenStorage.instance.save(tokens);
      _refreshCompleter!.complete(true);
      return true;
    } catch (_) {
      await TokenStorage.instance.clear();
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshing = false;
    }
  }

  dynamic _decode(http.Response res) {
    final body = res.bodyBytes.isEmpty ? '' : utf8.decode(res.bodyBytes);
    if (res.statusCode == 204) return null;
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    if (!ok) {
      throw ApiException.fromBody(statusCode: res.statusCode, body: body);
    }
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    } catch (_) {
      throw ApiException(
        statusCode: res.statusCode,
        code: 'PARSE_ERROR',
        message: 'Failed to parse server response.',
      );
    }
  }
}
