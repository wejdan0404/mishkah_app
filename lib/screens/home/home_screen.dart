import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/activities/activity_api.dart';
import '../../core/activities/start_activity_store.dart';
import '../../core/auth/auth_service.dart';
import '../../core/mood/mood_catalog.dart';
import '../../core/mood/mood_palette.dart';
import '../../core/mood/mood_recommendation.dart';
import '../../core/mood/mood_service.dart';
import '../../core/notifications/notification_count_store.dart';
import '../../core/tasks/reminder_store.dart';
import '../../core/tasks/task_service.dart';
import '../../core/tasks/task_store.dart';
import '../../core/theme/theme_controller.dart';
import '../activities/balance_station_screen.dart';
import '../activities/journaling_space_screen.dart';
import '../activities/play_area_screen.dart';
import '../activities/understand_feelings_exercise_screen.dart';
import '../smart_companion/activity_suggestion_registry.dart';
import '../smart_companion/widgets/activity_suggestion_card.dart';
import '../../models/task_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/cards/focus_card.dart';
import '../../widgets/empty_tasks_state.dart';
import 'main_shell.dart';

enum _Mood { excited, happy, relaxed, calm, bored, sad, upset, tense, neutral }

class _Tiffany {
  static const Color shade25 = Color(0xFFEFFBFA);
  static const Color shade100 = Color(0xFFB9ECE6);
  static const Color shade300 = Color(0xFF81D8D0);
}

extension _MoodStyle on _Mood {
  /// Admin-managed colours: when the catalogue has a color_seed for this mood,
  /// derive bg/ring/gradient from it (on-theme); otherwise fall back to the
  /// bundled palette so first paint / offline looks unchanged.
  MoodColors? get _palette {
    final String? seed = MoodCatalog.instance.colorSeedFor(slug);
    return seed == null ? null : MoodPalette.forSeed(seed);
  }

  Color get bg => _palette?.bg ?? _bgFallback;

  Color get _bgFallback {
    switch (this) {
      case _Mood.excited:
        return AppPaletteButteryYellow.shade400;
      case _Mood.happy:
        return AppSuccessColors.shade100;
      case _Mood.relaxed:
        return _Tiffany.shade100;
      case _Mood.calm:
        return AppInformationColors.shade50;
      case _Mood.bored:
        return AppWarningColors.shade200;
      case _Mood.sad:
        return AppInformationColors.shade300;
      case _Mood.upset:
        return AppDangerColors.shade100;
      case _Mood.tense:
        return AppPalettePurple.shade500;
      case _Mood.neutral:
        return AppNeutralColors.shade200;
    }
  }

  Color get ring => _palette?.ring ?? _ringFallback;

  Color get _ringFallback {
    switch (this) {
      case _Mood.excited:
        return AppPaletteButteryYellow.shade100;
      case _Mood.happy:
        return AppSuccessColors.shade300;
      case _Mood.relaxed:
        return _Tiffany.shade300;
      case _Mood.calm:
        return AppInformationColors.shade300;
      case _Mood.bored:
        return AppWarningColors.shade400;
      case _Mood.sad:
        return AppInformationColors.shade500;
      case _Mood.upset:
        return AppDangerColors.shade300;
      case _Mood.tense:
        return AppPalettePurple.shade300;
      case _Mood.neutral:
        return AppNeutralColors.shade400;
    }
  }

  /// Emoji, label and message are admin-managed — resolve them from the live
  /// catalogue (GET /moods) so Filament edits show up, falling back to the
  /// bundled value until the catalogue loads.
  String get emoji => MoodCatalog.instance.emojiFor(slug) ?? _emojiFallback;

  String get _emojiFallback {
    switch (this) {
      case _Mood.excited:
        return '🤩';
      case _Mood.happy:
        return '😊';
      case _Mood.relaxed:
        return '😎';
      case _Mood.calm:
        return '😌';
      case _Mood.bored:
        return '😫';
      case _Mood.sad:
        return '😢';
      case _Mood.upset:
        return '😞';
      case _Mood.tense:
        return '😰';
      case _Mood.neutral:
        return '😐';
    }
  }

  String get label => MoodCatalog.instance.labelFor(slug) ?? _labelFallback;

  String get _labelFallback {
    switch (this) {
      case _Mood.excited:
        return 'متحمس';
      case _Mood.happy:
        return 'سعيد';
      case _Mood.relaxed:
        return 'مسترخي';
      case _Mood.calm:
        return 'هادئ';
      case _Mood.bored:
        return 'ملول';
      case _Mood.sad:
        return 'حزين';
      case _Mood.upset:
        return 'منزعج';
      case _Mood.tense:
        return 'متوتر';
      case _Mood.neutral:
        return 'محايد';
    }
  }

  /// Slug matching the backend moods catalogue. Used to POST a check-in.
  /// The local enum names line up 1:1 with the seeded slugs so this is just
  /// `name`, but the indirection keeps the contract explicit if either side
  /// renames a value in the future.
  String get slug {
    switch (this) {
      case _Mood.excited:
        return 'excited';
      case _Mood.happy:
        return 'happy';
      case _Mood.relaxed:
        return 'relaxed';
      case _Mood.calm:
        return 'calm';
      case _Mood.bored:
        return 'bored';
      case _Mood.sad:
        return 'sad';
      case _Mood.upset:
        return 'upset';
      case _Mood.tense:
        return 'tense';
      case _Mood.neutral:
        return 'neutral';
    }
  }

  String get selectedMessage =>
      MoodCatalog.instance.messageFor(slug) ?? _selectedMessageFallback;

  String get _selectedMessageFallback {
    switch (this) {
      case _Mood.excited:
        return 'طاقتك عالية اليوم .. خلها في شيء يركّزك';
      case _Mood.happy:
        return 'سعادتك تنوّر يومك .. شاركها مع من تحب';
      case _Mood.relaxed:
        return 'استمتع بهالراحة .. أنت تستحقها';
      case _Mood.calm:
        return 'هدوءك نعمة .. استمتع باللحظة وخذ خطوة';
      case _Mood.bored:
        return 'جرّب نشاط بسيط .. اللحظات الصغيرة تفرق';
      case _Mood.sad:
        return 'خذ وقتك .. مشاعرك مفهومة ومقبولة';
      case _Mood.upset:
        return 'شعورك صادق ومهم .. كن لطيف مع نفسك';
      case _Mood.tense:
        return 'خذ نفس عميق .. لحظة بلحظة، أنت بخير';
      case _Mood.neutral:
        return 'لحظة هادئة .. التأمل يفتح آفاق جديدة';
    }
  }

  List<Color> get gradient => _palette?.gradient ?? _gradientFallback;

  List<Color> get _gradientFallback {
    switch (this) {
      case _Mood.excited:
        return const [
          AppPaletteButteryYellow.shade100,
          AppPaletteButteryYellow.shade200,
          AppPaletteButteryYellow.shade300,
        ];
      case _Mood.happy:
        return const [
          AppSuccessColors.shade300,
          AppSuccessColors.shade200,
          AppSuccessColors.shade100,
        ];
      case _Mood.relaxed:
        return const [_Tiffany.shade300, _Tiffany.shade100, _Tiffany.shade25];
      case _Mood.calm:
        return const [
          AppInformationColors.shade300,
          AppInformationColors.shade100,
          AppInformationColors.shade50,
        ];
      case _Mood.bored:
        return const [
          AppWarningColors.shade400,
          AppWarningColors.shade300,
          AppWarningColors.shade200,
        ];
      case _Mood.sad:
        return const [
          AppInformationColors.shade400,
          AppInformationColors.shade300,
          AppInformationColors.shade200,
        ];
      case _Mood.upset:
        return const [
          AppDangerColors.shade300,
          AppDangerColors.shade200,
          AppDangerColors.shade100,
        ];
      case _Mood.tense:
        return const [
          AppPalettePurple.shade200,
          AppPalettePurple.shade300,
          AppPalettePurple.shade400,
        ];
      case _Mood.neutral:
        return const [
          AppNeutralColors.shade400,
          AppNeutralColors.shade300,
          AppNeutralColors.shade200,
        ];
    }
  }
}

/// Inverse of `_Mood.slug` — resolve a backend mood slug back to the local
/// enum so the home screen can hydrate the "recorded today" state. Unknown
/// slugs return null (no card shown) rather than guessing a mood.
_Mood? _moodFromSlug(String? slug) {
  switch (slug) {
    case 'excited':
      return _Mood.excited;
    case 'happy':
      return _Mood.happy;
    case 'relaxed':
      return _Mood.relaxed;
    case 'calm':
      return _Mood.calm;
    case 'neutral':
      return _Mood.neutral;
    case 'tense':
      return _Mood.tense;
    case 'bored':
      return _Mood.bored;
    case 'upset':
      return _Mood.upset;
    case 'sad':
      return _Mood.sad;
    default:
      return null;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Mood? _selectedMood;
  String? _selectedMessage;
  // Backend picks for the "ابدأ نشاطك المبني على فهمك لشعورك" card — scored
  // against the mood inferred from the افهم شعورك flow (StartActivityStore).
  // null/empty = no card.
  List<String>? _startActivitySlugs;
  // The home "ابدأ لحظة للتركيز" nudge is dismissible for the session via its
  // "ذكّرني لاحقًا" button; this hides it until the next app open.
  bool _focusDismissed = false;

  @override
  void initState() {
    super.initState();
    // Hydrate the "تم تسجيل شعورك" state from the backend so a fresh app open
    // on a day the user already checked in shows the recorded card instead of
    // the picker. Best-effort: a null slug (no check-in / network error) just
    // leaves the picker showing, and we never clobber an in-session selection.
    _hydrateTodayMood();
    // Pull the live mood catalogue (emoji/label/message) so admin edits show;
    // rebuild once it lands so any already-painted moods refresh.
    MoodCatalog.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
    // Hydrate the bell's unread badge.
    NotificationCountStore.instance.refresh();
    // The افهم شعورك flow stashes an inferred mood here; reload the "ابدأ
    // نشاطك" picks whenever it changes (set on completion, or cleared once the
    // user opens a suggestion). load() triggers the listener after hydration.
    StartActivityStore.instance.addListener(_loadStartActivities);
    StartActivityStore.instance.load();
    // Hydrate today's gentle "لا تنسى" reminder (set by the افهم شعورك flow for
    // أكلم شخص / أكمل يومي). Consumed below via AnimatedBuilder.
    ReminderStore.instance.load();
  }

  @override
  void dispose() {
    StartActivityStore.instance.removeListener(_loadStartActivities);
    super.dispose();
  }

  Future<void> _hydrateTodayMood() async {
    final info = await MoodService.instance.todayMoodInfo();
    if (!mounted || info.slug == null || _selectedMood != null) return;
    final _Mood? mood = _moodFromSlug(info.slug);
    if (mood == null) return;
    setState(() {
      _selectedMood = mood;
      _selectedMessage = info.message;
    });
  }

  /// Add a task straight from the home tasks card. Opens a small sheet and
  /// forwards to TaskService (which optimistically updates TaskStore, so the
  /// list refreshes without extra wiring).
  Future<void> _onAddTask() async {
    // Tasks save to the account (backend-first) — gated for guests.
    if (AuthService.isGuest) {
      showLoginRequiredToast(context);
      return;
    }
    final String? label = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const _AddTaskSheet(),
    );
    final String? trimmed = label?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await TaskService.instance.add(trimmed);
  }

  void _onOpenNotifications() {
    // Refresh the unread badge when returning — items may have been read/deleted.
    Navigator.of(context)
        .pushNamed('/notifications')
        .then((_) => NotificationCountStore.instance.refresh());
  }

  /// Routes the single mood recommendation by its [MoodTarget], existing routes
  /// only. Breathing → Balance Station (NOT the session directly) so the
  /// official "قبل ما تبدأ" flow is preserved; AI → اسأل مشكاة.
  void _openMoodRecommendation(MoodTarget target) {
    switch (target) {
      case MoodTarget.focus:
        MainShell.jumpTo(context, MainShell.focusIndex);
        return;
      case MoodTarget.journey:
      // Journey route is available, so مسترخي resolves to Journey too.
      case MoodTarget.journeyOrFocus:
        MainShell.jumpTo(context, MainShell.journeyIndex);
        return;
      case MoodTarget.games:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: ActivityCategoryRoutes.playArea),
            builder: (_) => const PlayAreaScreen(),
          ),
        );
        return;
      case MoodTarget.journal:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const JournalingSpaceScreen(),
          ),
        );
        return;
      case MoodTarget.understandFeelings:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const UnderstandFeelingsExerciseScreen(),
          ),
        );
        return;
      case MoodTarget.breathing:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(
              name: ActivityCategoryRoutes.balanceStation,
            ),
            builder: (_) => const BalanceStationScreen(),
          ),
        );
        return;
      case MoodTarget.ai:
        Navigator.of(context).pushNamed('/smart-companion');
        return;
      case MoodTarget.activitiesDefault:
        MainShell.jumpTo(context, MainShell.activitiesIndex);
        return;
    }
  }

  Future<void> _onSelectMood(_Mood mood) async {
    if (_selectedMood != null) return;
    // Mood check-in saves to the account — gated for guests.
    if (AuthService.isGuest) {
      showLoginRequiredToast(context);
      return;
    }
    // Optimistically show the "تم تسجيل شعورك" card, but verify the POST
    // actually persisted. If it failed (network, consent, validation),
    // revert the card and tell the user — silently faking success was
    // hiding real check-in failures.
    setState(() => _selectedMood = mood);
    final result = await MoodService.instance.checkIn(mood.slug);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _selectedMood = null;
        _selectedMessage = null;
      });
      showAppToast(
        context,
        'ما قدرنا نسجّل مزاجك، نعيد المحاولة؟',
        type: AppToastType.error,
      );
      return;
    }
    setState(() => _selectedMessage = result.message);
  }

  /// Tapped from the recorded-mood card's edit button. Confirms gently first
  /// (changing a logged feeling is the user's choice, never nagged), then
  /// reopens the picker and commits the new mood.
  Future<void> _onEditMood() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _ChangeMoodConfirmDialog(),
    );
    if (confirmed != true || !mounted) return;
    // Refresh the catalogue so the picker reflects any admin changes.
    await MoodCatalog.instance.refresh();
    if (!mounted) return;
    final _Mood? mood = await showModalBottomSheet<_Mood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const _MoodPickerSheet(),
    );
    if (mood != null) _changeMood(mood);
  }

  /// Re-records today's mood after an explicit edit. Unlike [_onSelectMood]
  /// there's no "already recorded" guard — that's the whole point. On failure
  /// we revert to the *previous* feeling (not the picker) so the card never
  /// blanks out.
  Future<void> _changeMood(_Mood mood) async {
    final _Mood? previousMood = _selectedMood;
    final String? previousMessage = _selectedMessage;
    if (mood == previousMood) return;
    setState(() {
      _selectedMood = mood;
      _selectedMessage = null;
    });
    final result = await MoodService.instance.checkIn(mood.slug);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _selectedMood = previousMood;
        _selectedMessage = previousMessage;
      });
      showAppToast(
        context,
        'ما قدرنا نحدّث مزاجك، نعيد المحاولة؟',
        type: AppToastType.error,
      );
      return;
    }
    setState(() => _selectedMessage = result.message);
  }

  /// Fetch picks for the افهم شعورك "ابدأ نشاطك" card, scored against the mood
  /// inferred from that flow (StartActivityStore). Cleared to null when there's
  /// no stashed mood for today. Best-effort.
  Future<void> _loadStartActivities() async {
    final String? mood = StartActivityStore.instance.moodForToday;
    if (mood == null) {
      if (!mounted) return;
      setState(() => _startActivitySlugs = null);
      return;
    }
    final List<String> slugs = await ActivityApi.recommended(mood: mood);
    if (!mounted) return;
    setState(() => _startActivitySlugs = slugs);
  }

  /// Resolvable "ابدأ نشاطك" picks (capped at 3), or empty when none.
  List<String> get _startActivityPicks {
    final List<String>? slugs = _startActivitySlugs;
    if (slugs == null) return const <String>[];
    return slugs
        .where((String s) => resolveActivitySuggestion(s) != null)
        .take(3)
        .toList();
  }

  /// Time-of-day Arabic greeting, matched against the Flutter spec:
  ///   05–11 صباح الخير
  ///   12–16 طاب نهارك
  ///   17–20 مساء الخير
  ///   21–04 ليلة هادئة
  /// Computed client-side so it tracks the user's local clock without a
  /// round-trip to the server.
  String _greetingForNow() {
    final int hour = DateTime.now().hour;
    if (hour >= 5 && hour <= 11) return 'صباح الخير';
    if (hour >= 12 && hour <= 16) return 'طاب نهارك';
    if (hour >= 17 && hour <= 20) return 'مساء الخير';
    return 'ليلة هادئة';
  }

  String _firstName(String? fullName) {
    final n = fullName?.trim();
    if (n == null || n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeTopBar(
                  name: _firstName(AuthService.currentUser?.name),
                  greeting: _greetingForNow(),
                  message: 'ابدأ بخطوة صغيرة تغيّر حالتك',
                  onNotifications: _onOpenNotifications,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      0,
                      AppSpacing.xxl,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FeelingsCard(
                          selected: _selectedMood,
                          message: _selectedMessage,
                          onSelect: _onSelectMood,
                          onEdit: _onEditMood,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AnimatedBuilder(
                          animation: ReminderStore.instance,
                          builder: (context, _) {
                            final String? reminder =
                                ReminderStore.instance.textForToday;
                            if (reminder == null) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ReminderCard(
                                  text: reminder,
                                  onDismiss: () =>
                                      ReminderStore.instance.clear(),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: TaskStore.instance,
                          builder: (context, _) {
                            // ONE mood-based recommendation from the shared
                            // source of truth ("خطوتك التالية ✨"), plus the
                            // افهم شعورك "ابدأ نشاطك" card when present.
                            final MoodRecommendation rec =
                                moodRecommendationFor(_selectedMood?.slug);
                            final List<String> startPicks = _startActivityPicks;
                            final bool hasStartPicks = startPicks.isNotEmpty;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _MoodRecommendationCard(
                                  recommendation: rec,
                                  onStart: () =>
                                      _openMoodRecommendation(rec.target),
                                ),
                                if (hasStartPicks) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  _MoodActivitiesSection(
                                    slugs: startPicks,
                                    heading: '✨ ابدأ نشاطك',
                                    caption: 'المبني على فهمك لشعورك',
                                    // One-shot: opening a suggestion fulfils the
                                    // prompt, so clear it (the card disappears).
                                    onOpened: (_) =>
                                        StartActivityStore.instance.clear(),
                                  ),
                                ],
                                // Tasks card always shows (with its "+" add
                                // button) so a task can be added in both the
                                // pre- and post-mood-check states.
                                const SizedBox(height: AppSpacing.xl),
                                _TasksCard(onAdd: _onAddTask),
                                // Bottom utility cards — always below the tasks
                                // card, so each just needs one gap above it.
                                if (!_focusDismissed) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  FocusCard(
                                    heading: '🎯 ابدأ لحظة للتركيز',
                                    onStart: () => MainShell.jumpTo(
                                      context,
                                      MainShell.focusIndex,
                                    ),
                                    onRemindLater: () => setState(
                                      () => _focusDismissed = true,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.name,
    required this.greeting,
    required this.message,
    required this.onNotifications,
  });

  final String name;
  final String greeting;
  final String message;
  final VoidCallback onNotifications;

  static const double _emojiSize = 32;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: ThemeController.instance.darkMode,
            builder: (context, isDark, _) {
              // Dark: white lantern on a purple circle. Light: gold lantern on
              // a soft buttery-yellow circle.
              final Color circleColor = isDark
                  ? AppPalettePurple.shade300
                  : AppPaletteButteryYellow.shade100.withValues(alpha: 0.3);
              final Color iconColor = isDark
                  ? AppNeutralColors.white
                  : AppPaletteButteryYellow.shade25;
              return Container(
                width: _emojiSize,
                height: _emojiSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  AppSvgIcons.mishkatIcon,
                  height: 20,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting $name!',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.thmanyahDisplay(context).copyWith(
                    fontSize: AppFontSizes.md,
                    color: context.colors.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  textAlign: TextAlign.right,
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
          const SizedBox(width: AppSpacing.xl),
          _NotificationButton(onTap: onNotifications),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});

  final VoidCallback onTap;

  static const double _size = 32;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'الإشعارات',
      child: Material(
        color: context.colors.white,
        shape: const CircleBorder(),
        shadowColor: const Color(0x1A101828),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: _size,
            height: _size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: SvgPicture.asset(
                    AppSvgIcons.homeNotification,
                    width: _iconSize,
                    height: _iconSize,
                    colorFilter: ColorFilter.mode(
                      context.colors.shade700,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: ListenableBuilder(
                    listenable: NotificationCountStore.instance,
                    builder: (context, _) {
                      final int count = NotificationCountStore.instance.unread;
                      if (count <= 0) return const SizedBox.shrink();
                      return _NotificationBadge(count: count);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppDangerColors.shade500,
        borderRadius: BorderRadius.circular(AppRadius.full),
        // Cutout ring that matches the surface behind the badge, so it follows
        // the theme instead of staying literal white on the dark top bar.
        border: Border.all(color: context.colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: 9,
          fontWeight: AppFontWeights.bold,
          color: AppNeutralColors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: AppTextStyles.thmanyahHeading(context).copyWith(fontSize: AppFontSizes.sm),
    );
  }
}

class _CardCaption extends StatelessWidget {
  const _CardCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontFamily: AppFontFamily.text,
        fontSize: AppFontSizes.xxs,
        fontWeight: AppFontWeights.regular,
        color: context.colors.shade500,
        height: 1.4,
      ),
    );
  }
}

class _FeelingsCard extends StatelessWidget {
  const _FeelingsCard({
    required this.selected,
    required this.message,
    required this.onSelect,
    this.onEdit,
  });

  final _Mood? selected;
  final String? message;
  final ValueChanged<_Mood> onSelect;
  final VoidCallback? onEdit;

  Future<void> _onRecordTapped(BuildContext context) async {
    // Pull the latest catalogue (emoji/colour/order/visibility) on tap so the
    // picker reflects admin changes immediately instead of a stale render.
    await MoodCatalog.instance.refresh();
    if (!context.mounted) return;
    final _Mood? mood = await showModalBottomSheet<_Mood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const _MoodPickerSheet(),
    );
    if (mood != null) onSelect(mood);
  }

  @override
  Widget build(BuildContext context) {
    final _Mood? mood = selected;
    if (mood != null) {
      return _SelectedFeelingCard(mood: mood, message: message, onEdit: onEdit);
    }
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeading('🤔 كيف مزاجك الآن؟'),
          const SizedBox(height: AppSpacing.md),
          const _CardCaption(
            'سجّل حالتك المزاجية، ابدأ بخطوة صغيرة تغيّر حالتك.',
          ),
          const SizedBox(height: AppSpacing.xl),
          _PrimaryPill(
            label: 'سجّل مزاجك الآن',
            showArrow: true,
            onTap: () => _onRecordTapped(context),
          ),
        ],
      ),
    );
  }
}

class _MoodPickerSheet extends StatefulWidget {
  const _MoodPickerSheet();

  @override
  State<_MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<_MoodPickerSheet> {
  /// Bundled fallback order, shown until the catalogue loads (and offline).
  static const List<_Mood> _defaultOrder = [
    _Mood.excited,
    _Mood.happy,
    _Mood.relaxed,
    _Mood.calm,
    _Mood.bored,
    _Mood.sad,
    _Mood.upset,
    _Mood.tense,
    _Mood.neutral,
  ];

  /// The moods to show, driven by the admin catalogue (active set + order via
  /// display_order). Falls back to [_defaultOrder] until it loads. Brand-new
  /// admin slugs the client doesn't know yet are skipped.
  List<_Mood> get _order {
    final List<String> slugs = MoodCatalog.instance.orderedSlugs;
    if (slugs.isEmpty) return _defaultOrder;
    final List<_Mood> out = <_Mood>[];
    for (final String s in slugs) {
      final _Mood? m = _moodFromSlug(s);
      if (m != null) out.add(m);
    }
    return out.isEmpty ? _defaultOrder : out;
  }

  late int _selectedIndex;
  late final PageController _pageController;

  _Mood get _selected => _order[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _selectedIndex = _order.indexOf(_Mood.happy);
    if (_selectedIndex < 0) _selectedIndex = 0;
    _pageController = PageController(
      viewportFraction: 0.22,
      initialPage: _selectedIndex,
    );
    // Make the picker self-sufficient: load (and refresh) the mood catalogue so
    // the moods/emojis/colours are the admin-managed ones even if the sheet is
    // opened before the home screen's load finished. Rebuild once it lands and
    // keep the selection in range if the admin changed the set/order.
    MoodCatalog.instance.ensureLoaded().then((_) {
      if (!mounted) return;
      final int max = _order.isEmpty ? 0 : _order.length - 1;
      final int clamped = _selectedIndex > max ? max : _selectedIndex;
      setState(() => _selectedIndex = clamped);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _pageController.hasClients &&
            _pageController.page?.round() != clamped) {
          _pageController.jumpToPage(clamped);
        }
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _selectedIndex = i);
  }

  void _onItemTapped(int i) {
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _onConfirm() {
    Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          // Match the app background so the sheet reads as the same surface.
          color: context.colors.shade50,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Builder(
                builder: (context) {
                  // Square card: its width is the sheet width minus the 20px
                  // side insets, so the height matches to keep it 1:1.
                  final double cardSize =
                      MediaQuery.of(context).size.width - 40;
                  return SizedBox(
                    height: 134 + cardSize,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 154,
                          child: _MoodPickerHeader(mood: _selected),
                        ),
                        Positioned(
                          top: 134,
                          left: 20,
                          right: 20,
                          height: cardSize,
                          child: _MoodCard(mood: _selected),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _MoodCarousel(
                  moods: _order,
                  selectedIndex: _selectedIndex,
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  onItemTapped: _onItemTapped,
                  label: _selected.label,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: AppButton(
                  label: 'تأكيد',
                  expand: true,
                  onPressed: _onConfirm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodPickerHeader extends StatelessWidget {
  const _MoodPickerHeader({required this.mood});

  final _Mood mood;

  static const double _height = 154;

  static const String _cloudSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="80" height="41" viewBox="0 0 80 41" fill="none">'
      '<path opacity="0.35" d="M54.5328 0C66.3572 0.00018426 77.4904 9.17988 79.5137 28.8108C79.8464 32.0394 79.721 36.5995 79.6106 39.1277C79.5646 40.1813 78.6931 41 77.6384 41H1.92011C0.7435 41 -0.166145 39.9996 0.0257263 38.8387C0.89505 33.5791 4.02135 20.2009 13.7744 15.5135C21.7246 11.6926 28.4151 14.6343 32.1325 17.1703C33.5106 18.1104 35.807 17.4104 36.3307 15.8264C38.2412 10.048 43.1936 -0.000176694 54.5328 0Z" fill="#FFFFFF"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: _height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: mood.gradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: AppSpacing.lg,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    // On the always-light mood gradient, use the light-mode ink
                    // so the handle stays visible in both themes.
                    color: AppNeutralColors.shade600.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 42,
              right: -20,
              child: SvgPicture.string(_cloudSvg, width: 80, height: 41),
            ),
            Positioned(
              top: 88,
              left: -8,
              child: Transform.scale(
                scaleX: -1,
                child: SvgPicture.string(_cloudSvg, width: 64, height: 33),
              ),
            ),
            Center(
              child: Text(
                'كيف مزاجك الآن؟',
                textAlign: TextAlign.center,
                style: AppTextStyles.thmanyahDisplay(context).copyWith(
                  fontSize: AppFontSizes.lg,
                  fontWeight: AppFontWeights.bold,
                  // Header sits on the always-light mood gradient, so it needs
                  // the light-mode dark ink in both themes (the theme-aware
                  // shade600 turns light-grey in dark mode and vanishes here).
                  color: AppNeutralColors.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.mood});

  final _Mood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Size is driven by the parent Positioned (square: width == height).
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        // `white` sits above the darker app-background sheet, so the card reads
        // as raised in dark mode.
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        // Soft drop shadow in both themes — a faint navy in light, a deeper
        // (but soft) black in dark where a navy tint would vanish.
        boxShadow: [
          BoxShadow(
            color: context.forDark(
              const Color(0x14101828),
              const Color(0x59000000),
            ),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mood.ring.withValues(alpha: 0.2),
              ),
            ),
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mood.ring.withValues(alpha: 0.3),
              ),
            ),
            _MoodEmojiIcon(emoji: mood.emoji, size: 120),
          ],
        ),
      ),
    );
  }
}

class _MoodEmojiIcon extends StatelessWidget {
  const _MoodEmojiIcon({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          emoji,
          textAlign: TextAlign.center,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: const TextStyle(
            fontSize: 64,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}

const double _kCarouselHeight = 105;
const double _kCurveStartY = 105;
const double _kCurveControlY = 5;
const double _kViewportFraction = 0.22;
const double _kLabelTopY = 68;

double _kBezierY(double t) {
  final double s = 1 - t;
  return _kCurveStartY * (s * s * s + t * t * t) + 3 * _kCurveControlY * s * t;
}

class _MoodCarousel extends StatelessWidget {
  const _MoodCarousel({
    required this.moods,
    required this.selectedIndex,
    required this.controller,
    required this.onPageChanged,
    required this.onItemTapped,
    required this.label,
  });

  final List<_Mood> moods;
  final int selectedIndex;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onItemTapped;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kCarouselHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: _ArcLinePainter())),
          Positioned.fill(
            child: PageView.builder(
              controller: controller,
              onPageChanged: onPageChanged,
              itemCount: moods.length,
              clipBehavior: Clip.none,
              itemBuilder: (context, i) {
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    double page;
                    if (controller.hasClients &&
                        controller.position.haveDimensions) {
                      page = controller.page ?? selectedIndex.toDouble();
                    } else {
                      page = selectedIndex.toDouble();
                    }
                    final double signedDistance = page - i;
                    return _MoodCarouselItem(
                      mood: moods[i],
                      signedDistance: signedDistance,
                      onTap: () => onItemTapped(i),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            top: _kLabelTopY,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xxs,
                  fontWeight: AppFontWeights.semibold,
                  color: context.colors.shade500,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCarouselItem extends StatelessWidget {
  const _MoodCarouselItem({
    required this.mood,
    required this.signedDistance,
    required this.onTap,
  });

  final _Mood mood;
  final double signedDistance;
  final VoidCallback onTap;

  static const Color _sideFill = Color(0xFFFFF0BD);
  static const Color _sideStroke = Color(0xFFF2D680);

  @override
  Widget build(BuildContext context) {
    final double absDistance = signedDistance.abs();
    if (absDistance > 2.5) {
      return const SizedBox.shrink();
    }
    final bool isCenter = absDistance < 0.5;
    final bool isNeighbor = absDistance >= 0.5 && absDistance < 1.5;

    final double size;
    if (isCenter) {
      size = 60;
    } else if (isNeighbor) {
      size = 44;
    } else {
      size = 30;
    }

    final double emojiFontSize = size * 0.6;

    final double t = (0.5 + signedDistance * _kViewportFraction).clamp(
      0.0,
      1.0,
    );
    final double curveY = _kBezierY(t);
    final double emojiTop = curveY - size / 2;

    final Widget circle;
    if (isCenter) {
      circle = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.moodFill(mood.bg),
          shape: BoxShape.circle,
          border: Border.all(color: mood.ring, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: mood.ring.withValues(alpha: 0.35),
              blurRadius: 15,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _MoodEmojiIcon(emoji: mood.emoji, size: emojiFontSize),
      );
    } else {
      final double bgOpacity = isNeighbor ? 0.874 : 0.414;
      final double strokeOpacity = isNeighbor ? 0.70 : 0.40;
      final double strokeWidth = isNeighbor ? 1.25 : 1.0;
      circle = SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: bgOpacity,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: _sideFill,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _sideStroke.withValues(alpha: strokeOpacity),
                    width: strokeWidth,
                  ),
                ),
              ),
            ),
            _MoodEmojiIcon(emoji: mood.emoji, size: emojiFontSize),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: emojiTop,
          left: 0,
          right: 0,
          child: Center(
            child: MergeSemantics(
              child: Semantics(
                button: true,
                selected: isCenter,
                label: mood.label,
                hint: isCenter ? 'الحالة المختارة' : 'اختيار الحالة',
                child: GestureDetector(
                  onTap: onTap,
                  child: ExcludeSemantics(child: circle),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArcLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x008B7FD8),
          Color(0x598B7FD8),
          Color(0x8C8B7FD8),
          Color(0x598B7FD8),
          Color(0x008B7FD8),
        ],
        stops: [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(0, _kCurveStartY)
      ..cubicTo(
        size.width / 3,
        _kCurveControlY,
        size.width * 2 / 3,
        _kCurveControlY,
        size.width,
        _kCurveStartY,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SelectedFeelingCard extends StatelessWidget {
  const _SelectedFeelingCard({required this.mood, this.message, this.onEdit});

  final _Mood mood;
  final String? message;

  /// Reopen the picker to change today's recorded mood. Null = no edit button.
  final VoidCallback? onEdit;

  static const double _haloSize = 72;
  static const double _cardHeight = 134;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.xl);
    // This card always shows the bright light-mode gradient, so its text and
    // emoji halo stay light-mode colors (dark ink, white halo) in both themes.
    const Color textColor = AppNeutralColors.shade600;
    final String text =
        (message != null && message!.trim().isNotEmpty)
            ? message!
            : mood.selectedMessage;

    return Container(
      height: _cardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Recorded-mood card keeps its bright light-mode gradient in both
          // themes — a celebratory display of the logged feeling.
          colors: mood.gradient,
        ),
        borderRadius: radius,
        boxShadow: AppShadows.xs,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -8,
              right: -12,
              child: _FeelingCloud(
                pathData: _kFeelingCloudRight,
                width: 60,
                height: 44,
              ),
            ),
            Positioned(
              bottom: -6,
              left: -12,
              child: _FeelingCloud(
                pathData: _kFeelingCloudLeft,
                width: 58,
                height: 39,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'تم تسجيل مزاجك',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: AppFontFamily.text,
                            fontSize: AppFontSizes.xs,
                            fontWeight: AppFontWeights.regular,
                            color: textColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: AppFontFamily.title,
                            fontSize: 18,
                            fontWeight: AppFontWeights.bold,
                            color: textColor,
                            height: 1.4,
                            fontFeatures: const [
                              FontFeature('salt'),
                              FontFeature('ss01'),
                              FontFeature('ss08'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  SizedBox(
                    width: _haloSize,
                    height: _haloSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: _haloSize,
                          height: _haloSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppNeutralColors.white.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        Container(
                          width: _haloSize * 0.833,
                          height: _haloSize * 0.833,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppNeutralColors.white.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                        _MoodEmojiIcon(emoji: mood.emoji, size: 52),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              Positioned(
                top: 10,
                left: 10,
                child: MergeSemantics(
                  child: Semantics(
                    button: true,
                    label: 'تعديل المزاج',
                    child: Material(
                      color: AppNeutralColors.white.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onEdit,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: ExcludeSemantics(
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const String _kFeelingCloudRight =
    'M53.19 0C64.7188 0.000197742 75.5737 9.85158 77.5464 30.9189C77.876 34.4392 '
    '77.7446 39.4343 77.6357 42.1191C77.5928 43.1774 76.7192 44 75.6601 44H1.92924C0.759239 '
    '44 -0.149803 43.0087 0.0203094 41.8511C0.83152 36.3309 3.84406 21.7305 13.4506 '
    '16.6486C21.0436 12.632 27.4581 15.579 31.1238 18.2592C32.5178 19.2785 34.9643 18.5678 '
    '35.464 16.9148C37.3418 10.7029 42.1756 -0.000176694 53.19 0Z';

const String _kFeelingCloudLeft =
    'M-0.914562 0C-13.6258 0.000175271 -25.594 8.73208 -27.7691 27.4054C-28.1232 30.4454 '
    '-27.9947 34.7264 -27.8769 37.1454C-27.8259 38.1923 -26.9576 39 -25.9094 39H55.7822C56.9683 '
    '39 57.878 37.9819 57.6565 36.8167C56.6891 31.7283 53.2973 19.1781 42.9007 14.7568C34.0379 '
    '10.9878 26.6315 14.1363 22.7353 16.5986C21.3888 17.4495 19.2791 16.7667 18.7326 '
    '15.2706C16.7387 9.81268 11.4365 -0.0001703 -0.914562 0Z';

class _FeelingCloud extends StatelessWidget {
  const _FeelingCloud({
    required this.pathData,
    required this.width,
    required this.height,
  });

  final String pathData;
  final double width;
  final double height;

  static const double _opacity = 0.15;
  static const double _scale = 1.3;

  @override
  Widget build(BuildContext context) {
    final int w = width.toInt();
    final int h = height.toInt();
    final String svg =
        '<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" '
        'viewBox="0 0 $w $h" fill="none">'
        '<path opacity="$_opacity" d="$pathData" fill="#FFFFFF"/>'
        '</svg>';
    return SvgPicture.string(
      svg,
      width: width * _scale,
      height: height * _scale,
    );
  }
}

/// A gentle "لا تنسى" reminder surfaced by the افهم شعورك flow (أكلم شخص /
/// أكمل يومي). Soft purple card — distinct from the task list — with a subtle
/// dismiss. Mirrors the focus screen's motivation strip.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.text, required this.onDismiss});

  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppPalettePurple.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xs,
                fontWeight: AppFontWeights.regular,
                color: context.colors.shade600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          MergeSemantics(
            child: Semantics(
              button: true,
              label: 'إغلاق التذكير',
              child: InkWell(
                onTap: onDismiss,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxs),
                  child: ExcludeSemantics(
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: context.colors.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({required this.onAdd});

  /// Opens the add-task sheet. The "+" lives on the heading row, available
  /// whether or not there are tasks yet.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TaskStore.instance,
      builder: (context, _) {
        final List<TaskItem> all = TaskStore.instance.remaining;
        final List<TaskItem> tasks = all.take(4).toList(growable: false);
        final int extra = all.length - tasks.length;
        return AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: _CardHeading('📌 مهامك المتبقية')),
                  _AddTaskButton(onTap: onAdd),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (tasks.isEmpty)
                const EmptyTasksState()
              else
                for (int i = 0; i < tasks.length; i++) ...[
                  if (i != 0) const SizedBox(height: AppSpacing.md),
                  _TaskRow(task: tasks[i]),
                ],
              if (extra > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  '+ $extra أكثر',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

}

/// Small purple "+" on the tasks card heading — opens the add-task sheet.
class _AddTaskButton extends StatelessWidget {
  const _AddTaskButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    // The purple "+" stays visually 28×28; a 44×44 hit area around it (via the
    // outer InkResponse) meets the accessibility tap-target size without
    // enlarging the chip itself.
    return Semantics(
      button: true,
      label: 'إضافة مهمة',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppPalettePurple.shade200,
                borderRadius: radius,
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppNeutralColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal bottom sheet for adding a task from the home tasks card. Pops the
/// trimmed label (or null on cancel); the caller forwards it to TaskService.
class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final bool now = _controller.text.trim().isNotEmpty;
    if (now != _canSubmit) setState(() => _canSubmit = now);
  }

  void _submit() {
    final String value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxxl,
              AppSpacing.xxl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CardHeading('📌 إضافة مهمة'),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: context.colors.shade300, width: 1),
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    textInputAction: TextInputAction.done,
                    cursorColor: AppPalettePurple.shade300,
                    onSubmitted: (_) => _submit(),
                    style: TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.sm,
                      fontWeight: AppFontWeights.regular,
                      color: context.colors.shade700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'وش المهمة اللي ودّك تخلّصها؟',
                      hintStyle: TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.sm,
                        fontWeight: AppFontWeights.regular,
                        color: context.colors.shade400,
                      ),
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AppButton(
                  label: 'إضافة',
                  expand: true,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.shade400, width: 0.2),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppPalettePurple.shade200, width: 1.5),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              task.label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xs,
                fontWeight: AppFontWeights.regular,
                color: context.colors.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline list of activities matched to the user's recorded mood, in a white
/// card matching `_TasksCard` (مهامك المتبقية). Opens the activity directly on
/// tap. Slugs are pre-filtered to resolvable ones (and capped at 3) by the
/// caller; the null guard here is belt-and-suspenders.
class _MoodActivitiesSection extends StatelessWidget {
  const _MoodActivitiesSection({
    required this.slugs,
    this.heading = '✨ أنشطة تناسب مزاجك',
    this.caption,
    this.onOpened,
  });

  final List<String> slugs;

  /// Section title — "أنشطة تناسب مزاجك" for mood picks, or "ابدأ نشاطك" when
  /// surfacing the افهم شعورك suggestion.
  final String heading;

  /// Optional sub-line under the heading (e.g. "المبني على فهمك لشعورك").
  final String? caption;

  /// Called with the slug after an activity is opened (e.g. to clear a
  /// one-shot "ابدأ نشاطك" suggestion). Null = no side effect.
  final ValueChanged<String>? onOpened;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeading(heading),
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _CardCaption(caption!),
          ],
          const SizedBox(height: AppSpacing.xl),
          for (int i = 0; i < slugs.length; i++) ...[
            if (i != 0) const SizedBox(height: AppSpacing.md),
            Builder(
              builder: (context) {
                final ActivitySuggestion? s = resolveActivitySuggestion(slugs[i]);
                if (s == null) return const SizedBox.shrink();
                return ActivitySuggestionCard(
                  colors: s.colors,
                  label: s.label,
                  description: s.description,
                  onTap: () {
                    s.open(context);
                    onOpened?.call(slugs[i]);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Placeholder for the "أنشطة تناسب مزاجك" slot shown while the backend picks
/// for a just-recorded mood are still loading, so the suggestions arrive behind
/// a loader instead of popping in abruptly.
/// The single Home mood recommendation card ("خطوتك التالية ✨"): one recorded
/// mood → one suggested next activity, from the shared [MoodRecommendation]
/// source of truth (title + one-line description + "ابدأ بخطوة" CTA). No mood →
/// the calm neutral fallback. Calm card, no loud colors, no multiple cards.
class _MoodRecommendationCard extends StatelessWidget {
  const _MoodRecommendationCard({
    required this.recommendation,
    required this.onStart,
  });

  final MoodRecommendation recommendation;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeading('✨ خطوتك التالية'),
          const SizedBox(height: AppSpacing.md),
          Text(
            recommendation.cardTitle,
            textAlign: TextAlign.right,
            style: AppTextStyles.thmanyahHeading(context)
                .copyWith(fontSize: AppFontSizes.xs),
          ),
          const SizedBox(height: AppSpacing.xs),
          _CardCaption(recommendation.sentence),
          const SizedBox(height: AppSpacing.xl),
          _PrimaryPill(
            label: 'ابدأ بخطوة',
            showArrow: true,
            onTap: onStart,
          ),
        ],
      ),
    );
  }
}

class _PillArrow extends StatelessWidget {
  const _PillArrow({required this.color});

  final Color color;

  static const double _size = 16;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppSvgIcons.arrowLeft,
      width: _size,
      height: _size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({
    required this.label,
    required this.onTap,
    this.showArrow = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: AppPalettePurple.shade200,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: AppShadows.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xs,
                  fontWeight: AppFontWeights.semibold,
                  color: AppNeutralColors.white,
                  height: 1.2,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: AppSpacing.xs),
                const _PillArrow(color: AppNeutralColors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Gentle confirm before changing an already-recorded mood. Pops `true` to
/// proceed, `false`/null to keep the current feeling. Copy stays soft and
/// non-judgmental — there's no "right" feeling to return to.
class _ChangeMoodConfirmDialog extends StatelessWidget {
  const _ChangeMoodConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final BorderRadius btnRadius = BorderRadius.circular(AppRadius.lg);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 325,
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: AppShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '🤔',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 44),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'نغيّر شعورك؟',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                    color: context.colors.shade600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'يمكن اختيار شعور ثاني، ما فيه إجابة صح أو غلط.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: AppPalettePurple.shade200,
                        borderRadius: btnRadius,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(true),
                          borderRadius: btnRadius,
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: btnRadius,
                              boxShadow: AppShadows.xs,
                            ),
                            child: const Text(
                              'نعم، نغيّره',
                              style: TextStyle(
                                fontFamily: AppFontFamily.text,
                                fontSize: AppFontSizes.xs,
                                fontWeight: AppFontWeights.semibold,
                                color: AppNeutralColors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Material(
                        color: context.colors.white,
                        borderRadius: btnRadius,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(false),
                          borderRadius: btnRadius,
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: btnRadius,
                              border: Border.all(
                                color: context.colors.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'إلغاء',
                              style: TextStyle(
                                fontFamily: AppFontFamily.text,
                                fontSize: AppFontSizes.xs,
                                fontWeight: AppFontWeights.semibold,
                                color: context.colors.shade700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

