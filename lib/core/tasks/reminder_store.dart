import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Carries a gentle "لا تنسى" reminder from the افهم شعورك (understand-feelings)
/// flow to the home screen. When the user picks a need with no in-app activity
/// (أكلم شخص / أكمل يومي), we stash a short reminder here instead of creating a
/// real backend task — the home then surfaces it in a soft card (not in the
/// task list).
///
/// Scoped to the calendar day it was set: a reminder stashed on a previous day
/// is ignored (and cleared) so a stale prompt never lingers. Persisted via
/// secure storage so it survives an app restart on the same day. Mirrors
/// [StartActivityStore].
class ReminderStore extends ChangeNotifier {
  ReminderStore._();
  static final ReminderStore instance = ReminderStore._();

  static const _storageKey = 'mishkat.reminder.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _text;
  String? _date; // yyyy-mm-dd the reminder was set for
  bool _loaded = false;

  /// The reminder text for *today*, or null if none is set (or the stored one
  /// is from a previous day).
  String? get textForToday {
    if (_text == null || _date != _todayKey()) return null;
    return _text;
  }

  static String _todayKey() {
    final DateTime now = DateTime.now();
    final String mm = now.month.toString().padLeft(2, '0');
    final String dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final String? raw = await _storage.read(key: _storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(raw) as Map<String, dynamic>;
        _text = decoded['text'] as String?;
        _date = decoded['date'] as String?;
      } catch (_) {
        await _storage.delete(key: _storageKey);
      }
    }
    // Drop a reminder left over from a previous day.
    if (_date != _todayKey()) {
      _text = null;
      _date = null;
    }
    notifyListeners();
  }

  /// Stash [text] as today's reminder (from افهم شعورك).
  Future<void> set(String text) async {
    _text = text;
    _date = _todayKey();
    notifyListeners();
    await _persist();
  }

  /// Clear the reminder (e.g. once the user dismisses the card).
  Future<void> clear() async {
    if (_text == null && _date == null) return;
    _text = null;
    _date = null;
    notifyListeners();
    await _storage.delete(key: _storageKey);
  }

  Future<void> _persist() async {
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(<String, dynamic>{'text': _text, 'date': _date}),
    );
  }
}
