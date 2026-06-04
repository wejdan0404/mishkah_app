# Mishkat Backend Integration — Smoke Test Checklist

After the integration commits land, run these checks against a reachable backend
(staging or local). The default base URL is `https://api.mishkat.us`. To point
at a local API:

```bash
flutter run --dart-define=MISHKAT_API_BASE_URL=http://localhost:8080
```

The app should already pass `flutter analyze` and `flutter test` (11 unit tests).
The Android debug APK has been verified to build (`flutter build apk --debug`).

## 1. Cold launch — no session

- Splash animation plays (~3.8s + 700ms hold).
- App lands on `/onboarding` (no tokens stored yet).
- No exceptions in `flutter logs`.

## 2. Sign-up flow

- Tap "إنشاء حساب" → sign-up screen.
- Enter:
  - Name: `اختبار`
  - Email: `qa+<timestamp>@mishkat.local`
  - Password: `password1234`
  - Confirm password: `password1234`
- Tap "إنشاء حساب".
- Expected: SuccessScreen with "تـم إنشـاء حسابـك بنجـاح" → tap "ابدأ الآن" → `/home`.
- Backend check: user row created; four `user_consents` rows recorded
  (`privacy`, `terms`, `data_processing`, `ai_usage`).
- Error case: try registering with the same email twice → expect inline
  error "البريد الإلكتروني مستخدم." under the email field.

## 3. Sign-in flow

- From `/onboarding`, tap "تسجيل الدخول" or restart with stored tokens cleared.
- Enter the email + password used in Step 2.
- Expected: SuccessScreen "تـم تسجيل دخولك بنجـاح".
- Error case: wrong password → expect "البريد الإلكتروني أو كلمة المرور غير صحيحة"
  under the password field.

## 4. Edit profile

- From `/home`, navigate to "تعديل الملف الشخصي" (edit profile).
- Expected: a brief loading spinner, then name + email fields pre-fill from
  the backend.
- Change the name to "اختبار محدّث" and tap "حفظ التعديلات".
- Confirm in the dialog.
- Expected: dialog dismisses, screen pops. Backend check: name updated.
- Try changing the email → expect "لا يمكن تغيير البريد الإلكتروني من هنا حالياً."

## 5. Delete account

- From edit profile, tap "حذف الحساب" and confirm.
- Expected: navigate to `/signin`. Backend check: `deletion_requested_at`
  set on user, 7-day grace.
- Try logging back in within the grace window → expect 403 with code
  `ACCOUNT_PENDING_DELETE` and the Arabic message about cancelling deletion
  to be shown under the password field.

## 6. Smart companion streaming

- Sign in with a fresh account or one that still has consents.
- Open "اسأل مِشْكَاة" (chat screen).
- Tap a quick-reply chip (e.g. "أحس بتوتر").
- Expected:
  - Brief typing indicator.
  - Bot bubble starts appearing token-by-token as deltas stream in.
  - Conversation continues in the same thread for follow-up messages.
- Backend check: a row in `ai_threads` + alternating user/assistant rows in
  `ai_messages`. The assistant row has `provider` and `model` populated.

## 7. Session persistence (cold relaunch)

- Force-quit the app.
- Reopen.
- Expected: splash → `/home` directly. No login prompt.

## 8. Token-refresh recovery

- In the backend, manually invalidate the user's access token (e.g., delete
  the Sanctum token row, or wait for expiry if dev expiry is short).
- Hit any authenticated screen (e.g. open chat or edit profile).
- Expected: silent refresh — the user does not see a logout. The next API
  call succeeds with a freshly-issued access token. Confirm in the backend
  audit log that a `POST /auth/refresh` was made.
- If **both** tokens are revoked: the splash route falls back to `/signin`
  on next cold launch.

## 9. Consent gate

- (Advanced) On the backend, delete one consent row (e.g. `ai_usage`) for
  the current user.
- Send a chat message.
- Expected: a snackbar "فضلًا أكمل الموافقات في الإعدادات لتفعيل المرافق."
- The next `AuthService.ensureBaselineConsents()` (e.g. on next login) will
  silently re-post the missing scope.

## What I did NOT change

- Voice transcription still uses Supabase (`transcribe_audio_service.dart`
  and `supabase_config.dart` remain). This was out of scope.
- The current/new password fields in edit profile stay client-side only —
  there is no documented endpoint to change passwords from within an
  authenticated session. The "forgot password" flow (`POST /auth/forgot-password`
  + `POST /auth/reset-password`) is unchanged from the current stub.
- The Google sign-in button is still a stub (`_onGoogle` prints debug only).
  `POST /auth/google` is available; wiring it in is a separate task.
- No new fields added to the sign-up form — `birth_year`, `education_stage`,
  `region`, and `locale` are sent as defaults (`2010`, `middle_1`,
  `Riyadh`, `ar`). The user can update name/region/locale via edit profile
  later; birth-year/education-stage are not editable from any current screen.

## 10. حسابي page

- Open the bottom-nav profile tab.
- Expected: header shows the signed-in user's actual name (no longer "مرام بارفعة").
- Tap the header card → goes to edit profile (already covered in §4); on
  return the name updates if it was changed.
- Toggle "الإشعارات" ON → confirmation dialog → confirm → toggle stays on.
  Verify in backend: `notification_preferences.push_enabled = true` for this user.
- Toggle "الإشعارات" OFF → no dialog, instant PATCH. Verify `push_enabled = false`.
- If the PATCH fails, the toggle rolls back to its previous state and a snackbar
  "تعذّر تحديث إعدادات الإشعارات." appears.
- Tap "تسجيـل الخـروج" → confirm → app navigates to `/signin`. Verify the
  Sanctum token was revoked server-side (`personal_access_tokens` row deleted).

## 11. Notifications screen

- From حسابي's bell (or the home `/notifications` link), open الإشعارات.
- Expected: a brief loading spinner, then the real notifications list from
  `/api/v1/notifications/feed`.
- If the backend feed is empty: the empty-state message "لا توجد إشعارات حالياً."
  shows.
- Tap an unread item → title weight unchanged (we don't currently style by
  read-state) but the row is marked read on the server. Verify
  `notification_user.read_at` was set.
- If the auth probe fails: the screen shows "انتهت الجلسة. سجّل الدخول من جديد."
- If the network fails: the screen shows "تعذّر الاتصال بالخادم. تحقق من الشبكة."

## Out of scope — static screens that intentionally stay static

These five screens have **no documented backend endpoints** in the Postman
collection, so they remain client-side static:

- `lib/screens/faq/faq_screen.dart` — 4 hard-coded Q&A pairs.
- `lib/screens/about/about_mishkat_screen.dart` — 5 hard-coded info cards.
- `lib/screens/terms/terms_screen.dart` — 8 hard-coded sections.
- `lib/screens/privacy/privacy_screen.dart` — 7 hard-coded sections.
- `lib/screens/report_problem/report_problem_screen.dart` — form is stubbed
  because no `POST /report-problem` endpoint exists.

If the backend later adds `GET /api/v1/content/{slug}` or similar, those
screens can be wired in a follow-up plan.
