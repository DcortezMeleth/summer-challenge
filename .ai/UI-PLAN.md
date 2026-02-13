# UI Architecture for Summer Challenge (Strava-based Company Sports Challenge MVP)

## 1. UI Structure Overview

### Product UI goals (from PRD + session notes)

- **Public-first**: leaderboards and milestone are viewable without login.
- **LiveView-first**: server-rendered, multi-route LiveView app; no SPA assumptions.
- **Transparent + simple**: consistent tables, consistent formatting, explicit empty states, minimal admin tooling.
- **Batch-sync mental model**: the UI always communicates “data is as of last sync”.

### Key UI constraints the architecture enforces

- **Role-gated navigation** (UI hides; server must enforce):
  - Unauthenticated: Public pages + Sign in
  - Authenticated: Public pages + My Activities + Teams + Settings + Sign out
  - Admin: Authenticated + Admin
- **Stable nav ordering**:
  - Challenge selector (dropdown, always visible)
  - Leaderboards (dynamic tabs based on selected challenge's sport types)
  - Milestone (40 hours)
  - (authed) My Activities
  - (authed) Teams
  - (authed) Settings
  - (admin) Admin
  - Sign in / Sign out
- **Formatting consistency**:
  - Distance: **km, 1 decimal**
  - Elevation: **m, integer**
  - Moving time: **HH:mm**
- **Responsiveness scope**: readable without horizontal scrolling; lightweight responsive adjustments only.

### Explicit MVP deferrals (from session notes)

- **No late-join indicator** (PRD US-005/US-013 deferred).
- **No “My totals” summary card** on My Activities (deferred).
- **No team selection during onboarding** (Teams is a separate view).

### Key requirements extracted (UI-relevant)

#### Authentication & authorization

- **Strava OAuth sign-in** (US-001) with clear failure messaging and retry.
- **Admin role** via configuration allowlist; admin-only UI/controls (US-002, US-028).
- **Logout** clears session; public pages remain accessible (US-024).
- **Session expiration** leads to relogin without breaking public pages (US-034).

#### Activity ingestion & filtering (UI implications)

- Daily refresh; **last sync timestamp displayed on public and authed views** (US-003, US-014).
- Only challenge-window activities are shown/aggregated; users do not see out-of-window activity lists (US-012, US-009).
- Only whitelisted outdoor sport types are included; unknown types excluded and should not crash UI (US-011, US-023).
- Late join indicator is **explicitly deferred** in session notes (despite PRD US-005/US-013).

#### Public leaderboards & milestone

- Two separate leaderboards: **Running** and **Cycling** with identical columns/formatting (US-003, US-004, US-016).
- Milestone list for **40 hours moving time** (US-017) with no ranking and “as of last sync”.
- Empty states before first sync / no data (US-032).

#### Participant self-service

- **My Activities**: list of included challenge activities with per-activity include/exclude toggle (US-009, US-010).
- Exclusions persist across resyncs and Strava edits (UI must communicate that toggles are “sticky”) (US-010).
- Show last sync timestamp (US-009, US-014).

#### Teams

- Create team / join team; **one team per user**; **cap enforced** with clear feedback (US-006, US-007, US-025).
- Rename/delete by owner/admin with confirmation for delete (US-008, US-036).
- Team name shown on leaderboards (US-006/US-007 + US-003/US-004).

#### Admin tools & recovery

- Admin-only **force sync** with UI status/progress and errors surfaced minimally (US-015, US-031).
- Admin can rename/delete teams (US-002, US-036).
- **Admin challenge management**: create, edit, delete (pre-start only), archive (post-end only), clone challenges (US-040, US-041, US-042, US-043, US-044).
- Admins can view archived challenges; non-admins cannot (US-043).
- Errors shown without exposing sensitive data (US-022, US-031).

#### Privacy & retention (UI implications)

- Terms/Privacy banner after initial login; dismissal persists (US-019).
- Token security is backend; UI must never display tokens and should avoid exposing PII in logs/status (US-021, US-031).
- “Disconnect account” flow (US-035) should be discoverable in Settings; confirm destructive action.
- Purge date is visible to admins (US-020); non-admin UI avoids operational details.

## 2. View List

> Note: The app may implement these as LiveViews and LiveComponents; “API endpoints” below describe the backend capabilities the UI needs (HTTP routes, or LiveView event handlers) and are aligned with the DTOs/commands defined in `app/lib/summer_challenge/model/types.ex`.

### Main API endpoints (backend capabilities) the UI depends on

#### Authentication/session

- **GET `/auth/strava`**: starts Strava OAuth (redirect to Strava authorization).
- **GET `/auth/strava/callback`**: completes OAuth; creates/updates user + credentials; redirects to `/onboarding` on first login else back to last public page.
- **POST `/auth/logout`** (or **DELETE `/session`**): ends session; redirect to last public page.

#### Public data (read-only)

- **GET `/challenges`**: returns list of non-archived challenges (or all challenges for admins) with metadata (name, dates, active status).
- **GET `/leaderboard/:challenge_id/:sport_group`**: renders leaderboard page for the specified challenge and sport group using `leaderboard_entry_dto[]`.
- **GET `/milestone/:challenge_id`**: renders milestone list for the specified challenge using `milestone_entry_dto[]`.
- **GET `/meta/sync`** (or include on each page payload): returns last sync timestamp and status (from latest `sync_run_dto`).

#### Authenticated user actions

- **GET `/my/activities/:challenge_id`**: returns `activity_dto[]` for current user within the specified challenge's date range and allowed sport types, plus last sync metadata.
- **PATCH `/my/activities/:activity_id`**: toggles exclusion; accepts `toggle_activity_exclusion_command`; returns `activity_exclusion_dto`.
- **GET `/teams`**: returns `team_dto[]` (list) + current user’s team membership state.
- **POST `/teams`**: creates a team; accepts `create_team_command`; returns `team_dto`.
- **POST `/teams/:team_id/join`**: joins a team; accepts `join_team_command`; returns updated user/team state.
- **POST `/teams/:team_id/leave`**: leaves team; accepts `leave_team_command`; returns updated user/team state.
- **GET `/settings`**: returns current user settings (display name, admin flag, connected state).
- **PATCH `/settings/display_name`**: updates display name; accepts `update_display_name_command`.
- **POST `/settings/disconnect`**: disconnects Strava (removes credentials, stops sync); confirm destructive action (US-035).
- **DELETE `/settings/account`**: deletes account (disconnects Strava, marks user as deleted, preserves historical data); confirm destructive action (US-048).

#### Admin actions

- **GET `/admin`**: returns admin dashboard data (latest `sync_run_dto`, maybe recent runs, counts/errors).
- **POST `/admin/sync_runs`**: triggers force sync; accepts `force_sync_command`; returns `sync_run_dto` (or id).
- **PATCH `/admin/teams/:team_id`**: rename team; accepts `rename_team_command`.
- **DELETE `/admin/teams/:team_id`**: delete team; accepts `delete_team_command` (nullifies memberships in transaction).
- **GET `/admin/challenges`**: returns all challenges including archived ones.
- **POST `/admin/challenges`**: creates a new challenge; accepts `create_challenge_command`; returns `challenge_dto`.
- **PATCH `/admin/challenges/:challenge_id`**: edits a challenge; accepts `update_challenge_command`.
- **DELETE `/admin/challenges/:challenge_id`**: deletes a future challenge; validation enforces pre-start only.
- **POST `/admin/challenges/:challenge_id/archive`**: archives a past challenge; validation enforces post-end only.
- **POST `/admin/challenges/:challenge_id/clone`**: clones a challenge; accepts `clone_challenge_command`; returns new `challenge_dto`.
- **GET `/admin/purge`**: shows configured purge effective date/status (US-020).

---

### 2.1 Public: Running Leaderboard

- **View name**: Running Leaderboard
- **View path**: `/leaderboard/running` (default landing)
- **Main purpose**: Show the current running standings (distance/time/elevation/activity count) as of last sync.
- **Key information to display**:
  - Last sync timestamp (Europe/Warsaw display)
  - Table rows: rank, display name, team name, total distance, total moving time, total elevation gain, activity count
- **Key view components**:
  - App shell + hamburger menu
  - “Running / Cycling” switch (or two explicit links)
  - Sync status line (“Last sync: …”)
  - Leaderboard table (sortable is out-of-scope; fixed ordering by rank)
  - Empty state panel
- **UX, accessibility, and security considerations**:
  - Use semantic `<table>` with `<caption>` and proper headers
  - Keyboard focusable sport switch and nav items
  - Public content must not leak sensitive fields (no Strava IDs, no emails, no token state)
  - Robust empty state: “No results yet; check back after the first sync.”

### 2.2 Public: Cycling Leaderboard

- **View name**: Cycling Leaderboard
- **View path**: `/leaderboard/cycling`
- **Main purpose**: Same as running, but for cycling types.
- **Key information to display**: Same as running.
- **Key view components**: Same as running.
- **UX, accessibility, and security considerations**: Same as running.

### 2.3 Public: 40-hour Milestone

- **View name**: 40-hour Milestone
- **View path**: `/milestone`
- **Main purpose**: Show participants who reached the 40h moving-time threshold (no ranking).
- **Key information to display**:
  - Last sync timestamp
  - List/table of participants who reached 40h: display name, team (optional), total moving time (HH:mm), optional “achieved at” (if available)
  - Copy explaining milestone meaning and “as-of last sync”
- **Key view components**:
  - App shell + hamburger menu
  - Milestone list/table
  - Empty state (“No one has reached 40h yet.”)
- **UX, accessibility, and security considerations**:
  - Avoid “rank” semantics to prevent misinterpretation
  - Keep list readable without horizontal scroll

### 2.4 Authenticated: Onboarding (first login)

- **View name**: Onboarding
- **View path**: `/onboarding`
- **Main purpose**: Confirm/join the challenge, set required display name, show Terms/Privacy notice.
- **Key information to display**:
  - Primary copy: “You are joining the challenge.”
  - Display name form (required)
  - Terms/Privacy notice + links; “acceptance implied by continuing”
- **Key view components**:
  - Required display name form (`<.input>`, inline errors)
  - Primary CTA (“Continue”)
  - Terms/Privacy banner content (inline)
- **UX, accessibility, and security considerations**:
  - Validation: length only (1–80) with clear error messages
  - Focus management on error (move focus to first invalid field)
  - CSRF-protected form submits
  - Prevent open redirect: post-login redirect destinations must be allowlisted

### 2.5 Authenticated: My Activities

- **View name**: My Activities
- **View path**: `/my/activities`
- **Main purpose**: Let participants view eligible challenge activities and include/exclude them.
- **Key information to display**:
  - Last sync timestamp (and optional per-user last sync error warning)
  - Activity rows: date/time, sport type, distance (km), moving time (HH:mm), elevation (m), included/excluded toggle state
- **Key view components**:
  - Activity list table (or list on small screens)
  - Include/Exclude toggle per row (immediate update)
  - Toast/flash notifications on success/failure
  - Empty state (“No eligible activities found in the challenge window.”)
- **UX, accessibility, and security considerations**:
  - Toggle must be keyboard operable and screen-reader labeled (e.g., “Exclude activity on 2026-06-10 07:12 Run”)
  - Optimistic UI is allowed, but must handle failure clearly (toast + revert or retry affordance)
  - Authorize on server: user can only toggle their own activities
  - Avoid accidental rapid toggling: disable control while request in-flight

### 2.6 Authenticated: Teams

- **View name**: Teams
- **View path**: `/teams`
- **Main purpose**: Create/join/leave teams with a hard cap and single-team membership rule.
- **Key information to display**:
  - Current membership (team name, role: owner/member)
  - Team list: name, member count, join availability (full/not)
  - Any cap rule copy (e.g., “Max 5 members per team”)
- **Key view components**:
  - “Create a team” form (name input)
  - Team list with “Join” buttons
  - “Leave team” action when already in a team
  - Rename/delete controls visible only to team owner + admins (delete requires confirmation)
- **UX, accessibility, and security considerations**:
  - Enforce leave-then-join in UI: if already in team, disable join buttons and show guidance + “Leave team” CTA
  - Inline errors for name conflicts/length constraints
  - Confirm modal for delete; warn that members become teamless
  - Server must enforce cap and membership constraints (UI is not authoritative)

### 2.7 Authenticated: Settings

- **View name**: Settings
- **View path**: `/settings`
- **Main purpose**: Manage identity (display name) and account connection.
- **Key information to display**:
  - Current display name
  - Connection state (connected/disconnected; optionally “last sync” summary)
  - Optional warning if token refresh failed (“Sync paused until you reauthorize”) (US-029)
- **Key view components**:
  - Display name edit form (length-only validation)
  - “Disconnect Strava” destructive action with confirmation (US-035)
  - “Reauthorize with Strava” CTA if disconnected or revoked (US-029)
- **UX, accessibility, and security considerations**:
  - Confirm destructive actions
  - Prevent leaking PII: do not show emails unless explicitly required; prefer display name only
  - Make the “reauthorize” path obvious when sync is blocked

### 2.8 Admin: Admin Dashboard

- **View name**: Admin
- **View path**: `/admin`
- **Main purpose**: Give admins minimal recovery tools and visibility (last sync status + actions).
- **Key information to display**:
  - Latest sync run: started/finished, status (success/error/running), last sync timestamp
  - Minimal counts/stats (e.g., users attempted/succeeded/failed, activities upserted)
  - Recent errors list (no PII)
  - Purge date/status (US-020)
- **Key view components**:
  - “Force sync” button + in-progress indicator
  - Status panel (success/failure)
  - Team moderation section: search/list teams, rename, delete (with confirmation)
- **UX, accessibility, and security considerations**:
  - Admin-only route protection (server enforced); UI hides from non-admin
  - Avoid PII in logs/snippets; no tokens, no emails
  - Long-running actions should show progress or “sync started” acknowledgment

### 2.9 Cross-cutting: Auth entry points

- **View name**: Sign in entry point
- **View path**: (linked action) `/auth/strava`
- **Main purpose**: Start OAuth; on failure, route back with actionable message.
- **Key information to display**: Clear “Sign in with Strava” CTA, and errors (if any).
- **Key view components**: Nav item and optionally a hero CTA on public pages.
- **UX, accessibility, and security considerations**:
  - Ensure CTA is a standard link/button with accessible name
  - Error copy does not reveal internal details

## 3. User Journey Map

### Main journey: participant joins, views stats, and manages activities

1. **Visitor lands** on `/leaderboard/running` (public).
2. Visitor explores `/leaderboard/cycling` and `/milestone`.
3. Visitor clicks **Sign in with Strava** (nav CTA) → `/auth/strava` redirect.
4. After OAuth callback:
   - **First login** → redirect to `/onboarding`.
   - **Returning user** → redirect back to last public page.
5. **Onboarding**:
   - User confirms/edits **display name** (required).
   - User sees Terms/Privacy notice; continues.
6. User opens hamburger menu → **My Activities**:
   - Sees list and last sync time.
   - Toggles include/exclude on an activity; gets toast feedback.
7. User opens **Teams**:
   - Creates a team or joins an existing team (if not already on one).
   - If already on a team, UI enforces “Leave then Join”.
8. User opens **Settings**:
   - Updates display name (length validation).
   - If needed, disconnects or reauthorizes Strava.
9. User signs out via nav; returns to public leaderboard.

### Admin journey: recovery and moderation

1. Admin signs in → lands on public leaderboard (or last visited page).
2. Admin opens **Admin** view:
   - Reviews last sync status and recent errors.
   - Clicks **Force sync** if needed; sees “started / running / completed” state.
3. Admin moderates teams:
   - Renames a team with invalid name.
   - Deletes a team (confirmation) and verifies users become teamless.

## 4. Layout and Navigation Structure

### Global layout (app shell)

- **Single hamburger menu** available on all pages.
- **Top-level content region** with consistent page heading (`<h1>`) and short descriptive subtext.
- **Global flash/toast region** for:
  - auth errors
  - action confirmations
  - validation failures
  - sync action status (admin)

### Navigation items and visibility rules

- **Always visible**:
  - Leaderboards: Running, Cycling
  - Milestone
  - Sign in (if unauthenticated) / Sign out (if authenticated)
- **Authenticated only**:
  - My Activities
  - Teams
  - Settings
- **Admin only**:
  - Admin

### Route-level access control (security model)

- Public routes do not require session.
- Authenticated routes require session (redirect to public + flash if not).
- Admin routes require session + admin flag (redirect to public + flash if not).
- UI hides links when not eligible, but **server must enforce** every route/action.

### Information architecture and cross-page consistency

- Every leaderboard/milestone page includes:
  - **Last sync timestamp** line
  - Empty-state component when no rows
  - Consistent units and formatting
- Authenticated pages include:
  - Last sync timestamp (and warnings if user-specific sync errors)

## 5. Key Components

### Shared UI components

- **`AppShell` (Layouts + page header)**: consistent heading, content width, and global flash region.
- **`HamburgerMenu`**: role-aware nav list with stable ordering; keyboard accessible open/close.
- **`SyncStatusLine`**: renders last sync timestamp; for admins also renders status badge (success/error/running).
- **`EmptyState`**: standardized empty message + optional CTA (“Sign in”, “Try again later”).
- **`LeaderboardTable`**: reusable table for running/cycling with consistent column formatting.
- **`MilestoneList`**: list/table without rank emphasis; time formatting.
- **`Toast/Flash`**: success/error info for toggles, forms, and admin actions.
- **`ConfirmDialog`**: for destructive actions (team delete, disconnect account).

### Domain-specific components

- **`ActivityRow` + `ExcludeToggle`**: immediate include/exclude with in-flight disabled state; accessible labels.
- **`TeamCard/TeamRow`**: displays name + member count + join/leave/rename/delete actions based on role.
- **`DisplayNameForm`**: used in onboarding + settings; length validation and inline errors.
- **`AdminSyncPanel`**: force sync control + recent run status + minimal error list (no PII).

### Edge cases / error states (handled consistently across views)

- **No data / before first sync**: empty states on leaderboards and milestone (US-032).
- **Sync in progress**: admin sees “running”; public views still show last completed sync time.
- **OAuth failure**: show actionable message and retry (US-001, US-022).
- **Token revoked / refresh fails**: Settings shows warning + “Reauthorize” CTA; other pages remain usable (US-029).
- **Team is full**: join action fails with clear message; UI shows “Full” state (US-007, US-025).
- **Duplicate team name**: create/rename shows inline validation error (US-006, US-008).
- **Unauthorized actions**: server returns authorization error; UI shows flash and keeps public content viewable (US-028).
- **Session expired**: user is redirected to public page with “Session expired, please sign in again” (US-034).
- **Timezone confusion**: always label timestamps as Europe/Warsaw in the UI; store UTC in backend.

### User story → UI mapping (coverage checklist)

- **US-001 Sign in with Strava**: Public nav CTA; `/auth/strava` → callback; error flash; redirect back.
- **US-002 Admin access**: Admin-only nav item + `/admin`; server-gated; admin actions visible only there.
- **US-003 Public running leaderboard**: `/leaderboard/running` default; table + last sync line.
- **US-004 Cycling leaderboard**: `/leaderboard/cycling` parity with running.
- **US-005 Late join badge**: **Deferred** (explicit MVP exclusion in session notes); reserve UI slot later.
- **US-006 Team creation**: `/teams` create form; unique name messaging; cap copy.
- **US-007 Team join and membership**: `/teams` join buttons; full state messaging; leave-then-join enforcement.
- **US-008 Team rename and delete**: `/teams` for owner + `/admin` for admins; rename form; delete confirm dialog.
- **US-009 My activities viewing**: `/my/activities` list + last sync line; out-of-window hidden.
- **US-010 Exclude an activity**: `ExcludeToggle` per activity row + toasts; server persistence.
- **US-011 Activity inclusion rules**: UI reflects only stored allowed types; unknowns never shown; errors don’t crash UI.
- **US-012 Challenge window enforcement**: UI lists/aggregates only eligible window; copy in empty state if needed.
- **US-013 Late join counting rule**: **Deferred** with US-005; document as future enhancement.
- **US-014 Daily synchronization**: last sync timestamps everywhere; “as of last sync” copy.
- **US-015 Force sync**: `/admin` force sync button + progress/status area.
- **US-016 Leaderboard calculations**: table columns and formatting; tie display (no tie-break UI).
- **US-017 Milestone list**: `/milestone` list of ≥40h; no ranking.
- **US-018 Display name management**: onboarding required name; `/settings` edit name.
- **US-019 Terms/Privacy banner**: shown on onboarding; dismissal persists.
- **US-020 Data retention**: `/admin` shows purge date/status; destructive “disconnect” separate in settings.
- **US-021 Token security**: UI never shows tokens; admin status/logs avoid PII.
- **US-022 Error messaging**: consistent flash/toast patterns for OAuth/sync/actions.
- **US-023 Unknown sport type handling**: UI resilient; can show “Some activities were ignored” only if backend surfaces aggregate warning.
- **US-024 Logout**: nav “Sign out”; returns to public pages.
- **US-025 Prevent multiple team memberships**: Teams page enforces leave-then-join; server errors shown clearly.
- **US-026 Basic branding configuration**: App shell supports optional logo/primary color without layout changes (config-driven).
- **US-027 Display units**: shared formatters used across leaderboard/milestone/activities (km 1 decimal; m integer; HH:mm).
- **US-028 Unauthorized admin access prevention**: hidden admin UI + server-gated route; user-friendly error.
- **US-029 Handling token revocation**: Settings warning + reauthorize CTA; non-blocking elsewhere.
- **US-030 Display name defaulting**: onboarding allows confirm/edit; fallback name shown if backend sets one.
- **US-031 Minimal logging for recovery**: `/admin` shows last sync + basic stats + recent errors (no PII).
- **US-032 Empty states**: standardized empty state on leaderboards/milestone/activities/teams.
- **US-033 Handling large activity counts**: table remains performant; avoid heavy client-side processing; no pagination required but stable rendering.
- **US-034 Session expiration**: redirect + flash; public remains accessible.
- **US-035 Disconnect account**: Settings “Disconnect” confirm flow; state updates to disconnected.
- **US-036 Admin team integrity**: Admin team moderation section for rename/delete.
- **US-037 First-run configuration**: UI does not require; optionally show challenge dates as read-only banner (config).
- **US-038 Error-resilient ingestion**: UI shows partial failure status in admin; public pages still render from last good data.

### Requirement → UI element mapping (explicit)

- **Public leaderboards** → `LeaderboardTable`, sport route split (`/leaderboard/running`, `/leaderboard/cycling`), nav links.
- **Milestone (40h)** → `/milestone`, `MilestoneList`, copy “no ranking”.
- **Last sync visible everywhere** → `SyncStatusLine` on all leaderboard/milestone + authed views.
- **Per-activity exclude/include** → `ExcludeToggle` + toast/flash + in-flight disabled state.
- **Team cap + single membership** → Teams page states, disabled join CTAs, clear errors; confirm modals for delete.
- **Admin force sync** → `/admin` `AdminSyncPanel` with status + minimal errors list.
- **Terms/Privacy** → onboarding inline banner/module with persistent dismissal.
- **Token revocation handling** → Settings warning panel + reauthorize CTA.
- **Security (authz)** → role-gated nav + route-level enforcement + CSRF-protected forms.

### Potential user pain points and how the UI addresses them

- **“Why don’t my numbers match Strava right now?”** → “As of last sync” timestamp on all public pages; admin can force sync; Settings can show token/reauthorize warnings.
- **“I joined late / I don’t see old activities”** → Not surfaced in MVP (deferred late-join indicator); mitigate with clear copy in onboarding/help text if needed later.
- **“I accidentally excluded something / I can’t tell what counts”** → Per-row include/exclude control with immediate feedback + clear state label (Included/Excluded).
- **“Joining teams is confusing”** → Teams page makes current membership prominent and enforces leave-then-join with disabled join CTAs and explanatory text.
- **“Admin actions feel risky”** → Confirm dialogs for destructive actions; action status panels and minimal, non-PII error logs.

