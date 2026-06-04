# Mood-based activities on الرئيسية — Design

**Goal:** When the user picks a mood on the home screen, show an inline section of activities suited to that mood, and hide the generic "استكشف الأنشطة" explore card while a mood is recorded.

**Scope:** Flutter only. No backend change.

## Why no backend change
`GET /api/v1/activities/recommended` already returns the top‑3 activities scored against the user's **latest `MoodEntry`** (+3 when the activity's `mood_targets` contains that mood). Picking a mood on home calls `MoodService.checkIn(slug)` first, so the "latest mood" is the chosen one by the time we fetch. We reuse the existing `ActivityApi.recommended()` (returns a `List<String>` of slugs, filtered to `ActivitySlugs.all`).

## Components (all in `lib/screens/home/home_screen.dart`)
- **`_MoodActivitiesCard`** (new): heading **"أنشطة تناسب مزاجك"** + a vertical list of `ActivitySuggestionCard`s, one per recommended slug. Each card resolves via `resolveActivitySuggestion(slug)` (color + label) and on tap calls `resolveActivitySuggestion(slug)?.open(context)` — same behaviour as today's `_RecommendationsSheet`. Slugs that don't resolve are skipped.
- Reused: `ActivityApi.recommended()`, `ActivitySuggestionCard`, `resolveActivitySuggestion`, `_ActivitiesCard` (explore card, conditionally shown).

## State & data flow (`_HomeScreenState`)
- New field: `List<String>? _moodActivitySlugs` — `null` = not loaded yet.
- New method `_loadMoodActivities()`: `final slugs = await ActivityApi.recommended();` → `setState(() => _moodActivitySlugs = slugs);` (guarded by `mounted`).
- Triggers:
  - At the end of `_onSelectMood` (after a successful `checkIn`), call `_loadMoodActivities()`.
  - At the end of `_hydrateTodayMood`, when it sets `_selectedMood` from today's recorded mood, call `_loadMoodActivities()` — so reopening the app still shows the picks.

## Conditional rendering (build tree, under the mood card, above tasks)
Let `hasPicks = _selectedMood != null && _moodActivitySlugs != null && resolvable(_moodActivitySlugs).isNotEmpty`.
- **`hasPicks`** → render `_MoodActivitiesCard(slugs: resolvable picks)`; **do not** render the `_ActivitiesCard` explore card.
- **otherwise** (no mood yet, still loading, or empty/error) → render the existing `_ActivitiesCard` explore card (current behaviour). This guarantees no empty/dead state.

`resolvable(...)` = slugs for which `resolveActivitySuggestion(slug) != null`.

## Edge cases
- `recommended()` is best-effort (returns `[]` on error) → falls back to the explore card.
- Mood check-in is once/day; `_selectedMood` is also hydrated on app open, so the section persists across launches for the day.
- No loading spinner: until `_moodActivitySlugs` loads, the explore card stays (no flicker to an empty section).

## Testing
Flutter has no widget-test harness in this repo; verification is `flutter analyze` + manual: pick a mood → section appears with picks → tap opens the activity; reopen app same day → section still shows; explore card hidden while mood recorded, shown before.
