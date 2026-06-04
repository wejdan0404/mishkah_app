import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Carries the "ابدأ نشاطك المبني على فهمك لشعورك" signal from the افهم شعورك
/// (understand-feelings) flow to the home screen. When the user finishes that
/// flow and asks to act now (أهدأ شوي / آخذ بريك), we stash the mood inferred
/// from their emotion + intensity here. The home then asks the recommender for
/// that mood's top activities and shows them in a dedicated card — separate
/// from "أنشطة تناسب مزاجك", which stays pinned to the manually-recorded mood.
///
/// Scoped to the calendar day it was set: a mood stashed on a previous day is
/// ignored (and cleared) so a stale prompt never lingers. Persisted via secure
/// storage so it survives an app restart on the same day.
class StartActivityStore extends ChangeNotifier {
  StartActivityStore._();
  static final StartActivityStore instance = StartActivityStore._();

  static const _storageKey = 'mishkat.start_activity.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String? _mood;
  String? _date; // yyyy-mm-dd the mood was set for
  bool _loaded = false;

  /// The inferred mood slug for *today*, or null if none is set (or the stored
  /// one is from a previous day).
  String? get moodForToday {
    if (_mood == null || _date != _todayKey()) return null;
    return _mood;
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
        _mood = decoded['mood'] as String?;
        _date = decoded['date'] as String?;
      } catch (_) {
        await _storage.delete(key: _storageKey);
      }
    }
    // Drop a mood left over from a previous day.
    if (_date != _todayKey()) {
      _mood = null;
      _date = null;
    }
    notifyListeners();
  }

  /// Stash [mood] as today's "ابدأ نشاطك" mood (inferred from افهم شعورك).
  Future<void> setMood(String mood) async {
    _mood = mood;
    _date = _todayKey();
    notifyListeners();
    await _persist();
  }

  /// Clear the mood (e.g. once the user has opened one of the suggestions).
  Future<void> clear() async {
    if (_mood == null && _date == null) return;
    _mood = null;
    _date = null;
    notifyListeners();
    await _storage.delete(key: _storageKey);
  }

  Future<void> _persist() async {
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(<String, dynamic>{'mood': _mood, 'date': _date}),
    );
  }
}
