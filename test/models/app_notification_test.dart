import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/models/app_notification.dart';

void main() {
  test('AppNotification.fromJson reads documented shape', () {
    final json = {
      'id': '0193f9b1-aaaa-7000-8000-202605191200b',
      'title': 'وقت تسجيل المزاج',
      'body': 'دقيقة واحدة تكفي — كيف يومك حتى الآن؟',
      'data_payload': {'deep_link': 'mishkat://mood/check-in'},
      'category': 'reminder',
      'status': 'sent',
      'read': false,
      'read_at': null,
      'scheduled_for': '2026-05-20T09:15:23+03:00',
      'sent_at': '2026-05-20T09:15:23+03:00',
    };
    final n = AppNotification.fromJson(json);
    expect(n.id, '0193f9b1-aaaa-7000-8000-202605191200b');
    expect(n.title, 'وقت تسجيل المزاج');
    expect(n.category, NotificationCategory.reminder);
    expect(n.isRead, false);
    expect(n.deepLink, 'mishkat://mood/check-in');
  });

  test('NotificationFeed.fromJson reads list + counters', () {
    final feed = NotificationFeed.fromJson({
      'unread_count': 2,
      'items': [
        {
          'id': 'a',
          'title': 't',
          'body': 'b',
          'category': 'system',
          'status': 'sent',
          'read': true,
          'sent_at': '2026-05-20T09:15:23+03:00',
        },
      ],
    });
    expect(feed.unreadCount, 2);
    expect(feed.items, hasLength(1));
    expect(feed.items.single.category, NotificationCategory.system);
  });

  test('unknown category falls back to system', () {
    final n = AppNotification.fromJson({
      'id': '1',
      'title': 't',
      'body': 'b',
      'category': 'made-up',
      'status': 'sent',
      'read': false,
      'sent_at': '2026-05-20T09:15:23+03:00',
    });
    expect(n.category, NotificationCategory.system);
  });
}
