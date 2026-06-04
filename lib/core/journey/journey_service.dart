import 'package:flutter/foundation.dart';

import '../../models/journey_snapshot.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

// JourneyService — owner of the /api/v1/me/journey snapshot.
//
// A ChangeNotifier so the رحلتي screen can rebuild reactively whenever
// snapshot or loading state changes. Three responsibilities:
//
//   - `refresh()` performs the round-trip. `loading` is true for the
//     duration of the request so the UI can render a spinner without
//     keeping its own loading flag.
//   - `latest` is the last-known snapshot the رحلتي screen renders
//     against, which lets the screen draw immediately on revisit (no
//     flash of empty) while a fresh fetch happens in the background.
//   - Concurrent calls collapse onto the in-flight request so the home
//     screen's post-check-in refresh and the screen's tab-switch refresh
//     don't both hammer the API.
//
// Failures don't throw: `lastError` carries the message so callers decide
// whether to surface it.
class JourneyService extends ChangeNotifier {
  JourneyService._();
  static final JourneyService instance = JourneyService._();

  JourneySnapshot? _snapshot;
  String? _lastError;
  bool _loading = false;
  Future<JourneySnapshot?>? _inflight;

  JourneySnapshot? get latest => _snapshot;
  String? get lastError => _lastError;
  bool get loading => _loading;
  bool get hasData => _snapshot != null;

  Future<JourneySnapshot?> refresh() {
    final existing = _inflight;
    if (existing != null) return existing;

    _loading = true;
    // Don't blow away the cached snapshot — the UI keeps drawing the
    // last-known data while the new fetch is in flight.
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

  /// Drop the cached snapshot. Called on sign-out so the next signed-in
  /// user doesn't briefly see the previous user's stats.
  void clear() {
    _snapshot = null;
    _lastError = null;
    notifyListeners();
  }

  Future<JourneySnapshot?> _performRefresh() async {
    try {
      final dynamic data = await ApiClient.instance.get(ApiEndpoints.meJourney);
      if (data is Map<String, dynamic>) {
        _snapshot = JourneySnapshot.fromJson(data);
        _lastError = null;
        return _snapshot;
      }
      _lastError = 'Unexpected /me/journey shape.';
      return _snapshot;
    } catch (e) {
      _lastError = e.toString();
      return _snapshot;
    }
  }
}
