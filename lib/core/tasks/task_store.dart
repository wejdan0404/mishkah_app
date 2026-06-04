import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/task_item.dart';

class TaskStore extends ChangeNotifier {
  TaskStore._();
  static final TaskStore instance = TaskStore._();

  static const _storageKey = 'mishkat.tasks.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final List<TaskItem> _tasks = [];
  bool _loaded = false;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<TaskItem> get remaining =>
      _tasks.where((t) => !t.isCompleted).toList(growable: false);
  List<TaskItem> get completed =>
      _tasks.where((t) => t.isCompleted).toList(growable: false);

  Future<void> load() async {
    if (_loaded) return;
    final String? raw = await _storage.read(key: _storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _tasks
          ..clear()
          ..addAll(decoded
              .map((e) => TaskItem.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        await _storage.delete(key: _storageKey);
      }
    }
    _loaded = true;
    notifyListeners();
  }

  /// Replace the in-memory list with the server's view. Used by
  /// `TaskService.load()` after a successful GET /tasks so consumers
  /// like the home _TasksCard re-render with backend-truth data.
  void replaceAll(List<TaskItem> tasks) {
    _tasks
      ..clear()
      ..addAll(tasks);
    _loaded = true;
    notifyListeners();
    // Best-effort persistence; failure here only hurts offline reloads,
    // not the current session.
    _persist();
  }

  /// Merge a server-provided task into the local list (used when the
  /// backend assigned the canonical id for an optimistically-added row).
  Future<void> adoptRemote(TaskItem item) async {
    // Replace any local row with the same id; otherwise append.
    final i = _tasks.indexWhere((t) => t.id == item.id);
    if (i >= 0) {
      _tasks[i] = item;
    } else {
      _tasks.add(item);
    }
    notifyListeners();
    await _persist();
  }

  Future<TaskItem> add(String label) async {
    final String trimmed = label.trim();
    final TaskItem task = TaskItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: trimmed,
    );
    _tasks.add(task);
    notifyListeners();
    await _persist();
    return task;
  }

  Future<void> setCompleted(String id, bool isCompleted) async {
    final int i = _tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    if (_tasks[i].isCompleted == isCompleted) return;
    _tasks[i] = _tasks[i].copyWith(isCompleted: isCompleted);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    final int before = _tasks.length;
    _tasks.removeWhere((t) => t.id == id);
    if (_tasks.length == before) return;
    notifyListeners();
    await _persist();
  }

  /// Rename a task's label in place (optimistic; persisted locally). No-op for
  /// a blank label, a missing id, or an unchanged label.
  Future<void> rename(String id, String label) async {
    final String trimmed = label.trim();
    if (trimmed.isEmpty) return;
    final int i = _tasks.indexWhere((t) => t.id == id);
    if (i == -1 || _tasks[i].label == trimmed) return;
    _tasks[i] = _tasks[i].copyWith(label: trimmed);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await _storage.write(key: _storageKey, value: encoded);
  }
}
