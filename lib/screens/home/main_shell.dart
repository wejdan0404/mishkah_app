import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_icons.dart';
import '../../core/auth/auth_service.dart';
import '../../core/focus/focus_presets_service.dart';
import '../../core/focus/focus_service.dart';
import '../../core/journey/journey_service.dart';
import '../../core/notifications/push_service.dart';
import '../../core/permissions/notifications_prompt_flag.dart';
import '../../core/permissions/permission_flow.dart';
import '../../core/tasks/task_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons/ai_floating_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/nav/app_bottom_nav_bar.dart';
import 'activities_screen.dart';
import 'focus_screen.dart';
import 'home_screen.dart';
import 'journey_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = homeIndex});

  final int initialIndex;

  static const int accountIndex = 0;
  static const int journeyIndex = 1;
  static const int focusIndex = 2;
  static const int activitiesIndex = 3;
  static const int homeIndex = 4;

  /// Switch the shell to the given tab from anywhere that has a
  /// BuildContext under the shell. No-op if not under a MainShell.
  static void jumpTo(BuildContext context, int index) {
    final state = _MainShellScope.of(context);
    state?._onTabChanged(index);
  }

  /// The currently-selected tab as a listenable, for widgets that want to
  /// react when their tab becomes active (e.g. re-running an intro animation).
  /// Returns null if not under a MainShell.
  static ValueListenable<int>? activeIndexOf(BuildContext context) {
    return _MainShellScope.of(context)?._activeIndex;
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex = widget.initialIndex;
  late final ValueNotifier<int> _activeIndex = ValueNotifier(_currentIndex);

  // Each tab that fetches from the backend is wrapped in a full-screen
  // first-load veil (a faint scrim + centered loader) so the user sees "this
  // is loading" instead of an empty/half-built screen, then the content. Tabs
  // with no remote data — حسابي (cached user) and الأنشطة (static catalogue) —
  // are left bare so the veil never shows for them.
  late final List<Widget> _screens = [
    const ProfileScreen(),
    AnimatedBuilder(
      animation: JourneyService.instance,
      child: const JourneyScreen(),
      // First snapshot still in flight (later refreshes keep the old one).
      builder: (context, child) => LoadingOverlay(
        loading: JourneyService.instance.loading &&
            JourneyService.instance.latest == null,
        child: child!,
      ),
    ),
    AnimatedBuilder(
      animation: FocusService.instance,
      child: const FocusScreen(),
      // First /focus/today still in flight (no count yet).
      builder: (context, child) => LoadingOverlay(
        loading: FocusService.instance.loading && !FocusService.instance.hasData,
        child: child!,
      ),
    ),
    const ActivitiesScreen(),
    AnimatedBuilder(
      animation: TaskService.instance,
      child: const HomeScreen(),
      builder: (context, child) => LoadingOverlay(
        loading: TaskService.instance.firstLoad,
        child: child!,
      ),
    ),
  ];

  static const List<AppBottomNavItem> _items = [
    AppBottomNavItem(
      iconAsset: AppSvgIcons.navAccount,
      activeIconAsset: AppSvgIcons.navAccountSolid,
      label: 'حسابي',
    ),
    AppBottomNavItem(
      iconAsset: AppSvgIcons.navJourney,
      activeIconAsset: AppSvgIcons.navJourneySolid,
      label: 'رحلتي',
    ),
    AppBottomNavItem(
      iconAsset: AppSvgIcons.navFocus,
      activeIconAsset: AppSvgIcons.navFocusSolid,
      label: 'التركيز',
    ),
    AppBottomNavItem(
      iconAsset: AppSvgIcons.navActivities,
      activeIconAsset: AppSvgIcons.navActivitiesSolid,
      label: 'الأنشطـة',
    ),
    AppBottomNavItem(
      iconAsset: AppSvgIcons.navHome,
      activeIconAsset: AppSvgIcons.navHomeSolid,
      label: 'الرئيسية',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Refresh the tab we land on (usually home) immediately, so tasks and the
    // rest hydrate on first arrival instead of waiting for the first tab
    // switch. Services dedupe concurrent calls, so this is safe.
    _refreshForTab(_currentIndex);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybePromptNotifications(),
    );
  }

  /// One-time, after the user's first arrival at the home shell: ask for
  /// notifications via the shared Apple-standard flow. Marks the flag *before*
  /// showing so it never appears twice, even if dismissed.
  Future<void> _maybePromptNotifications() async {
    if (await NotificationsPromptFlag.hasPrompted()) return;
    await NotificationsPromptFlag.markPrompted();
    if (!mounted) return;

    // First-launch prompt: no app dialogs — go straight to the OS prompt (and
    // to Settings if somehow already denied). The app-styled priming/denied
    // dialogs live only on the explicit "حسابي" toggle (see profile_screen).
    final bool granted = await runPermissionFlow(
      readStatus: () => Permission.notification.status,
      request: () => Permission.notification.request(),
      openSettings: openAppSettings,
    );
    if (granted) {
      unawaited(PushService.instance.registerIfPossible());
    }
  }

  void _onTabChanged(int i) {
    setState(() => _currentIndex = i);
    _activeIndex.value = i;
    _refreshForTab(i);
  }

  @override
  void dispose() {
    _activeIndex.dispose();
    super.dispose();
  }

  /// Per-tab refresh. Each tab triggers a fresh fetch of its own data the
  /// moment the user lands on it, so a check-in (or completion, or profile
  /// edit) on one tab is reflected on every other tab without forcing a
  /// pull-to-refresh. All underlying services are ChangeNotifiers that
  /// dedupe concurrent calls, so this never double-hits the API.
  void _refreshForTab(int i) {
    switch (i) {
      case MainShell.accountIndex:
        // Profile shows name/email and consent state — refresh from
        // /auth/me so a name change on another device shows up here.
        AuthService.fetchCurrentUser();
        break;
      case MainShell.journeyIndex:
        JourneyService.instance.refresh();
        break;
      case MainShell.focusIndex:
        // Today's session count powers the progress card. Presets are
        // catalogue data that admins can edit, so refresh on every entry.
        // Hydrate tasks from the backend too so the picker stays in sync and
        // shows a loader on first open instead of an empty flash.
        FocusService.instance.refresh();
        FocusPresetsService.instance.refresh();
        TaskService.instance.load();
        break;
      case MainShell.activitiesIndex:
        // Activity catalogue is stable — no remote refresh needed yet.
        // Local task list stays reactive through TaskStore.
        break;
      case MainShell.homeIndex:
        // Greeting + name follow currentUser; mood catalogue is cached
        // for the session. Hydrate tasks from the backend on entry.
        AuthService.fetchCurrentUser();
        TaskService.instance.load();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MainShellScope(
      state: this,
      child: Scaffold(
        backgroundColor: context.colors.shade50,
        body: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: _screens),
            // Shared floating "اسأل مِشْكَاة" entry point. Living in the shell
            // means it shows on every main tab (الرئيسية / الأنشطة / التركيز /
            // رحلتي / حسابي) and is automatically hidden on pushed full-screen
            // flows (breathing & focus sessions, games, journal writing,
            // dialogs, success/summary screens) since those routes cover the
            // shell. It sits 20px above the bottom nav and 20px from the
            // trailing edge, so it never overlaps the bar. The label only
            // reveals on the home tab; other tabs show the icon alone.
            Positioned(
              right: 20,
              bottom: 20,
              child: AiFloatingButton(
                onTap: () =>
                    Navigator.of(context).pushNamed('/smart-companion'),
                activeTab: _activeIndex,
                tabIndex: MainShell.homeIndex,
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNavBar(
          items: _items,
          currentIndex: _currentIndex,
          onChanged: _onTabChanged,
        ),
      ),
    );
  }
}

class _MainShellScope extends InheritedWidget {
  const _MainShellScope({required this.state, required super.child});

  final _MainShellState state;

  static _MainShellState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_MainShellScope>()?.state;
  }

  @override
  bool updateShouldNotify(_MainShellScope oldWidget) => false;
}
