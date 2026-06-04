import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

import '../../models/auth_tokens.dart';
import '../../models/user.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_exception.dart';
import '../focus/focus_presets_service.dart';
import '../focus/focus_service.dart';
import '../journal/journal_store.dart';
import '../journey/journey_service.dart';
import '../notifications/push_service.dart';
import '../storage/token_storage.dart';
import '../tasks/task_service.dart';

class AuthService {
  AuthService._();

  static User? _currentUser;
  static User? get currentUser => _currentUser;
  static bool get isLoggedIn => TokenStorage.instance.hasSession;

  /// True when the user tapped "تجربة كضيف": a local, token-less browse mode.
  /// No token is created. Backend-saving actions are gated in the UI with a
  /// calm "سجّل الدخول لحفظ بياناتك." prompt (see [showLoginRequiredToast]).
  /// Read paths are best-effort and just fall back to empty/default state.
  /// Session-only (not persisted) and cleared on any real sign-in / logout, so
  /// a relaunch returns to the sign-in screen.
  static bool isGuest = false;

  /// Enter the local guest browse mode (see [isGuest]).
  static void enterGuestMode() {
    isGuest = true;
  }

  /// Sign in with email/password. Persists tokens + returns the user.
  /// Throws [ApiException] on failure (401 INVALID_CREDENTIALS, 422, 429, etc.).
  /// [restore] = true cancels a pending account deletion on a confirmed
  /// re-login (the sign-in screen asks first when it sees ACCOUNT_PENDING_DELETE).
  static Future<User> login({
    required String email,
    required String password,
    bool restore = false,
  }) async {
    final data = await ApiClient.instance.post(
      ApiEndpoints.login,
      auth: false,
      body: {
        'email': email,
        'password': password,
        if (restore) 'restore': true,
      },
    ) as Map<String, dynamic>;
    final user = await _persistSession(data);
    await ensureBaselineConsents();
    unawaited(PushService.instance.registerIfPossible());
    return user;
  }

  /// Register a new account. The signup UI only collects
  /// name/email/password — every other field is optional on the backend
  /// and gets populated later via PATCH /me once the user picks their
  /// birth year in onboarding.
  static Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.instance.post(
      ApiEndpoints.register,
      auth: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'locale': 'ar',
      },
    ) as Map<String, dynamic>;
    final user = await _persistSession(data);
    await ensureBaselineConsents();
    unawaited(PushService.instance.registerIfPossible());
    return user;
  }

  /// Sign in with Google. Triggers the native Google account picker, obtains
  /// an OpenID Connect ID token, exchanges it at POST /auth/google for a
  /// Sanctum session, then records baseline consents — exact same session
  /// shape as email [login]. Returns null if the user cancels the picker (or
  /// the platform can't show the interactive flow). Throws [ApiException] on
  /// a missing ID token or a backend rejection (e.g. GOOGLE_TOKEN_INVALID).
  ///
  /// Inert until Google OAuth client IDs + native config are added — see
  /// docs/GOOGLE_SIGNIN_SETUP.md. Without configuration the underlying SDK
  /// throws, which surfaces here as a handled [ApiException].
  static Future<User?> signInWithGoogle({bool restore = false}) async {
    final GoogleSignIn google = GoogleSignIn.instance;
    await _ensureGoogleInitialized();

    // Platforms without an interactive authenticate() flow (e.g. web) require
    // a dedicated button widget; treat as a no-op cancel for this scaffold.
    if (!google.supportsAuthenticate()) {
      return null;
    }

    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      // User dismissed / aborted the picker — not an error to surface.
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable) {
        return null;
      }
      // Configuration / provider errors (no client IDs yet, etc.) → handled
      // error so callers can show the standard error toast.
      throw ApiException(
        statusCode: 0,
        code: 'GOOGLE_SIGN_IN_FAILED',
        message: 'تعذّر تسجيل الدخول عبر جوجل، حاول مرة ثانية.',
      );
    }

    final String? idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const ApiException(
        statusCode: 0,
        code: 'GOOGLE_TOKEN_INVALID',
        message: 'تعذّر تسجيل الدخول عبر جوجل، حاول مرة ثانية.',
      );
    }

    final data = await ApiClient.instance.post(
      ApiEndpoints.googleAuth,
      auth: false,
      body: {'id_token': idToken, if (restore) 'restore': true},
    ) as Map<String, dynamic>;
    final user = await _persistSession(data);
    await ensureBaselineConsents();
    unawaited(PushService.instance.registerIfPossible());
    return user;
  }

  /// Best-effort: server-side revoke, then always clear local tokens.
  static Future<void> logout() async {
    try {
      await ApiClient.instance.post(ApiEndpoints.logout);
    } catch (_) {
      // ignore — we still want to clear locally
    }
    _currentUser = null;
    isGuest = false;
    await TokenStorage.instance.clear();
    // Drop every cached per-user snapshot so the next signed-in user
    // doesn't briefly see the previous user's stats. Each service
    // re-fetches on demand from initState/tab-change refreshes.
    JourneyService.instance.clear();
    FocusService.instance.clear();
    FocusPresetsService.instance.clear();
    TaskService.instance.clear();
    JournalStore.instance.clear();
  }

  /// Probe the current session. Returns null if no tokens or session invalid.
  static Future<User?> fetchCurrentUser() async {
    if (!TokenStorage.instance.hasSession) return null;
    try {
      final data =
          await ApiClient.instance.get(ApiEndpoints.authMe) as Map<String, dynamic>;
      final user = User.fromJson(data);
      _currentUser = user;
      return user;
    } on ApiException catch (e) {
      if (e.isUnauthenticated) {
        await TokenStorage.instance.clear();
        _currentUser = null;
      }
      return null;
    }
  }

  /// Update the user's editable profile fields (name, locale).
  static Future<User> updateProfile({
    String? name,
    String? locale,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (locale != null) body['locale'] = locale;
    final data = await ApiClient.instance.patch(
      ApiEndpoints.me,
      body: body,
    ) as Map<String, dynamic>;
    final user = User.fromJson(data);
    _currentUser = user;
    return user;
  }

  /// Schedule the current account for deletion (7-day grace).
  ///
  /// The API requires the caller to echo back the account's own email as a
  /// `confirm_email` safety check (it must match the signed-in user). We send
  /// it automatically since the UI already gates this behind an explicit
  /// confirm dialog. Throws [ApiException] if there's no live session.
  static Future<void> deleteAccount() async {
    final String? email = _currentUser?.email;
    if (email == null) {
      throw const ApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'انتهت الجلسة، سجّل دخولك من جديد.',
      );
    }
    await ApiClient.instance.delete(
      ApiEndpoints.me,
      body: {'confirm_email': email},
    );
    // We do NOT clear tokens — the API spec allows cancel-by-login
    // during the grace period. Clearing locally would block that.
    _currentUser = null;
  }

  /// Change the signed-in user's password. The server revokes every other
  /// session on success; this device's token stays valid so the user does
  /// NOT need to log in again. Throws [ApiException] on validation failure
  /// (wrong current password, weak new password, mismatched confirmation).
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.instance.post(
      ApiEndpoints.mePassword,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      },
    );
  }

  /// Request an OTP to verify a NEW email address before switching to it.
  /// The code is mailed to [newEmail] so receiving it proves ownership.
  /// Throws [ApiException] (422 VALIDATION_FAILED if the email is taken or
  /// malformed).
  static Future<void> requestEmailChangeOtp(String newEmail) async {
    await ApiClient.instance.post(
      ApiEndpoints.meEmailOtp,
      body: {'email': newEmail.trim()},
    );
  }

  /// Confirm the email-change code. On success the backend applies the change
  /// and returns the updated user, which we cache. Throws [ApiException]
  /// (422 OTP_INVALID) on a wrong/expired code.
  static Future<User> verifyEmailChangeOtp({
    required String newEmail,
    required String code,
  }) async {
    final data = await ApiClient.instance.post(
      ApiEndpoints.meEmailVerify,
      body: {'email': newEmail.trim(), 'code': code},
    ) as Map<String, dynamic>;
    final user = User.fromJson(data);
    _currentUser = user;
    return user;
  }

  /// Record all four baseline consents (privacy, terms, data_processing,
  /// ai_usage). Idempotent. Errors are swallowed — gated endpoints will
  /// surface their own 403 CONSENT_REQUIRED if anything is missing.
  static Future<void> ensureBaselineConsents() async {
    for (final scope in const ['privacy', 'terms', 'data_processing', 'ai_usage']) {
      try {
        await ApiClient.instance.post(
          ApiEndpoints.consent,
          body: {'scope': scope, 'version': '1.0'},
        );
      } catch (_) {
        // best-effort
      }
    }
  }

  // ---- internals ----

  static bool _googleInitialized = false;

  /// google_sign_in 7.x requires [GoogleSignIn.initialize] to be awaited
  /// exactly once before any other call. Client IDs come from native config
  /// files (google-services.json / Info.plist) at this scaffold stage, so we
  /// initialize with no explicit IDs; the user wires those in later.
  /// The Google **Web** OAuth client ID used as `serverClientId`, which makes
  /// the ID token's audience the web client on BOTH platforms — exactly what
  /// the backend verifies (`GOOGLE_CLIENT_ID`). Without it, iOS tokens carry
  /// the iOS-client audience and the backend rejects them.
  ///
  /// Defaults to the mishkat-api web client (not a secret — it also ships in
  /// google-services.json), so Google sign-in works out of the box. Override
  /// per build with `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` if needed.
  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '103240003911-vuff5d6jb1sp4bafj7r036m20cqpo3sm.apps.googleusercontent.com',
  );

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          _googleServerClientId.isEmpty ? null : _googleServerClientId,
    );
    _googleInitialized = true;
  }

  static Future<User> _persistSession(Map<String, dynamic> data) async {
    // A real session supersedes any guest browse mode.
    isGuest = false;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = User.fromJson(userJson);
    final tokensJson = (data['tokens'] ?? data) as Map<String, dynamic>;
    final tokens = AuthTokens.fromJson(tokensJson);
    await TokenStorage.instance.save(tokens);
    _currentUser = user;
    // Pull the user's server-persisted journal entries for this session.
    unawaited(JournalStore.instance.load());
    return user;
  }
}
