import 'package:flutter/foundation.dart';

import '../../models/focus_preset.dart';

// FocusIntentBus — tiny event channel between home-screen entry
// points (task pill, خذ لحظة تركيز card) and the التركيز screen.
//
// Home calls `requestStart(...)` then `MainShell.jumpTo(focusIndex)`;
// the focus screen consumes the intent on entry and acts on it
// (preselect task + open preset picker, or just show the tab).
//
// Single-shot semantics: every consume() clears the intent so a later
// random tab switch doesn't accidentally re-trigger the picker.
class FocusIntentBus extends ChangeNotifier {
  FocusIntentBus._();
  static final FocusIntentBus instance = FocusIntentBus._();

  String? _taskId;
  bool _openPicker = false;
  FocusPreset? _preset;

  String? get taskId => _taskId;
  bool get openPicker => _openPicker;
  FocusPreset? get preset => _preset;
  bool get hasIntent => _openPicker || _taskId != null || _preset != null;

  void requestStart({String? taskId, bool openPicker = false, FocusPreset? preset}) {
    _taskId = taskId;
    _openPicker = openPicker;
    _preset = preset;
    notifyListeners();
  }

  ({String? taskId, bool openPicker, FocusPreset? preset}) consume() {
    final out = (taskId: _taskId, openPicker: _openPicker, preset: _preset);
    _taskId = null;
    _openPicker = false;
    _preset = null;
    return out;
  }
}
