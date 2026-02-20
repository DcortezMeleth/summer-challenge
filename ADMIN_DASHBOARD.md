# Unified Admin Dashboard ✅

## Overview

The admin dashboard provides a unified interface for all administrative tasks, combining system monitoring, force sync functionality, and challenge management in one page. This consolidation makes it easier to manage all admin responsibilities from a single location.

## What Was Implemented

### 1. Unified Admin Dashboard (`/admin`)

A single admin page that includes:

**Dashboard Section:**
- **System Statistics**
  - Total users
  - Users with credentials (syncable users)
  - Pending jobs
  - Failed jobs in the last 24 hours

- **Force Sync Control**
  - Button to manually trigger sync for all users
  - Visual feedback during sync operation
  - Display of next scheduled sync time
  - Last sync timestamp

**Challenge Management Section:**
- View all challenges (active, inactive, archived)
- Create new challenges
- Edit existing challenges
- Clone challenges for quick setup
- Archive or delete challenges

### 2. Enhanced Security

**Admin-Only Route Protection:**

All admin routes are protected at the router level with the `:require_admin` hook:

```elixir
live_session :admin, on_mount: {Auth, :require_admin} do
  live "/admin", Admin.ChallengesLive, :index
  live "/admin/challenges/new", Admin.ChallengesLive, :new
  live "/admin/challenges/:id/edit", Admin.ChallengesLive, :edit
  live "/admin/challenges/:id/clone", Admin.ChallengesLive, :clone
end
```

**Behavior:**
- ✅ Admin users: Full access to all `/admin` routes
- ❌ Non-admin authenticated users: Redirected with error message
- ❌ Non-authenticated users: Redirected to login

### 3. Files Modified

**Production Code:**
1. `lib/summer_challenge_web/live/admin/challenges_live.ex`
   - Enhanced with dashboard stats and force sync functionality
   - Maintains all existing challenge management features
   - Unified UI with clear visual separation

2. `lib/summer_challenge_web/hooks/auth.ex` (already had `:require_admin`)
   - Enforces admin-only access at router level

3. `lib/summer_challenge_web/router.ex`
   - Simplified routes: `/admin` now points to the unified page
   - Removed separate `/admin/challenges` route

4. `lib/summer_challenge_web/components/core_components.ex`
   - Updated Admin nav link to point to `/admin`

**Files Removed:**
- `lib/summer_challenge_web/live/admin/dashboard_live.ex` (merged into challenges_live.ex)
- `test/summer_challenge_web/live/admin/dashboard_live_test.exs` (merged into challenges_live_test.exs)

**Tests:**
5. `test/summer_challenge_web/live/admin/challenges_live_test.exs`
   - Enhanced with dashboard and force sync tests
   - All challenge management tests updated for new routes
   - Comprehensive test coverage for unified interface

## How to Use

### Accessing the Admin Dashboard

1. Sign in as an admin user (user with `is_admin: true`)
2. Click "Admin" in the navigation menu (or navigate to `/admin`)
3. You'll see the unified dashboard with:
   - System stats at the top
   - Force sync control
   - Challenge management below

### Using Force Sync

1. On the admin dashboard, locate the "Activity Sync" section
2. Click the **"Force Sync Now"** button
3. The button will show "Syncing..." with an animated spinner
4. A success message confirms the job was queued
5. Stats are refreshed to show the new pending job

### Managing Challenges

All existing challenge management features remain available:

1. **View Challenges:** See all challenges in the table below the dashboard
2. **Create New:** Click "New Challenge" button
3. **Edit:** Click the edit icon on any challenge row
4. **Clone:** Click the clone icon to duplicate a challenge
5. **Archive:** Archive completed challenges
6. **Delete:** Delete challenges that haven't started yet

### Monitoring Jobs

**On the Dashboard:**
- View current job counts in the stats cards
- See when the last sync completed
- Check failed job count (last 24 hours)

**In LiveDashboard:**
- Visit `/dev/dashboard` (development) for detailed Oban monitoring
- View all queues, job details, and failures
- Manually retry failed jobs

## Technical Details

### Force Sync Implementation

When an admin clicks "Force Sync Now":

1. **Job Creation:**
   ```elixir
   SyncAllWorker.new(%{}) |> Oban.insert()
   ```

2. **Unique Constraint:**
   - If a sync job is already queued/executing, returns existing job
   - Prevents duplicate syncs (1-hour uniqueness window)

3. **Job Execution:**
   - Calls `SummerChallenge.SyncService.sync_all()`
   - Syncs all users with valid credentials
   - Retries up to 3 times on failure

4. **Result:**
   - Returns stats: `%{total: X, success: Y, error: Z}`
   - Logs completion with metrics

### Authorization Flow

```
User Request to /admin
    ↓
Auth Hook: :require_admin
    ↓
Check Session → Has user_id?
    ↓ No → Redirect to /leaderboard (error: "Please sign in")
    ↓ Yes
    ↓
Load User from DB
    ↓ Not found → Redirect (error: "Session expired")
    ↓ Found
    ↓
Check is_admin?
    ↓ No → Redirect (error: "No permission")
    ↓ Yes
    ↓
Allow Access ✅
```

### Database Queries

The dashboard efficiently loads stats using aggregation queries:

```elixir
# Total users
Repo.aggregate(User, :count)

# Syncable users (with credentials)
length(Accounts.list_syncable_users())

# Pending jobs
Repo.one(from j in Oban.Job,
  where: j.state in ["available", "scheduled", "executing"],
  select: count(j.id))

# Failed jobs (24h)
Repo.one(from j in Oban.Job,
  where: j.state in ["retryable", "discarded"] and
    j.attempted_at >= ^twenty_four_hours_ago,
  select: count(j.id))

# Last sync time
Repo.one(from j in Oban.Job,
  where: j.worker == "SummerChallenge.Workers.SyncAllWorker" and
    j.state == "completed",
  order_by: [desc: j.completed_at],
  limit: 1,
  select: j.completed_at)
```

## Testing

All tests pass, including dashboard, force sync, and challenge management:

```bash
mix test test/summer_challenge_web/live/admin/challenges_live_test.exs
# 23 tests, 0 failures ✅
```

**Test Coverage:**
- ✅ Authorization (admin-only access, non-admin redirect)
- ✅ Dashboard statistics display
- ✅ Force sync button functionality
- ✅ Job queueing with Oban
- ✅ UI state updates (syncing state)
- ✅ Challenge listing and filtering
- ✅ Challenge CRUD operations
- ✅ Challenge cloning and archiving

## Security Considerations

1. **Admin-Only Access:** Protected at router level with `:require_admin` hook
2. **CSRF Protection:** Built-in Phoenix CSRF protection
3. **Session Validation:** Every request validates session and user
4. **Authorization Logging:** Admin access attempts are logged
5. **No Sensitive Data:** Dashboard doesn't expose credentials or tokens
6. **Input Validation:** All challenge data validated with Ecto changesets

## UI/UX Features

### Unified Interface
- Single page for all admin tasks
- Clear visual hierarchy with dashboard on top
- Seamless transition between monitoring and management

### Dashboard Section
- **Stats Cards:** Color-coded with icons (blue, green, yellow, red)
- **Sync Control:** Prominent button with real-time status
- **Visual States:** Loading spinner, disabled state, success feedback

### Challenge Management
- **Table View:** All challenges with status badges
- **Action Buttons:** Edit, clone, archive/delete icons
- **Modal Forms:** Clean create/edit experience
- **Empty State:** Helpful message when no challenges exist

### Visual Feedback
- Flash messages for success/error
- Loading states during operations
- Smooth animations (spinner, transitions)
- Responsive design works on mobile

## Migration from Separate Pages

Previously, the admin interface was split between:
- `/admin` - Dashboard (stats and force sync)
- `/admin/challenges` - Challenge management

**Now:**
- `/admin` - Unified page with both features
- Better UX with everything in one place
- No need to navigate between pages

**Navigation Updated:**
- Admin link in navbar now goes directly to `/admin`
- All internal redirects updated to `/admin`
- Form cancel buttons return to `/admin`

## Future Enhancements

Potential improvements:

1. **Real-time Updates:** Use PubSub to update stats as jobs complete
2. **User Management:** Add user administration interface
3. **Job Cancellation:** Allow admins to cancel queued/executing jobs
4. **Scheduled Sync Management:** UI to configure cron schedule
5. **User-Specific Sync:** Force sync for individual users
6. **Sync History:** View historical sync results and trends
7. **Notifications:** Email/Slack notifications for failed syncs
8. **Tabbed Interface:** If more admin features are added, consider tabs

## Related Documentation

- [OBAN_MIGRATION.md](OBAN_MIGRATION.md) - Details about Oban setup and migration
- [LiveDashboard](http://localhost:4000/dev/dashboard) - Detailed job monitoring (dev only)
- [Oban Documentation](https://hexdocs.pm/oban) - Official Oban docs
