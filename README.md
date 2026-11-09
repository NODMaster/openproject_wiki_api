# openproject_wiki_api

A plugin for [OpenProject](https://www.openproject.org/) that exposes wiki pages through a REST API under `/api/v3/wiki_api`.

It is built for integrations and AI agents that need programmatic access to project wikis: listing pages, reading content, creating child pages and updating pages — all through plain HTTPS + API tokens, with the same permission model as the web UI.

## Features

- List wiki pages of a project (paginated, ordered by title)
- Read a page by ID or by slug/permalink
- Create pages (optionally as a child of an existing page)
- Update title, content and parent; optimistic locking via `lock_version`
- Page history (journals) and HTML diff between versions
- List page attachments with download URLs
- Health endpoint for deployment checks

Everything respects the standard OpenProject permissions: `view_wiki_pages` for reads, `edit_wiki_pages` for writes. Users only see what they could see in the web UI.

## Requirements

- OpenProject 17.x (developed and tested on 17.6, compatible with 17.9)
- A project with the **Wiki** module enabled

## Installation

Standard OpenProject plugin installation.

1. Copy the plugin directory into `modules/`:

   ```bash
   cp -r openproject_wiki_api /app/modules/openproject_wiki_api
   ```

2. Register the gem in `Gemfile.modules`, inside the `group :opf_plugins do` block:

   ```ruby
   gem 'openproject_wiki_api', path: 'modules/openproject_wiki_api'
   ```

3. Install dependencies and restart:

   ```bash
   bundle install
   # restart the application (e.g. `docker compose restart web worker cron`)
   ```

4. Verify:

   ```bash
   curl -u apikey:<TOKEN> https://<host>/api/v3/wiki_api/health
   # => {"status":"ok","plugin":"openproject_wiki_api","version":"0.4.0"}
   ```

> **Docker note.** In the official `openproject/openproject` container there is no outbound access to rubygems.org. Do **not** delete or regenerate `Gemfile.lock` there — add the plugin's four lock entries textually (see [docs/API.md](docs/API.md#gemfilelock-in-docker) for details), otherwise `bundle install` will fail and the web container will end up in a restart loop.

## Usage

Authenticate with any OpenProject **API token** (user profile → Access tokens) using HTTP Basic auth with the literal username `apikey`:

```bash
curl -u apikey:<TOKEN> https://<host>/api/v3/wiki_api/projects/my-project/wiki_pages
```

Quick example — create a page:

```bash
curl -u apikey:<TOKEN> -X POST \
  -H "Content-Type: application/json" \
  -d '{"title":"Meeting notes","text":"# Notes\nHello","journal_notes":"created via API"}' \
  https://<host>/api/v3/wiki_api/projects/my-project/wiki_pages
```

See [docs/API.md](docs/API.md) for the full endpoint reference, payload formats and behaviour notes (CommonMark, slug derivation, journal aggregation, optimistic locking).

## Behaviour notes

- Page content is **CommonMark** markdown.
- The slug/permalink is derived from the title automatically.
- Rapid successive edits by the same user may be **aggregated** into one journal entry (OpenProject setting `journal aggregation time`, default 5 minutes). Pass distinct `journal_notes` and mind the interval if you rely on version history.
- Updates use optimistic locking: pass the current `lock_version`, a stale value returns `409`.

## 💖 Support the Project / Поддержать проект

If you find this plugin useful, please consider supporting its development. You can do it in a way that is most convenient for you:

### 🌍 International Support
- **Tribute (Credit cards, Apple/Google Pay):** [Support via Tribute](https://web.tribute.tg/d/Tzc)
- **USDT (TRC-20):** `TCapCF7MBhkCjjP6DoGvhLXP2ZM5sNV3S5`

### 🇷🇺 Для спонсоров из РФ и СНГ
- **DonationAlerts (Карты РФ, СБП, криптовалюта):** [donationalerts.com/r/nodmaster](https://www.donationalerts.com/r/nodmaster)
- **Tribute (Карты РФ, вывод в USDT):** [Поддержать через Tribute](https://web.tribute.tg/d/Tzc)

## License

GPLv3 — see [LICENSE](LICENSE).

## Authors

- NODMaster — https://github.com/NODMaster
- Kimi AI

Not affiliated with OpenProject GmbH.
