import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_count_store.dart';
import 'notification_service.dart';

/// Background/terminated-state FCM handler. Must be a top-level (or static)
/// function annotated with `vm:entry-point` so the background isolate can find
/// it. Kept minimal: the system tray renders the notification and the
/// server-persisted feed stays the source of truth — this just ensures the
/// isolate spins up (so data-only messages aren't dropped) and never throws
/// when Firebase isn't configured on the build.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured on this build — nothing to do.
  }
}

/// Guarded FCM registration. Everything here is wrapped in try/catch and a
/// one-shot guard so the app runs normally when Firebase is NOT configured
/// (no `google-services.json` / `GoogleService-Info.plist`): in that case
/// `Firebase.initializeApp()` throws and we simply no-op. Push only becomes
/// live once the native config is added — see docs/PUSH_SETUP.md.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _initialized = false;

  /// Best-effort: initialize Firebase + listeners once, then — ONLY if the OS
  /// notification permission is already granted — fetch the FCM token and
  /// register it with the backend. This NEVER prompts for permission: the
  /// Arabic rationale + real OS request is driven from حسابي (profile), so the
  /// default OS prompt never fires at startup. Safe to call repeatedly (app
  /// start, login, and right after the user grants permission in حسابي).
  /// Never throws; failures (incl. missing Firebase config) are swallowed.
  Future<void> registerIfPossible() async {
    try {
      // No native Firebase config on these platforms in this scaffold; bail
      // before touching the SDK so desktop/web debug runs stay clean.
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
        return;
      }

      if (!_initialized) {
        // Throws if there are no native config files yet → caught below.
        await Firebase.initializeApp();

        // Wake a background isolate for messages that arrive un-foregrounded.
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );

        // Surface foreground messages minimally — the system tray + the
        // server-persisted feed stay the source of truth; this is a breadcrumb.
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint(
            'PushService: foreground message ${message.messageId ?? '(no id)'}',
          );
          // A push just arrived — bump the bell's unread badge.
          NotificationCountStore.instance.refresh();
        });

        // Re-register whenever FCM rotates the token.
        FirebaseMessaging.instance.onTokenRefresh.listen((String refreshed) {
          if (refreshed.isEmpty) return;
          unawaited(
            NotificationService.instance.registerDeviceToken(
              refreshed,
              _platform(),
            ),
          );
        });

        _initialized = true;
      }

      final messaging = FirebaseMessaging.instance;

      // Do NOT request permission here. Only register a token once the user
      // has already granted it (from حسابي or the OS settings) — this is what
      // keeps the default OS prompt from firing at app start.
      final settings = await messaging.getNotificationSettings();
      final bool authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) {
        debugPrint(
          'PushService: notifications not authorized (${settings.authorizationStatus}) — skipping token registration.',
        );
        return;
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('PushService: got FCM token, registering with backend.');
        await NotificationService.instance.registerDeviceToken(
          token,
          _platform(),
        );
      } else {
        // On iOS this happens when the app has no APNs token yet — usually the
        // Push Notifications capability is missing or the APNs key isn't set in
        // Firebase. onTokenRefresh will register it once the token arrives.
        debugPrint(
          'PushService: getToken() returned null — no APNs/FCM token available yet.',
        );
      }
    } catch (e) {
      // Firebase not configured / offline — push stays inert and the app keeps
      // running. Allow a later retry to re-init.
      _initialized = false;
      debugPrint('PushService: registration skipped ($e)');
    }
  }

  String _platform() => Platform.isIOS ? 'ios' : 'android';
}
