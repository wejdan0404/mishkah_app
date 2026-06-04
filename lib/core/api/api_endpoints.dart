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
  static const String googleAuth = '$apiV1/auth/google';
  static const String refresh = '$apiV1/auth/refresh';
  static const String logout = '$apiV1/auth/logout';
  static const String authMe = '$apiV1/auth/me';

  // Forgot password — email OTP. Request a 4-digit code, verify it for a
  // single-use reset token, then set the new password with that token.
  static const String forgotPassword = '$apiV1/auth/forgot-password';
  static const String verifyResetOtp = '$apiV1/auth/verify-otp';
  static const String resetPassword = '$apiV1/auth/reset-password';

  // Me
  static const String me = '$apiV1/me';
  static const String consent = '$apiV1/me/consent';
  static const String mePassword = '$apiV1/me/password';
  static const String meDeviceToken = '$apiV1/me/device-token';

  // Email change — OTP mailed to the NEW address; verify applies the change.
  static const String meEmailOtp = '$apiV1/me/email/otp';
  static const String meEmailVerify = '$apiV1/me/email/verify';

  // مساحة التدوين — server-persisted journal entries (CRUD).
  static const String journal = '$apiV1/me/journal';
  static String journalEntry(String id) => '$apiV1/me/journal/$id';

  // Notifications
  static const String notificationsFeed = '$apiV1/notifications/feed';
  static const String notificationsReadAll = '$apiV1/notifications/read-all';
  static String notificationRead(String id) =>
      '$apiV1/notifications/$id/read';
  static String notificationDelete(String id) => '$apiV1/notifications/$id';
  static const String notificationPreferences =
      '$apiV1/notifications/preferences';

  // AI
  static const String aiThreads = '$apiV1/ai/threads';
  static String aiThread(String id) => '$apiV1/ai/threads/$id';
  static String aiMessages(String threadId) =>
      '$apiV1/ai/threads/$threadId/messages';

  // Voice companion speech-to-text — multipart audio in, {transcript} out.
  static const String aiTranscribe = '$apiV1/ai/transcribe';

  // Mood catalogue + check-in. The catalogue is fetched once after sign-in
  // and cached locally; check-in posts a slug + optional note + source.
  static const String moods = '$apiV1/moods';
  static const String moodCheckIn = '$apiV1/mood/check-in';
  static const String moodToday = '$apiV1/mood/today';

  // /mood/calendar?month=YYYY-MM — daily dominant-mood aggregates for any month
  // (the journey snapshot only carries the current month). Powers the رحلتي
  // الشهر calendar so browsing past months shows their moods.
  static const String moodCalendar = '$apiV1/mood/calendar';

  // /me/journey powers the رحلتي screen — stats, weekly trend, monthly
  // grid, and highlights all in one envelope.
  static const String meJourney = '$apiV1/me/journey';

  // /focus/today powers the daily progress card on the التركيز screen —
  // {completed_today, daily_goal}.
  static const String focusToday = '$apiV1/focus/today';

  // /focus/presets — admin-managed quick-start session catalogue.
  static const String focusPresets = '$apiV1/focus/presets';

  // /focus/today/finish — toggle the "أنهيت اليوم" marker for the
  // current local date.
  static const String focusTodayFinish = '$apiV1/focus/today/finish';

  // /focus/sessions/* — backend lifecycle for the focus timer.
  static const String focusSessionsStart = '$apiV1/focus/sessions/start';
  static String focusSessionComplete(String id) =>
      '$apiV1/focus/sessions/$id/complete';
  static String focusSessionAbandon(String id) =>
      '$apiV1/focus/sessions/$id/abandon';

  // /tasks — server-backed task list (already exposed by the backend;
  // Flutter starts using it in this phase).
  static const String tasks = '$apiV1/tasks';
  static String task(String id) => '$apiV1/tasks/$id';
  static String taskComplete(String id) => '$apiV1/tasks/$id/complete';

  // Activities — bespoke local screens record completions against fixed
  // backend slugs (start/complete/abandon). GET /activities is used to hide
  // cards an admin has deactivated.
  static const String activities = '$apiV1/activities';
  // /activities/recommended — mood-scored top picks for the signed-in user.
  static const String activitiesRecommended = '$apiV1/activities/recommended';
  static String activityStart(String slug) => '$apiV1/activities/$slug/start';
  static String activityComplete(String slug) =>
      '$apiV1/activities/$slug/complete';
  static String activityAbandon(String slug) =>
      '$apiV1/activities/$slug/abandon';

  // /activities/daily-suggestion — random active "مقترح اليوم" picked
  // per request by the backend; safe to call best-effort (returns a
  // default Arabic line if no active rows exist).
  static const String activitiesDailySuggestion =
      '$apiV1/activities/daily-suggestion';
}
