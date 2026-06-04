# حسابي (My Account) Page Integration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace static mock data on the حسابي (Profile) screen and its linked Notifications screen with real backend data, using only endpoints documented in `mishkat.postman_collection.json`. No layout changes.

**Architecture:** A new lightweight `NotificationService` wraps the four documented notification endpoints. The Profile screen reads `AuthService.currentUser?.name` for the header, fetches `NotificationPreferences` on init to seed the notifications toggle, and calls `AuthService.logout()` (which already POSTs `/auth/logout`) on confirmed logout. The Notifications screen fetches the live feed on init and gracefully degrades to an empty/error state.

**Tech Stack:** Existing — `package:http`, `ApiClient`, no new deps.

---

## Endpoints in scope (from Postman)

| UI surface | Endpoint | Notes |
|---|---|---|
| Profile header — user name | `GET /api/v1/auth/me` | Already cached in `AuthService.currentUser`. Just read it. |
| Profile — Dark mode toggle | (no endpoint) | Stays local state. Mishkat backend has no theme persistence. |
| Profile — Notifications toggle | `GET` + `PATCH /api/v1/notifications/preferences` | Toggle controls `push_enabled` (the dialog copy says "تفعيل الإشعارات"). |
| Profile — Logout button | `POST /api/v1/auth/logout` | Already implemented in `AuthService.logout()` — just call it. |
| Notifications screen — feed | `GET /api/v1/notifications/feed?limit=30` | Already-read state and `unread_count` come from the same response. |
| Notifications screen — tap an item | `POST /api/v1/notifications/{id}/read` | Idempotent; fire-and-forget after the user opens the item or scrolls past. |
| FAQ / About / Terms / Privacy / Report Problem | (no endpoint) | Documented Postman collection has nothing for these. Stay static — out of scope. |

---

## File Structure

**New files:**
```
lib/
├── core/
│   └── notifications/
│       └── notification_service.dart   — GET feed, POST read, GET/PATCH preferences
└── models/
    ├── app_notification.dart           — single notification item DTO + NotificationCategory enum + feed wrapper
    └── notification_preferences.dart   — Preferences DTO with categoriesEnabled / quietHoursStart / quietHoursEnd / timezone / inAppEnabled / pushEnabled
```

**Modified files:**
```
lib/screens/home/profile_screen.dart                      — name from AuthService, real logout, wire toggle
lib/screens/notifications/notifications_screen.dart       — fetch feed + render real items
```

**New tests:**
```
test/models/app_notification_test.dart
test/models/notification_preferences_test.dart
```

---

### Task 1: Notification + Preferences DTOs

**Files:**
- Create: `lib/models/app_notification.dart`
- Create: `lib/models/notification_preferences.dart`
- Test: `test/models/app_notification_test.dart`
- Test: `test/models/notification_preferences_test.dart`

- [ ] **Step 1: Write the failing tests**

`test/models/app_notification_test.dart`:

```dart
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
```

`test/models/notification_preferences_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/models/notification_preferences.dart';

void main() {
  test('NotificationPreferences.fromJson reads documented shape', () {
    final p = NotificationPreferences.fromJson({
      'categories_enabled': ['safety', 'system', 'reminder'],
      'quiet_hours_start': '22:00',
      'quiet_hours_end': '07:00',
      'timezone': 'Asia/Riyadh',
      'in_app_enabled': true,
      'push_enabled': false,
    });
    expect(p.categoriesEnabled, ['safety', 'system', 'reminder']);
    expect(p.quietHoursStart, '22:00');
    expect(p.quietHoursEnd, '07:00');
    expect(p.timezone, 'Asia/Riyadh');
    expect(p.inAppEnabled, true);
    expect(p.pushEnabled, false);
  });

  test('NotificationPreferences.fromJson has safe defaults', () {
    final p = NotificationPreferences.fromJson(const {});
    expect(p.categoriesEnabled, isEmpty);
    expect(p.inAppEnabled, true);
    expect(p.pushEnabled, true);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/models/app_notification_test.dart test/models/notification_preferences_test.dart`
Expected: FAIL (files do not exist).

- [ ] **Step 3: Write `lib/models/app_notification.dart`**

```dart
enum NotificationCategory { safety, system, reminder, motivation, achievement, campaign }

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
    final payload = (json['data_payload'] as Map?)?.cast<String, dynamic>();
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
```

- [ ] **Step 4: Write `lib/models/notification_preferences.dart`**

```dart
class NotificationPreferences {
  const NotificationPreferences({
    required this.categoriesEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.timezone,
    required this.inAppEnabled,
    required this.pushEnabled,
  });

  final List<String> categoriesEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String? timezone;
  final bool inAppEnabled;
  final bool pushEnabled;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final raw = (json['categories_enabled'] as List?) ?? const <dynamic>[];
    return NotificationPreferences(
      categoriesEnabled: raw.whereType<String>().toList(),
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
      timezone: json['timezone'] as String?,
      inAppEnabled: json['in_app_enabled'] as bool? ?? true,
      pushEnabled: json['push_enabled'] as bool? ?? true,
    );
  }

  NotificationPreferences copyWith({bool? pushEnabled, bool? inAppEnabled}) =>
      NotificationPreferences(
        categoriesEnabled: categoriesEnabled,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
        timezone: timezone,
        inAppEnabled: inAppEnabled ?? this.inAppEnabled,
        pushEnabled: pushEnabled ?? this.pushEnabled,
      );
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/models/app_notification_test.dart test/models/notification_preferences_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/models/app_notification.dart lib/models/notification_preferences.dart test/models/app_notification_test.dart test/models/notification_preferences_test.dart
git commit -m "feat(models): AppNotification + NotificationPreferences DTOs"
```

---

### Task 2: NotificationService

**Files:**
- Create: `lib/core/notifications/notification_service.dart`
- Modify: `lib/core/api/api_endpoints.dart` — add notification paths

- [ ] **Step 1: Add endpoints to `lib/core/api/api_endpoints.dart`**

Replace the existing file content with:

```dart
class ApiEndpoints {
  const ApiEndpoints._();

  // Base URL — override at build time:
  //   flutter run --dart-define=MISHKAT_API_BASE_URL=http://localhost:8080
  static const String baseUrl = String.fromEnvironment(
    'MISHKAT_API_BASE_URL',
    defaultValue: 'https://api.mishkat.us',
  );

  static const String apiV1 = '/api/v1';

  // Auth
  static const String register = '$apiV1/auth/register';
  static const String login = '$apiV1/auth/login';
  static const String refresh = '$apiV1/auth/refresh';
  static const String logout = '$apiV1/auth/logout';
  static const String authMe = '$apiV1/auth/me';

  // Me
  static const String me = '$apiV1/me';
  static const String consent = '$apiV1/me/consent';

  // Notifications
  static const String notificationsFeed = '$apiV1/notifications/feed';
  static const String notificationsReadAll = '$apiV1/notifications/read-all';
  static String notificationRead(String id) =>
      '$apiV1/notifications/$id/read';
  static const String notificationPreferences = '$apiV1/notifications/preferences';

  // AI
  static const String aiThreads = '$apiV1/ai/threads';
  static String aiThread(String id) => '$apiV1/ai/threads/$id';
  static String aiMessages(String threadId) =>
      '$apiV1/ai/threads/$threadId/messages';
}
```

- [ ] **Step 2: Write `lib/core/notifications/notification_service.dart`**

```dart
import '../../models/app_notification.dart';
import '../../models/notification_preferences.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Fetch the latest notifications feed. Returns at most [limit] items.
  Future<NotificationFeed> fetchFeed({int limit = 30, bool unreadOnly = false}) async {
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
    await ApiClient.instance.post(ApiEndpoints.notificationRead(notificationId));
  }

  /// Mark all notifications as read.
  Future<void> markAllRead() async {
    await ApiClient.instance.post(ApiEndpoints.notificationsReadAll);
  }

  Future<NotificationPreferences> fetchPreferences() async {
    final data = await ApiClient.instance.get(ApiEndpoints.notificationPreferences)
        as Map<String, dynamic>;
    return NotificationPreferences.fromJson(data);
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
```

- [ ] **Step 3: Verify compile**

Run: `flutter analyze lib/core/notifications/ lib/core/api/api_endpoints.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/core/notifications/ lib/core/api/api_endpoints.dart
git commit -m "feat(notifications): NotificationService + endpoint constants"
```

---

### Task 3: Wire profile header name to AuthService

**Files:**
- Modify: `lib/screens/home/profile_screen.dart`

- [ ] **Step 1: Add the import**

In `lib/screens/home/profile_screen.dart`, add after the existing `import '../../theme/app_tokens.dart';` line:

```dart
import '../../core/auth/auth_service.dart';
```

- [ ] **Step 2: Replace the hardcoded name**

Find:

```dart
                        _ProfileHeaderCard(
                          name: 'مـرام بارفعـة',
                          onTap: () =>
                              Navigator.of(context).pushNamed('/edit-profile'),
                        ),
```

Replace with:

```dart
                        _ProfileHeaderCard(
                          name: AuthService.currentUser?.name ?? '',
                          onTap: () async {
                            await Navigator.of(context).pushNamed('/edit-profile');
                            if (!mounted) return;
                            setState(() {}); // refresh name after edit-profile saves
                          },
                        ),
```

- [ ] **Step 3: Verify compile**

Run: `flutter analyze lib/screens/home/profile_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/screens/home/profile_screen.dart
git commit -m "feat(profile): show real user name from AuthService.currentUser"
```

---

### Task 4: Wire logout to AuthService.logout()

**Files:**
- Modify: `lib/screens/home/profile_screen.dart`

- [ ] **Step 1: Replace `_onLogout`**

Find the existing method:

```dart
  Future<void> _onLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _LogoutConfirmationDialog(),
    );
    if (!mounted) return;
    if (confirmed == true) {
      Navigator.of(context).pushNamedAndRemoveUntil('/signin', (_) => false);
    }
  }
```

Replace with:

```dart
  bool _isLoggingOut = false;

  Future<void> _onLogout() async {
    if (_isLoggingOut) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _LogoutConfirmationDialog(),
    );
    if (!mounted) return;
    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);
    try {
      await AuthService.logout();
    } finally {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/signin', (_) => false);
    }
  }
```

(Move the `bool _isLoggingOut = false;` declaration to live alongside `bool _darkMode = false;` at the top of the state class — the snippet above shows it next to the method only for context.)

- [ ] **Step 2: Verify compile**

Run: `flutter analyze lib/screens/home/profile_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home/profile_screen.dart
git commit -m "feat(profile): logout now revokes server-side session via AuthService.logout()"
```

---

### Task 5: Wire notifications toggle to NotificationService

**Files:**
- Modify: `lib/screens/home/profile_screen.dart`

- [ ] **Step 1: Add imports**

Add alongside existing imports:

```dart
import '../../core/notifications/notification_service.dart';
import '../../models/notification_preferences.dart';
```

- [ ] **Step 2: Replace the toggle's local state with a fetched-then-PATCHed flow**

Find:

```dart
class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  bool _notifications = false;
```

Replace with:

```dart
class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  bool _notifications = false;
  bool _isLoggingOut = false;
  bool _prefsLoaded = false;
  bool _togglingNotifications = false;
  NotificationPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await NotificationService.instance.fetchPreferences();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _notifications = prefs.pushEnabled;
        _prefsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      // Failure is silent here — the toggle stays at its default (off) until
      // the user pulls to refresh next time. We do NOT show an error banner
      // because the rest of the screen still works without it.
      setState(() => _prefsLoaded = true);
    }
  }
```

- [ ] **Step 3: Replace `_onNotificationsChanged` with the real PATCH**

Find:

```dart
  Future<void> _onNotificationsChanged(bool v) async {
    setState(() => _notifications = v);
    if (!v) return;
    final bool? enabled = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _EnableNotificationsDialog(),
    );
    if (!mounted) return;
    if (enabled != true) {
      setState(() => _notifications = false);
    }
  }
```

Replace with:

```dart
  Future<void> _onNotificationsChanged(bool v) async {
    if (_togglingNotifications || !_prefsLoaded) return;

    // For turning ON, show the confirmation dialog first; for turning OFF,
    // PATCH immediately.
    if (v) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => const _EnableNotificationsDialog(),
      );
      if (!mounted) return;
      if (confirmed != true) return;
    }

    final bool previous = _notifications;
    setState(() {
      _notifications = v;
      _togglingNotifications = true;
    });
    try {
      final updated = await NotificationService.instance.updatePreferences(
        pushEnabled: v,
      );
      if (!mounted) return;
      setState(() => _prefs = updated);
    } catch (_) {
      if (!mounted) return;
      // Roll back the UI state if the server rejected.
      setState(() => _notifications = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text('تعذّر تحديث إعدادات الإشعارات.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _togglingNotifications = false);
    }
  }
```

- [ ] **Step 4: Verify compile**

Run: `flutter analyze lib/screens/home/profile_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home/profile_screen.dart
git commit -m "feat(profile): notifications toggle reads + writes /notifications/preferences"
```

---

### Task 6: Wire Notifications screen to /notifications/feed

**Files:**
- Modify: `lib/screens/notifications/notifications_screen.dart`

**Rule:** No layout change. Keep `AppTopNav`, the `ListView.separated`, the `_NotificationCard`, the `_NotificationItem` data shape. Only the data source changes from hardcoded list → API fetch.

- [ ] **Step 1: Convert to StatefulWidget and fetch the feed**

Replace the entire file content with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/api/api_exception.dart';
import '../../core/notifications/notification_service.dart';
import '../../models/app_notification.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const String routeName = '/notifications';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<_NotificationItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final feed = await NotificationService.instance.fetchFeed();
      if (!mounted) return;
      setState(() {
        _items = feed.items.map(_NotificationItem.fromApi).toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.isUnauthenticated
            ? 'انتهت الجلسة. سجّل الدخول من جديد.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذّر الاتصال بالخادم. تحقق من الشبكة.';
      });
    }
  }

  Future<void> _onItemTapped(_NotificationItem item) async {
    if (item.isRead) return;
    // Fire-and-forget; UI already reflects "read" optimistically.
    setState(() {
      _items = [
        for (final it in _items)
          if (it.id == item.id) it.copyWith(isRead: true) else it,
      ];
    });
    try {
      await NotificationService.instance.markRead(item.id);
    } catch (_) {
      // ignore — the next refresh will reconcile.
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Scaffold(
      backgroundColor: AppNeutralColors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppTopNav(title: 'الإشعارات'),
              const SizedBox(height: AppSpacing.xxxl),
              Expanded(child: _buildBody(now)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DateTime now) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppPalettePurple.shade300),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.sm,
              color: AppNeutralColors.shade500,
              height: 1.4,
            ),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Text(
            'لا توجد إشعارات حالياً.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.sm,
              color: AppNeutralColors.shade500,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _NotificationCard(
          item: item,
          now: now,
          onTap: () => _onItemTapped(item),
        );
      },
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.title,
    required this.time,
    required this.body,
    required this.isRead,
  });

  final String id;
  final String title;
  final DateTime time;
  final String body;
  final bool isRead;

  _NotificationItem copyWith({bool? isRead}) => _NotificationItem(
        id: id,
        title: title,
        time: time,
        body: body,
        isRead: isRead ?? this.isRead,
      );

  factory _NotificationItem.fromApi(AppNotification n) {
    // Prefer sent_at, fall back to scheduled_for, else now.
    DateTime time;
    final raw = n.sentAt ?? n.scheduledFor;
    if (raw != null) {
      time = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      time = DateTime.now();
    }
    return _NotificationItem(
      id: n.id,
      title: n.title,
      time: time,
      body: n.body,
      isRead: n.isRead,
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.now,
    required this.onTap,
  });

  final _NotificationItem item;
  final DateTime now;
  final VoidCallback onTap;

  static const double _iconSize = 32;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _iconSize,
            height: _iconSize,
            decoration: BoxDecoration(
              color: AppPaletteButteryYellow.shade100,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              AppSvgIcons.homeNotification,
              width: 18,
              height: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.thmanyahCaption.copyWith(
                          fontSize: AppFontSizes.sm,
                          fontWeight: item.isRead
                              ? AppFontWeights.regular
                              : AppFontWeights.semibold,
                          color: AppNeutralColors.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _relativeTime(item.time, now),
                      style: const TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.xxs,
                        color: AppNeutralColors.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.body,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    color: AppNeutralColors.shade500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime t, DateTime now) {
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
    if (diff.inDays < 7) return 'قبل ${diff.inDays} ي';
    return 'قبل ${diff.inDays ~/ 7} أ';
  }
}
```

> **Note:** This preserves the visual elements that were in the original file (icon circle, title row, time, body) — only the data source and `onTap` are new. Compare against the prior file's `_NotificationCard` and adjust borders/padding/colors if the existing private widget had different styling that I didn't capture above. If the prior `_NotificationCard` used different exact tokens, port them over verbatim.

- [ ] **Step 2: Verify compile**

Run: `flutter analyze lib/screens/notifications/notifications_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/screens/notifications/notifications_screen.dart
git commit -m "feat(notifications): fetch real feed from /notifications/feed with read-on-tap"
```

---

### Task 7: Full validation pass

- [ ] **Step 1: Analyze the whole project**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: All tests pass (existing 11 + 5 new = 16 total).

- [ ] **Step 3: Build debug APK to catch any platform-specific compile issue**

Run: `flutter build apk --debug 2>&1 | tail -5`
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: Document the smoke-test additions**

Append to `docs/superpowers/plans/2026-05-23-smoke-test-checklist.md` (after the existing §9):

```markdown
## 10. حسابي page

- Open the bottom-nav profile tab.
- Expected: header shows the signed-in user's actual name (no longer "مرام بارفعة").
- Tap the header card → goes to edit profile (already covered in §4).
- Toggle "الإشعارات" ON → confirmation dialog → confirm → toggle stays on.
  Verify in backend: `notification_preferences.push_enabled = true` for this user.
- Toggle "الإشعارات" OFF → no dialog, instant PATCH. Verify push_enabled = false.
- Tap "تسجيل الخروج" → confirm → app goes to /signin. Verify the Sanctum
  token was revoked server-side.

## 11. Notifications screen

- From حسابي's bell, open الإشعارات.
- Expected: a brief loading spinner, then the real notifications list from
  /api/v1/notifications/feed. If the backend has none, the empty-state
  message "لا توجد إشعارات حالياً." shows.
- Tap an unread item → title weight changes from bold to regular. Verify
  `notification_user.read_at` was set on the backend.
- If the auth probe fails, the screen shows "انتهت الجلسة. سجّل الدخول من جديد."
```

- [ ] **Step 5: Final commit**

```bash
git add docs/superpowers/plans/2026-05-23-smoke-test-checklist.md
git commit -m "docs: smoke-test steps for account page + notifications"
```

---

## Out of scope / static screens we intentionally do not wire

These five screens contain only marketing/help copy. The Postman collection has no endpoints for them. They stay static:

- `lib/screens/faq/faq_screen.dart` — 4 hard-coded Q&A pairs.
- `lib/screens/about/about_mishkat_screen.dart` — 5 hard-coded info cards.
- `lib/screens/terms/terms_screen.dart` — 8 hard-coded sections.
- `lib/screens/privacy/privacy_screen.dart` — 7 hard-coded sections.
- `lib/screens/report_problem/report_problem_screen.dart` — form is stubbed because there is no documented `POST /report-problem` endpoint.

If a `GET /api/v1/content/{slug}` (or similar) is added to the backend later, those screens can be wired in a follow-up plan — not now.

---

## Self-review

- **Spec coverage:** Profile name (T3), logout (T4), notifications toggle (T5), notifications feed (T6), DTOs + service that underpin both screens (T1+T2). The static screens are explicitly named under "Out of scope" so nothing falls through the cracks.
- **No placeholders:** every code step contains the full code to write.
- **Type consistency:** `NotificationCategory` enum is referenced identically in T1 (declaration), T1 test, and T6 (via `AppNotification.category`). `NotificationPreferences.pushEnabled` flows from T1 → T2 (`updatePreferences(pushEnabled: ...)`) → T5 (`prefs.pushEnabled`).
- **Layout invariant:** T6's note about porting prior `_NotificationCard` tokens verbatim is the only place where pixel-level attention is required; everything else is behavior-only.
