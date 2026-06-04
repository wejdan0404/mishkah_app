# Mood-driven "مناسب لك الآن" tag (Balance Station) + home section polish — Design

**Scope:** Flutter only. No backend change. Reuses `ActivityApi.recommended()`, the existing `_SuggestionBadge`, and `AppSectionCard`.

## Part A — محطة التوازن: mood-driven top-fit tag
Today the Balance Station shows `_SuggestionBadge` ("مناسب لك الآن") whenever an activity's hardcoded `suggested == true`. Make it mood-driven.

- On open, the screen fetches `ActivityApi.recommended()` — the backend's mood-scored, **ordered** picks (it scores against the user's latest `MoodEntry`). Best-effort: empty list on error → no tags. Store as `List<String> _recommendedOrder` and `setState` when it arrives.
- **Top fit per section** — at most one tag per section, on the highest-ranked recommended activity in that section:
  - تنفس (breathing): `breathe_calmly` is tagged iff it appears in `_recommendedOrder`. (It's the only breathing activity.)
  - يقظة ذهنية (mindfulness): among `{understand_feelings, activate_senses}`, tag only the one that appears **first** in `_recommendedOrder`. If neither appears, no tag.
- General rule used in code: build a `Set<String> _suggestedSlugs` = for each section, the single slug that is the earliest-occurring section member in `_recommendedOrder` (omitted if none). An activity card sets `suggested = _suggestedSlugs.contains(slug)`.
- The previously hardcoded `suggested: true` values are removed; `suggested` is computed from `_suggestedSlugs`. Until `recommended()` resolves (or if it errors/empties), no badge shows.

## Part B — الرئيسية "أنشطة تناسب مزاجك"
- Wrap `_MoodActivitiesSection` in a white `AppSectionCard` (same container as مهامك المتبقية / `_TasksCard`). The tinted `ActivitySuggestionCard`s sit inside the white card, mirroring how `_TaskRow`s sit inside `_TasksCard`.
- Cap the rendered list to **max 3** (`_moodActivityPicks` → `.take(3)`). **Min 1** is already enforced — the section only renders when there is ≥1 resolvable pick, otherwise the explore card shows.

## Edge cases
- `recommended()` is best-effort everywhere (`[]` on error). Balance Station → no tags; home → explore-card fallback.
- Balance Station currently does not load mood/recommendations; add the fetch in its `initState` alongside the existing `activeSlugs()` load.
- Slugs not resolvable in the registry are skipped (home section) / simply never match (balance station).

## Testing
`flutter analyze` + manual: record a mood whose top picks include a breathing/mindfulness activity → open محطة التوازن → the matching تنفس / يقظة ذهنية card shows "مناسب لك الآن"; a mood with no breathing/mindfulness fit → no tag. Home: section is a white card capped at 3 items; hidden (explore card shown) when there are 0 picks.
