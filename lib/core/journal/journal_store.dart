import 'package:flutter/foundation.dart';

import '../../models/journal_entry.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// Server-persisted مساحة التدوين (was device-only). Entries live in
/// `/me/journal`; this store keeps an in-memory mirror for the UI and a
/// ChangeNotifier so screens rebuild.
///
/// Writes are OPTIMISTIC: the UI's add/edit/delete/pin calls are fire-and-
/// forget (the writing screen pops immediately), so we mutate the local list +
/// notify right away, then sync to the backend and reconcile/revert on the
/// response. Reads (`load`) replace the mirror from the server.
class JournalStore extends ChangeNotifier {
  JournalStore._();
  static final JournalStore instance = JournalStore._();

  static const int maxPinned = 3;

  final List<JournalEntry> _entries = <JournalEntry>[];

  int get pinnedCount => _entries.where((e) => e.isPinned).length;

  List<JournalEntry> get entries {
    final List<JournalEntry> sorted = List<JournalEntry>.from(_entries);
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return List.unmodifiable(sorted);
  }

  /// Fetch the entries from the backend and replace the mirror. Best-effort:
  /// on error (offline / not signed in) the current list is kept.
  Future<void> load() async {
    try {
      final dynamic data = await ApiClient.instance.get(ApiEndpoints.journal);
      if (data is List) {
        final List<JournalEntry> fetched = data
            .whereType<Map<String, dynamic>>()
            .map(JournalEntry.fromJson)
            .toList();
        _entries
          ..clear()
          ..addAll(fetched);
        notifyListeners();
      }
    } catch (_) {
      // keep whatever we already have
    }
  }

  /// Clear the in-memory mirror (on sign-out).
  void clear() {
    _entries.clear();
    notifyListeners();
  }

  Future<JournalEntry> add({
    required String title,
    required String body,
    String? topicId,
    String? mood,
    List<dynamic>? bodyDelta,
  }) async {
    // Optimistic local insert with a temp id so the list updates instantly.
    final DateTime now = DateTime.now();
    final String tempId = 'local-${now.microsecondsSinceEpoch}';
    final JournalEntry optimistic = JournalEntry(
      id: tempId,
      title: title.trim(),
      body: body.trim(),
      createdAt: now,
      updatedAt: now,
      topicId: topicId,
      mood: mood,
      bodyDelta: bodyDelta,
    );
    _entries.insert(0, optimistic);
    notifyListeners();

    try {
      final dynamic data = await ApiClient.instance.post(
        ApiEndpoints.journal,
        body: {
          'title': title.trim(),
          'body': body.trim(),
          'topic_id': ?topicId,
          'mood': ?mood,
          // Sent when present; ignored by the backend until it adds the column.
          'body_delta': ?bodyDelta,
        },
      );
      if (data is Map<String, dynamic>) {
        final JournalEntry saved = JournalEntry.fromJson(data);
        final int i = _entries.indexWhere((e) => e.id == tempId);
        if (i != -1) {
          _entries[i] = saved;
          notifyListeners();
        }
        return saved;
      }
    } catch (_) {
      // Roll back the optimistic insert on failure.
      _entries.removeWhere((e) => e.id == tempId);
      notifyListeners();
    }
    return optimistic;
  }

  Future<void> update({
    required String id,
    required String title,
    required String body,
    String? mood,
    List<dynamic>? bodyDelta,
  }) async {
    final int i = _entries.indexWhere((e) => e.id == id);
    if (i == -1) return;
    final JournalEntry previous = _entries[i];
    _entries[i] = previous.copyWith(
      title: title.trim(),
      body: body.trim(),
      mood: mood,
      bodyDelta: bodyDelta,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Temp (never-synced) entries can't be PATCHed — they reconcile via add().
    if (id.startsWith('local-')) return;

    try {
      await ApiClient.instance.patch(
        ApiEndpoints.journalEntry(id),
        body: {
          'title': title.trim(),
          'body': body.trim(),
          'mood': ?mood,
          'body_delta': ?bodyDelta,
        },
      );
    } catch (_) {
      final int j = _entries.indexWhere((e) => e.id == id);
      if (j != -1) {
        _entries[j] = previous;
        notifyListeners();
      }
    }
  }

  Future<void> remove(String id) async {
    final int i = _entries.indexWhere((e) => e.id == id);
    if (i == -1) return;
    final JournalEntry removed = _entries.removeAt(i);
    notifyListeners();

    if (id.startsWith('local-')) return;

    try {
      await ApiClient.instance.delete(ApiEndpoints.journalEntry(id));
    } catch (_) {
      _entries.insert(i, removed);
      notifyListeners();
    }
  }

  /// Toggle the pin. Returns false (no change) if pinning would exceed
  /// [maxPinned]. Optimistic; reverts on a server error.
  Future<bool> togglePin(String id) async {
    final int i = _entries.indexWhere((e) => e.id == id);
    if (i == -1) return false;
    final bool willPin = !_entries[i].isPinned;
    if (willPin && pinnedCount >= maxPinned) return false;

    final JournalEntry previous = _entries[i];
    _entries[i] = previous.copyWith(isPinned: willPin);
    notifyListeners();

    if (id.startsWith('local-')) return true;

    try {
      await ApiClient.instance.patch(
        ApiEndpoints.journalEntry(id),
        body: {'is_pinned': willPin},
      );
    } catch (_) {
      final int j = _entries.indexWhere((e) => e.id == id);
      if (j != -1) {
        _entries[j] = previous;
        notifyListeners();
      }
    }
    return true;
  }
}
