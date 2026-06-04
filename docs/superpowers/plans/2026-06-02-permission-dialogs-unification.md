# Permission Dialogs Unification — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the four divergent permission dialogs (mic onboarding, mic chat, notifications enable, notifications disable) with one system-styled dialog + one shared Apple-standard permission flow, with unified Arabic copy.

**Architecture:** A presentation unit (`showSystemPermissionDialog`) renders a native-looking alert (Cupertino on Apple, Material elsewhere) with language-driven text direction. A logic unit (`runPermissionFlow`) implements the Apple flow — first ask fires the OS prompt, a permanently-denied permission routes to system Settings — using injected callbacks so it is unit-testable without platform channels. Copy lives in one `PermissionCopy` holder. Call sites (onboarding, chat, profile, main shell) compose these two units.

**Tech Stack:** Flutter 3.38, `permission_handler: ^11.3.1`, `flutter_secure_storage: ^9.2.2`, `flutter_test` (`testWidgets`).

**Spec:** `docs/superpowers/specs/2026-06-02-permission-dialogs-unification-design.md`

---

## File Structure

| File | Responsibility |
|------|----------------|
| `lib/constants/permission_copy.dart` | **Create** — all permission dialog strings in one place |
| `lib/widgets/dialogs/system_permission_dialog.dart` | **Create** — native-styled dialog presenter, returns `bool` |
| `lib/core/permissions/permission_flow.dart` | **Create** — Apple-standard flow orchestrator (injected deps) |
| `lib/core/permissions/notifications_prompt_flag.dart` | **Create** — "have we prompted for notifications yet" flag |
| `lib/screens/onboarding/onboarding_screens.dart` | **Modify** — mic flow uses new units; add resume sync for CTA |
| `lib/screens/smart_companion/smart_companion_chat_screen.dart` | **Modify** — mic flow uses new units |
| `lib/screens/home/profile_screen.dart` | **Modify** — notifications enable/disable use new units; drop branded notif dialogs |
| `lib/screens/home/main_shell.dart` | **Modify** — prompt notifications once after first home entry |
| `ios/Runner/Info.plist` | **Modify** — unify `NSMicrophoneUsageDescription` copy |
| `test/widgets/system_permission_dialog_test.dart` | **Create** — widget tests |
| `test/core/permissions/permission_flow_test.dart` | **Create** — unit tests |

> **Android note:** Android has no app-authored microphone usage-description string (the OS supplies its own runtime-permission text), so there is nothing to change in `AndroidManifest.xml`. Only `Info.plist` is updated. This narrows the spec's "Info.plist / AndroidManifest" to Info.plist only.

---

## Task 1: Permission copy constants

**Files:**
- Create: `lib/constants/permission_copy.dart`

- [ ] **Step 1: Create the copy holder**

```dart
/// Every user-facing string for permission dialogs lives here so the wording
/// stays consistent across onboarding, chat, profile, and the first-launch
/// notifications prompt. Saudi-colloquial voice; unified "مرافقك الذكي".
class PermissionCopy {
  PermissionCopy._();

  // Microphone
  static const String micTitle = 'السماح بالوصول للميكروفون؟';
  static const String micPrimingBody =
      'اسمح بالوصول للميكروفون عشان تتكلم مع مرافقك الذكي بصوتك، '
      'وما نستخدمه إلا وقت المحادثة الصوتية.';
  static const String micDeniedBody =
      'فعّل الميكروفون من إعدادات جهازك عشان تتكلم مع مرافقك الذكي بصوتك.';

  // Notifications — enable / allow
  static const String notificationsTitle = 'تبي تذكيرات تساعدك تستمر؟';
  static const String notificationsPrimingBody =
      'نرسل لك تنبيهات بسيطة تساعدك تستمر، وتقدر توقفها وقت ما تبي.';
  static const String notificationsDeniedBody =
      'فعّل الإشعارات من إعدادات جهازك عشان توصلك تنبيهات تساعدك تستمر.';

  // Notifications — disable (app can't revoke OS permission; route to Settings)
  static const String notificationsDisableTitle = 'تبي توقف الإشعارات؟';
  static const String notificationsDisableBody =
      'إيقاف الإشعارات يكون من إعدادات جهازك، نوديك لها الحين.';

  // Shared button labels
  static const String allowLabel = 'السماح';
  static const String enableNotificationsLabel = 'تفعيل الإشعارات';
  static const String notNowLabel = 'ليس الآن';
  static const String laterLabel = 'لاحقًا';
  static const String openSettingsLabel = 'فتح الإعدادات';
  static const String cancelLabel = 'إلغاء';
}
```

> **Copy note for the executor / reviewer:** `micTitle`, `micPrimingBody`, `micDeniedBody`, `notificationsTitle`, `notificationsPrimingBody`, `notificationsDeniedBody`, and all button labels are user-approved. The two **disable** strings (`notificationsDisableTitle`, `notificationsDisableBody`) use the earlier-proposed "Option A" wording and are pending the user's final confirmation — do not treat them as locked.

- [ ] **Step 2: Commit**

```bash
git add lib/constants/permission_copy.dart
git commit -m "feat: add unified permission dialog copy constants"
```

---

## Task 2: System-styled permission dialog

**Files:**
- Create: `lib/widgets/dialogs/system_permission_dialog.dart`
- Test: `test/widgets/system_permission_dialog_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/widgets/dialogs/system_permission_dialog.dart';

void main() {
  // Helper: a button that opens the dialog and records its bool result.
  Widget host(void Function(bool) onResult) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final r = await showSystemPermissionDialog(
                context,
                title: 'عنوان',
                message: 'رسالة',
                confirmLabel: 'السماح',
                cancelLabel: 'إلغاء',
              );
              onResult(r);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  testWidgets('shows title, message and both labels', (tester) async {
    await tester.pumpWidget(host((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('عنوان'), findsOneWidget);
    expect(find.text('رسالة'), findsOneWidget);
    expect(find.text('السماح'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);
  });

  testWidgets('returns true when confirm tapped', (tester) async {
    bool? result;
    await tester.pumpWidget(host((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('السماح'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('returns false when cancel tapped', (tester) async {
    bool? result;
    await tester.pumpWidget(host((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('wraps content in RTL Directionality by default', (tester) async {
    await tester.pumpWidget(host((_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final Directionality dir = tester.widget(
      find
          .ancestor(
            of: find.text('عنوان'),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(dir.textDirection, TextDirection.rtl);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widgets/system_permission_dialog_test.dart`
Expected: FAIL — `showSystemPermissionDialog` is undefined (compile error).

- [ ] **Step 3: Implement the dialog**

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A permission dialog styled like the operating system's own alerts —
/// [CupertinoAlertDialog] on Apple platforms, [AlertDialog] elsewhere.
///
/// Text direction follows the content language: pass [TextDirection.ltr] for
/// English copy; the default [TextDirection.rtl] suits Arabic.
///
/// Returns `true` when the user taps the primary (confirm) action, `false`
/// when they cancel or dismiss it.
Future<bool> showSystemPermissionDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  TextDirection textDirection = TextDirection.rtl,
}) async {
  final TargetPlatform platform = Theme.of(context).platform;
  final bool isApple =
      platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

  final bool? result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => Directionality(
      textDirection: textDirection,
      child: isApple
          ? CupertinoAlertDialog(
              title: Text(title),
              content: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(cancelLabel),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
            )
          : AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(cancelLabel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(confirmLabel),
                ),
              ],
            ),
    ),
  );
  return result ?? false;
}
```

> Tests run on the default test platform (Android → Material branch). The Apple branch is exercised by manual verification on the iOS simulator in Task 10.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widgets/system_permission_dialog_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/dialogs/system_permission_dialog.dart test/widgets/system_permission_dialog_test.dart
git commit -m "feat: add system-styled permission dialog"
```

---

## Task 3: Apple-standard permission flow

**Files:**
- Create: `lib/core/permissions/permission_flow.dart`
- Test: `test/core/permissions/permission_flow_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mishkat/core/permissions/permission_flow.dart';

void main() {
  test('granted permission returns true without showing any dialog', () async {
    bool primingShown = false;
    bool deniedShown = false;
    bool requested = false;

    final granted = await runPermissionFlow(
      readStatus: () async => PermissionStatus.granted,
      request: () async {
        requested = true;
        return PermissionStatus.granted;
      },
      showPrimingDialog: () async {
        primingShown = true;
        return true;
      },
      showDeniedDialog: () async {
        deniedShown = true;
        return true;
      },
      openSettings: () async => true,
    );

    expect(granted, isTrue);
    expect(primingShown, isFalse);
    expect(deniedShown, isFalse);
    expect(requested, isFalse);
  });

  test('first ask: priming accepted -> requests OS permission', () async {
    bool requested = false;

    final granted = await runPermissionFlow(
      readStatus: () async => PermissionStatus.denied,
      request: () async {
        requested = true;
        return PermissionStatus.granted;
      },
      showPrimingDialog: () async => true,
      showDeniedDialog: () async => fail('denied dialog should not show'),
      openSettings: () async => fail('settings should not open'),
    );

    expect(requested, isTrue);
    expect(granted, isTrue);
  });

  test('first ask: priming declined -> no OS request, returns false', () async {
    bool requested = false;

    final granted = await runPermissionFlow(
      readStatus: () async => PermissionStatus.denied,
      request: () async {
        requested = true;
        return PermissionStatus.granted;
      },
      showPrimingDialog: () async => false,
      showDeniedDialog: () async => fail('denied dialog should not show'),
      openSettings: () async => fail('settings should not open'),
    );

    expect(requested, isFalse);
    expect(granted, isFalse);
  });

  test('permanently denied: confirm -> opens settings, returns false', () async {
    bool settingsOpened = false;
    bool requested = false;

    final granted = await runPermissionFlow(
      readStatus: () async => PermissionStatus.permanentlyDenied,
      request: () async {
        requested = true;
        return PermissionStatus.granted;
      },
      showPrimingDialog: () async => fail('priming dialog should not show'),
      showDeniedDialog: () async => true,
      openSettings: () async {
        settingsOpened = true;
        return true;
      },
    );

    expect(settingsOpened, isTrue);
    expect(requested, isFalse);
    expect(granted, isFalse);
  });

  test('permanently denied: declined -> does not open settings', () async {
    bool settingsOpened = false;

    final granted = await runPermissionFlow(
      readStatus: () async => PermissionStatus.permanentlyDenied,
      request: () async => PermissionStatus.granted,
      showPrimingDialog: () async => fail('priming dialog should not show'),
      showDeniedDialog: () async => false,
      openSettings: () async {
        settingsOpened = true;
        return true;
      },
    );

    expect(settingsOpened, isFalse);
    expect(granted, isFalse);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/permissions/permission_flow_test.dart`
Expected: FAIL — `runPermissionFlow` is undefined.

- [ ] **Step 3: Implement the flow**

```dart
import 'package:permission_handler/permission_handler.dart';

/// Reads the current status of a single permission.
typedef PermissionStatusReader = Future<PermissionStatus> Function();

/// Fires the real OS permission request and returns the resulting status.
typedef PermissionRequester = Future<PermissionStatus> Function();

/// Shows a dialog and returns whether the user tapped its primary action.
typedef PermissionDialogPresenter = Future<bool> Function();

/// Opens the system Settings page for this app.
typedef SettingsOpener = Future<bool> Function();

/// Runs the standard Apple permission flow for one permission and returns
/// whether it ends up granted *right now*:
///
///  * already granted        → returns true, shows nothing
///  * permanently denied      → denied dialog → (if confirmed) open Settings →
///                              returns false (a later grant is detected when
///                              the app resumes from Settings)
///  * otherwise (first ask)    → priming dialog → (if accepted) OS request →
///                              returns whether the OS granted it
Future<bool> runPermissionFlow({
  required PermissionStatusReader readStatus,
  required PermissionRequester request,
  required PermissionDialogPresenter showPrimingDialog,
  required PermissionDialogPresenter showDeniedDialog,
  required SettingsOpener openSettings,
}) async {
  final PermissionStatus status = await readStatus();
  if (status.isGranted) return true;

  if (status.isPermanentlyDenied || status.isRestricted) {
    final bool goToSettings = await showDeniedDialog();
    if (goToSettings) await openSettings();
    return false;
  }

  final bool allow = await showPrimingDialog();
  if (!allow) return false;

  final PermissionStatus result = await request();
  return result.isGranted;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/permissions/permission_flow_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/permissions/permission_flow.dart test/core/permissions/permission_flow_test.dart
git commit -m "feat: add Apple-standard permission flow orchestrator"
```

---

## Task 4: First-launch notifications flag

**Files:**
- Create: `lib/core/permissions/notifications_prompt_flag.dart`

- [ ] **Step 1: Implement the flag store**

Mirrors the project's existing `flutter_secure_storage` pattern (see `lib/core/storage/token_storage.dart`, key prefix `mishkat.*`). No test: it is a thin wrapper over the platform keystore, which is unavailable in `flutter test`.

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers whether we've already shown the one-time notifications priming
/// prompt after the user's first entry to the home shell.
class NotificationsPromptFlag {
  NotificationsPromptFlag._();

  static const String _key = 'mishkat.notifications.prompted';
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<bool> hasPrompted() async =>
      (await _storage.read(key: _key)) == 'true';

  static Future<void> markPrompted() =>
      _storage.write(key: _key, value: 'true');
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/permissions/notifications_prompt_flag.dart
git commit -m "feat: add one-time notifications-prompt flag"
```

---

## Task 5: Wire onboarding mic flow

**Files:**
- Modify: `lib/screens/onboarding/onboarding_screens.dart`

Current code: `_onRequestMicAccess` (lines ~215-223) calls a local `_showMicAccessDialog` (lines ~225-285) then `Permission.microphone.request()`. We replace both with the shared units and add resume sync so the CTA flips to "ابدأ الآن" if the user enables the mic from Settings and returns.

- [ ] **Step 1: Add imports**

At the top of the file, alongside the existing `permission_handler` import, add:

```dart
import '../../constants/permission_copy.dart';
import '../../core/permissions/permission_flow.dart';
import '../../widgets/dialogs/system_permission_dialog.dart';
```

- [ ] **Step 2: Make the onboarding State observe lifecycle**

Find the State class declaration (it currently uses `TickerProviderStateMixin` for the animation controllers). Add `WidgetsBindingObserver`:

```dart
    with TickerProviderStateMixin, WidgetsBindingObserver {
```

In `initState()` (after `super.initState();`) add:

```dart
    WidgetsBinding.instance.addObserver(this);
```

In `dispose()` (before `super.dispose();`) add:

```dart
    WidgetsBinding.instance.removeObserver(this);
```

Add this method to the State class:

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the user enabled the mic from system Settings and came back, reflect
    // it so the CTA reads "ابدأ الآن" instead of asking again.
    if (state == AppLifecycleState.resumed && !_micRequested) {
      Permission.microphone.status.then((s) {
        if (mounted && s.isGranted) setState(() => _micRequested = true);
      });
    }
  }
```

- [ ] **Step 3: Replace `_onRequestMicAccess` and delete `_showMicAccessDialog`**

Replace the whole `_onRequestMicAccess` method with:

```dart
  /// Final-step CTA: runs the shared mic permission flow, then flips the CTA
  /// to "ابدأ الآن" regardless of the outcome (the user has now been asked).
  Future<void> _onRequestMicAccess() async {
    await runPermissionFlow(
      readStatus: () => Permission.microphone.status,
      request: () => Permission.microphone.request(),
      openSettings: openAppSettings,
      showPrimingDialog: () => showSystemPermissionDialog(
        context,
        title: PermissionCopy.micTitle,
        message: PermissionCopy.micPrimingBody,
        confirmLabel: PermissionCopy.allowLabel,
        cancelLabel: PermissionCopy.notNowLabel,
      ),
      showDeniedDialog: () => showSystemPermissionDialog(
        context,
        title: PermissionCopy.micTitle,
        message: PermissionCopy.micDeniedBody,
        confirmLabel: PermissionCopy.openSettingsLabel,
        cancelLabel: PermissionCopy.cancelLabel,
      ),
    );
    if (!mounted) return;
    setState(() => _micRequested = true);
  }
```

Then **delete** the entire `_showMicAccessDialog` method (the `Future<bool?> _showMicAccessDialog() { ... }` block, ~60 lines). If `showCupertinoDialog`/`CupertinoAlertDialog` are no longer referenced elsewhere in the file, also remove the now-unused `import 'package:flutter/cupertino.dart';` if present.

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/screens/onboarding/onboarding_screens.dart`
Expected: No errors. If `use_build_context_synchronously` is reported on the `showSystemPermissionDialog(context, ...)` calls, resolve it by adding `if (!mounted) return;` immediately before the `await runPermissionFlow(` line (the State is already mounted at first tap; the flow's first await is the status read). Re-run until clean.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/onboarding/onboarding_screens.dart
git commit -m "refactor: onboarding mic uses shared permission dialog + flow"
```

---

## Task 6: Wire chat mic flow

**Files:**
- Modify: `lib/screens/smart_companion/smart_companion_chat_screen.dart`

Current code: `_showMicPermissionDialog` (lines ~168-233) shows an ad-hoc native dialog whose primary action calls `openAppSettings()`. `_startListening` (line ~235) calls `Permission.microphone.request()` then, if not granted, `_showMicPermissionDialog()`. We replace this with the shared flow.

> **Resume sync:** the chat screen re-reads the mic status on *every* mic tap inside `_startListening`, so a permission granted in Settings is picked up on the next tap. No `WidgetsBindingObserver` is needed here — adding one would be dead code. This is a deliberate, documented narrowing of the spec's "add observer to chat".

- [ ] **Step 1: Add imports**

Alongside the existing `permission_handler` / `record` imports, add:

```dart
import '../../constants/permission_copy.dart';
import '../../core/permissions/permission_flow.dart';
import '../../widgets/dialogs/system_permission_dialog.dart';
```

- [ ] **Step 2: Replace `_startListening`'s permission gate and delete `_showMicPermissionDialog`**

In `_startListening`, replace the opening permission block:

```dart
  Future<void> _startListening() async {
    final PermissionStatus status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      await _showMicPermissionDialog();
      return;
    }
```

with:

```dart
  Future<void> _startListening() async {
    final bool granted = await runPermissionFlow(
      readStatus: () => Permission.microphone.status,
      request: () => Permission.microphone.request(),
      openSettings: openAppSettings,
      showPrimingDialog: () => showSystemPermissionDialog(
        context,
        title: PermissionCopy.micTitle,
        message: PermissionCopy.micPrimingBody,
        confirmLabel: PermissionCopy.allowLabel,
        cancelLabel: PermissionCopy.notNowLabel,
      ),
      showDeniedDialog: () => showSystemPermissionDialog(
        context,
        title: PermissionCopy.micTitle,
        message: PermissionCopy.micDeniedBody,
        confirmLabel: PermissionCopy.openSettingsLabel,
        cancelLabel: PermissionCopy.cancelLabel,
      ),
    );
    if (!mounted || !granted) return;
```

Keep everything after that point in `_startListening` unchanged (the `try { final Directory dir = ... }` recording block).

Then **delete** the entire `_showMicPermissionDialog` method (~lines 168-233). If `showCupertinoDialog`/`CupertinoAlertDialog`/`AlertDialog` are no longer referenced elsewhere in the file, remove the now-unused `import 'package:flutter/cupertino.dart';` if present.

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/screens/smart_companion/smart_companion_chat_screen.dart`
Expected: No errors. Resolve any `use_build_context_synchronously` the same way as Task 5 (guard with `if (!mounted) return;` before the `await runPermissionFlow(` call).

- [ ] **Step 4: Commit**

```bash
git add lib/screens/smart_companion/smart_companion_chat_screen.dart
git commit -m "refactor: chat mic uses shared permission dialog + flow"
```

---

## Task 7: Wire profile notifications

**Files:**
- Modify: `lib/screens/home/profile_screen.dart`

Replace the branded `_EnableNotificationsDialog` / `_DisableNotificationsDialog` usage with the shared units. The profile State already has `WidgetsBindingObserver` + `didChangeAppLifecycleState` + `_loadPermissionStatus` — keep them. Keep `_ConfirmationDialog`, `_DialogPrimaryButton`, `_DialogSecondaryButton`, and `_LogoutConfirmationDialog` (still used for logout).

- [ ] **Step 1: Add imports**

Alongside the existing `permission_handler` import, add:

```dart
import '../../constants/permission_copy.dart';
import '../../core/permissions/permission_flow.dart';
import '../../widgets/dialogs/system_permission_dialog.dart';
```

- [ ] **Step 2: Replace `_enableNotifications`**

Replace the whole `_enableNotifications` method (lines ~100-138) with:

```dart
  /// Turn notifications ON via the shared Apple-standard flow, then mirror the
  /// real OS result onto the toggle and register the push token if granted.
  Future<void> _enableNotifications() async {
    setState(() => _togglingNotifications = true);
    final bool granted = await runPermissionFlow(
      readStatus: () => Permission.notification.status,
      request: () => Permission.notification.request(),
      openSettings: openAppSettings,
      showPrimingDialog: () => showSystemPermissionDialog(
        context,
        title: PermissionCopy.notificationsTitle,
        message: PermissionCopy.notificationsPrimingBody,
        confirmLabel: PermissionCopy.enableNotificationsLabel,
        cancelLabel: PermissionCopy.laterLabel,
      ),
      showDeniedDialog: () => showSystemPermissionDialog(
        context,
        title: PermissionCopy.notificationsTitle,
        message: PermissionCopy.notificationsDeniedBody,
        confirmLabel: PermissionCopy.openSettingsLabel,
        cancelLabel: PermissionCopy.cancelLabel,
      ),
    );
    if (!mounted) return;
    setState(() {
      _notifications = granted;
      _togglingNotifications = false;
    });
    if (granted) {
      unawaited(PushService.instance.registerIfPossible());
    }
    // If the user went to Settings, didChangeAppLifecycleState re-reads the
    // real state when they return.
  }
```

- [ ] **Step 3: Replace `_disableNotifications`**

Replace the whole `_disableNotifications` method (lines ~142-151) with:

```dart
  /// Turn notifications OFF. An app can't revoke its own OS permission, so we
  /// route the user to system Settings where the real switch lives.
  Future<void> _disableNotifications() async {
    final bool goToSettings = await showSystemPermissionDialog(
      context,
      title: PermissionCopy.notificationsDisableTitle,
      message: PermissionCopy.notificationsDisableBody,
      confirmLabel: PermissionCopy.openSettingsLabel,
      cancelLabel: PermissionCopy.cancelLabel,
    );
    if (!mounted || !goToSettings) return;
    await openAppSettings();
    // Leave the toggle as-is; didChangeAppLifecycleState re-reads on return.
  }
```

- [ ] **Step 4: Delete the branded notification dialog classes**

Delete the `_EnableNotificationsDialog` class (lines ~564-589) and the `_DisableNotificationsDialog` class (lines ~591-617). Do **not** touch `_LogoutConfirmationDialog`, `_ConfirmationDialog`, `_DialogPrimaryButton`, or `_DialogSecondaryButton`.

- [ ] **Step 5: Analyze**

Run: `flutter analyze lib/screens/home/profile_screen.dart`
Expected: No errors and no "unused element" warnings (confirms the deleted dialogs had no other references). If `SvgPicture`/`AppSvgIcons.profileEnableNotifications` become unused, leave them only if still referenced elsewhere; otherwise remove the dead import/usage flagged by analyze. Resolve any `use_build_context_synchronously` as in Task 5.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/home/profile_screen.dart
git commit -m "refactor: profile notifications use shared permission dialog + flow"
```

---

## Task 8: Prompt notifications after first home entry

**Files:**
- Modify: `lib/screens/home/main_shell.dart`

`_MainShellState` (line ~47) currently has no `initState`. Add one that, once, after the first frame, runs the notifications flow if we haven't prompted before.

- [ ] **Step 1: Add imports**

At the top of `main_shell.dart` add:

```dart
import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

import '../../constants/permission_copy.dart';
import '../../core/notifications/push_service.dart';
import '../../core/permissions/notifications_prompt_flag.dart';
import '../../core/permissions/permission_flow.dart';
import '../../widgets/dialogs/system_permission_dialog.dart';
```

(Keep the existing imports; `package:flutter/foundation.dart` and `material.dart` are already there.)

- [ ] **Step 2: Add `initState` + the prompt method to `_MainShellState`**

Add to the `_MainShellState` class (e.g. just above `_onTabChanged`):

```dart
  @override
  void initState() {
    super.initState();
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

    final bool granted = await runPermissionFlow(
      readStatus: () => Permission.notification.status,
      request: () => Permission.notification.request(),
      openSettings: openAppSettings,
      showPrimingDialog: () => showSystemPermissionDialog(
        context,
        title: PermissionCopy.notificationsTitle,
        message: PermissionCopy.notificationsPrimingBody,
        confirmLabel: PermissionCopy.enableNotificationsLabel,
        cancelLabel: PermissionCopy.laterLabel,
      ),
      showDeniedDialog: () => showSystemPermissionDialog(
        context,
        title: PermissionCopy.notificationsTitle,
        message: PermissionCopy.notificationsDeniedBody,
        confirmLabel: PermissionCopy.openSettingsLabel,
        cancelLabel: PermissionCopy.cancelLabel,
      ),
    );
    if (granted) {
      unawaited(PushService.instance.registerIfPossible());
    }
  }
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/screens/home/main_shell.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/home/main_shell.dart
git commit -m "feat: prompt notifications once after first home entry"
```

---

## Task 9: Unify the iOS microphone usage description

**Files:**
- Modify: `ios/Runner/Info.plist:30`

- [ ] **Step 1: Replace the string**

Find:

```xml
	<key>NSMicrophoneUsageDescription</key>
	<string>تستخدم مِشْكَاة الميكروفون عشان تسمعك وقت تتكلم مع المرافق الذكي.</string>
```

Replace the `<string>` line with:

```xml
	<string>تستخدم مِشْكَاة الميكروفون عشان تتكلم مع مرافقك الذكي بصوتك، وما يُستخدم إلا وقت المحادثة الصوتية.</string>
```

> Note: `ios/Runner/Info.plist` already has an unrelated uncommitted modification in the working tree from before this work. Stage only the line you changed.

- [ ] **Step 2: Commit (only the Info.plist string change)**

```bash
git add -p ios/Runner/Info.plist   # stage only the NSMicrophoneUsageDescription hunk
git commit -m "copy: unify iOS microphone usage description"
```

---

## Task 10: Full verification

**Files:** none (verification only)

- [ ] **Step 1: Static analysis (whole project)**

Run: `flutter analyze`
Expected: No new errors or warnings introduced by this change.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: All tests pass, including the new `system_permission_dialog_test.dart` (4) and `permission_flow_test.dart` (5).

- [ ] **Step 3: Manual verification on the iOS simulator**

Reset state between runs with:
`xcrun simctl privacy booted reset microphone com.mariyyahaziz.mishkat`
(and delete + reinstall the app to clear the notifications flag and onboarding state).

Verify each flow:

1. **Mic — onboarding, first ask:** logged out → splash → onboarding → last step → "السماح بالوصول" → system-styled dialog shows `micPrimingBody`, Arabic right-aligned → "السماح" → real iOS mic prompt appears.
2. **Mic — onboarding, after deny:** with mic permanently denied, the dialog shows `micDeniedBody` and the confirm button reads "فتح الإعدادات" → opens device Settings → enable → return → CTA reads "ابدأ الآن".
3. **Mic — chat:** with mic denied, open smart companion chat → tap mic → dialog shows; "فتح الإعدادات" opens Settings; after enabling and returning, tapping mic again starts recording.
4. **Notifications — first home entry:** fresh install → finish onboarding → sign in → land on home → notifications dialog appears once with `notificationsPrimingBody`; relaunch app → it does **not** appear again.
5. **Notifications — profile enable:** حسابي → toggle notifications on → same dialog → "تفعيل الإشعارات" → iOS prompt (first time) or Settings (if denied); toggle mirrors the real OS state after returning.
6. **Notifications — profile disable:** with notifications on, toggle off → dialog shows `notificationsDisableBody` → "فتح الإعدادات" opens Settings.
7. **Visual:** all six dialogs share the same native iOS alert appearance (no custom bell icon / colored buttons on the permission dialogs); logout confirmation still uses the branded `_ConfirmationDialog`.

- [ ] **Step 4: Report results**

Summarize pass/fail per flow with the actual observed behavior. Do not claim completion until `flutter analyze`, `flutter test`, and the manual checklist all pass.

---

## Notes for the executor

- **DRY:** the two `showSystemPermissionDialog` closures (priming + denied) recur at four call sites with different copy — that's intentional composition, not duplication to extract.
- **Disable copy is provisional** — see the note in Task 1. Flag it for the user before final sign-off.
- **`use_build_context_synchronously`** is the most likely analyzer complaint; the fix (a `mounted` guard before the flow call) is noted in each wiring task.
