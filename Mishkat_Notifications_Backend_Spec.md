# Mishkat — In-App Notifications · Backend Spec (handoff)

Audience: mishkat-api (Laravel/PHP) backend team.
Scope: real in-app notifications, generated server-side, consumed by the existing Flutter app.
Copy is **locked** — use the exact Arabic strings below. Do not rewrite, lengthen, shorten, or add emojis.

> Note: Flutter does NOT own this copy. The Flutter notifications screen displays
> backend `title`/`body` as received. This document is the source of truth for
> the backend team to implement the approved content + generation rules.

---

## 1) Data model — `notifications` table

| column | type | notes |
|---|---|---|
| id | uuid/string (PK) | |
| user_id | FK → users | |
| type | string (enum) | one of the 8 types below |
| title | string | exact locked copy |
| body | string | exact locked copy |
| icon_key | string | always `"bell"` for now |
| action_target | string (enum) | routing key (see §5) |
| action_payload | json, nullable | optional extra (e.g. `{ "activity_slug": "..." }`) |
| is_read | boolean, default false | |
| created_at | timestamp | newest-first ordering |
| scheduled_for | timestamp, nullable | only if scheduling is added later |
| metadata | json, nullable | optional |

Index suggestion: `(user_id, type, created_at)` for the per-day duplicate check and feed.

---

## 2) Locked notification content (exact)

| type | title | body | action_target |
|---|---|---|---|
| mood_check_in | سجّل مزاجك | دقيقة بسيطة تكفي تعرف حالتك. | mood_flow_or_home |
| activity_suggestion | نشاط مناسب الآن | اقتراح خفيف يساعدك تبدأ بهدوء. | activities |
| focus_reminder | وقت التركيز | جلسة قصيرة تساعدك تنظّم أفكارك. | focus |
| streak_reminder | استمر بهدوء | خطوة صغيرة تحفظ تواصلك اليوم. | progress_or_home |
| journal_reminder | اكتب لحظة | سطر بسيط يخفف زحمة الشعور. | journal |
| breathing_reminder | خذ نفس | تنفّس قصير يساعدك تهدأ. | breathing |
| task_reminder | مهمة بسيطة | اختَر مهمة واحدة وابدأ بخطوة. | focus |
| general | خذ لحظة | ابدأ بشيء بسيط يناسب وقتك. | home |

`icon_key` = `"bell"` for all. Tone: neutral white-dialect Arabic, no gendered directed verbs, no fear/guilt/pressure, no clinical claims.

---

## 3) Generation rules (per user, evaluated for "today")

- **mood_check_in** — create if NO mood record exists for today.
- **activity_suggestion** — create if today's mood exists AND no activity was started today.
- **focus_reminder** — create if the user has focus tasks AND no focus session started today.
- **streak_reminder** — create only if streak logic exists AND today still needs an action. Use the gentle copy only — **never** say the streak is lost / "راح يضيع" / "لا تخسر" / "لا تنسى وإلا".
- **journal_reminder** — create if today's mood is one of `sad` (حزين), `tense` (متوتر), `upset` (منزعج), `bored` (ملول) AND no journal entry today.
- **breathing_reminder** — create if today's mood is `tense` (متوتر) or `upset` (منزعج) AND no breathing exercise completed today.
- **task_reminder** — create if the user has incomplete tasks today.
- **general** — fallback only, when none of the above can be generated.

**Do not** generate all types at once for the same user. Use real user context.

### Priority (when generating on demand, pick the highest applicable)
1. mood_check_in
2. breathing_reminder
3. journal_reminder
4. focus_reminder
5. task_reminder
6. activity_suggestion
7. streak_reminder
8. general

### Duplicate prevention
Before creating, check the user does NOT already have a notification of the **same `type` on the same calendar day**. Skip if one exists.

Additionally, the backend MUST prevent duplicate creation by **fingerprint** — never create two notifications with the same `(user_id, type, title, body)` within a short window, even if other fields (id, timestamp) differ. A generator that fires twice must not produce two rows. (Flutter also de-dups on render: exact `id`, then `category | normalized title | normalized body | 2-minute timestamp bucket` — but this is only a display safety net; same-content notifications spaced more than ~2 minutes apart are intentionally NOT collapsed by the app to avoid hiding real events, so the backend must not create them.)

---

## 4) Endpoints

The Flutter app already calls these — keep the response shapes below.

- `GET /me/notifications?limit=30[&unread_only=true]` → `{ "unread_count": N, "items": [ ... ] }`, newest first.
- `POST /me/notifications/{id}/read` → mark one as read. `204`.
- (optional) `POST /me/notifications/read-all`.
- (already used) `DELETE /me/notifications/{id}` → delete one. `204`.

---

## 5) action_target → Flutter destination

| action_target | destination |
|---|---|
| mood_flow_or_home | mood flow if a safe route exists, else Home |
| activities | Activities tab |
| focus | Focus tab |
| progress_or_home | Progress/Journey tab if available, else Home |
| journal | Journaling screen |
| breathing | Breathing list / Balance Station (NOT a session directly) |
| home | Home |

---

## 6) Item JSON shape

```json
{
  "id": "uuid",
  "type": "mood_check_in",
  "title": "سجّل مزاجك",
  "body": "دقيقة بسيطة تكفي تعرف حالتك.",
  "icon_key": "bell",
  "action_target": "mood_flow_or_home",
  "action_payload": null,
  "is_read": false,
  "created_at": "2026-06-04T09:41:00Z",
  "scheduled_for": null
}
```

> Schema note: the CURRENT Flutter model parses `read` (not `is_read`),
> `sent_at`/`scheduled_for` (timestamp), and `data_payload.deep_link` (routing).
> If you adopt the new field names above (`is_read`, `created_at`, `type`,
> `icon_key`, `action_target`, `action_payload`), the Flutter model + tap-routing
> need a small update on the app side — expected, done once your schema is final.

---

## 7) Out of scope (do not change)
Auth, mood recommendation logic, breathing logic, games, focus logic. No push/FCM unless that infra already exists — this is in-app notifications only.

---

## 8) Flutter side — already done / pending
- Done (Flutter): unified relative time → "منذ …" everywhere; unified yellow/gold bell icon (no per-type colors); real backend feed stays connected; mark-as-read on entry; **id-dedup on render** (same id never shown twice); empty/error/loading states; title/body overflow ellipsis.
- IMPORTANT: the design mockup (Figma) still shows the OLD style ("قبل …" + per-type colored bells + old copy). The **implemented Flutter code does not** — it already renders "منذ …" + one gold bell. The duplicate "وسام جديد" seen in testing is two distinct backend rows (different ids/times) → fix in backend generation (§3 duplicate prevention), not Flutter.
- Pending (Flutter, after schema is final): parse `type`/`icon_key`/`action_target`/`action_payload`/`is_read`/`created_at`; tap → navigate by `action_target` (currently tapping only marks read, it does not navigate).
