# Tech Stack Summary (MVP)

## Runtime & Framework

* **Elixir + Phoenix (LiveView)** for web UI, APIs, and background orchestration in one runtime.
* **No React** in MVP. LiveView handles leaderboards, admin, and “My Activities”.

## Data & Persistence

* **Postgres** as primary DB.

  * Use a managed Postgres (Supabase *DB only* or equivalent).
* **Ecto** for schemas, queries, and migrations.

## Background Jobs & Scheduling

* **Oban** for jobs (nightly sync, per-user sync, purge).
* **Oban Cron** or **Quantum** to schedule the nightly job at **00:05 Europe/Warsaw**.

## HTTP & Integrations

* **Tesla** (HTTP client) with **Finch** adapter and **Jason** (JSON) to call **Strava API**.
* Handle token refresh, pagination, and rate limits (`X-RateLimit-*`).

## Security & Secrets

* **Cloak Ecto** to encrypt Strava access/refresh tokens at rest (AES-GCM).
* Signed/encrypted Phoenix session cookies.
* Minimal scopes (e.g., `activity:read`).
* 90-day data purge job.

## Container & Deploy

* **Docker** image (single service).
* Host on any Elixir-friendly provider (Fly.io/Render/Gigalixir/VM).
* Environment via `runtime.exs` and env vars.

## Key Environment Variables

```
STRAVA_CLIENT_ID
STRAVA_CLIENT_SECRET
STRAVA_REDIRECT_URI
SECRET_KEY_BASE
DATABASE_URL
OBAN_DB_QUEUE_INTERVAL (optional)
```

## Minimal Data Model (Ecto)

* `users`: `display_name`, `strava_access_token (enc)`, `strava_refresh_token (enc)`, `strava_expires_at`, `joined_at`, `is_admin`
* `activities`: `strava_id (unique)`, `user_id`, `sport_type`, `start_at`, `distance_m`, `moving_time_s`, `elev_gain_m`, `trainer`, `commute`, `excluded`
* `teams`: `name`
* `team_memberships`: `team_id`, `user_id` (one team per user)

## Core Modules (suggested)

* `MyApp.Strava.OAuth` – exchange/refresh tokens.
* `MyApp.Strava.API` – fetch paginated activities, rate-limit aware.
* `MyApp.Ingest` – map & upsert activities, dedupe on `strava_id`.
* `MyApp.Workers.NightlySync` – enqueue per-user sync jobs.
* `MyApp.Workers.SyncUser` – fetch + persist user activities.
* `MyAppWeb` (LiveView) – public leaderboards, “My Activities”, admin panel.

## Non-Goals (MVP)

* No real-time streaming, no React SPA, no Supabase auth/edge functions.
* No complex analytics beyond leaderboards/milestones.

## Notes for Tools/Agents

* Prefer server-side renders with LiveView.
* All DB writes via Ecto changesets.
* Use Oban retries/backoff on 429/5xx; `{:snooze, seconds}` to respect limits.
* Store only necessary fields; never log tokens or PII.
