1. List of tables with their columns, data types, and constraints

- Users (`users`)
  - `id` uuid PRIMARY KEY DEFAULT gen_random_uuid()
  - `display_name` text NOT NULL UNIQUE CHECK (char_length(display_name) BETWEEN 1 AND 80)
  - `strava_athlete_id` bigint UNIQUE
  - `joined_at` timestamptz
  - `counting_started_at` timestamptz
  - `last_synced_at` timestamptz
  - `last_sync_error` text
  - `is_admin` boolean NOT NULL DEFAULT false
  - `team_id` uuid REFERENCES teams(id)
  - `inserted_at` timestamptz NOT NULL
  - `updated_at` timestamptz NOT NULL

- Teams (`teams`)
  - `id` uuid PRIMARY KEY DEFAULT gen_random_uuid()
  - `name` text NOT NULL UNIQUE CHECK (char_length(name) BETWEEN 1 AND 80)
  - `owner_user_id` uuid REFERENCES users(id)
  - `inserted_at` timestamptz NOT NULL
  - `updated_at` timestamptz NOT NULL

- Activities (`activities`)
  - `id` uuid PRIMARY KEY DEFAULT gen_random_uuid()
  - `user_id` uuid NOT NULL REFERENCES users(id)
  - `strava_id` bigint NOT NULL UNIQUE
  - `sport_type` text NOT NULL CHECK (sport_type IN ('Run','TrailRun','Ride','GravelRide','MountainBikeRide'))
  - `sport_category` text GENERATED ALWAYS AS (
      CASE
        WHEN sport_type IN ('Run','TrailRun') THEN 'run'
        WHEN sport_type IN ('Ride','GravelRide','MountainBikeRide') THEN 'ride'
        ELSE NULL
      END
    ) STORED
  - `start_at` timestamptz NOT NULL
  - `distance_m` integer NOT NULL CHECK (distance_m >= 0)
  - `moving_time_s` integer NOT NULL CHECK (moving_time_s >= 0)
  - `elev_gain_m` integer NOT NULL CHECK (elev_gain_m >= 0)
  - `excluded` boolean NOT NULL DEFAULT false
  - `inserted_at` timestamptz NOT NULL
  - `updated_at` timestamptz NOT NULL

- User Credentials (`user_credentials`)
  - `user_id` uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE
  - `access_token_enc` bytea NOT NULL
  - `refresh_token_enc` bytea NOT NULL
  - `expires_at` timestamptz NOT NULL
  - `inserted_at` timestamptz NOT NULL
  - `updated_at` timestamptz NOT NULL

- Sync Runs (`sync_runs`)
  - `id` uuid PRIMARY KEY DEFAULT gen_random_uuid()
  - `started_at` timestamptz NOT NULL DEFAULT now()
  - `finished_at` timestamptz
  - `status` text NOT NULL CHECK (status IN ('running','success','error','cancelled'))
  - `stats` jsonb NOT NULL DEFAULT '{}'
  - `inserted_at` timestamptz NOT NULL
  - `updated_at` timestamptz NOT NULL


2. Relationships between tables

- `users.team_id` → `teams.id` (many users to one team). Team membership is single-valued via this FK (no join table in MVP).
- `teams.owner_user_id` → `users.id` (optional one-to-one/one-to-many; a user can own at most one team by app logic, not enforced at DB).
- `activities.user_id` → `users.id` (many activities to one user).
- `user_credentials.user_id` → `users.id` (one-to-one; PK equals FK, cascade on delete).
- `sync_runs` is standalone; referenced only by app logic for reporting.

Cardinality summary:
- Users ↔ Teams: many-to-one via `users.team_id`.
- Users ↔ Activities: one-to-many.
- Users ↔ UserCredentials: one-to-one.


3. Indexes

- Users
  - UNIQUE (`display_name`)
  - UNIQUE (`strava_athlete_id`)
  - INDEX (`team_id`)

- Teams
  - UNIQUE (`name`)
  - Optional: INDEX (`owner_user_id`)

- Activities
  - UNIQUE (`strava_id`)
  - INDEX (`user_id`, `start_at`)
  - INDEX (`user_id`, `sport_category`, `start_at`) WHERE `excluded` = false

- Sync Runs
  - INDEX (`started_at`)


4. PostgreSQL policies (if applicable)

- Row-Level Security (RLS): Not enabled in MVP. Authorization is enforced in the application layer per requirements.
- If enabled in the future:
  - `users`: Allow a user to select/update only their own row (by session user id), admins bypass.
  - `activities`: Allow select/update where `user_id = current_user_id()`, admins bypass.
  - `user_credentials`: Restrict strictly to owner and trusted server roles only; typically no direct app-level selects.


5. Any additional notes or explanations about design decisions

- UUIDs: Use `gen_random_uuid()` (requires `pgcrypto` extension). Enable with `CREATE EXTENSION IF NOT EXISTS pgcrypto;` in an initial migration.
- Timestamps: Store all as `timestamptz` in UTC. Application handles Europe/Warsaw display and challenge-window logic.
- Names: `display_name` and `teams.name` enforce length 1–80 and are case-sensitive by default (ensure DB collation is case-sensitive).
- Sport types: `sport_type` is constrained to included outdoor types only: 'Run','TrailRun','Ride','GravelRide','MountainBikeRide'. Unknown/disallowed types are filtered at ingestion and not stored.
- `sport_category` generated column simplifies leaderboard filtering ('run' vs 'ride').
- Team deletion: Per MVP, deletion is handled in application code by first nullifying `users.team_id` within a transaction; the FK does not auto-nullify.
- Team size cap: Enforced in application logic by counting users with the same `team_id` within a transaction.
- Credentials security: `access_token_enc` and `refresh_token_enc` are encrypted via Cloak Ecto at the application level and stored as `bytea`.
- Sync tracing: `sync_runs.status` is constrained to a small set for predictable reporting; `stats` can hold counts like fetched/inserted/updated/failed.
- Data retention: Purge logic (90 days post-challenge) is implemented via jobs (e.g., Oban) in the application layer; schema supports deletes via FKs (credentials cascade, others controlled in-app).

