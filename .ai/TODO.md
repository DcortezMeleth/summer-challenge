# MVP TODO — Unimplemented Requirements

Based on PRD gap analysis. See `.ai/PRD.md` for full acceptance criteria.

---

## Teams (US-006, US-007, US-008, US-025, US-036, US-049)

Biggest missing feature. Schema exists but no context functions or UI.

- [x] Implement `Teams` context: `create_team/2`, `join_team/2`, `leave_team/1`, `rename_team/3`, `delete_team/2`
- [x] Enforce team size cap (hardcoded 5) on join with a clear error
- [x] Enforce single-team membership (must leave before joining another)
- [x] Mark users as teamless automatically when their team is deleted
- [x] Build Teams LiveView page (`/teams`): create form, browsable join list, leave button, rename/delete for owner
- [x] Implement `Leaderboards.get_team_leaderboard/2` — full SQL aggregation per sport group
- [x] Write 34 tests covering all Teams context functions
- [x] Fix bug in `Team.changeset` and `Team.rename_changeset` (`get_field(team, :name)` called on struct instead of changeset — replaced with `update_change(:name, &String.trim/1)`)

---

## Settings / Account Page (US-018, US-035, US-048)

No post-onboarding settings screen exists.

- [ ] Build Settings LiveView (`/settings`) with:
  - [ ] Edit display name (US-018)
  - [ ] Disconnect Strava — removes tokens, stops future syncs, allows reconnect (US-035)
  - [ ] Delete account — removes tokens, marks user as deleted, preserves historical activity data (US-048)
- [ ] Add link to Settings in the navbar for authenticated users

---

## Token Revocation Handling (US-029)

Failed token refresh is only logged; user is never notified.

- [ ] On token refresh failure during sync, mark user with a `sync_error` / `needs_reauth` flag
- [ ] Surface a non-blocking warning banner to the user on next login
- [ ] Provide a "Reauthorize with Strava" action that re-initiates OAuth

---

## Data Retention (US-020, US-021)

Type definition exists in `types.ex` but no implementation.

- [ ] Implement 90-day post-challenge purge Oban job: revoke/delete tokens, delete user records
- [ ] Add purge date to the admin dashboard view

---

## Terms & Privacy Pages (US-019)

Onboarding banner links to `/terms` and `/privacy` but those routes don't exist.

- [ ] Create `/terms` route and page
- [ ] Create `/privacy` route and page

---

## Admin Sync Error Log (US-031)

Admin dashboard shows basic stats but no error history.

- [ ] Add a "Recent Errors" section to the admin dashboard showing the last ~20 sync errors (no PII)

---

## Session Expiration (US-034)

No configurable server-side session timeout is set.

- [ ] Configure a server-side session max-age / inactivity timeout
- [ ] Verify expired sessions redirect to Strava OAuth rather than erroring

---

## Branding Configuration (US-026)

No configurable logo or primary color.

- [ ] Support logo file path and primary color via app config (e.g. `config :summer_challenge, logo: ...`)
- [ ] Use safe defaults when not configured; no layout breakage
