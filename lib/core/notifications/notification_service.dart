import 'package:flutter/foundation.dart';

import '../../models/app_notification.dart';
import '../../models/notification_preferences.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Fetch the latest notifications feed. Returns at most [limit] items.
  Future<NotificationFeed> fetchFeed({
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    final data = await ApiClient.instance.get(
      ApiEndpoints.notificationsFeed,
      query: {
        'limit': '$limit',
        if (unreadOnly) 'unread_only': 'true',
      },
    ) as Map<String, dynamic>;
    return NotificationFeed.fromJson(data);
  }

  /// Mark a single notification as read. 204 expected.
  Future<void> markRead(String notificationId) async {
    await ApiClient.instance.post(
      ApiEndpoints.notificationRead(notificationId),
    );
  }

  /// Mark all notifications as read.
  Future<void> markAllRead() async {
    await ApiClient.instance.post(ApiEndpoints.notificationsReadAll);
  }

  /// Delete a single notification from the feed. 204 expected.
  Future<void> delete(String notificationId) async {
    await ApiClient.instance.delete(
      ApiEndpoints.notificationDelete(notificationId),
    );
  }

  Future<NotificationPreferences> fetchPreferences() async {
    final data = await ApiClient.instance.get(
      ApiEndpoints.notificationPreferences,
    ) as Map<String, dynamic>;
    return NotificationPreferences.fromJson(data);
  }

  /// Register this device's push token with the backend so the
  /// notifications pipeline can deliver FCM messages. Best-effort: any
  /// failure (offline, not signed in, backend 4xx/5xx) is swallowed so push
  /// registration never blocks or breaks a sign-in flow.
  Future<void> registerDeviceToken(String token, String platform) async {
    try {
      await ApiClient.instance.post(
        ApiEndpoints.meDeviceToken,
        body: {'token': token, 'platform': platform},
      );
      debugPrint('NotificationService: device token registered ($platform).');
    } catch (e) {
      // best-effort — the token re-registers on next launch / token refresh.
      // Logged so a failed registration (e.g. not signed in → 401) is visible.
      debugPrint('NotificationService: device token registration failed ($e).');
    }
  }

  /// Update push and/or in-app toggles. Leaves the rest of the preferences
  /// untouched server-side.
  Future<NotificationPreferences> updatePreferences({
    bool? pushEnabled,
    bool? inAppEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (pushEnabled != null) body['push_enabled'] = pushEnabled;
    if (inAppEnabled != null) body['in_app_enabled'] = inAppEnabled;
    final data = await ApiClient.instance.patch(
      ApiEndpoints.notificationPreferences,
      body: body,
    ) as Map<String, dynamic>;
    return NotificationPreferences.fromJson(data);
  }
}
