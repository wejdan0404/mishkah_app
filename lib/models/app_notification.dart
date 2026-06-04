enum NotificationCategory {
  safety,
  system,
  reminder,
  motivation,
  achievement,
  campaign,
}

NotificationCategory _categoryFromString(String? value) {
  switch (value) {
    case 'safety':
      return NotificationCategory.safety;
    case 'reminder':
      return NotificationCategory.reminder;
    case 'motivation':
      return NotificationCategory.motivation;
    case 'achievement':
      return NotificationCategory.achievement;
    case 'campaign':
      return NotificationCategory.campaign;
    case 'system':
    default:
      return NotificationCategory.system;
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.isRead,
    this.deepLink,
    this.scheduledFor,
    this.sentAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final bool isRead;
  final String? deepLink;
  final String? scheduledFor;
  final String? sentAt;
  final String? readAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // data_payload is an object or null; tolerate a JSON array (e.g. []) by
    // treating any non-Map as "no payload" rather than throwing.
    final dynamic rawPayload = json['data_payload'];
    final Map<String, dynamic>? payload =
        rawPayload is Map ? rawPayload.cast<String, dynamic>() : null;
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: _categoryFromString(json['category'] as String?),
      isRead: json['read'] as bool? ?? false,
      deepLink: payload?['deep_link'] as String?,
      scheduledFor: json['scheduled_for'] as String?,
      sentAt: json['sent_at'] as String?,
      readAt: json['read_at'] as String?,
    );
  }
}

class NotificationFeed {
  const NotificationFeed({required this.unreadCount, required this.items});

  final int unreadCount;
  final List<AppNotification> items;

  factory NotificationFeed.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List?) ?? const <dynamic>[];
    return NotificationFeed(
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList(),
    );
  }
}
