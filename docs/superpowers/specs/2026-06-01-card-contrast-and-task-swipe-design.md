# Mood-activity card contrast + Focus task swipe (delete/rename) — Design

**Scope:** Flutter only. No backend change (task DELETE + PATCH already exist).

## Part 1 — ActivitySuggestionCard text contrast
The card paints the title + "افتح النشاط" subtitle in the activity's light accent
(`color`, e.g. `AppInformationColors.shade300/400`) on a light tint → low contrast.

- Add `final Color textColor` to `ActivitySuggestion` and a `textColor` param to
  `ActivitySuggestionCard`. The card uses `textColor` for the title + subtitle; the
  tint background, border, and play button keep `color` (on-theme).
- Registry `textColor` = a darker token shade of each accent's palette:
  - info accent → `AppInformationColors.shade600`
  - warning accent → `AppWarningColors.shade600`
  - danger accent → `AppDangerColors.shade600`
  - purple accent (sleepCalm) → `AppPalettePurple.shade200` (already the darkest purple token)
- No custom colors; improves readability wherever the card renders (home
  "أنشطة تناسب مزاجك", the explore sheet, the smart-companion suggestion).

## Part 2 — Focus task swipe (delete / rename)
Backend ready: `DELETE /api/v1/tasks/{id}` and `PATCH /api/v1/tasks/{id}` (accepts `title`).

Client additions:
- `TaskService.update(String id, String title)` → `PATCH /tasks/{id}` with `{title}`; returns bool (best-effort).
- `TaskStore.rename(String id, String label)` → optimistic in-memory label update + `_persist()` + `TaskService.update` (matches the existing add/remove optimistic+sync pattern).

Focus screen (`focus_screen.dart`), wrap each task row (`_TaskBulletRow`) in a `Dismissible`
mirroring the journal screen's two-direction RTL pattern:
- **`startToEnd` (RTL: swipe right→left) → delete:** red background + trash icon; `confirmDismiss` removes the task (`TaskStore.remove`) and returns `true`.
- **`endToStart` (RTL: swipe left→right) → edit name:** purple background + edit icon; `confirmDismiss` opens the existing add-task bottom sheet **pre-filled** with the current label, renames on submit (`TaskStore.rename`), and returns `false` (row stays).
- Reuse `_AddTaskSheet` for the rename input by giving it an optional `initialValue` + heading; opening it from the row's swipe.

## Edge cases
- Delete/rename are optimistic; the underlying TaskService calls are best-effort (a later load reconciles).
- Empty rename (blank/whitespace) is ignored (sheet returns null/empty → no-op).
- Both home `_TasksCard` and Focus read the same `TaskStore`; swipe lives only on the Focus list per the request, but `rename`/`remove` update the shared store so the home list stays consistent.

## Testing
`flutter analyze` + manual: swipe a Focus task right→left → it deletes; swipe left→right → the pre-filled sheet opens, edit + submit → the row shows the new name (and the home list reflects it). Mood-activity cards show darker, readable text.
