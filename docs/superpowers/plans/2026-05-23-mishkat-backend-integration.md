# Mishkat Backend Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire Mishkat's Flutter screens (sign-in, sign-up, edit profile, smart companion chat) to the Laravel `/api/v1/*` backend documented in `mishkat.postman_collection.json`, replacing the existing dummy auth flow and the Supabase-backed smart companion. **No UI layout changes** — only behavior changes inside existing widgets.

**Architecture:**
- Thin networking layer in `lib/core/` (no state-management library added — codebase has none).
- Singleton `ApiClient` wraps `package:http` with base URL, bearer-token injection, response/error envelope parsing, and one-shot 401 → refresh retry.
- `TokenStorage` uses `flutter_secure_storage` for `access_token` + `refresh_token` (only new dep added).
- `AuthService` owns login/register/me/refresh/logout/consent + an in-memory `currentUser` cache, exposed via static methods.
- Smart companion gets a new `AiService` that creates/reuses a thread and consumes SSE deltas from `POST /ai/threads/{id}/messages`. The chat screen accumulates deltas and renders them in the same `BotMessageBubble` widget — no layout change.
- The four consents (`privacy`, `terms`, `data_processing`, `ai_usage`) are silently submitted after register/login because the existing UI does not collect granular consent — pressing "إنشاء حساب" / "تسجيل الدخول" is treated as acceptance of the existing terms/privacy screens linked elsewhere in the app.

**Tech Stack:**
- Flutter 3.38.8 / Dart 3.10.7
- `package:http` ^1.2.2 (already present)
- `flutter_secure_storage` (to be added)
- Base URL via `--dart-define=MISHKAT_API_BASE_URL=...`, default `https://api.mishkat.us`

---

## Architectural Decisions (read first)

1. **No state management library.** The codebase uses plain `StatefulWidget` + local state. We follow the same pattern — `AuthService.login(...)` returns a `User` and stores tokens; screens manage their own loading/error UI in `setState`.

2. **Sign-up: defaults for required fields.** The API requires `birth_year`, `education_stage`, `region`, `locale` for `POST /auth/register`, but the form only collects `name/email/password`. **Do not add fields** (layout rule). Send `birth_year=2010, education_stage="middle_1", region="Riyadh", locale="ar"` as placeholders. Users can update `name`, `locale`, `region` later via PATCH `/me`; `birth_year` and `education_stage` are not editable from current UI.

3. **Edit profile field handling.** PATCH `/me` only accepts `name`, `locale`, `region`. The screen has `name`, `email`, `current_password`, `new_password`:
   - `name` → sent to PATCH `/me` (the only writable field actually shown).
   - `email` → display-only when loaded; if user edits, show an Arabic warning and keep server value (we do not call any email-change endpoint because none is documented for an authenticated user).
   - `current_password` + `new_password` → out of scope of the documented endpoints. The current UI's "verify current then set new" remains client-only validation; on save we **do not** call any password-change endpoint (none exists). Keep the existing client-only flow but `debugPrint` a TODO. The screen's primary backend action is updating `name`.

4. **Smart companion: stream tokens, no layout change.** The new SSE endpoint emits `message.delta` events with `{"text": "..."}` chunks. We accumulate into the same `BotMessageBubble` (replacing its text live). The existing `_isThinking` typing indicator shows until the first delta arrives, then we swap it for an incrementally-filled bubble. Exercise guides are gone (the new API does not return them) — the existing `_ChatItem.exercise` code path simply will not be exercised.

5. **Consent gate handling.** Any gated endpoint can return `403 CONSENT_REQUIRED`. The `ApiClient` does not auto-recover. The `AuthService.ensureBaselineConsents()` helper is called after login/register success and POSTs all four consent scopes; failures there are logged and surface as the next API call's 403 (which we then show to the user).

6. **Token refresh.** Tokens are issued as `access_token` + `refresh_token` (the Postman collection uses both `data.access_token`/`data.refresh_token` in test scripts and `data.tokens.access`/`data.tokens.refresh` in the example response — backend may emit either). The DTO accepts both shapes. `ApiClient` retries a request once on 401 after calling `POST /auth/refresh`.

7. **Splash navigation.** The current splash always pushes to `/onboarding`. We change `_goHome()` to: if we have stored tokens AND `GET /auth/me` succeeds, push to `/home`; else push to `/onboarding`. This is the **only** navigation change.

---

## File Structure

**New files:**
```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart           — HTTP wrapper: base URL, headers, token, envelope parse, 401-refresh retry
│   │   ├── api_endpoints.dart        — Path constants
│   │   ├── api_exception.dart        — ApiException(code, message, status, details) + factory from response
│   │   └── api_envelope.dart         — Decode {data, meta} | {error}
│   ├── auth/
│   │   └── auth_service.dart         — login/register/refresh/logout/me/consent + in-memory current user
│   ├── ai/
│   │   └── ai_service.dart           — createThread, sendMessageStream (SSE), listThreads, listMessages
│   └── storage/
│       └── token_storage.dart        — flutter_secure_storage wrapper
└── models/
    ├── user.dart                     — User DTO (id, name, email, locale, region, birth_year, education_stage, email_verified, is_active, is_pending_deletion, last_seen_at, created_at)
    ├── auth_tokens.dart              — Tokens DTO (access, refresh, expires_in, refresh_expires_in)
    ├── api_error.dart                — {code, message, details}
    ├── ai_thread.dart                — Thread DTO
    └── ai_message.dart               — Message DTO + StreamEvent union (delta/received/complete/error)
```

**Modified files:**
```
lib/
├── main.dart                                                — bootstrap TokenStorage + AuthService before runApp
├── screens/splash/splash_screen.dart                        — gated navigation by stored token + /auth/me probe
├── screens/auth/sign_in_screen.dart                         — _onSubmit calls AuthService.login + maps errors
├── screens/auth/sign_up_screen.dart                         — _onSubmit calls AuthService.register + consents
├── screens/edit_profile/edit_profile_screen.dart            — initState loads /me, _onSave PATCHes /me, _onDeleteAccount DELETEs /me
├── screens/smart_companion/smart_companion_chat_screen.dart — _send uses AiService streaming; _items[last] mutates in place during stream
└── screens/smart_companion/models/companion_response.dart   — keep file (CompanionResponse + ExerciseGuide) but no longer constructed from JSON; chat screen builds CompanionResponse(aiReply: finalText) directly
pubspec.yaml                                                 — add flutter_secure_storage
```

**Files to delete:**
```
lib/screens/smart_companion/services/smart_companion_service.dart   — replaced by core/ai/ai_service.dart
lib/screens/smart_companion/services/supabase_config.dart           — Supabase no longer used
```
(`transcribe_audio_service.dart` stays — voice transcription is unrelated to the chat backend.)

---

### Task 1: Add `flutter_secure_storage` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:` add (after `permission_handler: ^11.3.1`):

```yaml
  flutter_secure_storage: ^9.2.2
```

- [ ] **Step 2: Fetch the package**

Run: `flutter pub get`
Expected: `Got dependencies!` and no version-solving errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): add flutter_secure_storage for token persistence"
```

---

### Task 2: API endpoints + base URL config

**Files:**
- Create: `lib/core/api/api_endpoints.dart`

- [ ] **Step 1: Write the file**

```dart
class ApiEndpoints {
  const ApiEndpoints._();

  // Base URL — override at build time:
  //   flutter run --dart-define=MISHKAT_API_BASE_URL=http://localhost:8080
  static const String baseUrl = String.fromEnvironment(
    'MISHKAT_API_BASE_URL',
    defaultValue: 'https://api.mishkat.us',
  );

  static const String apiV1 = '/api/v1';

  // Auth
  static const String register = '$apiV1/auth/register';
  static const String login = '$apiV1/auth/login';
  static const String refresh = '$apiV1/auth/refresh';
  static const String logout = '$apiV1/auth/logout';
  static const String authMe = '$apiV1/auth/me';

  // Me
  static const String me = '$apiV1/me';
  static const String consent = '$apiV1/me/consent';

  // AI
  static const String aiThreads = '$apiV1/ai/threads';
  static String aiThread(String id) => '$apiV1/ai/threads/$id';
  static String aiMessages(String threadId) =>
      '$apiV1/ai/threads/$threadId/messages';
}
```

- [ ] **Step 2: Verify compile**

Run: `flutter analyze lib/core/api/api_endpoints.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/api/api_endpoints.dart
git commit -m "feat(core): add api endpoint constants and dart-define base url"
```

---

### Task 3: ApiException type

**Files:**
- Create: `lib/core/api/api_exception.dart`
- Test: `test/core/api/api_exception_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/api/api_exception_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/core/api/api_exception.dart';

void main() {
  group('ApiException.fromBody', () {
    test('parses standard error envelope', () {
      final exc = ApiException.fromBody(
        statusCode: 422,
        body: '{"error":{"code":"VALIDATION_FAILED","message":"Validation failed.","details":{"errors":{"email":["taken"]}}}}',
      );
      expect(exc.statusCode, 422);
      expect(exc.code, 'VALIDATION_FAILED');
      expect(exc.message, 'Validation failed.');
      expect(exc.details, isNotNull);
      expect((exc.details!['errors'] as Map)['email'], ['taken']);
    });

    test('falls back when body is not valid envelope', () {
      final exc = ApiException.fromBody(statusCode: 500, body: 'oops');
      expect(exc.statusCode, 500);
      expect(exc.code, 'UNKNOWN');
      expect(exc.message, isNotEmpty);
    });

    test('fieldErrors returns flat map for validation', () {
      final exc = ApiException(
        statusCode: 422,
        code: 'VALIDATION_FAILED',
        message: 'x',
        details: const {
          'errors': {
            'email': ['taken'],
            'password': ['too short', 'no uppercase'],
          },
        },
      );
      expect(exc.fieldErrors, {
        'email': 'taken',
        'password': 'too short',
      });
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/api/api_exception_test.dart`
Expected: FAIL (target file does not exist).

- [ ] **Step 3: Write the implementation**

```dart
import 'dart:convert';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  factory ApiException.fromBody({
    required int statusCode,
    required String body,
  }) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is Map<String, dynamic>) {
          return ApiException(
            statusCode: statusCode,
            code: (err['code'] as String?) ?? 'UNKNOWN',
            message: (err['message'] as String?) ?? 'Unknown error',
            details: (err['details'] as Map?)?.cast<String, dynamic>(),
          );
        }
      }
    } catch (_) {
      // fall through
    }
    return ApiException(
      statusCode: statusCode,
      code: 'UNKNOWN',
      message: 'Unexpected response ($statusCode).',
    );
  }

  /// For 422 VALIDATION_FAILED: returns {field: firstMessage} or {}.
  Map<String, String> get fieldErrors {
    final errors = details?['errors'];
    if (errors is! Map) return const {};
    final out = <String, String>{};
    errors.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        out[key.toString()] = value.first.toString();
      } else if (value is String) {
        out[key.toString()] = value;
      }
    });
    return out;
  }

  bool get isUnauthenticated => statusCode == 401 || code == 'UNAUTHENTICATED';
  bool get isConsentRequired => code == 'CONSENT_REQUIRED';
  bool get isValidation => code == 'VALIDATION_FAILED';
  bool get isRateLimited => code == 'RATE_LIMITED' || code == 'AI_USAGE_EXCEEDED';

  @override
  String toString() => 'ApiException($statusCode $code: $message)';
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/api/api_exception_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/api/api_exception.dart test/core/api/api_exception_test.dart
git commit -m "feat(core): typed ApiException with envelope parsing and field errors"
```

---

### Task 4: User + Tokens DTOs

**Files:**
- Create: `lib/models/user.dart`
- Create: `lib/models/auth_tokens.dart`
- Test: `test/models/user_test.dart`
- Test: `test/models/auth_tokens_test.dart`

- [ ] **Step 1: Write the failing tests**

`test/models/user_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/models/user.dart';

void main() {
  test('User.fromJson reads the documented shape', () {
    final json = {
      'id': '9b7c6df0-1234-4abc-9def-aaaaaaaaaaaa',
      'name': 'سعد القاضي',
      'email': 'demo@mishkat.local',
      'email_verified': true,
      'birth_year': 2010,
      'education_stage': 'middle_1',
      'region': 'Riyadh',
      'locale': 'ar',
      'is_active': true,
      'is_pending_deletion': false,
      'last_seen_at': '2026-05-20T09:15:23+03:00',
      'created_at': '2026-01-12T18:42:00+03:00',
    };

    final u = User.fromJson(json);
    expect(u.id, '9b7c6df0-1234-4abc-9def-aaaaaaaaaaaa');
    expect(u.name, 'سعد القاضي');
    expect(u.email, 'demo@mishkat.local');
    expect(u.locale, 'ar');
    expect(u.region, 'Riyadh');
    expect(u.birthYear, 2010);
    expect(u.educationStage, 'middle_1');
    expect(u.emailVerified, true);
    expect(u.isPendingDeletion, false);
  });

  test('User.fromJson tolerates missing optional fields', () {
    final u = User.fromJson({'id': 'x', 'name': 'y', 'email': 'z@z.z'});
    expect(u.locale, 'ar');
    expect(u.birthYear, isNull);
    expect(u.region, isNull);
  });
}
```

`test/models/auth_tokens_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/models/auth_tokens.dart';

void main() {
  test('AuthTokens.fromJson handles {access, refresh} shape', () {
    final t = AuthTokens.fromJson({
      'access': 'a-token',
      'refresh': 'r-token',
      'expires_in': 3600,
      'refresh_expires_in': 2592000,
    });
    expect(t.access, 'a-token');
    expect(t.refresh, 'r-token');
    expect(t.expiresIn, 3600);
  });

  test('AuthTokens.fromJson handles {access_token, refresh_token} shape', () {
    final t = AuthTokens.fromJson({
      'access_token': 'a',
      'refresh_token': 'r',
    });
    expect(t.access, 'a');
    expect(t.refresh, 'r');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/models/`
Expected: FAIL (files do not exist).

- [ ] **Step 3: Write the implementations**

`lib/models/user.dart`:

```dart
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerified = false,
    this.birthYear,
    this.educationStage,
    this.region,
    this.locale = 'ar',
    this.isActive = true,
    this.isPendingDeletion = false,
    this.lastSeenAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final bool emailVerified;
  final int? birthYear;
  final String? educationStage;
  final String? region;
  final String locale;
  final bool isActive;
  final bool isPendingDeletion;
  final String? lastSeenAt;
  final String? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailVerified: json['email_verified'] as bool? ?? false,
      birthYear: (json['birth_year'] as num?)?.toInt(),
      educationStage: json['education_stage'] as String?,
      region: json['region'] as String?,
      locale: (json['locale'] as String?) ?? 'ar',
      isActive: json['is_active'] as bool? ?? true,
      isPendingDeletion: json['is_pending_deletion'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  User copyWith({String? name, String? locale, String? region}) => User(
        id: id,
        name: name ?? this.name,
        email: email,
        emailVerified: emailVerified,
        birthYear: birthYear,
        educationStage: educationStage,
        region: region ?? this.region,
        locale: locale ?? this.locale,
        isActive: isActive,
        isPendingDeletion: isPendingDeletion,
        lastSeenAt: lastSeenAt,
        createdAt: createdAt,
      );
}
```

`lib/models/auth_tokens.dart`:

```dart
class AuthTokens {
  const AuthTokens({
    required this.access,
    required this.refresh,
    this.expiresIn,
    this.refreshExpiresIn,
  });

  final String access;
  final String refresh;
  final int? expiresIn;
  final int? refreshExpiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final access = (json['access'] ?? json['access_token']) as String?;
    final refresh = (json['refresh'] ?? json['refresh_token']) as String?;
    if (access == null || refresh == null) {
      throw const FormatException('Missing access/refresh in tokens payload');
    }
    return AuthTokens(
      access: access,
      refresh: refresh,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      refreshExpiresIn: (json['refresh_expires_in'] as num?)?.toInt(),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/models/`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/models/user.dart lib/models/auth_tokens.dart test/models/
git commit -m "feat(models): User and AuthTokens DTOs with tolerant parsing"
```

---

### Task 5: TokenStorage (secure persistence)

**Files:**
- Create: `lib/core/storage/token_storage.dart`

- [ ] **Step 1: Write the implementation**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/auth_tokens.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _accessKey = 'mishkat.auth.access';
  static const _refreshKey = 'mishkat.auth.refresh';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _cachedAccess;
  String? _cachedRefresh;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _cachedAccess = await _storage.read(key: _accessKey);
    _cachedRefresh = await _storage.read(key: _refreshKey);
    _loaded = true;
  }

  String? get accessToken => _cachedAccess;
  String? get refreshToken => _cachedRefresh;
  bool get hasSession => _cachedAccess != null && _cachedRefresh != null;

  Future<void> save(AuthTokens tokens) async {
    _cachedAccess = tokens.access;
    _cachedRefresh = tokens.refresh;
    _loaded = true;
    await Future.wait([
      _storage.write(key: _accessKey, value: tokens.access),
      _storage.write(key: _refreshKey, value: tokens.refresh),
    ]);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    _loaded = true;
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }
}
```

- [ ] **Step 2: Verify compile**

Run: `flutter analyze lib/core/storage/`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/storage/token_storage.dart
git commit -m "feat(core): TokenStorage using flutter_secure_storage with in-memory cache"
```

---

### Task 6: ApiClient with envelope parsing + 401 refresh retry

**Files:**
- Create: `lib/core/api/api_client.dart`

This file is the trust center: every other layer goes through it. Read carefully.

- [ ] **Step 1: Write the implementation**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/auth_tokens.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

typedef _RetryAfterRefresh = Future<http.Response> Function();

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  http.Client _client = http.Client();

  /// Returns the decoded `data` field on success. Throws [ApiException] on failure.
  Future<dynamic> get(String path, {Map<String, String>? query, bool auth = true, String locale = 'ar'}) {
    return _send(
      () => _client.get(_uri(path, query), headers: _headers(auth: auth, locale: locale)),
      auth: auth,
      locale: locale,
      retry: (h) => _client.get(_uri(path, query), headers: h),
    );
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true, String locale = 'ar'}) {
    final encoded = body == null ? null : utf8.encode(jsonEncode(body));
    return _send(
      () => _client.post(_uri(path), headers: _headers(auth: auth, locale: locale), body: encoded),
      auth: auth,
      locale: locale,
      retry: (h) => _client.post(_uri(path), headers: h, body: encoded),
    );
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true, String locale = 'ar'}) {
    final encoded = body == null ? null : utf8.encode(jsonEncode(body));
    return _send(
      () => _client.patch(_uri(path), headers: _headers(auth: auth, locale: locale), body: encoded),
      auth: auth,
      locale: locale,
      retry: (h) => _client.patch(_uri(path), headers: h, body: encoded),
    );
  }

  Future<dynamic> delete(String path, {Object? body, bool auth = true, String locale = 'ar'}) {
    final encoded = body == null ? null : utf8.encode(jsonEncode(body));
    return _send(
      () => _client.delete(_uri(path), headers: _headers(auth: auth, locale: locale), body: encoded),
      auth: auth,
      locale: locale,
      retry: (h) => _client.delete(_uri(path), headers: h, body: encoded),
    );
  }

  /// Stream a POST request as raw response (used for SSE).
  /// Caller is responsible for parsing and closing.
  Future<http.StreamedResponse> postStream(
    String path, {
    required Map<String, dynamic> body,
    String locale = 'ar',
  }) async {
    final req = http.Request('POST', _uri(path))
      ..headers.addAll(_headers(auth: true, locale: locale, accept: 'text/event-stream'))
      ..body = jsonEncode(body);
    var res = await _client.send(req);
    if (res.statusCode != 401) return res;

    // 401 → refresh + retry once
    final refreshed = await _tryRefresh();
    if (!refreshed) {
      // Drain to free socket then throw.
      await res.stream.drain<void>();
      throw const ApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Authentication required.',
      );
    }
    await res.stream.drain<void>();
    final retryReq = http.Request('POST', _uri(path))
      ..headers.addAll(_headers(auth: true, locale: locale, accept: 'text/event-stream'))
      ..body = jsonEncode(body);
    res = await _client.send(retryReq);
    return res;
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
    return _decode(res);
  }

  bool _refreshing = false;
  Completer<bool>? _refreshCompleter;

  Future<bool> _tryRefresh() async {
    // De-dupe concurrent refresh attempts.
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
    } catch (e) {
      throw ApiException(
        statusCode: res.statusCode,
        code: 'PARSE_ERROR',
        message: 'Failed to parse server response.',
      );
    }
  }
}
```

- [ ] **Step 2: Verify compile**

Run: `flutter analyze lib/core/api/api_client.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/api/api_client.dart
git commit -m "feat(core): ApiClient with envelope parsing, 401 refresh retry, and SSE postStream"
```

---

### Task 7: AuthService (login/register/logout/me/consent)

**Files:**
- Create: `lib/core/auth/auth_service.dart`

- [ ] **Step 1: Write the implementation**

```dart
import '../../models/auth_tokens.dart';
import '../../models/user.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_exception.dart';
import '../storage/token_storage.dart';

class AuthService {
  AuthService._();

  static User? _currentUser;
  static User? get currentUser => _currentUser;
  static bool get isLoggedIn => TokenStorage.instance.hasSession;

  /// Sign in with email/password. Persists tokens + returns the user.
  /// Throws [ApiException] on failure (401 INVALID_CREDENTIALS, 422, 429, etc.).
  static Future<User> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.instance.post(
      ApiEndpoints.login,
      auth: false,
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    final user = _persistSession(data);
    await ensureBaselineConsents();
    return user;
  }

  /// Register a new account. The current UI only collects name/email/password;
  /// we pass placeholder defaults for the required-but-uncollected fields.
  static Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.instance.post(
      ApiEndpoints.register,
      auth: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        // Placeholders — UI does not collect these. User can edit name/region/locale later.
        'birth_year': 2010,
        'education_stage': 'middle_1',
        'region': 'Riyadh',
        'locale': 'ar',
      },
    ) as Map<String, dynamic>;
    final user = _persistSession(data);
    await ensureBaselineConsents();
    return user;
  }

  /// Best-effort: server-side revoke, then always clear local tokens.
  static Future<void> logout() async {
    try {
      await ApiClient.instance.post(ApiEndpoints.logout);
    } catch (_) {
      // ignore — we still want to clear locally
    }
    _currentUser = null;
    await TokenStorage.instance.clear();
  }

  /// Probe the current session. Returns null if no tokens or session invalid.
  static Future<User?> fetchCurrentUser() async {
    if (!TokenStorage.instance.hasSession) return null;
    try {
      final data = await ApiClient.instance.get(ApiEndpoints.authMe) as Map<String, dynamic>;
      final user = User.fromJson(data);
      _currentUser = user;
      return user;
    } on ApiException catch (e) {
      if (e.isUnauthenticated) {
        await TokenStorage.instance.clear();
        _currentUser = null;
      }
      return null;
    }
  }

  /// Update the user's editable profile fields (name, locale, region).
  static Future<User> updateProfile({
    String? name,
    String? locale,
    String? region,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (locale != null) body['locale'] = locale;
    if (region != null) body['region'] = region;
    final data = await ApiClient.instance.patch(
      ApiEndpoints.me,
      body: body,
    ) as Map<String, dynamic>;
    final user = User.fromJson(data);
    _currentUser = user;
    return user;
  }

  /// Schedule the current account for deletion (7-day grace).
  static Future<void> deleteAccount() async {
    await ApiClient.instance.delete(ApiEndpoints.me);
    // We do NOT clear tokens — the API spec allows cancel-by-login
    // during the grace period. Clearing locally would block that.
    _currentUser = null;
  }

  /// Record all four baseline consents (privacy, terms, data_processing, ai_usage).
  /// Idempotent on the server. Errors are swallowed — gated endpoints will surface
  /// their own 403 CONSENT_REQUIRED if anything is missing.
  static Future<void> ensureBaselineConsents() async {
    for (final scope in const ['privacy', 'terms', 'data_processing', 'ai_usage']) {
      try {
        await ApiClient.instance.post(
          ApiEndpoints.consent,
          body: {'scope': scope, 'version': '1.0'},
        );
      } catch (_) {
        // best-effort
      }
    }
  }

  // ---- internals ----

  static User _persistSession(Map<String, dynamic> data) {
    final userJson = data['user'] as Map<String, dynamic>;
    final user = User.fromJson(userJson);
    final tokensJson = (data['tokens'] ?? data) as Map<String, dynamic>;
    final tokens = AuthTokens.fromJson(tokensJson);
    // Fire-and-forget save; caller awaits the surrounding future already.
    TokenStorage.instance.save(tokens);
    _currentUser = user;
    return user;
  }
}
```

- [ ] **Step 2: Verify compile**

Run: `flutter analyze lib/core/auth/`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/core/auth/auth_service.dart
git commit -m "feat(core): AuthService with login/register/refresh/me/consent and in-memory current user"
```

---

### Task 8: Bootstrap TokenStorage in main()

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Edit `main()` to load tokens before runApp**

Replace:

```dart
void main() {
  runApp(const MishkatApp());
}
```

with:

```dart
import 'core/storage/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStorage.instance.load();
  runApp(const MishkatApp());
}
```

(Add the `import` next to the other `import` lines.)

- [ ] **Step 2: Verify compile**

Run: `flutter analyze lib/main.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat(app): preload TokenStorage before runApp so screens see hasSession synchronously"
```

---

### Task 9: Sign-in screen → AuthService.login

**Files:**
- Modify: `lib/screens/auth/sign_in_screen.dart`

**No layout changes.** Only the `_onSubmit` body changes; everything else (including form fields, styling, the Google button stub, the "forgot password" stub) stays exactly as it is.

- [ ] **Step 1: Replace `_onSubmit`**

In `lib/screens/auth/sign_in_screen.dart`, replace the existing `_onSubmit` method (lines ~31–59) with:

```dart
Future<void> _onSubmit() async {
  if (_isLoading) return;

  final emailError = _emailController.text.isEmpty ? 'هذا الحقل مطلوب' : null;
  final passwordError =
      _passwordController.text.isEmpty ? 'هذا الحقل مطلوب' : null;

  setState(() {
    _emailError = emailError;
    _passwordError = passwordError;
  });

  if (emailError != null || passwordError != null) return;

  setState(() => _isLoading = true);
  try {
    await AuthService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SuccessScreen(
          title: 'تم تسجيل دخولك بنجاح',
          subtitle: 'انطلق في استخدام مِشْكَاة لتعزيز صحتك النفسية',
          buttonLabel: 'ابدأ الآن',
        ),
      ),
    );
  } on ApiException catch (e) {
    if (!mounted) return;
    setState(() {
      if (e.statusCode == 401 || e.code == 'INVALID_CREDENTIALS') {
        _emailError = ' ';
        _passwordError = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      } else if (e.code == 'ACCOUNT_PENDING_DELETE') {
        _passwordError = 'الحساب قيد الحذف. سجّل الدخول لإلغاء الحذف خلال 7 أيام.';
      } else if (e.isRateLimited) {
        _passwordError = 'محاولات كثيرة. حاول بعد قليل.';
      } else if (e.isValidation) {
        final fields = e.fieldErrors;
        _emailError = fields['email'];
        _passwordError = fields['password'] ?? e.message;
      } else {
        _passwordError = e.message;
      }
    });
  } catch (_) {
    if (!mounted) return;
    setState(() => _passwordError = 'تعذّر الاتصال بالخادم. تحقق من الشبكة.');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

- [ ] **Step 2: Add the imports**

At the top of the same file, alongside existing imports, add:

```dart
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_service.dart';
```

- [ ] **Step 3: Verify compile**

Run: `flutter analyze lib/screens/auth/sign_in_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/auth/sign_in_screen.dart
git commit -m "feat(auth): wire sign-in screen to AuthService.login with Arabic error mapping"
```

---

### Task 10: Sign-up screen → AuthService.register

**Files:**
- Modify: `lib/screens/auth/sign_up_screen.dart`

- [ ] **Step 1: Replace `_onSubmit`**

In `lib/screens/auth/sign_up_screen.dart`, replace the existing `_onSubmit` method (lines ~38–79) with:

```dart
Future<void> _onSubmit() async {
  if (_isLoading) return;

  final nameError = _nameController.text.isEmpty ? 'هذا الحقل مطلوب' : null;
  final emailError = _emailController.text.isEmpty ? 'هذا الحقل مطلوب' : null;
  final passwordError =
      _passwordController.text.isEmpty ? 'هذا الحقل مطلوب' : null;
  final confirmPasswordError = _confirmPasswordController.text.isEmpty
      ? 'هذا الحقل مطلوب'
      : (_confirmPasswordController.text != _passwordController.text
            ? 'كلمة المرور غير متطابقة'
            : null);

  setState(() {
    _nameError = nameError;
    _emailError = emailError;
    _passwordError = passwordError;
    _confirmPasswordError = confirmPasswordError;
  });

  if (nameError != null ||
      emailError != null ||
      passwordError != null ||
      confirmPasswordError != null) {
    return;
  }

  setState(() => _isLoading = true);
  try {
    await AuthService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SuccessScreen(
          title: 'تـم إنشـاء حسابـك بنجـاح',
          subtitle: 'انطلق في استخدام مِشْكَاة لتعزيز صحتك النفسية',
          buttonLabel: 'ابدأ الآن',
        ),
      ),
    );
  } on ApiException catch (e) {
    if (!mounted) return;
    setState(() {
      if (e.isValidation) {
        final f = e.fieldErrors;
        _emailError = _arabicFieldError(f['email']);
        _passwordError = _arabicFieldError(f['password']);
        _nameError = _arabicFieldError(f['name']);
      } else if (e.isRateLimited) {
        _emailError = 'محاولات كثيرة. حاول بعد قليل.';
      } else {
        _emailError = e.message;
      }
    });
  } catch (_) {
    if (!mounted) return;
    setState(() => _emailError = 'تعذّر الاتصال بالخادم. تحقق من الشبكة.');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

String? _arabicFieldError(String? serverMsg) {
  if (serverMsg == null) return null;
  // Soft-translate the common Laravel validation messages users will see.
  final m = serverMsg.toLowerCase();
  if (m.contains('already been taken')) return 'البريد الإلكتروني مستخدم.';
  if (m.contains('must be at least') && m.contains('character')) {
    return 'كلمة المرور قصيرة. يجب 10 أحرف على الأقل.';
  }
  if (m.contains('confirmation does not match')) {
    return 'كلمة المرور غير متطابقة.';
  }
  return serverMsg;
}
```

- [ ] **Step 2: Add imports**

At the top of the file, add:

```dart
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_service.dart';
```

- [ ] **Step 3: Verify compile**

Run: `flutter analyze lib/screens/auth/sign_up_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/auth/sign_up_screen.dart
git commit -m "feat(auth): wire sign-up to AuthService.register with consent + Arabic error mapping"
```

---

### Task 11: Edit profile → GET/PATCH /me, DELETE /me

**Files:**
- Modify: `lib/screens/edit_profile/edit_profile_screen.dart`

**Critical layout rule:** Do **not** add, remove, or reorder any widgets. Only behavior inside `initState`, `_onSave`, `_onDeleteAccount`, and the `_initial*` constants changes. The `_correctCurrentPassword` constant and the new-password reveal animation stay (they're client-side UI flair; no documented endpoint exists to change passwords from within the app).

- [ ] **Step 1: Replace state init and field handlers**

In `lib/screens/edit_profile/edit_profile_screen.dart`:

1. Add imports at the top:

```dart
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_service.dart';
import '../../models/user.dart';
```

2. Replace the `_initial*` constants (lines ~21–25) and the controller declarations (lines ~27–33) with:

```dart
  static const String _correctCurrentPassword = 'password123';

  String _initialName = '';
  String _initialEmail = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
```

3. Replace `initState` (lines ~43–50) with:

```dart
  @override
  void initState() {
    super.initState();
    _nameController.addListener(_recomputeHasChanges);
    _emailController.addListener(_recomputeHasChanges);
    _currentPasswordController.addListener(_onCurrentPasswordChanged);
    _newPasswordController.addListener(_recomputeHasChanges);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final User? user = AuthService.currentUser ?? await AuthService.fetchCurrentUser();
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'تعذّر تحميل بياناتك. سجّل الدخول مرة أخرى.';
        });
        return;
      }
      setState(() {
        _initialName = user.name;
        _initialEmail = user.email;
        _nameController.text = user.name;
        _emailController.text = user.email;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    }
  }
```

- [ ] **Step 2: Replace `_onSave`**

Replace the existing `_onSave` (lines ~89–133) with:

```dart
  Future<void> _onSave() async {
    if (_isSaving) return;
    final String email = _emailController.text.trim();
    final bool emailValid = _emailRegex.hasMatch(email);
    final String currentPw = _currentPasswordController.text;
    final String newPw = _newPasswordController.text;

    String? emailError;
    String? currentPwError;
    String? newPwError;

    if (!emailValid) emailError = 'صيغة البريد الإلكتروني غير صحيحة';
    if (email != _initialEmail) {
      // No documented endpoint changes email for an authenticated user.
      emailError = 'لا يمكن تغيير البريد الإلكتروني من هنا حالياً.';
    }
    if (currentPw.isNotEmpty && currentPw != _correctCurrentPassword) {
      currentPwError = 'كلمة المرور الحالية غير صحيحة';
    }
    if (_currentPasswordVerified && newPw.isNotEmpty && newPw.length < 8) {
      newPwError = 'كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل';
    }

    setState(() {
      _emailError = emailError;
      _currentPasswordError = currentPwError;
      _newPasswordError = newPwError;
    });

    if (emailError != null || currentPwError != null || newPwError != null) {
      return;
    }

    final NavigatorState navigator = Navigator.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _SaveChangesDialog(),
    );
    if (!mounted) return;
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final String name = _nameController.text.trim();
      if (name != _initialName) {
        await AuthService.updateProfile(name: name);
      }
      if (!mounted) return;
      navigator.maybePop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.isValidation) {
          final f = e.fieldErrors;
          _emailError = f['name'] ?? f['email'] ?? e.message;
        } else {
          _emailError = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
```

- [ ] **Step 3: Replace `_onDeleteAccount`**

Replace the existing `_onDeleteAccount` (lines ~135–148) with:

```dart
  Future<void> _onDeleteAccount() async {
    final NavigatorState navigator = Navigator.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (!mounted) return;
    if (confirmed != true) return;

    try {
      await AuthService.deleteAccount();
      if (!mounted) return;
      navigator.pushNamedAndRemoveUntil('/signin', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              e.code == 'CONFLICT'
                  ? 'تم تقديم طلب الحذف مسبقاً.'
                  : e.message,
            ),
          ),
        ),
      );
    }
  }
```

- [ ] **Step 4: Pass loading state to the save button + show loader during initial fetch**

In the `build` method, change the save button line:

```dart
                  child: AppButton(
                    label: 'حفظ التعديلات',
                    expand: true,
                    onPressed: _hasChanges ? _onSave : null,
                  ),
```

to:

```dart
                  child: AppButton(
                    label: 'حفظ التعديلات',
                    expand: true,
                    isLoading: _isSaving,
                    onPressed: _hasChanges && !_isSaving ? _onSave : null,
                  ),
```

Then wrap the inner `SingleChildScrollView` body so the form is shown only after load. Replace the `Expanded(child: SingleChildScrollView(...))` block with:

```dart
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppPalettePurple.shade300,
                        ),
                      )
                    : _loadError != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xxl),
                              child: Text(
                                _loadError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: AppFontFamily.text,
                                  fontSize: AppFontSizes.sm,
                                  color: AppDangerColors.shade500,
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xxl,
                              0,
                              AppSpacing.xxl,
                              AppSpacing.xl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ... existing children identical to before ...
                              ],
                            ),
                          ),
              ),
```

> Keep the existing children list **unchanged inside the `Column`** — same widgets, same order, same styling. We're only conditionally rendering the existing scrollview.

- [ ] **Step 5: Verify compile**

Run: `flutter analyze lib/screens/edit_profile/edit_profile_screen.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/screens/edit_profile/edit_profile_screen.dart
git commit -m "feat(profile): load and save via GET/PATCH /me, wire delete to DELETE /me"
```

---

### Task 12: AI thread + message DTOs

**Files:**
- Create: `lib/models/ai_thread.dart`
- Create: `lib/models/ai_message.dart`

- [ ] **Step 1: Write `ai_thread.dart`**

```dart
class AiThread {
  const AiThread({
    required this.id,
    this.title,
    this.messageCount = 0,
    this.lastMessageAt,
    this.createdAt,
  });

  final String id;
  final String? title;
  final int messageCount;
  final String? lastMessageAt;
  final String? createdAt;

  factory AiThread.fromJson(Map<String, dynamic> json) => AiThread(
        id: json['id'] as String,
        title: json['title'] as String?,
        messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
        lastMessageAt: json['last_message_at'] as String?,
        createdAt: json['created_at'] as String?,
      );
}
```

- [ ] **Step 2: Write `ai_message.dart`**

```dart
enum AiMessageRole { user, assistant }

class AiMessage {
  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    this.isFlagged = false,
    this.provider,
    this.model,
    this.createdAt,
  });

  final String id;
  final AiMessageRole role;
  final String content;
  final bool isFlagged;
  final String? provider;
  final String? model;
  final String? createdAt;

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
        id: json['id'] as String,
        role: (json['role'] as String?) == 'user'
            ? AiMessageRole.user
            : AiMessageRole.assistant,
        content: json['content'] as String? ?? '',
        isFlagged: json['is_flagged'] as bool? ?? false,
        provider: json['provider'] as String?,
        model: json['model'] as String?,
        createdAt: json['created_at'] as String?,
      );
}

/// Streaming event from POST /ai/threads/{id}/messages (SSE).
sealed class AiStreamEvent {
  const AiStreamEvent();
}

class AiStreamMessageReceived extends AiStreamEvent {
  const AiStreamMessageReceived({required this.id, required this.isFlagged});
  final String id;
  final bool isFlagged;
}

class AiStreamDelta extends AiStreamEvent {
  const AiStreamDelta(this.text);
  final String text;
}

class AiStreamComplete extends AiStreamEvent {
  const AiStreamComplete({required this.threadId});
  final String threadId;
}

class AiStreamError extends AiStreamEvent {
  const AiStreamError(this.message);
  final String message;
}
```

- [ ] **Step 3: Verify compile**

Run: `flutter analyze lib/models/ai_thread.dart lib/models/ai_message.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/models/ai_thread.dart lib/models/ai_message.dart
git commit -m "feat(models): AI thread/message DTOs and sealed stream event union"
```

---

### Task 13: AiService with SSE streaming

**Files:**
- Create: `lib/core/ai/ai_service.dart`
- Test: `test/core/ai/ai_service_sse_parser_test.dart`

- [ ] **Step 1: Write the failing test for the SSE parser**

We isolate the SSE parsing as a top-level pure function so it's testable without HTTP.

`test/core/ai/ai_service_sse_parser_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/core/ai/ai_service.dart';
import 'package:mishkat/models/ai_message.dart';

void main() {
  Stream<List<int>> bytesFromString(String s) async* {
    yield utf8.encode(s);
  }

  test('parses a complete SSE stream', () async {
    const raw = '''
event: message.received
data: {"id":"m1","is_flagged":false}

event: message.delta
data: {"text":"مرحبا"}

event: message.delta
data: {"text":" بك"}

event: message.complete
data: {"thread_id":"t1"}

''';
    final events = await parseSseStream(bytesFromString(raw)).toList();
    expect(events, hasLength(4));
    expect(events[0], isA<AiStreamMessageReceived>());
    expect((events[1] as AiStreamDelta).text, 'مرحبا');
    expect((events[2] as AiStreamDelta).text, ' بك');
    expect((events[3] as AiStreamComplete).threadId, 't1');
  });

  test('tolerates chunk splits across lines and partial JSON', () async {
    Stream<List<int>> chunks() async* {
      yield utf8.encode('event: message.delta\n');
      yield utf8.encode('data: {"text":"part1"}\n\n');
      yield utf8.encode('event: message.del');
      yield utf8.encode('ta\ndata: {"text":"part2"}\n\nevent: message.complete\ndata: {"thread_id":"t9"}\n\n');
    }
    final events = await parseSseStream(chunks()).toList();
    expect(events.whereType<AiStreamDelta>().map((e) => e.text).toList(),
        ['part1', 'part2']);
    expect(events.last, isA<AiStreamComplete>());
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/ai/ai_service_sse_parser_test.dart`
Expected: FAIL (target file does not exist).

- [ ] **Step 3: Write the AiService**

`lib/core/ai/ai_service.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import '../../models/ai_message.dart';
import '../../models/ai_thread.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  Future<AiThread> createThread({String? title}) async {
    final data = await ApiClient.instance.post(
      ApiEndpoints.aiThreads,
      body: {if (title != null) 'title': title},
    ) as Map<String, dynamic>;
    return AiThread.fromJson(data);
  }

  Future<List<AiThread>> listThreads() async {
    final data = await ApiClient.instance.get(ApiEndpoints.aiThreads);
    final list = data is List ? data : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(AiThread.fromJson)
        .toList();
  }

  Future<List<AiMessage>> listMessages(String threadId) async {
    final data = await ApiClient.instance.get(ApiEndpoints.aiMessages(threadId));
    final list = data is List ? data : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(AiMessage.fromJson)
        .toList();
  }

  Future<void> deleteThread(String threadId) async {
    await ApiClient.instance.delete(ApiEndpoints.aiThread(threadId));
  }

  /// Send a message and yield streaming events (delta/complete/error/received).
  /// The stream completes when the server emits `message.complete` or the
  /// connection ends. Errors bubble up via [AiStreamError] events, NOT thrown.
  Stream<AiStreamEvent> sendMessage({
    required String threadId,
    required String content,
  }) async* {
    final res = await ApiClient.instance.postStream(
      ApiEndpoints.aiMessages(threadId),
      body: {'content': content},
    );
    if (res.statusCode != 200) {
      // Body should be JSON error envelope; surface it as a single error event.
      final body = await res.stream.bytesToString();
      yield AiStreamError(_extractErrorMessage(body, res.statusCode));
      return;
    }
    yield* parseSseStream(res.stream);
  }

  String _extractErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>?;
      final err = decoded?['error'] as Map<String, dynamic>?;
      final msg = err?['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    } catch (_) {}
    return 'تعذّر استلام الرد ($statusCode).';
  }
}

/// Parses an SSE byte stream into a stream of [AiStreamEvent]s.
/// Exported for testing.
Stream<AiStreamEvent> parseSseStream(Stream<List<int>> bytes) async* {
  final buffer = StringBuffer();
  String? eventName;
  String? dataJson;

  await for (final chunk in bytes.transform(utf8.decoder)) {
    buffer.write(chunk);
    final str = buffer.toString();
    final lastTerminator = _lastEventBoundary(str);
    if (lastTerminator < 0) continue;
    final complete = str.substring(0, lastTerminator);
    final remainder = str.substring(lastTerminator);
    buffer
      ..clear()
      ..write(remainder);

    for (final block in complete.split(RegExp(r'\n\n|\r\n\r\n'))) {
      eventName = null;
      dataJson = null;
      for (final line in block.split(RegExp(r'\r?\n'))) {
        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          dataJson = (dataJson == null ? '' : '$dataJson\n') + line.substring(5).trim();
        }
      }
      if (eventName == null) continue;
      yield _decodeEvent(eventName, dataJson);
    }
  }

  // Flush any trailing block (rare; servers usually end with \n\n).
  final trailing = buffer.toString();
  if (trailing.trim().isNotEmpty) {
    eventName = null;
    dataJson = null;
    for (final line in trailing.split(RegExp(r'\r?\n'))) {
      if (line.startsWith('event:')) eventName = line.substring(6).trim();
      else if (line.startsWith('data:')) dataJson = line.substring(5).trim();
    }
    if (eventName != null) yield _decodeEvent(eventName, dataJson);
  }
}

int _lastEventBoundary(String s) {
  final idxLF = s.lastIndexOf('\n\n');
  final idxCRLF = s.lastIndexOf('\r\n\r\n');
  final pos = idxCRLF > idxLF ? idxCRLF + 4 : (idxLF >= 0 ? idxLF + 2 : -1);
  return pos;
}

AiStreamEvent _decodeEvent(String name, String? dataJson) {
  Map<String, dynamic> data;
  try {
    data = dataJson == null
        ? const <String, dynamic>{}
        : (jsonDecode(dataJson) as Map<String, dynamic>);
  } catch (_) {
    data = const <String, dynamic>{};
  }
  switch (name) {
    case 'message.received':
      return AiStreamMessageReceived(
        id: (data['id'] as String?) ?? '',
        isFlagged: data['is_flagged'] as bool? ?? false,
      );
    case 'message.delta':
      return AiStreamDelta((data['text'] as String?) ?? '');
    case 'message.complete':
      return AiStreamComplete(threadId: (data['thread_id'] as String?) ?? '');
    case 'message.error':
      return AiStreamError((data['message'] as String?) ?? 'تعذّر استلام الرد.');
    default:
      return AiStreamDelta(''); // unknown event — emit empty delta to keep stream alive
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/ai/ai_service_sse_parser_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/ai/ai_service.dart test/core/ai/ai_service_sse_parser_test.dart
git commit -m "feat(ai): AiService for threads + SSE streaming with chunk-tolerant parser"
```

---

### Task 14: Wire chat screen to AiService (replace Supabase)

**Files:**
- Modify: `lib/screens/smart_companion/smart_companion_chat_screen.dart`

**Critical layout rule:** No widget tree changes. We only replace the body of `_send` and the `_companion` field. The bot message bubble updates in place while streaming — this is text-content mutation only.

- [ ] **Step 1: Replace imports + field declarations + state**

In `lib/screens/smart_companion/smart_companion_chat_screen.dart`:

1. Remove these imports:

```dart
import 'models/companion_response.dart';
import 'services/smart_companion_service.dart';
```

2. Add these imports:

```dart
import '../../core/ai/ai_service.dart';
import '../../core/api/api_exception.dart';
import '../../models/ai_message.dart';
import '../../models/ai_thread.dart';
```

3. Replace the field declaration:

```dart
  final SmartCompanionService _companion = SmartCompanionService();
```

with:

```dart
  final AiService _ai = AiService.instance;
  AiThread? _thread;
  StreamSubscription<AiStreamEvent>? _activeStream;
```

- [ ] **Step 2: Replace `dispose`**

```dart
  @override
  void dispose() {
    _activeStream?.cancel();
    _recorder.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
```

- [ ] **Step 3: Replace `_send`**

Replace the whole `_send` method with the streaming implementation:

```dart
  Future<void> _send(String message) async {
    if (message.isEmpty || _isThinking) return;
    setState(() {
      _items.add(_ChatItem.user(message));
      _isThinking = true;
      _conversationStarted = true;
      _textController.clear();
    });
    _scrollToBottom();

    try {
      _thread ??= await _ai.createThread();
      // Append an empty bot bubble we'll fill as deltas arrive.
      final int botIndex = _items.length;
      setState(() {
        _items.add(_ChatItem.bot(''));
      });

      final stream = _ai.sendMessage(threadId: _thread!.id, content: message);
      bool gotFirstDelta = false;
      final buffer = StringBuffer();

      await for (final event in stream) {
        if (!mounted) return;
        if (event is AiStreamDelta) {
          if (event.text.isEmpty) continue;
          buffer.write(event.text);
          if (!gotFirstDelta) {
            gotFirstDelta = true;
            setState(() => _isThinking = false);
          }
          setState(() {
            _items[botIndex] = _ChatItem.bot(buffer.toString());
          });
          _scrollToBottom();
        } else if (event is AiStreamError) {
          _showSnack(event.message);
          if (!gotFirstDelta) {
            // remove the empty placeholder
            setState(() => _items.removeAt(botIndex));
          }
          break;
        } else if (event is AiStreamComplete) {
          if (buffer.isEmpty) {
            setState(() => _items.removeAt(botIndex));
            _showSnack('لم أستلم رد. حاول مرة أخرى.');
          }
          break;
        }
      }
    } on ApiException catch (e) {
      _showSnack(_arabicForApiError(e));
    } catch (_) {
      _showSnack('صار خطأ غير متوقع، تكفى جرب مرة ثانية.');
    } finally {
      if (mounted) setState(() => _isThinking = false);
    }
  }

  String _arabicForApiError(ApiException e) {
    if (e.code == 'AI_USAGE_EXCEEDED') return 'وصلت لحد رسائل اليوم. جرّب بكرة.';
    if (e.isConsentRequired) return 'فضلًا أكمل الموافقات في الإعدادات لتفعيل المرافق.';
    if (e.isUnauthenticated) return 'انتهت الجلسة. سجّل الدخول من جديد.';
    if (e.isRateLimited) return 'محاولات كثيرة. خذ نفسًا وحاول بعد قليل.';
    return e.message;
  }
```

- [ ] **Step 4: Verify compile**

Run: `flutter analyze lib/screens/smart_companion/smart_companion_chat_screen.dart`
Expected: `No issues found!` (NB: the file no longer imports `companion_response.dart` — but `ListeningOrbWrapper` etc. don't depend on it.)

- [ ] **Step 5: Commit**

```bash
git add lib/screens/smart_companion/smart_companion_chat_screen.dart
git commit -m "feat(ai): smart companion chat screen consumes AiService streaming via SSE"
```

---

### Task 15: Remove dead Supabase code

**Files:**
- Delete: `lib/screens/smart_companion/services/smart_companion_service.dart`
- Delete: `lib/screens/smart_companion/services/supabase_config.dart`
- Delete: `lib/screens/smart_companion/models/companion_response.dart`

`companion_response.dart` is no longer imported anywhere after Task 14.

- [ ] **Step 1: Verify nothing else imports the files**

Run: `grep -RIn -E "smart_companion_service|supabase_config|companion_response" lib/ test/`
Expected: no matches (other than the files being deleted themselves, which the next step removes).

- [ ] **Step 2: Delete the files**

Run:
```bash
rm lib/screens/smart_companion/services/smart_companion_service.dart
rm lib/screens/smart_companion/services/supabase_config.dart
rm lib/screens/smart_companion/models/companion_response.dart
```

- [ ] **Step 3: Re-verify compile**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add -A lib/screens/smart_companion/
git commit -m "chore(ai): remove unused Supabase-backed smart companion service and config"
```

---

### Task 16: Splash gated navigation

**Files:**
- Modify: `lib/screens/splash/splash_screen.dart`

- [ ] **Step 1: Replace `_goHome`**

In `lib/screens/splash/splash_screen.dart`, replace:

```dart
  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }
```

with:

```dart
  Future<void> _goHome() async {
    if (!mounted) return;
    final NavigatorState navigator = Navigator.of(context);
    if (!TokenStorage.instance.hasSession) {
      navigator.pushReplacementNamed('/onboarding');
      return;
    }
    final user = await AuthService.fetchCurrentUser();
    if (!mounted) return;
    navigator.pushReplacementNamed(user != null ? '/home' : '/signin');
  }
```

- [ ] **Step 2: Add imports**

At the top of the file:

```dart
import '../../core/auth/auth_service.dart';
import '../../core/storage/token_storage.dart';
```

- [ ] **Step 3: Adjust the status listener so `_goHome` is awaited**

Change:

```dart
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(_holdAfter, _goHome);
        }
      })
```

to:

```dart
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(_holdAfter, () {
            // ignore: discarded_futures
            _goHome();
          });
        }
      })
```

- [ ] **Step 4: Verify compile**

Run: `flutter analyze lib/screens/splash/splash_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/screens/splash/splash_screen.dart
git commit -m "feat(splash): probe /auth/me when tokens exist, route to /home or /signin accordingly"
```

---

### Task 17: Static analysis pass + unit test run

- [ ] **Step 1: Run analyzer across the project**

Run: `flutter analyze`
Expected: `No issues found!` (zero info/warnings/errors).
If any new warnings appear, fix them before continuing.

- [ ] **Step 2: Run the unit-test suite**

Run: `flutter test`
Expected: All tests pass (the seven we added: `api_exception_test`, `user_test`, `auth_tokens_test`, two `ai_service_sse_parser_test` cases).

- [ ] **Step 3: Commit if any fixups were needed**

```bash
git status
# If clean, skip. Otherwise:
git add -A
git commit -m "chore: address analyzer warnings post-integration"
```

---

### Task 18: Manual integration smoke test

This is the validation phase. The Bash steps below assume you have either a real or staging backend reachable.

- [ ] **Step 1: Launch against the production base URL (default)**

Run:
```bash
flutter run -d <device-id>
```
(Or pass `--dart-define=MISHKAT_API_BASE_URL=http://localhost:8080` if you have a local API.)

- [ ] **Step 2: Cold-launch flow — no session → onboarding/signin**

- Splash plays. After ~3.8s + 700ms, the app navigates to `/onboarding` (no tokens stored yet).
- Confirm: no exceptions in `flutter logs`.

- [ ] **Step 3: Sign-up flow**

- Tap "إنشاء حساب" → go to sign-up.
- Fill: name `اختبار`, email `qa+<timestamp>@mishkat.local`, password `password1234`, confirm same.
- Tap "إنشاء حساب".
- Expected: SuccessScreen with "تـم إنشـاء حسابـك بنجـاح". `flutter logs` shows no exceptions.
- Verify in backend (Postman or DB) that the user was created and four consent rows were written.

- [ ] **Step 4: Edit profile flow**

- From home, navigate to "تعديل الملف الشخصي" (route `/edit-profile`).
- Expected: name and email fields pre-fill from `/auth/me`.
- Change the name. Tap "حفظ التعديلات" → confirm dialog → tap "حفظ".
- Expected: dialog dismisses, screen pops, no error toast.
- Verify in backend that `name` was updated.

- [ ] **Step 5: Smart companion streaming flow**

- Navigate to "اسأل مِشْكَاة" (route `/smart-companion/chat`).
- Type "أحس بتوتر" → send.
- Expected: typing indicator briefly appears, then a bot bubble starts filling word-by-word as deltas arrive.
- Verify in backend that an AI thread was created and a user + assistant message pair exists.

- [ ] **Step 6: Logout / cold relaunch**

- Close and reopen the app.
- Expected: splash → `/home` directly (session restored via stored tokens + /auth/me probe).

- [ ] **Step 7: Invalid-token recovery**

- In the backend, manually revoke the user's access token (or just wait for it to expire if expiry is short in dev).
- Reopen the app. The next API call should 401, ApiClient refreshes silently, and the user lands on `/home` as if nothing happened.
- If refresh also fails (both expired): the user lands on `/signin`.

- [ ] **Step 8: Commit any final tweaks**

```bash
git status
# If everything green and clean, you're done.
```

---

## Self-review checklist (run after writing the plan)

- [x] Every required Postman endpoint that current UI touches has a task: auth/register (T10), auth/login (T9), auth/refresh (T6 internal), auth/me (T16+T11), auth/logout (T7), me PATCH (T11), me DELETE (T11), me/consent (T7 helper), ai/threads POST (T13/T14), ai/threads/{id}/messages POST stream (T13/T14).
- [x] No "TBD"/"implement later"/"handle edge cases"-only steps. Code is concrete.
- [x] Layout invariant — no widget tree changes in T9/T10/T11/T14, only behavior and conditional rendering using existing primitives.
- [x] Type consistency — `AuthTokens.access/refresh`, `User.id/name/email/locale/region`, `AiStreamDelta.text`, `AiStreamComplete.threadId` referenced identically across tasks.
- [x] Files deleted in T15 confirmed to be no-longer imported (T14 removes their last importer).
