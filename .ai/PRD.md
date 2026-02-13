# Product Requirements Document (PRD) - Strava-based Company Sports Challenge (MVP)

## 1. Product Overview

The Strava-based Company Sports Challenge is a lightweight web application that powers multiple sports competitions for employees. Participants authenticate with Strava once, and the app ingests their activities to produce transparent per-sport leaderboards and time-based milestone lists across multiple challenges. Each challenge can be configured with specific date ranges, allowed sport types, and activity groupings. The product emphasizes simplicity, daily batch sync, flexible sport type configuration, and minimal admin tooling. It is desktop-first, public by default for viewing leaderboards, and requires login only for personal activity management, team participation, and admin operations.

Primary stakeholders:

* Participants: employees who join challenges (expected up to 100 per challenge).
* Organizing committee: 4–5 people who create challenges, set dates, configure sport types, and manage prizes outside the app.
* Admin users: a small allowlist for challenge management, essential recovery, and moderation actions.

Timeline and delivery:

* Single developer with approximately one month to deliver MVP.
* Kanban milestones focusing on small, incremental deliverables.

## 2. User Problem

Existing Strava challenges do not meet the company’s needs:

* They support only one sport per challenge, while the company needs running and cycling.
* The company wants an outdoor-only rule and a time-based milestone (e.g., 40 hours) without ranking for time.
* Manual scripts and Strava limitations previously caused operational overhead, data loss risk, and fragile processes.
* The company also needs team-based competition mechanics and a way for users to self-exclude duplicates or incorrect activities.

The MVP solves these pain points by providing: Strava login, daily data ingestion with correct filtering, public leaderboards for running and cycling, a 40-hour milestone list derived from moving time, self-service activity exclusion, and simple team functionality.

## 3. Functional Requirements

### 3.1 Authentication and authorization

* Strava OAuth sign-in for participants.
* Start with broader scopes to include private activities; scopes can be reduced later without breaking core flows.
* Admin role defined via email allowlist stored in configuration.
* On first login, show a light Terms/Privacy banner; acceptance implied by continuing.

### 3.2 Activity ingestion and filtering

* Daily batch synchronization at midnight Europe/Warsaw; no strict SLA.
* Ingest activities for connected users; incremental fetch since last sync.
* Activities are fetched for all connected users and filtered per-challenge based on:
  * Activity start time between 00:00 on the first day and 23:59 on the last day of each challenge (Europe/Warsaw timezone).
  * Sport types allowed in each challenge (configured per challenge).
* Sport type groups are predefined in configuration:
  * **Running (Outdoor)**: Run, TrailRun
  * **Cycling (Outdoor)**: Ride, GravelRide, MountainBikeRide
  * **Running (Virtual)**: VirtualRun
  * **Cycling (Virtual)**: VirtualRide
  * **Excluded by default**: EBikeRide, EMountainBikeRide, Workout, Hike, Walk, Handcycle, Wheelchair
* Each challenge can include any combination of sport types; leaderboard tabs are dynamically created based on the sport type groups present in the challenge.
* Store required activity fields: Strava activity ID, user ID, sport type, start time, distance, moving_time, total_elevation_gain, and excluded flag.

### 3.3 Challenge selection and display

* Users can view any non-archived challenge via a dropdown selector.
* Default challenge shown on first visit: the active challenge with the latest start date, or the most recent inactive challenge if no active challenges exist.
* Challenge selector shows: challenge name, start date, and active/inactive status.
* Challenges are ordered in the selector: active challenges first (sorted by start date descending), then inactive challenges (sorted by start date descending).
* Archived challenges are hidden from non-admin users.

### 3.4 Leaderboards and milestone

* Leaderboard tabs are dynamically created based on sport type groups included in the selected challenge.
* Each tab aggregates activities for all sport types in that group (e.g., Running tab includes Run + TrailRun).
* Columns: position, display name, team, total distance, total moving time, total elevation gain, number of activities.
* Only participants with at least one qualifying activity in the selected challenge are shown.
* Milestone view for 40 hours: list of participants who reached 40 hours moving time in the selected challenge; no top ranking or prizes for time.

### 3.5 Teams

* Teams are global across all challenges.
* Participants may create a team or join an existing team; one team per user at any time.
* Hardcoded team size cap (e.g., 5). Team creators and admins can rename or delete teams.
* Team name appears in leaderboards; team-based ranking uses per-sport aggregation consistent with the selected leaderboard and challenge.

### 3.6 Participant self-service

* My Activities page accessible after login via a menu.
* Activities are shown for the currently selected challenge.
* Users can exclude or re-include specific activities; exclusions persist across re-syncs and Strava edits.
* No bulk actions, no reason entry required.
* Last sync timestamp is displayed.
* Users can delete their account, which disconnects Strava and marks them as deleted (historical data preserved for leaderboard integrity).

### 3.7 Admin challenge management

* Admins can create, edit, and archive challenges.
* Challenge creation requires:
  * Name (required)
  * Start date and end date (minimum 7 calendar days duration)
  * Selection of allowed sport types (presented grouped by category)
* Challenges can be edited at any time.
* Challenges can be deleted only if not yet started (start date in the future).
* Challenges can be archived only if they are past (end date in the past); archived challenges are hidden from non-admin users and cannot be unarchived.
* Admins can clone an existing challenge as a template for a new challenge.
* Admins can view archived challenges.

### 3.8 Admin tools

* Admin-only manual force sync button.
* Admin options for team rename/delete and basic moderation.
* Display last sync time; show a small log snippet or status to aid manual recovery.

### 3.9 Privacy, identity, and retention

* Default display name is first name + initial; user can edit display name.
* No avatars in MVP.
* Store only minimal personal data: user ID and display name; encrypt tokens at rest.
* Users can delete their account at any time; deletion disconnects Strava and marks the user as deleted while preserving historical activity data.
* Purge all data 90 days after the last challenge ends.

### 3.10 Non-functional

* Desktop-first, simple responsive layout; support latest Chrome, Firefox, Opera, Safari.
* No pagination required for the expected number of participants per challenge.
* No real-time sync; once-daily updates are acceptable.
* No formal monitoring or error-rate dashboards in MVP.
* Challenges can have overlapping date ranges; multiple challenges can be active simultaneously.

## 4. Product Boundaries

In scope:

* Strava-only OAuth and ingestion.
* Multiple challenges with configurable date ranges and sport types.
* Dynamic leaderboard tabs based on sport type groups in each challenge.
* 40-hour moving-time milestone list per challenge.
* Public leaderboards and simple logged-in views.
* Challenge selection dropdown with active/inactive filtering.
* My Activities with per-activity exclude/include (scoped to selected challenge).
* Teams with create/join, one team per user, hard cap (global across challenges).
* Admin challenge management: create, edit, delete (pre-start only), archive (post-end only), clone.
* Admin allowlist, force sync, simple team moderation.
* Terms/Privacy banner and minimal identity controls.
* Account deletion (disconnect + mark deleted).
* Data purge 90 days after last challenge ends.

Out of scope for MVP:

* Additional providers (Garmin, Polar, Coros, etc.).
* Real-time webhooks or sub-daily sync SLAs.
* Elevation-based algorithms or geo-challenge features (e.g., Squadrats).
* Prize management workflows and complex moderation.
* Leaderboard snapshots, exports, and advanced auditing.
* Mobile-optimized UX past basic responsiveness.
* Complex sorting/filtering beyond sport toggle.
* Per-challenge teams (teams are global).
* Challenge analytics dashboard (participant counts, activity stats).
* Unarchiving archived challenges.
* Custom milestone thresholds per challenge (40 hours is hardcoded).

## 5. User Stories

US-001 Authentication with Strava
Title: Sign in with Strava
Description: As a participant, I want to authenticate using Strava so my outdoor activities can be fetched and included in the challenge.
Acceptance Criteria:

1. Given a visitor on the public leaderboard, when they click Sign in with Strava and complete OAuth, then they are redirected back to the leaderboard.
2. Tokens are stored securely and linked to the participant’s account.
3. If OAuth fails, the user sees a clear error message and remains on or returns to the leaderboard.
4. Terms/Privacy banner displays after first login and can be dismissed.

US-002 Authorization and admin role
Title: Admin access
Description: As an admin, I need access to admin-only actions to recover from errors and moderate teams.
Acceptance Criteria:

1. Admin status is determined by an email allowlist in configuration.
2. Admin-only menu is visible only to admins after login.
3. Admin can trigger a force sync.
4. Admin can rename or delete any team.

US-003 Public leaderboard viewing
Title: View running leaderboard by default
Description: As any visitor, I want to see the running leaderboard without logging in.
Acceptance Criteria:

1. Default page shows Running leaderboard with columns: position, display name, team, total distance, total moving time, total elevation gain, number of activities.
2. Toggle to switch to Cycling leaderboard is available and functional.
3. Data reflects the most recent completed daily sync; last sync time is displayed.

US-004 Cycling leaderboard viewing
Title: View cycling leaderboard
Description: As any visitor, I want to switch to the cycling leaderboard.
Acceptance Criteria:

1. Cycling leaderboard shows the same columns as Running.
2. Distances aggregate only included cycling activity types.

US-006 Team creation
Title: Create a team
Description: As a participant, I want to create a team to compete with colleagues.
Acceptance Criteria:

1. After login, a participant can open Teams and create a team with a unique name.
2. Team creation respects the hard cap for team size (e.g., 5).
3. The creator becomes the team owner.
4. The team appears in leaderboards once it has at least one participant.

US-007 Team join and membership
Title: Join a team
Description: As a participant, I want to join a team so my results contribute to team totals.
Acceptance Criteria:

1. A participant can join exactly one team.
2. Joining fails with a clear message if the team is at the size cap.
3. After joining, the participant’s team appears on their leaderboard row.
4. Participants can switch teams only if they are not already in one; if switching is allowed, leaving the previous team is enforced first. (For MVP, one active team at a time with explicit leave-then-join flow.)

US-008 Team rename and delete
Title: Manage team identity
Description: As a team creator or admin, I want to rename or delete my team.
Acceptance Criteria:

1. The rename option is available to the team creator and admins.
2. Delete prompts for confirmation; deleting removes memberships or marks them as teamless.
3. Leaderboards update on next calculation cycle after a rename or deletion.

US-009 My activities viewing
Title: View my activities
Description: As a logged-in participant, I want to see a list of my included challenge activities.
Acceptance Criteria:

1. Activities list shows date/time, sport type, distance, moving time, elevation gain, and an include/exclude checkbox.
2. Activities outside the challenge window are not shown.
3. The page displays the last sync timestamp.

US-010 Exclude an activity
Title: Exclude a problematic activity
Description: As a participant, I want to exclude a duplicate or incorrect activity from my totals.
Acceptance Criteria:

1. Unchecking an activity marks it as excluded.
2. Exclusions persist across re-syncs and Strava edits.
3. Users can re-include an excluded activity by rechecking it.
4. Excluded activities are ignored in all totals and leaderboards after the next calculation cycle.

US-011 Activity inclusion rules
Title: Outdoor filtering and sport mapping
Description: As the system, I must include only allowed outdoor activities and ignore disallowed types.
Acceptance Criteria:

1. Only Run, TrailRun, Ride, GravelRide, MountainBikeRide are included.
2. VirtualRun, VirtualRide, EBikeRide, EMountainBikeRide, Workout, Hike, Walk, Handcycle, Wheelchair are excluded.
3. Unknown sport types are logged for review and excluded by default in MVP.

US-012 Challenge window enforcement
Title: Date window based on start time
Description: As the system, I must include activities based on their start time within the configured window.
Acceptance Criteria:

1. Activities with start time on or after 00:00 first day and on or before 23:59 last day (Europe/Warsaw) are eligible.
2. Activities outside the window are excluded from all totals.
3. Window dates are configurable.

US-014 Daily synchronization
Title: Nightly data sync
Description: As an admin and participant, I want activities refreshed daily.
Acceptance Criteria:

1. A daily job starts at midnight Europe/Warsaw to fetch new activities.
2. Incremental fetch since the last successful sync is used.
3. Last sync time is visible on public and logged-in views.

US-015 Force sync
Title: Admin-triggered sync
Description: As an admin, I want to trigger a manual sync if something goes wrong.
Acceptance Criteria:

1. Admin-only button triggers a sync task.
2. The UI indicates that a sync is in progress or recently completed.
3. Errors are surfaced in a minimal status area or log snippet.

US-016 Leaderboard calculations
Title: Aggregate per-sport totals
Description: As the system, I must compute totals for each sport and display them correctly.
Acceptance Criteria:

1. Running leaderboard aggregates distance, moving time, elevation gain, and number of activities for included running types.
2. Cycling leaderboard aggregates the same metrics for included cycling types.
3. Ties are allowed and shown as the same position or as sequential positions without tie-break logic.

US-017 Milestone list
Title: 40-hour moving-time milestone
Description: As a participant, I want to see whether I reached 40 hours moving time during the challenge.
Acceptance Criteria:

1. The system calculates moving-time totals per participant across all included activities.
2. Participants with at least 40 hours are listed; no ranking is applied.
3. The milestone list refreshes after each daily sync.

US-018 Display name management
Title: Edit display name
Description: As a participant, I want to edit my display name used in public views.
Acceptance Criteria:

1. Default display is first name + initial.
2. User can set a custom display name via settings.
3. Changes reflect on leaderboards after save.

US-019 Privacy and consent notice
Title: Terms/Privacy banner
Description: As the organization, we need a minimal notice for terms and privacy.
Acceptance Criteria:

1. After initial login, a banner with links to Terms and Privacy appears.
2. Dismissing the banner hides it for that user going forward.
3. The banner copy states that logging in implies acceptance.

US-020 Data retention
Title: Post-challenge purge
Description: As the organization, we must delete data after the challenge ends.
Acceptance Criteria:

1. All stored data is purged 90 days after challenge end.
2. Tokens are revoked or deleted as part of purge.
3. A minimal admin view shows the configured purge date.

US-021 Token security
Title: Secure token storage
Description: As the system, I must store tokens securely.
Acceptance Criteria:

1. Access and refresh tokens are encrypted at rest.
2. Tokens are only accessible to server processes that require them.
3. On user disconnect or data purge, tokens are removed.

US-022 Error messaging
Title: Clear OAuth and sync errors
Description: As a user or admin, I want clear messaging for common errors.
Acceptance Criteria:

1. OAuth failures show an actionable message and retry option.
2. Sync errors show a brief status in the admin view.
3. Public leaderboard remains viewable during errors.

US-023 Unknown sport type handling
Title: Safe handling of unrecognized types
Description: As the system, I must handle unknown Strava sport types safely.
Acceptance Criteria:

1. Unknown types are excluded from totals by default.
2. Unknown types are logged for later review.
3. The system continues without crashing or blocking sync.

US-024 Logout
Title: Sign out
Description: As a logged-in participant, I want to sign out of the app.
Acceptance Criteria:

1. Logout action clears local session.
2. Public leaderboard remains accessible after logout.
3. Next login requires Strava OAuth again if no session is present.

US-025 Team membership edge cases
Title: Prevent multiple team memberships
Description: As the system, I must enforce single-team membership.
Acceptance Criteria:

1. A user cannot join a new team without leaving the current one.
2. If a team is deleted, affected users become teamless automatically.
3. Team cap is enforced on join with a clear message if full.

US-026 Basic branding configuration
Title: Optional logo and color
Description: As the organizer, I may want minimal branding.
Acceptance Criteria:

1. Logo file and primary color can be configured.
2. If not provided, defaults are used without layout issues.
3. Branding does not affect functionality or accessibility.

US-027 Display units
Title: Distance and elevation units
Description: As a user, I want distances shown in meters/kilometers and elevation in meters.
Acceptance Criteria:

1. Distances are displayed as km with reasonable precision; raw storage remains in meters.
2. Elevation is shown in meters on leaderboards.
3. Rounding rules are consistent across pages.

US-028 Unauthorized admin access prevention
Title: Protect admin actions
Description: As the system, I must ensure only admins perform admin actions.
Acceptance Criteria:

1. Admin endpoints require an authenticated session with an admin flag.
2. Non-admin attempts return an authorization error.
3. Admin UI elements are hidden from non-admin users.

US-029 Handling token revocation
Title: Graceful handling of revoked access
Description: As the system, I must handle revoked Strava permissions.
Acceptance Criteria:

1. If token refresh fails, the user is marked with a non-blocking warning.
2. Their activities stop syncing until reauthorized.
3. The warning is visible to the user on login with a reauthorize option.

US-030 Participant display name defaulting
Title: Default identity mapping
Description: As the system, I must set a safe default display name.
Acceptance Criteria:

1. On first login, display name set to first name + initial from available Strava profile data.
2. If first name is unavailable, default to the portion of the email before @ or to an anonymized alias.
3. Users can update the display name in settings.

US-031 Minimal logging for recovery
Title: View last sync status
Description: As an admin, I want minimal logging to understand sync results.
Acceptance Criteria:

1. Admin view shows timestamp of last sync and basic success/failure counts.
2. Recent errors (e.g., last 20) can be viewed in a simple list.
3. No PII is displayed in logs.

US-032 Empty states
Title: Graceful empty states
Description: As any user, I want the UI to be understandable when there is no data.
Acceptance Criteria:

1. Before the challenge starts or before first sync, leaderboards show an informative empty state.
2. My Activities shows a helpful message when no activities are present.
3. Teams view indicates when a user is not on a team.

US-033 Handling large activity counts
Title: Stable totals for power users
Description: As the system, I must handle participants with many activities.
Acceptance Criteria:

1. Aggregations for up to 100 users with up to 100 activities each complete within acceptable time during nightly sync.
2. Leaderboards render without timeouts.
3. Numerical totals are accurate and consistent with underlying records.

US-034 Logout security edge case
Title: Session expiration
Description: As the system, I must expire sessions securely.
Acceptance Criteria:

1. Sessions expire after a configurable period of inactivity.
2. Expired sessions require relogin via Strava OAuth.
3. Public pages remain accessible.

US-035 Disconnect account
Title: Revoke access voluntarily
Description: As a participant, I want to disconnect my Strava account from the app.
Acceptance Criteria:

1. Disconnect action removes tokens and stops future syncing.
2. Existing records remain until the 90-day purge unless deleted by policy.
3. Reconnecting later resumes syncing from that point forward.

US-036 Admin team integrity
Title: Prevent inappropriate team names
Description: As an admin, I want to fix team names that violate guidelines.
Acceptance Criteria:

1. Admin can rename any team.
2. Changes reflect in leaderboards after next calculation cycle.
3. Delete is available when a team must be removed entirely.


US-037 First-run configuration
Title: Configure challenge dates and sports
Description: As an admin/organizer, I need to set challenge dates and confirm sport mappings.
Acceptance Criteria:

1. Challenge start and end dates can be configured in an environment or simple settings file.
2. Sport mapping list is configurable.
3. Changing dates updates inclusion logic immediately for subsequent syncs.

US-038 Error-resilient ingestion
Title: Continue on partial failures
Description: As the system, I must continue ingestion even if some user fetches fail.
Acceptance Criteria:

1. A single user’s failure does not block others.
2. Failures are recorded in minimal logs.
3. Next nightly sync retries failed users.

US-039 Challenge selection
Title: View and select challenges
Description: As any user, I want to view different challenges and see their leaderboards.
Acceptance Criteria:

1. A challenge dropdown selector is visible on all leaderboard and milestone pages.
2. The selector shows challenge name, start date, and active/inactive status.
3. Challenges are ordered: active challenges first (by start date descending), then inactive challenges (by start date descending).
4. Archived challenges are hidden from non-admin users.
5. The default challenge shown is the active challenge with the latest start date, or the most recent inactive challenge if none are active.
6. Selecting a challenge updates the leaderboard and milestone data to show only that challenge's results.

US-040 Create challenge
Title: Admin creates a new challenge
Description: As an admin, I want to create a new challenge with specific dates and sport types.
Acceptance Criteria:

1. Admin can access a "Create Challenge" form.
2. Form requires: challenge name, start date, end date (minimum 7 calendar days apart).
3. Form presents sport types grouped by category (Running Outdoor, Cycling Outdoor, Running Virtual, Cycling Virtual) for selection.
4. Admin can select any combination of sport types.
5. After creation, the challenge appears in the challenge selector.
6. Validation prevents creating challenges with duration less than 7 days.

US-041 Edit challenge
Title: Admin edits an existing challenge
Description: As an admin, I want to edit challenge details at any time.
Acceptance Criteria:

1. Admin can edit any challenge (active, inactive, or future).
2. Editable fields: name, start date, end date, allowed sport types.
3. Validation enforces minimum 7-day duration.
4. Changes take effect immediately for subsequent syncs and leaderboard calculations.

US-042 Delete challenge
Title: Admin deletes a future challenge
Description: As an admin, I want to delete a challenge that hasn't started yet.
Acceptance Criteria:

1. Delete option is available only for challenges where start date is in the future.
2. Delete requires confirmation.
3. After deletion, the challenge is removed from the system entirely.
4. Delete is not available for started or past challenges.

US-043 Archive challenge
Title: Admin archives a past challenge
Description: As an admin, I want to archive old challenges to keep the selector clean.
Acceptance Criteria:

1. Archive option is available only for challenges where end date is in the past.
2. Archive requires confirmation.
3. Archived challenges are hidden from non-admin users in the challenge selector.
4. Admins can still view and select archived challenges.
5. Archived challenges cannot be unarchived.

US-044 Clone challenge
Title: Admin clones an existing challenge
Description: As an admin, I want to clone an existing challenge as a template for a new one.
Acceptance Criteria:

1. Clone option is available for any challenge.
2. Cloning creates a new challenge with the same sport type configuration.
3. The new challenge has a default name (e.g., "Copy of [Original Name]") that can be edited.
4. Admin must set new start and end dates before saving.
5. The cloned challenge appears as a new, separate challenge.

US-045 Dynamic leaderboard tabs
Title: Leaderboard tabs based on challenge sport types
Description: As any user, I want to see leaderboard tabs that match the selected challenge's sport types.
Acceptance Criteria:

1. Leaderboard tabs are dynamically created based on sport type groups in the selected challenge.
2. Each tab shows only activities from sport types in that group (e.g., Running tab shows Run + TrailRun).
3. If a challenge has no running types, no running tab is shown.
4. If a challenge has no cycling types, no cycling tab is shown.
5. Tabs are labeled clearly (e.g., "Running (Outdoor)", "Cycling (Virtual)").

US-046 Challenge-scoped leaderboards
Title: Leaderboards show only challenge participants
Description: As any user, I want to see only participants who have activities in the selected challenge.
Acceptance Criteria:

1. Leaderboards show only users with at least one qualifying activity in the selected challenge.
2. Qualifying activities must: be within the challenge date range, match allowed sport types, and not be excluded.
3. Users without qualifying activities do not appear on the leaderboard.
4. Switching challenges updates the participant list accordingly.

US-047 Challenge-scoped My Activities
Title: View activities for selected challenge
Description: As a logged-in participant, I want to see my activities for the currently selected challenge.
Acceptance Criteria:

1. My Activities page shows only activities within the selected challenge's date range and allowed sport types.
2. Switching challenges updates the activity list.
3. Activity exclusions are challenge-independent (excluding an activity in one view excludes it everywhere).

US-048 Delete account
Title: User deletes their account
Description: As a participant, I want to delete my account and disconnect from Strava.
Acceptance Criteria:

1. Delete account option is available in Settings at any time.
2. Delete requires confirmation with clear warning about consequences.
3. Deletion disconnects Strava (removes tokens) and marks the user as deleted.
4. Historical activity data is preserved for leaderboard integrity.
5. Deleted users cannot log in again unless they reconnect via Strava OAuth.
6. Deleted users' display names and team memberships remain visible on historical leaderboards.

US-049 Global teams across challenges
Title: Teams work across all challenges
Description: As a participant, I want my team membership to apply to all challenges.
Acceptance Criteria:

1. Teams are global; joining a team applies to all challenges.
2. Team rankings are calculated per-challenge based on that challenge's sport types and date range.
3. A user's team name appears consistently across all challenge leaderboards.

US-050 Sport type group configuration
Title: Predefined sport type groups
Description: As the system, I must group sport types consistently for leaderboard tabs.
Acceptance Criteria:

1. Sport type groups are defined in configuration: Running (Outdoor), Cycling (Outdoor), Running (Virtual), Cycling (Virtual).
2. Each group maps to specific Strava sport types (e.g., Running Outdoor = Run + TrailRun).
3. Leaderboard tabs are created based on which groups have at least one sport type selected in the challenge.
4. Unknown sport types are excluded and logged.

## 6. Success Metrics

Primary metrics for MVP:

1. Authentication success: approximately 80 percent of users complete Strava OAuth on their first attempt, measured informally through user check-ins and simple counts.
2. Data freshness: leaderboards update at least daily; last sync timestamp visible on pages.
3. Correctness: zero known calculation discrepancies between app totals and spot-checked Strava values.
4. Usability and engagement: observed usage at challenge start and end; participants can self-exclude activities and see changes reflected post-sync.
5. Operational simplicity: organizers avoid following users manually; admin force sync resolves occasional issues; exclusions persist across syncs.

Secondary indicators:

* Team participation rate and cap adherence.
* Minimal support requests related to sign-in, visibility of activities, or totals.

Checklist review:

* Each user story is testable with explicit acceptance criteria.
* Acceptance criteria are clear and specific for functional behaviors.
* The set of user stories covers authentication, ingestion, leaderboards, teams, self-service exclusions, admin recovery, privacy, and retention for a fully functional MVP.
* Authentication and authorization requirements are included and traceable via US-001, US-002, US-031, US-037.
