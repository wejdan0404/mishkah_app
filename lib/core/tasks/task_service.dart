import 'package:flutter/foundation.dart';

import '../../models/task_item.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'task_store.dart';

// TaskService — backend-synced task list.
//
// The home + focus screens render from `TaskStore.instance` via
// AnimatedBuilder. To avoid changing every widget's data source, this
// service is a write-through cache: it fetches GET /tasks, hydrates
// TaskStore with the result, and forwards local mutations (add /
// complete / remove) to the server while keeping the local store
// optimistically in sync. Widgets keep listening to TaskStore.
//
// Failures don't throw — `lastError` carries the message.
class TaskService extends ChangeNotifier {
  TaskService._();
  static final TaskService instance = TaskService._();

  bool _loading = false;
  bool _hasLoaded = false;
  String? _lastError;
  Future<void>? _inflight;

  bool get loading => _loading;
  String? get lastError => _lastError;

  /// True once the first backend fetch has completed (success or failure).
  /// Lets UI tell "we're fetching for the first time and don't know the list
  /// yet" (show a loader) apart from "fetched already, the list is just empty"
  /// (show the empty state) — and avoids re-showing the loader on later
  /// refreshes when we already have an answer.
  bool get hasLoaded => _hasLoaded;

  /// True only during the very first fetch, before any result is in. UI uses
  /// this to gate the first-load spinner without flickering it on refreshes.
  bool get firstLoad => _loading && !_hasLoaded;

  Future<void> load() {
    final existing = _inflight;
    if (existing != null) return existing;

    _loading = true;
    notifyListeners();

    final future = _performLoad();
    _inflight = future;
    future.whenComplete(() {
      _loading = false;
      _hasLoaded = true;
      _inflight = null;
      notifyListeners();
    });
    return future;
  }

  Future<TaskItem?> add(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return null;
    try {
      final dynamic data = await ApiClient.instance.post(
        ApiEndpoints.tasks,
        body: {'title': trimmed},
      );
      final TaskItem item = _itemFromJson(data as Map<String, dynamic>);
      // Push into the local store so existing AnimatedBuilders rebuild.
      await TaskStore.instance.adoptRemote(item);
      _lastError = null;
      return item;
    } catch (e) {
      _lastError = e.toString();
      return null;
    }
  }

  Future<bool> complete(String id) async {
    try {
      await ApiClient.instance.post(ApiEndpoints.taskComplete(id));
      await TaskStore.instance.setCompleted(id, true);
      _lastError = null;
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await ApiClient.instance.delete(ApiEndpoints.task(id));
      await TaskStore.instance.remove(id);
      _lastError = null;
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> update(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;
    try {
      await ApiClient.instance.patch(
        ApiEndpoints.task(id),
        body: {'title': trimmed},
      );
      await TaskStore.instance.rename(id, trimmed);
      _lastError = null;
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  void clear() {
    _hasLoaded = false;
    TaskStore.instance.replaceAll(const []);
  }

  // ---- internals ----

  Future<void> _performLoad() async {
    try {
      final dynamic data = await ApiClient.instance.get(ApiEndpoints.tasks);
      if (data is List) {
        final list = data
            .whereType<Map<String, dynamic>>()
            .map(_itemFromJson)
            .toList(growable: false);
        TaskStore.instance.replaceAll(list);
        _lastError = null;
      } else if (data is Map<String, dynamic> && data['items'] is List) {
        // Some envelopes nest the list under `items`.
        final raw = data['items'] as List;
        final list = raw
            .whereType<Map<String, dynamic>>()
            .map(_itemFromJson)
            .toList(growable: false);
        TaskStore.instance.replaceAll(list);
        _lastError = null;
      } else {
        _lastError = 'Unexpected /tasks shape.';
      }
    } catch (e) {
      _lastError = e.toString();
    }
  }

  TaskItem _itemFromJson(Map<String, dynamic> j) {
    final String id = (j['id'] ?? '').toString();
    final String label = (j['title'] ?? j['label'] ?? '').toString();
    final String? status = j['status'] as String?;
    final bool completed = status == 'completed' || j['is_completed'] == true;
    return TaskItem(id: id, label: label, isCompleted: completed);
  }
}
