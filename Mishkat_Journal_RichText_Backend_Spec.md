# Mishkat — Journal Rich Text · Backend Spec (handoff)

Audience: mishkat-api (Laravel/PHP) backend team.
Goal: persist rich journal formatting without breaking existing plain-text notes.

## What the Flutter app now sends/expects

The Journal editor was upgraded to a real rich-text editor (flutter_quill). It now
stores formatting as **Quill Delta JSON**.

- **`body`** (existing column) — UNCHANGED. Still the plain-text version, extracted
  from the editor. Always present and human-readable. This is the fallback.
- **`body_delta`** (NEW, optional) — Quill Delta JSON (a JSON array of ops). The
  rich version of `body`. Null/absent for old notes.

## Required backend changes (small, additive)

1. **Add a nullable JSON column** `body_delta` to the `journal_entries` table.
   - Type: `json` / `jsonb` (or `text` holding JSON). **Nullable.** No backfill needed.
   - Old rows keep `body_delta = null` and still work (the app loads from `body`).

2. **Create endpoint** `POST /me/journal` — accept and persist `body_delta` if present.
3. **Update endpoint** `PATCH /me/journal/{id}` — accept and persist `body_delta` if present.
4. **Get endpoints** (`GET /me/journal`, single entry) — return `body_delta` (null when absent).

No migration beyond the nullable column. `body` remains the source of truth for
plain text (search, snippets, list cards).

## Payload shape

Request (create/update) — `body_delta` is optional:
```json
{
  "title": "صباح هادي",
  "body": "شربت قهوتي وأنا أسمع المطر.",
  "topic_id": "beauty",
  "mood": null,
  "body_delta": [
    { "insert": "شربت " },
    { "insert": "قهوتي", "attributes": { "bold": true } },
    { "insert": " وأنا أسمع المطر.\n" }
  ]
}
```

Response (get) should include `body_delta` (null for old notes):
```json
{ "id": "...", "title": "...", "body": "...", "body_delta": [ ... ] }
```

## Current limitation (until the above lands)

- The Flutter app **sends** `body_delta` already, but if the backend ignores it
  (doesn't store it), the rich formatting will **not persist** across reloads —
  reopening the note shows the plain `body` only. `body` is never lost.
- Rich formatting works **visually while editing**; persistence requires this
  backend change.
