import 'package:flutter/foundation.dart';

import '../../models/focus_preset.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

// FocusPresetsService — caches the /focus/presets list and feeds the
// _PresetsCard widget on the التركيز tab. Same shape as JourneyService
// / FocusService: ChangeNotifier, in-flight dedupe, never throws.
class FocusPresetsService extends ChangeNotifier {
  FocusPresetsService._();
  static final FocusPresetsService instance = FocusPresetsService._();

  List<FocusPreset> _presets = const [];
  bool _loading = false;
  String? _lastError;
  Future<void>? _inflight;

  List<FocusPreset> get presets => _presets;
  bool get loading => _loading;
  String? get lastError => _lastError;
  bool get hasData => _presets.isNotEmpty;

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

  void clear() {
    _presets = const [];
    _lastError = null;
    notifyListeners();
  }

  Future<void> _performRefresh() async {
    try {
      final dynamic data = await ApiClient.instance.get(ApiEndpoints.focusPresets);
      if (data is Map<String, dynamic> && data['presets'] is List) {
        final raw = data['presets'] as List;
        _presets = raw
            .whereType<Map<String, dynamic>>()
            .map(FocusPreset.fromJson)
            .toList(growable: false);
        _lastError = null;
      } else {
        _lastError = 'Unexpected /focus/presets shape.';
      }
    } catch (e) {
      _lastError = e.toString();
    }
  }
}
