# FCM push notification setup

`PushService.registerIfPossible()` initializes Firebase, requests notification
permission, fetches the FCM token, and registers it with the backend via
`POST /api/v1/me/device-token` (`{token, platform}`). It is called after a
successful login / register / Google sign-in and once on app start when a
session already exists.

**Push is inert until the native config below is added.** The whole flow is
wrapped in a guard: with no `google-services.json` / `GoogleService-Info.plist`,
`Firebase.initializeApp()` throws, `PushService` swallows it, and the app runs
normally (no token is registered, no crash). It also no-ops on web/desktop.

Packages: `firebase_core: ^4.9.0`, `firebase_messaging: ^16.2.2`.

> The `path_provider_android` override (pinned at `2.2.23` for the `jni`
> Gradle issue) is unaffected — adding the Firebase deps resolved cleanly
> without forcing it higher.

---

## 1. Firebase project

Create / open a Firebase project at <https://console.firebase.google.com/> and
register both app platforms:

- **Android app** with package name **`com.mariyyahaziz.mishkat`** (from
  `android/app/build.gradle.kts` → `applicationId`).
- **iOS app** with bundle identifier **`com.mariyyahaziz.mishkat`** (from
  `ios/Runner.xcodeproj` → `PRODUCT_BUNDLE_IDENTIFIER` for Runner).

(Using the FlutterFire CLI — `flutterfire configure` — is the easiest way to
generate everything; the manual steps are below if you prefer.)

---

## 2. Android

1. Download **`google-services.json`** from the Android app in Firebase and
   place it at **`android/app/google-services.json`**. That's the only step —
   the `com.google.gms.google-services` plugin is already declared in
   `settings.gradle.kts` and applied **conditionally** in `app/build.gradle.kts`
   (only when this file exists), so dropping it in enables FCM + Google sign-in
   with no further Gradle edits.
2. Notification permission on Android 13+ is requested at runtime by
   `FirebaseMessaging.requestPermission()` (already wired in `PushService`).

---

## 3. iOS

1. Download **`GoogleService-Info.plist`** from the iOS app in Firebase and add
   it to the **Runner** target in Xcode (drag into `ios/Runner`, "Copy items if
   needed", Runner target checked).
2. In the **Apple Developer** portal, create an **APNs Auth Key** (`.p8`) and
   upload it under **Firebase → Project settings → Cloud Messaging → Apple app
   configuration** (with its Key ID and your Team ID).
3. In Xcode, on the Runner target → **Signing & Capabilities**, add:
   - **Push Notifications**.
   - **Background Modes** → enable **Remote notifications**.

---

## 4. Backend

The backend already exposes `POST /api/v1/me/device-token` and the delivery
pipeline. No backend change is needed for the Flutter side; just ensure the
server has its FCM credentials configured to send.

---

## How to verify

1. Add the native config above for the platform you're testing and run the app
   on a real device (push does not work on simulators/emulators without extra
   setup).
2. Sign in. On success `PushService` registers the token — confirm the
   `POST /me/device-token` call reaches the backend.
3. Send a test message from **Firebase Console → Messaging** (or your backend)
   and confirm delivery. Foreground messages currently log a debug breadcrumb
   only; background/terminated messages display via the system tray.
