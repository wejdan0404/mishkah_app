import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// App-wide dark-mode flag, toggled from the Profile screen and persisted
/// across launches. Exposed as a [ValueListenable] so any widget can rebuild
/// itself the moment the user flips the switch — no global theme rebuild
/// required.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _darkKey = 'mishkat.theme.dark';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);
  bool _loaded = false;

  bool get isDark => darkMode.value;

  Future<void> load() async {
    if (_loaded) return;
    darkMode.value = (await _storage.read(key: _darkKey)) == 'true';
    _loaded = true;
  }

  Future<void> setDarkMode(bool value) async {
    if (darkMode.value == value) return;
    darkMode.value = value;
    await _storage.write(key: _darkKey, value: value ? 'true' : 'false');
  }
}
