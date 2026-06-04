import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers whether we've already shown the one-time notifications priming
/// prompt after the user's first entry to the home shell.
class NotificationsPromptFlag {
  NotificationsPromptFlag._();

  static const String _key = 'mishkat.notifications.prompted';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<bool> hasPrompted() async =>
      (await _storage.read(key: _key)) == 'true';

  static Future<void> markPrompted() =>
      _storage.write(key: _key, value: 'true');
}
