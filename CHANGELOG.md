# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-11-09

First public release.

### Added

- REST API for wiki pages under `/api/v3/wiki_api`:
  - `GET /wiki_api/health` — deployment smoke check;
  - `GET /wiki_api/projects/{project_id}/wiki_pages` — paginated page list;
  - `POST /wiki_api/projects/{project_id}/wiki_pages` — create a page (optionally as a child);
  - `GET /wiki_api/projects/{project_id}/wiki_pages/{slug}` — read a page by slug;
  - `GET /wiki_api/wiki_pages/{id}` — read a page by ID;
  - `PATCH /wiki_api/wiki_pages/{id}` — update title/text/parent with optimistic locking (`lock_version`);
  - `DELETE /wiki_api/wiki_pages/{id}` — delete a page;
  - `GET /wiki_api/wiki_pages/{id}/journals` — page history;
  - `GET /wiki_api/wiki_pages/{id}/journals/diff` — HTML diff between versions;
  - `GET /wiki_api/wiki_pages/{id}/attachments` — page attachments with download URLs.
- Standard permission enforcement (`view_wiki_pages` / `edit_wiki_pages`).
- Documentation: README (EN/RU) and full API reference.

### Notes

- Developed and tested on OpenProject 17.6, verified compatible with 17.9.
- Docker installation requires a textual (not regenerated) `Gemfile.lock` update — see `docs/API.md`.
