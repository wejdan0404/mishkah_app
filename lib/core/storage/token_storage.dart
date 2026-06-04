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
