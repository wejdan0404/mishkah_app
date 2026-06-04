import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Tracks the unread in-app notification count for the home bell badge.
///
/// A singleton [ChangeNotifier] so the bell can rebuild whenever the count
/// changes. [refresh] is best-effort: on any error it keeps the last known
/// value rather than flickering to zero.
class NotificationCountStore extends ChangeNotifier {
  NotificationCountStore._();
  static final NotificationCountStore instance = NotificationCountStore._();

  int _unread = 0;
  int get unread => _unread;

  /// Re-fetch the unread count from the feed. The server computes the count
  /// over all unread rows, so a tiny page keeps the payload small.
  Future<void> refresh() async {
    try {
      final feed = await NotificationService.instance.fetchFeed(limit: 1);
      _set(feed.unreadCount);
    } catch (_) {
      // Keep the last known count (offline / not signed in).
    }
  }

  /// Reset to zero (e.g. on sign-out).
  void clear() => _set(0);

  void _set(int value) {
    final int next = value < 0 ? 0 : value;
    if (next == _unread) return;
    _unread = next;
    notifyListeners();
  }
}
