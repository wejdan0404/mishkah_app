import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';

// FocusService — owner of /api/v1/focus/today snapshot for the
// التركيز screen progress card AND the إنهيت اليوم marker.
//
// Mirrors JourneyService:
//   - ChangeNotifier so the UI rebuilds reactively.
//   - In-flight refresh dedupe so concurrent calls don't double-hit
//     the API.
//   - Failures don't throw — `lastError` carries the message.
class FocusService extends ChangeNotifier {
  FocusService._();
  static final FocusService instance = FocusService._();

  int? _completedToday;
  int _dailyGoal = 4;
  bool _finishedToday = false;
  DateTime? _finishedAt;
  bool _loading = false;
  String? _lastError;
  Future<void>? _inflight;

  int? get completedToday => _completedToday;
  int get dailyGoal => _dailyGoal;
  bool get finishedToday => _finishedToday;
  DateTime? get finishedAt => _finishedAt;
  bool get loading => _loading;
  String? get lastError => _lastError;
  bool get hasData => _completedToday != null;

  Future<void> refresh() {
    final existing = _inflight;
    if (existing != null) return existing;

    _loading = true;
    notifyListeners();

    final future = _performRefresh();
    _inflight = future;
    future.whenComplete(() {
      _loading = false;
      _inflight = null;
      notifyListeners();
    });
    return future;
  }

  /// Toggle the per-day "أنهيت اليوم" marker. Optimistic — flips the
  /// local flag immediately, then sends the request. On failure the
  /// flag rolls back and `lastError` is set so the UI can surface it.
  Future<bool> toggleFinishedToday() async {
    final previousFlag = _finishedToday;
    final previousAt = _finishedAt;
    _finishedToday = !previousFlag;
    _finishedAt = _finishedToday ? DateTime.now() : null;
    notifyListeners();

    try {
      final endpoint = ApiEndpoints.focusTodayFinish;
      final dynamic data = previousFlag
          ? await ApiClient.instance.delete(endpoint)
          : await ApiClient.instance.post(endpoint);
      if (data is Map<String, dynamic>) {
        _hydrate(data);
      }
      _lastError = null;
      return true;
    } catch (e) {
      _finishedToday = previousFlag;
      _finishedAt = previousAt;
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _completedToday = null;
    _finishedToday = false;
    _finishedAt = null;
    _lastError = null;
    notifyListeners();
  }

  // ---- internals ----

  Future<void> _performRefresh() async {
    try {
      final dynamic data = await ApiClient.instance.get(ApiEndpoints.focusToday);
      if (data is Map<String, dynamic>) {
        _hydrate(data);
        _lastError = null;
      } else {
        _lastError = 'Unexpected /focus/today shape.';
      }
    } catch (e) {
      _lastError = e.toString();
    }
  }

  void _hydrate(Map<String, dynamic> data) {
    _completedToday = (data['completed_today'] as num?)?.toInt() ?? 0;
    _dailyGoal = (data['daily_goal'] as num?)?.toInt() ?? _dailyGoal;
    _finishedToday = data['finished_today'] == true;
    final at = data['finished_at'];
    _finishedAt = (at is String) ? DateTime.tryParse(at) : null;
  }
}
