import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/api/api_exception.dart';
import '../../core/notifications/notification_count_store.dart';
import '../../core/notifications/notification_service.dart';
import '../../models/app_notification.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/loading_overlay.dart';
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
      // Robust de-dup BEFORE mapping: exact id first, then a conservative
      // content key (see [_dedupeNotifications]) so backend duplicates that
      // arrive with DIFFERENT ids but identical content in the same minute
      // window also collapse. Done on the raw AppNotification list because the
      // UI model drops `category`.
      final List<AppNotification> deduped = _dedupeNotifications(feed.items);
      assert(() {
        debugPrint(
          'Notifications dedup: ${feed.items.length} fetched → '
          '${deduped.length} shown',
        );
        return true;
      }());
      if (!mounted) return;
      setState(() {
        _items = deduped.map(_NotificationItem.fromApi).toList();
        _isLoading = false;
        _errorMessage = null;
      });
      // Entering the screen counts as reading them all: tell the backend so the
      // "new" shadow is gone next time — but DON'T flip the local state, so the
      // shadows stay visible for this whole visit and only clear on re-entry.
      if (_items.any((it) => !it.isRead)) {
        unawaited(NotificationService.instance.markAllRead().catchError((_) {}));
        // Visiting the screen reads them all → clear the home bell badge.
        NotificationCountStore.instance.clear();
      }
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل الإشعارات';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر تحميل الإشعارات';
      });
    }
  }

  Future<void> _onItemTapped(_NotificationItem item) async {
    if (item.isRead) return;
    // Reading is already handled on screen entry (markAllRead). A tap just
    // nudges the backend for this one too; we intentionally don't flip the
    // local state, so the "new" shadow stays for the whole visit.
    try {
      await NotificationService.instance.markRead(item.id);
    } catch (_) {
      // Ignore — next refresh reconciles.
    }
  }

  Future<void> _onDelete(_NotificationItem item) async {
    // Optimistically drop it from the list (the swipe already animated it out),
    // then fire-and-forget the delete.
    setState(() {
      _items = _items.where((it) => it.id != item.id).toList();
    });
    try {
      await NotificationService.instance.delete(item.id);
    } catch (_) {
      // best-effort — a later refresh reconciles if the server rejected it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppTopNav(title: 'الإشعارات'),
              const SizedBox(height: AppSpacing.xxxl),
              // Same full-screen first-load veil the tab screens use; the back
              // button in AppTopNav stays outside it so it's always tappable.
              Expanded(
                child: LoadingOverlay(
                  loading: _isLoading,
                  child: _buildBody(now),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DateTime now) {
    // While loading, the LoadingOverlay veil carries the spinner — keep the
    // body blank so no empty/error state flashes faintly behind it.
    if (_isLoading) return const SizedBox.shrink();
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.sm,
                  color: context.colors.shade500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'حاول مرة أخرى بعد قليل.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xxs,
                  color: context.colors.shade400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'لا توجد إشعارات حالياً',
                textAlign: TextAlign.center,
                style: AppTextStyles.thmanyahHeading(context).copyWith(
                  fontSize: AppFontSizes.sm,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'سنخبرك عندما يكون هناك شيء جديد.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xxs,
                  color: context.colors.shade400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _buildSectionedList(now);
  }

  /// Groups notifications into time buckets (اليوم / آخر 7 أيام / آخر 30 يومًا /
  /// الأقدم), each under a Thmanyah-font header, newest first.
  Widget _buildSectionedList(DateTime now) {
    final List<_NotificationItem> items = [..._items]
      ..sort((a, b) => b.time.compareTo(a.time));

    final List<_NotificationItem> today = [];
    final List<_NotificationItem> last7 = [];
    final List<_NotificationItem> last30 = [];
    final List<_NotificationItem> older = [];

    final DateTime today0 = DateTime(now.year, now.month, now.day);
    for (final it in items) {
      final DateTime t0 = DateTime(it.time.year, it.time.month, it.time.day);
      final int daysAgo = today0.difference(t0).inDays;
      if (daysAgo <= 0) {
        today.add(it);
      } else if (daysAgo <= 7) {
        last7.add(it);
      } else if (daysAgo <= 30) {
        last30.add(it);
      } else {
        older.add(it);
      }
    }

    final List<Widget> children = [];
    void addSection(String title, List<_NotificationItem> bucket) {
      if (bucket.isEmpty) return;
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.xxl));
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Text(
            title,
            textAlign: TextAlign.right,
            style: AppTextStyles.thmanyahHeading(context),
          ),
        ),
      );
      for (int i = 0; i < bucket.length; i++) {
        if (i != 0) children.add(const SizedBox(height: AppSpacing.md));
        final item = bucket[i];
        children.add(
          Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.horizontal,
            onDismissed: (_) => _onDelete(item),
            background: const _DismissDeleteBackground(),
            // Screen reader users can't swipe, so expose delete as a custom
            // action in the rotor / local context menu.
            child: Semantics(
              customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
                const CustomSemanticsAction(label: 'حذف الإشعار'): () =>
                    _onDelete(item),
              },
              child: _NotificationCard(
                item: item,
                now: now,
                onTap: () => _onItemTapped(item),
              ),
            ),
          ),
        );
      }
    }

    addSection('اليوم', today);
    addSection('آخر 7 أيام', last7);
    addSection('آخر 30 يومًا', last30);
    addSection('الأقدم', older);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.xl,
      ),
      children: children,
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
    final raw = n.sentAt ?? n.scheduledFor;
    final DateTime time =
        raw != null ? (DateTime.tryParse(raw) ?? DateTime.now()) : DateTime.now();
    return _NotificationItem(
      id: n.id,
      title: n.title,
      time: time,
      body: n.body,
      isRead: n.isRead,
    );
  }
}

/// Removes duplicate notifications before rendering. Two passes, conservative:
///   1. exact `id` — never render the same row twice.
///   2. a content key — `category | normalized title | normalized body |
///      2-minute timestamp bucket` — to also collapse backend duplicates that
///      arrive with DIFFERENT ids but identical content within the same minute
///      window (the common "generator fired twice" case).
/// The feed is newest-first, so keeping the first occurrence keeps the newest.
/// Genuinely distinct notifications — or same-content ones more than ~2 minutes
/// apart — are intentionally NOT removed (that would hide real events; spacing
/// like that is a backend generation issue).
List<AppNotification> _dedupeNotifications(List<AppNotification> items) {
  final Set<String> seenIds = <String>{};
  final Set<String> seenKeys = <String>{};
  final List<AppNotification> out = <AppNotification>[];
  for (final AppNotification n in items) {
    if (!seenIds.add(n.id)) continue; // exact-id duplicate
    if (!seenKeys.add(_notificationDedupeKey(n))) continue; // content duplicate
    out.add(n);
  }
  return out;
}

/// Conservative content key for [_dedupeNotifications]. Buckets the timestamp to
/// 2-minute windows so near-simultaneous duplicates collapse without merging
/// events that are minutes/hours apart.
String _notificationDedupeKey(AppNotification n) {
  final String title = _normalizeNotificationText(n.title);
  final String body = _normalizeNotificationText(n.body);
  final String category = n.category.name;
  final String? raw = n.sentAt ?? n.scheduledFor;
  final DateTime? dt = raw == null ? null : DateTime.tryParse(raw);
  final String bucket = dt == null
      ? 'no-time'
      : DateTime(dt.year, dt.month, dt.day, dt.hour, (dt.minute ~/ 2) * 2)
          .toIso8601String();
  return '$category|$title|$body|$bucket';
}

/// Trims, collapses repeated whitespace, and strips the Arabic tatweel (ـ) so
/// cosmetically-different-but-identical backend strings compare equal.
String _normalizeNotificationText(String s) => s
    .replaceAll('ـ', '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// One consistent Arabic relative timestamp using "منذ ..." everywhere:
/// "الآن" / "منذ دقيقتين" / "منذ ساعة" / "منذ يوم" / "منذ يومين" / …
String _formatNotificationTime(DateTime time, DateTime now) {
  final Duration diff = now.difference(time);

  if (diff.inMinutes < 1) {
    return 'الآن';
  }
  if (diff.inHours < 1) {
    return _relativeArabic(
      diff.inMinutes,
      singular: 'منذ دقيقة',
      dual: 'منذ دقيقتين',
      few: 'دقائق',
      many: 'دقيقة',
    );
  }
  if (diff.inDays < 1) {
    return _relativeArabic(
      diff.inHours,
      singular: 'منذ ساعة',
      dual: 'منذ ساعتين',
      few: 'ساعات',
      many: 'ساعة',
    );
  }
  return _relativeArabic(
    diff.inDays,
    singular: 'منذ يوم',
    dual: 'منذ يومين',
    few: 'أيام',
    many: 'يومًا',
  );
}

String _relativeArabic(
  int n, {
  required String singular,
  required String dual,
  required String few,
  required String many,
}) {
  if (n == 1) return singular;
  if (n == 2) return dual;
  if (n >= 3 && n <= 10) return 'منذ $n $few';
  return 'منذ $n $many';
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

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      onTap: onTap,
      // Spoken as a single button: unread state + title + body + time. Swipe
      // sideways to delete (announced via the hint on the row below).
      semanticLabel: '${item.isRead ? '' : 'غير مقروء، '}'
          '${item.title}، ${item.body}، '
          '${_formatNotificationTime(item.time, now)}',
      // Just-sent (unread) notifications get a soft shadow to stand out; once
      // read they sit flat — a quick "new vs seen" read.
      boxShadow: item.isRead ? const <BoxShadow>[] : AppShadows.md,
      borderWidth: 0.8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _NotificationIconBadge(),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.thmanyahHeading(context).copyWith(
                          fontSize: AppFontSizes.xs,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _formatNotificationTime(item.time, now),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.xxs,
                        fontWeight: AppFontWeights.regular,
                        color: context.colors.shade400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
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
}

class _DismissDeleteBackground extends StatelessWidget {
  const _DismissDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDangerColors.shade500,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.delete_outline, color: AppNeutralColors.white, size: 22),
          Icon(Icons.delete_outline, color: AppNeutralColors.white, size: 22),
        ],
      ),
    );
  }
}

class _NotificationIconBadge extends StatelessWidget {
  const _NotificationIconBadge();

  static const double _size = 24;
  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.forDark(
          AppPaletteButteryYellow.shade500,
          const Color(0xFF332700),
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: context.forDark(
            AppPaletteButteryYellow.shade25,
            const Color(0xFF332700),
          ),
          width: 0.5,
        ),
      ),
      child: SvgPicture.asset(
        AppSvgIcons.homeNotification,
        width: _iconSize,
        height: _iconSize,
        colorFilter: const ColorFilter.mode(
          AppPaletteButteryYellow.shade25,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
