# View Implementation Plan — Public Leaderboards (Running + Cycling)

## 1. Overview
This feature delivers **two public (no login required) leaderboards** for a company sports challenge:
- **Running leaderboard** is the **default landing view**.
- **Cycling leaderboard** is accessible via a **toggle** that preserves the same table layout/columns.

The view renders standings derived from the **most recent completed daily sync**, displaying a **Last sync** timestamp in **Europe/Warsaw**. The UI must remain **PII-safe** (no emails, no Strava identifiers, no token status) and **desktop-first** with a simple responsive layout (no pagination expected for ~100 participants).

Implementation target: **Phoenix LiveView + Tailwind CSS**, server-rendered (no SPA).

## 2. View Routing
Recommended approach: a single LiveView with a sport param.

- **Primary**: `/leaderboard/:sport` where `:sport` is `"running" | "cycling"`
- **Default landing**: `/` redirects to `/leaderboard/running`

Alternate (acceptable): two explicit routes:
- `/leaderboard/running`
- `/leaderboard/cycling`

Route behavior:
- Invalid sport values redirect to `/leaderboard/running` (optionally with a non-blocking flash message).

## 3. Component Structure
High-level hierarchy (LiveView + function components):

```
LeaderboardLive (route: /leaderboard/:sport)
└─ <Layouts.app flash={@flash} ...>  (Phoenix v1.8 wrapper)
   └─ AppShell (header + page container)
      ├─ TopNav (brand + optional auth actions)
      ├─ SportSwitch (Running/Cycling tabs -> patch navigation)
      ├─ SyncStatusLine (last sync timestamp, Warsaw)
      ├─ ErrorBanner (optional, only when fetch fails)
      └─ LeaderboardTable
         ├─ TableCaption
         ├─ TableHeader
         └─ LeaderboardRow (repeated)
            ├─ JoinedLateBadge (optional)
            └─ MetricCells (distance/time/elevation/activities)
```

## 4. Component Details

### `SummerChallengeWeb.LeaderboardLive` (LiveView)
- **Purpose**: Entry point for public leaderboard viewing; validates `:sport` param, loads data from the domain/context, maps DTOs → render-ready view models, and renders the page.
- **Main elements**:
  - `<Layouts.app flash={@flash} current_scope={@current_scope}>` wrapper (per Phoenix v1.8 guidelines).
  - `<main>` + `<section>` container for content.
  - Renders `SportSwitch`, `SyncStatusLine`, `ErrorBanner` (optional), and `LeaderboardTable`.
- **Handled interactions**:
  - `handle_params/3` reacts to route changes (running ↔ cycling) and triggers reload.
  - Navigation uses `<.link patch={...}>` (no full page reload).
- **Handled validation (UI boundary)**:
  - **Sport allowlist**: `sport_param in ["running","cycling"]`. Invalid → redirect to running.
  - **Public data enforcement**: templates only consume safe fields (display name, team name, totals, joined-late flag, rank).
  - **Consistency**: columns identical for both sports.
- **Types**:
  - Input: `SummerChallenge.Model.Types.leaderboard_entry_dto()`
  - Output: `leaderboard_page_vm()` (see Types section)
- **Props**: none (route entrypoint).

### `AppShell` (function component)
- **Purpose**: Consistent page chrome (header + content container), aligned with desktop-first requirement.
- **Main elements**:
  - `<header>` for branding and actions.
  - Content slot container.
- **Handled interactions**: none required for MVP (optional hamburger/menu can be added later).
- **Validation**: none.
- **Types**: `Phoenix.Component.slot()`
- **Props**:
  - `:title` (optional string)
  - `:inner_block` slot

### `SportSwitch` (function component)
- **Purpose**: Toggle between Running and Cycling leaderboards; accessible segmented control.
- **Main elements**:
  - `<nav aria-label="Sport selection">`
  - Two `<.link patch={...}>` tabs with active styling + focus ring.
- **Handled interactions**:
  - Click/keyboard activation → patch navigation to the other sport path.
- **Validation**:
  - Active state derived from `current_sport` which must be one of allowed values.
- **Types**: `sport_tab_vm()`
- **Props**:
  - `:tabs` (`[sport_tab_vm()]`) (preferred: computed in LiveView)

### `SyncStatusLine` (function component)
- **Purpose**: Displays **Last sync** timestamp in **Europe/Warsaw** (or an empty-state copy when missing).
- **Main elements**:
  - `<p>` text line above the table.
- **Handled interactions**: none.
- **Validation**:
  - If `last_sync_at == nil`, show: “Last sync: not yet completed”.
  - If present, show a consistently formatted Warsaw-time string.
- **Types**:
  - Prefer passing `last_sync_label :: String.t()` (pre-formatted in pure formatter).
- **Props**:
  - `:last_sync_label` (string)

### `ErrorBanner` (function component, optional but recommended)
- **Purpose**: Non-blocking error state when leaderboard loading fails; PRD requires public leaderboard remains viewable during errors.
- **Main elements**:
  - Small inline alert panel above the table (Tailwind).
- **Handled interactions**: none.
- **Validation**:
  - Only render when `error_message` is present.
- **Types**: `String.t() | nil`
- **Props**:
  - `:error_message` (string | nil)

### `LeaderboardTable` (function component)
- **Purpose**: Semantic table for leaderboard rows; consistent columns for both sports.
- **Main elements**:
  - `<table>` with:
    - `<caption>` describing sport + last sync
    - `<thead>` with headers:
      - Position
      - Display name
      - Team
      - Total distance
      - Total moving time
      - Total elevation gain
      - Activities
      - (Joined-late icon either inline in name cell or a small indicator column)
    - `<tbody>` with `LeaderboardRow` entries
  - Empty-state panel adjacent to the table if there are no rows.
- **Handled interactions**: none.
- **Validation**:
  - If `rows == []`, show PRD empty state (see Error Handling / Empty States).
  - Units:
    - Distance displayed in **km** (storage in meters).
    - Elevation displayed in **m**.
    - Moving time displayed as a human duration.
- **Types**: `[leaderboard_row_vm()]`
- **Props**:
  - `:sport_label` ("Running" | "Cycling")
  - `:rows` (`[leaderboard_row_vm()]`)
  - `:empty_message` (string)

### `LeaderboardRow` (function component)
- **Purpose**: Render a single participant row with rank, identity, and totals.
- **Main elements**:
  - `<tr>` with cells:
    - Rank
    - Display name + optional joined-late badge
    - Team (or “—”)
    - Distance label
    - Moving time label
    - Elevation label
    - Activity count label
- **Handled interactions**: none.
- **Validation**:
  - `joined_late` only controls badge visibility; do not display `counting_started_at` publicly.
  - Team placeholder used when `team_name` is nil.
- **Types**: `leaderboard_row_vm()`
- **Props**:
  - `:row` (`leaderboard_row_vm()`)

### `JoinedLateBadge` (function component, optional)
- **Purpose**: Indicates a late joiner with a small icon and tooltip (native `title` is sufficient for MVP).
- **Main elements**:
  - `<span>` icon with `title` and screen-reader text if needed.
- **Handled interactions**:
  - Hover/focus shows tooltip.
- **Validation**:
  - Render only when `joined_late == true`.
  - Tooltip copy must match PRD rule: “Counting starts from authorization time when backfill is unavailable.”
- **Types**: boolean + `String.t()`
- **Props**:
  - `:joined_late` (boolean)
  - `:tooltip` (string)

## 5. Types
The LiveView consumes existing DTOs and maps them into view models optimized for rendering.

### Existing DTOs (inputs)
From `SummerChallenge.Model.Types`:
- **`leaderboard_entry_dto()`**:
  - `rank :: non_neg_integer()`
  - `sport_category :: "run" | "ride"`
  - `user :: user_dto()`
  - `totals :: leaderboard_totals()`
  - `last_activity_at :: DateTime.t() | nil` (not required for this table; do not render publicly unless added to PRD)
- **`user_dto()`** (publicly renderable subset):
  - `display_name :: String.t()`
  - `team_name :: String.t() | nil`
  - `joined_late :: boolean()`
  - (Do not render: `id`, `is_admin`, `team_id`, `joined_at`, `counting_started_at`, `last_synced_at`, `last_sync_error`)
- **`leaderboard_totals()`**:
  - `distance_m :: non_neg_integer()`
  - `moving_time_s :: non_neg_integer()`
  - `elev_gain_m :: non_neg_integer()`
  - `activity_count :: non_neg_integer()`

### New ViewModels (render-ready)
Define in `SummerChallengeWeb.ViewModels.Leaderboard` (preferred) or inside the LiveView module.

#### `sport_tab_vm()`
- **Fields**:
  - `id :: :running | :cycling`
  - `label :: String.t()` ("Running" | "Cycling")
  - `to :: String.t()` (path like `/leaderboard/running`)
  - `active :: boolean()`

#### `leaderboard_row_vm()`
- **Fields**:
  - `rank :: non_neg_integer()`
  - `display_name :: String.t()`
  - `team_name :: String.t()` (already resolved; “—” when missing)
  - `joined_late :: boolean()`
  - `distance_label :: String.t()` (e.g., "42.3 km")
  - `moving_time_label :: String.t()` (e.g., "12:34:56")
  - `elev_gain_label :: String.t()` (e.g., "1,234 m")
  - `activity_count_label :: String.t()` (e.g., "17")

#### `leaderboard_page_vm()`
- **Fields**:
  - `sport :: :running | :cycling`
  - `sport_label :: String.t()`
  - `tabs :: [sport_tab_vm()]`
  - `last_sync_label :: String.t()`
  - `rows :: [leaderboard_row_vm()]`
  - `empty? :: boolean()`
  - `empty_message :: String.t()`
  - `error_message :: String.t() | nil`

### Formatting utilities (pure functions)
Create a small pure module (recommended): `SummerChallengeWeb.Formatters`.

Required helpers:
- `format_km(distance_m :: non_neg_integer()) :: String.t()`
  - meters → km, consistent rounding (PRD: “reasonable precision”).
- `format_duration(seconds :: non_neg_integer()) :: String.t()`
  - seconds → "H:MM:SS" (or "HH:MM" if you decide; keep consistent across pages).
- `format_meters(meters :: non_neg_integer()) :: String.t()`
  - include thousands separators; suffix " m".
- `format_warsaw_datetime(dt :: DateTime.t() | nil) :: String.t()`
  - `nil` → “Last sync: not yet completed”
  - otherwise convert to `"Europe/Warsaw"` and format consistently.

## 6. State Management
Use LiveView assigns as the state store:
- `:page :: leaderboard_page_vm()`
- Optional: `:loading? :: boolean()` (if data loads asynchronously later)

Derived state:
- `tabs` derived from `page.sport`
- `empty?` derived from `rows == []`

No JS hooks required for MVP (tooltips can use `title`).

## 7. API Integration
The view should call a **context boundary** function (server-side) rather than a client API call.

### Recommended context contract
Add or use:
- `SummerChallenge.Leaderboards.get_public_leaderboard(sport_category :: "run" | "ride") ::
   {:ok, %{entries: [SummerChallenge.Model.Types.leaderboard_entry_dto()], last_sync_at: DateTime.t() | nil}}
   | {:error, term()}`

### LiveView integration flow
On initial mount and whenever `:sport` param changes:
1. Validate `sport_param` ∈ {"running","cycling"}.
2. Map to `sport_category`:
   - `"running"` → `"run"`
   - `"cycling"` → `"ride"`
3. Call `get_public_leaderboard/1`.
4. Map DTOs → `leaderboard_row_vm()` list:
   - Use formatter helpers for labels.
   - Resolve `team_name` placeholder (“—”).
5. Format `last_sync_at` into `last_sync_label` (Warsaw).
6. Assign `:page` with `error_message = nil`.

On error (`{:error, reason}`):
- Keep page shell visible.
- Set `error_message` to a generic message.
- Use `empty_message` / existing rows as appropriate.
- Log `reason` server-side (ensure no PII/tokens are logged).

## 8. User Interactions
- **Open leaderboard (default)**:
  - Visiting `/` redirects to `/leaderboard/running`.
  - Running leaderboard renders without authentication.
- **Switch sport**:
  - Clicking “Cycling” tab navigates via patch to `/leaderboard/cycling`.
  - Clicking “Running” tab navigates back to `/leaderboard/running`.
  - Table columns remain identical; only data changes.
- **Keyboard navigation**:
  - Sport tabs are reachable via Tab/Shift+Tab.
  - Enter/Space activates the patch link.
- **Joined-late tooltip (if badge enabled)**:
  - Hover/focus the badge to see the tooltip text.

## 9. Conditions and Validation
- **Sport selection allowlist**:
  - Enforced in `handle_params/3`.
  - Invalid → redirect to running; optional flash.
- **Public data only (privacy)**:
  - Template must not render IDs, emails, Strava identifiers, tokens, or sync error details.
  - Only render: rank, display name, team name, totals, joined-late indicator.
- **Most recent completed sync**:
  - View displays `last_sync_at` from the same data source used to produce the leaderboard totals.
- **Units and rounding**:
  - Distances shown in km (from meters) with consistent rounding.
  - Elevation shown in meters.
  - Duration shown in a consistent "H:MM:SS" (or chosen) format.
- **Ties**:
  - Ties are allowed; UI shows the `rank` provided (no tie-break logic in the view).
- **No pagination**:
  - Render full list (expected ~100 participants).

## 10. Error Handling
- **Leaderboard fetch failure**:
  - Render `ErrorBanner` with: “Unable to load leaderboard right now. Please try again later.”
  - Keep the rest of the page visible (PRD: public leaderboard remains viewable during errors).
- **No last sync yet**:
  - Show “Last sync: not yet completed”.
  - If also no rows: show empty state message below.
- **Empty state (no rows)**:
  - Show: “No results yet; check back after the first sync.”
  - This covers “before challenge starts / before first sync” expectations.
- **Malformed sport param**:
  - Redirect to running; optional flash “Unknown sport; showing running leaderboard.”

## 11. Implementation Steps
1. **Routing**
   - Add LiveView route(s) for `/leaderboard/:sport`.
   - Add redirect `/` → `/leaderboard/running`.
2. **LiveView**
   - Implement `SummerChallengeWeb.LeaderboardLive` with `mount/3`, `handle_params/3`, and `render/1`.
   - Ensure template begins with `<Layouts.app flash={@flash} ...>`.
3. **Context integration**
   - Ensure a public context function exists (recommended: `SummerChallenge.Leaderboards.get_public_leaderboard/1`) returning the DTOs + `last_sync_at`.
4. **View models + formatters**
   - Create `SummerChallengeWeb.ViewModels.Leaderboard` structs/typespecs.
   - Create `SummerChallengeWeb.Formatters` for km/duration/meters/Warsaw datetime.
5. **Function components**
   - Add `AppShell`, `SportSwitch`, `SyncStatusLine`, `ErrorBanner`, `LeaderboardTable`, `LeaderboardRow`, `JoinedLateBadge`.
6. **Accessibility and semantics pass**
   - Use `<caption>`, `<th scope="col">`, and visible focus states for tabs.
   - Ensure the joined-late badge has accessible text/tooltip via `title`.
7. **Acceptance criteria verification (US-003/US-004)**
   - Running is default and public.
   - Toggle switches to cycling and shows same columns.
   - Last sync timestamp is shown (Warsaw time).
   - Joined-late icon displays for relevant users.

