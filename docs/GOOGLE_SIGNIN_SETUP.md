# Google Sign-In setup

The Google button in the sign-in and sign-up screens is wired to
`AuthService.signInWithGoogle()`, which obtains a Google **ID token** and
exchanges it at `POST /api/v1/auth/google` for the same Sanctum session +
baseline consents as email login.

**This flow is inert until the steps below are done.** With no OAuth client IDs
/ native config, the `google_sign_in` SDK throws on `authenticate()`. The app
catches that and surfaces a handled `ApiException` (Arabic error toast) — it
never crashes. Once configured, the button signs the user in for real.

Package: `google_sign_in: ^7.2.0` (the 7.x API — `GoogleSignIn.instance`,
`initialize()` then `authenticate()`). The **web client ID** is passed in code
as `serverClientId`, sourced from a build-time define (see step 4); the
per-platform client IDs come from the native config files below.

---

## 1. Create the OAuth clients (Google Cloud Console)

In [Google Cloud Console](https://console.cloud.google.com/) → **APIs &
Services → Credentials**, create OAuth 2.0 Client IDs for each platform you
ship. You will need:

- **Web client ID** — the audience the **backend** verifies the ID token
  against. Put it in the backend env as `GOOGLE_CLIENT_ID`. On Android the
  native SDK also uses this as the `serverClientId`, so it is required even for
  Android-only testing.
- **Android client ID** — bound to the app's **package name** and **SHA-1**
  certificate fingerprint (see below).
- **iOS client ID** — bound to the iOS **bundle identifier**.

> The ID token sent to the backend must have the **web client ID** as its
> `aud`. Make sure the backend `GOOGLE_CLIENT_ID` matches that web client.

---

## 2. Android

- Package name: **`com.mariyyahaziz.mishkat`** (from
  `android/app/build.gradle.kts` → `applicationId`).
- Get the debug SHA-1:
  ```bash
  cd android && ./gradlew signingReport
  # or:
  keytool -list -v -keystore ~/.android/debug.keystore \
    -alias androiddebugkey -storepass android -keypass android
  ```
  Register that SHA-1 (and the **release** keystore SHA-1, and the Play App
  Signing SHA-1 once uploaded) on the **Android OAuth client**.
- Recommended: download **`google-services.json`** from the Firebase/Cloud
  console and drop it at `android/app/google-services.json`. (If you also do
  the FCM push setup in `PUSH_SETUP.md`, the same file and the
  `com.google.gms.google-services` Gradle plugin cover both.)

---

## 3. iOS

- Download **`GoogleService-Info.plist`** (or grab the values from the iOS
  OAuth client) and add the iOS client's **reversed client ID** as a URL
  scheme in `ios/Runner/Info.plist`:
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <!-- Reversed iOS client ID, e.g.
             com.googleusercontent.apps.1234567890-abcdef -->
        <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
      </array>
    </dict>
  </array>
  ```
- If you ship `GoogleService-Info.plist`, add it to the Runner target in Xcode.

---

## 4. Backend + build-time define

- Set `GOOGLE_CLIENT_ID` (the **web** client ID from step 1) in the backend
  environment so `POST /api/v1/auth/google` verifies the incoming ID token's
  audience. (`GOOGLE_CLIENT_SECRET` is unused by the ID-token flow — leave it.)
- Build the Flutter app with the **same web client ID** passed as
  `serverClientId`, so the ID token's `aud` is the web client on **both**
  platforms (without this, iOS tokens carry the iOS-client audience and the
  backend rejects them):

  ```bash
  flutter build apk    --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
  flutter build ipa    --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
  # (and the same --dart-define on `flutter run`)
  ```

  The code reads it via `String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID')` and
  passes it to `GoogleSignIn.instance.initialize(serverClientId: …)`. Combine it
  with the existing `--dart-define=MISHKAT_API_BASE_URL=…` if you override that.

---

## How to verify

1. Add the native config above for the platform you're testing.
2. Run the app, open the sign-in screen, tap the Google button.
3. The native account picker appears; choose an account.
4. On success the app navigates to the success screen (same as email login).
   On a backend rejection (e.g. `GOOGLE_TOKEN_INVALID`) the Arabic error toast
   shows. Cancelling the picker is a silent no-op.
