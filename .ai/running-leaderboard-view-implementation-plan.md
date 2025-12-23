# View Implementation Plan — Running Leaderboard (Public)

## 1. Overview
The **Running Leaderboard** is a **public (no login required)** view that shows participant standings for the **running** sport category, aggregated from included challenge activities as of the **most recent completed sync**. The view is also responsible for providing a **toggle to switch to the Cycling leaderboard**, while keeping the table layout/columns consistent between sports.

This plan targets **Phoenix LiveView + Tailwind CSS** (per tech stack), using server-rendered state and LiveView navigation rather than a client SPA.

## 2. View Routing
- **Primary route (default landing)**: `/leaderboard/running`
- **Secondary route (toggle target)**: `/leaderboard/cycling`
- **Optional/Recommended consolidation**: `/leaderboard/:sport` where `:sport` is `"running" | "cycling"`
  - Redirect `/` → `/leaderboard/running` (to satisfy “Running by default”).

## 3. Component Structure
High-level hierarchy (LiveView + function components):

```
LeaderboardLive (route: /leaderboard/:sport)
└─ AppShell (layout wrapper; header + nav)
   ├─ TopNav
   │  ├─ Brand
   │  └─ AuthActions (optional placeholder in MVP if auth not implemented yet)
   ├─ SportSwitch (Running/Cycling links)
   ├─ SyncStatusLine (last sync timestamp)
   └─ LeaderboardTable
      ├─ TableCaption
      ├─ TableHeader
      └─ LeaderboardRow (repeated)
         ├─ JoinedLateBadge (icon + tooltip)
         └─ MetricsCells (distance/time/elevation/count)
```

## 4. Component Details
### `SummerChallengeWeb.LeaderboardLive` (LiveView)
- **Purpose**: Orchestrates routing (`:sport` param), loads leaderboard data from the domain/context, and renders the page using function components.
- **Main elements**:
  - `<main>` container (Tailwind layout)
  - `<section>` wrapping the leaderboard content
  - Renders `SportSwitch`, `SyncStatusLine`, `LeaderboardTable`
- **Handled events**:
  - **`handle_params/3`**: reacts to URL changes (`/leaderboard/running` ↔ `/leaderboard/cycling`) and triggers data load.
  - **Optional `handle_event("refresh", ...)`**: _not_ required for US-003/004 (public view), but can be a future enhancement.
- **Validation conditions**:
  - **Sport param allowlist**: only `"running"` and `"cycling"` are valid.
    - Invalid/unknown values: redirect to `/leaderboard/running` and (optional) flash `"Unknown sport; showing running leaderboard"`.
  - **Data safety**:
    - Never render PII: **no emails**, no Strava IDs, no token status.
    - Only render fields from DTOs needed for table columns.
- **Types used**:
  - `SummerChallenge.Model.Types.leaderboard_entry_dto/0`
  - `SummerChallenge.Model.Types.user_dto/0`
  - `SummerChallenge.Model.Types.leaderboard_totals/0`
  - **New ViewModels** (defined in this plan; see Types section):
    - `sport_tab_vm`
    - `leaderboard_page_vm`
    - `leaderboard_row_vm`
- **Props**: none (route entrypoint).

### `AppShell` (function component)
- **Purpose**: Provides consistent application chrome: header/top nav and a content slot. (PRD/UI plan mentions “app shell + hamburger menu”.)
- **Main elements**:
  - `<header>` with brand + optional nav button
  - `<div>` content container slot
- **Handled events**:
  - Optional: hamburger open/close (if implemented now). Not required for the leaderboard MVP.
- **Validation conditions**: none.
- **Types**:
  - `Phoenix.Component.slot()`
- **Props**:
  - `:title` (string, optional; e.g., “Leaderboard”)
  - `:current_user` (optional future use)
  - `:inner_block` slot

### `SportSwitch` (function component)
- **Purpose**: Toggle between Running and Cycling leaderboards, accessible and keyboard-friendly.
- **Main elements**:
  - `<nav aria-label="Sport selection">`
  - Two `<.link patch={...}>` (or `<a>` if not using LiveView patch) styled as segmented control.
- **Handled events**:
  - Navigation via LiveView patch:
    - Running → `push_patch`/`<.link patch>` to `/leaderboard/running`
    - Cycling → `push_patch`/`<.link patch>` to `/leaderboard/cycling`
- **Validation conditions**:
  - Current sport must be one of allowed values to compute active styles.
- **Types**:
  - `sport_tab_vm` (contains label, path, active flag)
- **Props**:
  - `:current_sport` (`:running | :cycling` as atom in VM)
  - `:tabs` (`[sport_tab_vm]`) OR compute tabs internally from `:current_sport`

### `SyncStatusLine` (function component)
- **Purpose**: Displays “Last sync: …” in **Europe/Warsaw** (PRD/UI plan requirement).
- **Main elements**:
  - `<p>` with timestamp
  - If missing: “Last sync: not yet completed”
- **Handled events**: none.
- **Validation conditions**:
  - If `last_sync_at` is `nil`, render empty state copy.
  - Ensure timezone conversion and formatting is consistent across the app.
- **Types**:
  - `DateTime.t() | nil`
  - `leaderboard_page_vm` (preferred: pass pre-formatted string to avoid formatting logic in template)
- **Props**:
  - `:last_sync_label` (string; already formatted)
  - OR `:last_sync_at` (`DateTime.t() | nil`) + `:timezone` ("Europe/Warsaw")

### `LeaderboardTable` (function component)
- **Purpose**: Renders the leaderboard as a semantic HTML table with the columns defined in PRD.
- **Main elements**:
  - `<table>` with:
    - `<caption>` describing current sport + last sync
    - `<thead>` with column headers:
      - Position
      - Display name
      - Team
      - Total distance
      - Total moving time
      - Total elevation gain
      - Activities
      - (Optional) Joined late indicator column or inline in name cell
    - `<tbody>` with repeated `LeaderboardRow`
- **Handled events**: none (read-only).
- **Validation conditions**:
  - If `rows == []`, show a **table-adjacent empty state**:
    - “No results yet; check back after the first sync.”
  - Ensure totals are displayed in **km** and **m** per PRD (storage is meters/seconds).
- **Types**:
  - `[leaderboard_row_vm]`
- **Props**:
  - `:sport_label` ("Running" | "Cycling")
  - `:rows` (`[leaderboard_row_vm]`)
  - `:empty_state_message` (string)

### `LeaderboardRow` (function component)
- **Purpose**: Renders a single participant row.
- **Main elements**:
  - `<tr>`
  - Cells:
    - Rank
    - Display name + joined-late badge (if applicable)
    - Team name (or “—”)
    - Distance (km)
    - Moving time (hh:mm or hh:mm:ss)
    - Elev gain (m)
    - Activity count
- **Handled events**: none.
- **Validation conditions**:
  - Joined late badge shown only when `row.joined_late == true`.
  - Team cell: if `team_name == nil`, render placeholder.
- **Types**:
  - `leaderboard_row_vm`
- **Props**:
  - `:row` (`leaderboard_row_vm`)

### `JoinedLateBadge` (function component)
- **Purpose**: Indicates late joiners (PRD mentions an icon + tooltip; even if the PRD later says “out of scope”, the user stories reference it—implement as optional).
- **Main elements**:
  - `<span>` icon with `title` and/or accessible tooltip pattern.
- **Handled events**: none.
- **Validation conditions**:
  - Render only when `joined_late == true`.
- **Types**:
  - boolean
- **Props**:
  - `:tooltip` (string; copy should match PRD rule)

## 5. Types
This project already defines backend DTO types in `SummerChallenge.Model.Types`. The LiveView should treat them as **input DTOs** and map them into **ViewModels** optimized for rendering (strings already formatted, placeholders resolved, etc.).

### Existing DTOs (from `SummerChallenge.Model.Types`)
- **`leaderboard_entry_dto`**:
  - `rank :: non_neg_integer()`
  - `sport_category :: "run" | "ride"`
  - `user :: user_dto`
  - `totals :: leaderboard_totals`
  - `last_activity_at :: DateTime.t() | nil`
- **`user_dto`** (fields relevant to this view):
  - `display_name :: String.t()`
  - `team_name :: String.t() | nil`
  - `joined_late :: boolean()`
  - (Other fields exist; must not be rendered publicly)
- **`leaderboard_totals`**:
  - `distance_m :: non_neg_integer()`
  - `moving_time_s :: non_neg_integer()`
  - `elev_gain_m :: non_neg_integer()`
  - `activity_count :: non_neg_integer()`

### New ViewModels (recommend adding in `SummerChallengeWeb.ViewModels.Leaderboard` or inside the LiveView module)
Define these as maps/structs (struct preferred for clarity).

#### `sport_tab_vm`
- **Purpose**: render-ready data for the sport switch control.
- **Fields**:
  - `id :: :running | :cycling`
  - `label :: String.t()` (e.g., "Running")
  - `to :: String.t()` (route path)
  - `active :: boolean()`

#### `leaderboard_row_vm`
- **Purpose**: a single row with formatted strings and safe public fields only.
- **Fields**:
  - `rank :: non_neg_integer()`
  - `display_name :: String.t()`
  - `team_name :: String.t()` (already resolved; use "—" when missing)
  - `joined_late :: boolean()`
  - `distance_label :: String.t()` (e.g., "42.3 km")
  - `moving_time_label :: String.t()` (e.g., "12:34:56")
  - `elev_gain_label :: String.t()` (e.g., "1,234 m")
  - `activity_count_label :: String.t()` (e.g., "17")

#### `leaderboard_page_vm`
- **Purpose**: page-level rendering state.
- **Fields**:
  - `sport :: :running | :cycling`
  - `sport_label :: String.t()` ("Running"/"Cycling")
  - `tabs :: [sport_tab_vm]`
  - `last_sync_label :: String.t()` (already formatted for Europe/Warsaw)
  - `rows :: [leaderboard_row_vm]`
  - `empty? :: boolean()`
  - `empty_message :: String.t()`
  - `error_message :: String.t() | nil`

### Formatting utilities (pure functions; “functional core”)
Create small pure helpers (module suggested: `SummerChallengeWeb.Formatters`):
- `format_km(distance_m :: non_neg_integer()) :: String.t()`
  - Convert meters → km with consistent rounding (e.g., 1 decimal or 2 decimals).
- `format_duration(moving_time_s :: non_neg_integer()) :: String.t()`
  - Seconds → "H:MM:SS" (or "HH:MM" if desired, but be consistent with PRD “moving time”).
- `format_meters(elev_gain_m :: non_neg_integer()) :: String.t()`
  - Add thousands separators.
- `format_warsaw_datetime(dt :: DateTime.t() | nil) :: String.t()`
  - Convert to "Europe/Warsaw" and format, e.g., "2025-12-23 00:05 CET".

## 6. State Management
Use LiveView assigns as the state store (no client-side store required).

### LiveView assigns (suggested)
- `:page :: leaderboard_page_vm`
- `:loading? :: boolean()` (optional; useful if you later load asynchronously)

### Derived state
- `tabs` derived from `:page.sport`
- `empty?` derived from `rows == []`

### Hooks
No custom JS hooks required for MVP.
- For tooltip: start with native `title` attribute for accessibility. If you later need richer tooltips, add a small Phoenix hook (but keep MVP simple).

## 7. API Integration
Because the stack is Phoenix LiveView, the “frontend API call” is typically a **server-side call to a context function** during `mount/3` or `handle_params/3`.

### Required domain/context functions (define in backend; LiveView consumes)
Create a public API module (context boundary) that returns the DTOs defined in `SummerChallenge.Model.Types`.

Suggested interface:
- `SummerChallenge.Leaderboards.get_public_leaderboard(sport_category :: "run" | "ride") :: {:ok, %{entries: [leaderboard_entry_dto], last_sync_at: DateTime.t() | nil}} | {:error, term()}`

### LiveView integration flow
- On first render and on sport changes:
  - Validate sport param → map to `"run" | "ride"`
  - Call `get_public_leaderboard/1`
  - Map DTOs → `leaderboard_row_vm` list
  - Format `last_sync_at` → `last_sync_label`
  - Assign `:page`

### Request/Response types (at the LiveView boundary)
- **Request**: `sport_param :: String.t()` from route (e.g., `"running"`)
- **Response**:
  - `{:ok, %{entries: [SummerChallenge.Model.Types.leaderboard_entry_dto()], last_sync_at: DateTime.t() | nil}}`
  - or `{:error, reason}`

*(If you later add a JSON endpoint, it should mirror the same DTO shape; for MVP, prefer LiveView/context calls.)*

## 8. User Interactions
- **Switch sport**
  - **Action**: click “Cycling” tab
  - **Expected outcome**:
    - URL updates to `/leaderboard/cycling` (patch navigation)
    - Table rerenders with cycling totals
    - Columns remain identical
- **Keyboard navigation**
  - **Action**: Tab/Shift+Tab through sport switch links
  - **Expected outcome**: visible focus ring; Enter triggers navigation
- **Joined-late tooltip**
  - **Action**: hover/focus the badge
  - **Expected outcome**: tooltip text explaining counting rule (or simple title)

## 9. Conditions and Validation
Conditions verified by the interface (and how they affect UI):
- **Sport selection**
  - **Condition**: `sport_param in ["running", "cycling"]`
  - **Component**: `LeaderboardLive`
  - **Effect**:
    - Valid: load appropriate leaderboard.
    - Invalid: redirect to running; optional flash.
- **Public data only**
  - **Condition**: render only allowed fields (display name, team name, totals, joined_late).
  - **Components**: `LeaderboardTable`, `LeaderboardRow`
  - **Effect**: prevents accidental PII leakage.
- **Units display**
  - **Condition**: distance shown in km, elevation in m, moving time in a human format.
  - **Components**: `LeaderboardRow` (via formatter utilities)
  - **Effect**: consistent UX across views.
- **Empty state**
  - **Condition**: `rows == []`
  - **Component**: `LeaderboardTable`
  - **Effect**: show message: “No results yet; check back after the first sync.”

## 10. Error Handling
Potential errors and handling strategy:
- **Leaderboard fetch failure** (`{:error, reason}`)
  - Show a non-blocking error panel above table:
    - “Unable to load leaderboard right now. Please try again later.”
  - Keep page shell visible.
  - Log server-side reason (avoid PII).
- **No last sync timestamp** (`last_sync_at == nil`)
  - Render `SyncStatusLine` as “Last sync: not yet completed”
  - Show empty state if also `rows == []`.
- **Malformed sport param**
  - Redirect to running, optional flash.
- **Inconsistent DTO data** (defensive)
  - If `entry.sport_category` doesn’t match selected category, drop it (or trust server; prefer trusting server but keep a guard in mapping).

## 11. Implementation Steps
1. **Add routes**
   - Add LiveView routes for `/leaderboard/running` and `/leaderboard/cycling` (or `/leaderboard/:sport`) in `SummerChallengeWeb.Router`.
   - Redirect `/` to `/leaderboard/running` (replace the hardcoded HTML home).
2. **Create the LiveView**
   - Add `lib/summer_challenge_web/live/leaderboard_live.ex` with `mount/3`, `handle_params/3`, and render function.
3. **Add UI components**
   - Add function components in `lib/summer_challenge_web/components/`:
     - `app_shell.ex` (or keep inline until broader app exists)
     - `leaderboard_components.ex` containing `sport_switch/1`, `sync_status_line/1`, `leaderboard_table/1`, `leaderboard_row/1`, `joined_late_badge/1`
4. **Add formatting helpers**
   - Create `SummerChallengeWeb.Formatters` with `format_km/1`, `format_duration/1`, `format_meters/1`, `format_warsaw_datetime/1`.
5. **Define ViewModels**
   - Create `SummerChallengeWeb.ViewModels.Leaderboard` (structs) OR define them as maps with typespecs in the LiveView module.
6. **Integrate data source**
   - Call `SummerChallenge.Leaderboards.get_public_leaderboard/1`.
   - Map DTOs to row VMs and assign into `:page`.
7. **Accessibility + semantics pass**
   - Ensure table uses `<caption>`, `<th scope="col">`, visible focus styles on sport tabs, and no color-only state indicators.
8. **Verify acceptance criteria**
   - Running is default landing.
   - Toggle switches to cycling.
   - Last sync is displayed (Warsaw time).
   - Columns match PRD for both sports.

