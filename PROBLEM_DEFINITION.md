# Application - Company Sports Challenge (MVP)

## Key problem
Every summer we run a company sports challenge, but Strava’s built-in challenges don’t support our actual format:
- we want to track **multiple sports in one challenge** (running + cycling) while Strava challenge supports only a single sport,
- we want a **time-based milestone** (e.g. 40h = reward),
- we want **team rankings**,
- and we want to **exclude indoor/virtual activities** to promote going outside.
Last year we hacked it together with a custom script and manual following, but it was fragile (7-day fetch window, deduplication, data restrictions, organizer had to follow everyone). We need a dedicated app that lets employees log in with Strava and gives us reliable, transparent leaderboards for the whole season.

## Minimal set of functionalities
1. **Authentication via Strava**
   - Participant signs in with Strava OAuth.
   - We store access/refresh tokens needed to fetch their activities.

2. **Activity ingestion & storage**
   - Daily job fetches activities for all connected users.
   - We store activities in our DB (id, athlete, start date, duration, distance, sport type).
   - We filter to challenge window (e.g. 2026-06-01 → 2026-09-15).
   - We **exclude indoor/virtual** activities (e.g. VirtualRide, VirtualRun, other non-outdoor types).

3. **Sport grouping**
   - **Running group**: Run, TrailRun.
   - **Cycling group**: Ride, GravelRide, MountainBikeRide (configurable list).
   - Other activities are ignored in MVP.

4. **Leaderboards**
   - **Running leaderboard** (sum of distance in challenge period, only running group).
   - **Cycling leaderboard** (sum of distance in challenge period, only cycling group).
   - **Time progress** view (sum of moving time of all valid activities — used to check who reached 40h; no “top 3” prizes here).
   - Ranking shows: position, name, team (if any), metric value.

5. **Teams**
   - Logged-in user can **create a team** or **join an existing one**.
   - Optional team size cap (e.g. max 5).
   - **Team leaderboard**: sum of chosen metric per team (per-sport or overall — MVP: per-sport is enough).

6. **Participant self-service**
   - Logged-in user can see **their fetched activities** for the challenge period.
   - User can **manually exclude** a specific activity (e.g. duplicate recording).
   - Leaderboards ignore excluded activities.

7. **Public web UI**
   - Public page with running leaderboard, cycling leaderboard, team leaderboard, and “40h finishers”.
   - Logged-in users see an extra “My activities” section.

8. **Basic organizer view (very light)**
   - Hardcoded challenge name and dates in config/env.
   - No full admin panel in MVP.

## What's not in the MVP
- **No multi-provider auth** (Garmin/Polar/Coros) — Strava only.
- **No advanced challenge types** (geo-grids / Squadrats-style areas / map-based achievements).
- **No automatic prize management** (prizes announced via Slack/other channels).
- **No real-time sync / webhooks** — daily/batch updates are enough.
- **No complex anti-cheating / anomaly detection** — we only exclude virtual/indoor activities.
- **No historical retro-import for people who never authorized Strava** — if someone joins very late and Strava won’t give us early activities, we accept that.
- **No organization-level UI to configure challenge dates/categories** — dates are hardcoded for this edition.

## Success criteria
- At least **80% of participants successfully connect Strava** without organizer intervention.
- Organizers **do not need to follow participants manually** or deduplicate in spreadsheets.
- Leaderboards for **running** and **cycling** are available to everyone and refresh **at least once a day**.
- “40h” milestone can be **proved from the app** (list of users ≥ 40h).
- Teams can be created/joined by participants themselves, with the cap enforced.
- We can run the 2026 challenge for **up to 100 participants** without hitting Strava rate limits or doing manual fixes.
