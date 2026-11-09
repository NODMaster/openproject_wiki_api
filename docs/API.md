# openproject_wiki_api — API Reference

Base URL: `/api/v3/wiki_api`

All endpoints require authentication (HTTP Basic, username `apikey`, password = personal API token) and the standard wiki permissions of the project: `view_wiki_pages` for read operations, `edit_wiki_pages` for create/update/delete.

`project_id` accepts either the numeric project ID or the project identifier.

Errors follow API v3 conventions: `401` unauthenticated, `403` insufficient permission, `404` unknown page/project, `409` stale `lock_version`, `422` validation error.

---

## Endpoints

### GET `/wiki_api/health`

Deployment smoke check.

**Response 200:**

```json
{"status": "ok", "plugin": "openproject_wiki_api", "version": "0.4.0"}
```

### GET `/wiki_api/projects/{project_id}/wiki_pages`

List pages of the project's wiki (ordered by title).

Query parameters: `offset` (1-based page number, default 1), `pageSize` (default 25; `-1` = configured maximum).

**Response 200:**

```json
{
  "_type": "Collection",
  "total": 2,
  "count": 2,
  "pageSize": 25,
  "offset": 1,
  "_embedded": {
    "wikiPages": [
      {
        "id": 15,
        "title": "Это тестовая вики",
        "slug": "это-тестовая-вики",
        "parent": null,
        "version": 1,
        "createdAt": "2026-11-09T10:00:00.000Z",
        "updatedAt": "2026-11-09T10:00:00.000Z"
      }
    ]
  }
}
```

### POST `/wiki_api/projects/{project_id}/wiki_pages`

Create a page in the project wiki.

Body (JSON):

| Field         | Type    | Required | Description                                        |
|---------------|---------|----------|----------------------------------------------------|
| `title`       | string  | yes      | Page title; the slug/permalink is derived from it  |
| `text`        | string  | no       | Page content (CommonMark markdown)                 |
| `parent_id`   | integer | no       | ID of the parent wiki page                         |
| `journal_notes` | string | no      | Notes stored on the initial journal entry          |

**Response 201:** page detail (see below).
**422** if the project has no wiki module or the title is invalid.

```bash
curl -u apikey:<TOKEN> -X POST -H "Content-Type: application/json" \
  -d '{"title":"Ответ ассистента","text":"Содержимое","parent_id":15,"journal_notes":"created by agent"}' \
  https://<host>/api/v3/wiki_api/projects/34/wiki_pages
```

### GET `/wiki_api/projects/{project_id}/wiki_pages/{slug}`

Read a single page by slug/permalink. **Response 200:** page detail.

```bash
curl -u apikey:<TOKEN> https://<host>/api/v3/wiki_api/projects/34/wiki_pages/это-тестовая-вики
```

### GET `/wiki_api/wiki_pages/{id}`

Read a single page by ID. **Response 200:** page detail.

**Page detail object:**

```json
{
  "id": 15,
  "title": "Это тестовая вики",
  "slug": "это-тестовая-вики",
  "parent": {"id": 14, "title": "Parent page"},
  "version": 3,
  "createdAt": "2026-11-09T10:00:00.000Z",
  "updatedAt": "2026-11-09T12:30:00.000Z",
  "project": {"id": 34, "identifier": "ai-agents", "name": "Создать ИИ агентов"},
  "text": "# Заголовок\n\nСодержимое страницы…",
  "format": "common_mark"
}
```

### PATCH `/wiki_api/wiki_pages/{id}`

Update a page. Only provided fields are changed; changing `text` creates a new journal version.

Body (JSON):

| Field           | Type    | Description                                                        |
|-----------------|---------|--------------------------------------------------------------------|
| `title`         | string  | New title (slug is re-derived)                                     |
| `text`          | string  | New content (CommonMark)                                           |
| `parent_id`     | integer | New parent page ID (detaching is not supported via API)            |
| `journal_notes` | string  | Notes stored on the new journal entry                              |
| `lock_version`  | integer | Current lock version — a stale value results in `409`              |

**Response 200:** updated page detail.

```bash
curl -u apikey:<TOKEN> -X PATCH -H "Content-Type: application/json" \
  -d '{"text":"Обновлённое содержимое","lock_version":3,"journal_notes":"update via API"}' \
  https://<host>/api/v3/wiki_api/wiki_pages/15
```

### DELETE `/wiki_api/wiki_pages/{id}`

Delete a page. **Response 204.**

### GET `/wiki_api/wiki_pages/{id}/journals`

Page history, ordered by version.

```json
[
  {
    "id": 91,
    "version": 1,
    "createdAt": "2026-11-09T10:00:00.000Z",
    "author": {"id": 11, "login": "kimi_AI", "name": "KIMI ИИ ассистент"},
    "notes": "created by agent",
    "text": "Первая версия…"
  }
]
```

### GET `/wiki_api/wiki_pages/{id}/journals/diff?from=&to=`

Diff between two versions. `to` defaults to the latest version, `from` defaults to `to - 1`. **404** if a version does not exist.

```json
{
  "from": 1,
  "to": 2,
  "diff": "<span class=\"diff_in\">…HTML diff…</span>",
  "textFrom": "Первая версия…",
  "textTo": "Вторая версия…"
}
```

### GET `/wiki_api/wiki_pages/{id}/attachments`

List page attachments.

```json
[
  {
    "id": 7,
    "filename": "diagram.png",
    "filesize": 12345,
    "contentType": "image/png",
    "author": {"id": 11, "login": "kimi_AI", "name": "KIMI ИИ ассистент"},
    "createdAt": "2026-11-09T11:00:00.000Z",
    "downloadUrl": "/api/v3/attachments/7/content"
  }
]
```

---

## Behaviour notes

### Content format

Page text is stored and returned as **CommonMark** markdown (constant `common_mark`). The `format` field is informational.

### Slug derivation

The slug (permalink) is derived from the title by OpenProject's `WikiPage` logic — spaces become dashes, Cyrillic is preserved (e.g. `Это тестовая вики` → `это-тестовая-вики`). Use the slug route for human-readable references, the ID route for robust automation.

### Journal aggregation

OpenProject merges consecutive journal entries by the same user made within the *journal aggregation time* (administration setting, default **5 minutes**). Rapid successive PATCHes may therefore end up in a single version. For agents: either pace edits beyond the aggregation window or treat the journal list as the source of truth instead of assuming one version per request.

### Optimistic locking

`PATCH` accepts the current `lock_version` (returned in every page detail as `version`). Send the value you last read; if the page changed in between you get `409` and can re-read and retry.

### Gemfile.lock in Docker

The official `openproject/openproject` containers have **no network access to rubygems.org**, and `bundle install` fails if `Gemfile.lock` is missing or inconsistent — which puts the web container into a restart loop (and an autoheal sidecar will amplify it).

When installing the plugin in Docker, do not regenerate the lockfile. Instead take the original `Gemfile.lock` from the image and add four entries textually:

1. `PATH` section — copy the `openproject-openid_connect` block and rename it to `openproject_wiki_api` (the copy includes its `specs:` line with `openproject-auth_plugins` as the first dependency).
2. `GEM → specs` — add the line `openproject_wiki_api (0.4.0)` after the `openproject-webhooks (…)` entry.
3. `DEPENDENCIES` — add `openproject_wiki_api!` after `openproject-webhooks!`.

Then copy the lockfile into `web`, `worker` and `cron` containers, `chown app:app`, run `bundle check` and restart.
