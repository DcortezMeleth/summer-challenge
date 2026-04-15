# SPA Migration Plan

## Can We Do It Without Changing Libs/Frameworks?

**Yes.** Phoenix LiveView is already a SPA framework by design. The migration consists
entirely of reorganizing existing code — no new dependencies, no JavaScript framework,
no changes to Tailwind/esbuild/Phoenix/LiveView versions.

---

## What "SPA" Means in a LiveView App

A classical SPA avoids full page reloads by handling routing client-side. LiveView
already does this over a persistent WebSocket connection: after the first page load the
socket stays open and only the changed DOM nodes are patched. However, three structural
issues in the current codebase prevent this SPA behaviour from being fully realised.

---

## Root Causes of Non-SPA Behaviour

### Issue 1 — Multiple `live_session` groups force WebSocket reconnects

```elixir
# router.ex (current)
live_session :public,        on_mount: {Auth, :optional}             # group A
live_session :authenticated, on_mount: {Auth, :require_authenticated} # group B
live_session :admin,         on_mount: {Auth, :require_admin}         # group C
```

Navigating *between* groups (e.g. `/leaderboard` → `/my/activities`) tears down the
WebSocket and opens a new one. The user sees a full HTML re-render and a brief blank
flash — exactly the opposite of a SPA.

**Within** a single `live_session`, navigation via `<.link navigate>` or
`push_navigate/2` is instant: no reconnect, only a DOM diff.

### Issue 2 — Nav chrome lives inside each LiveView (re-renders on every page change)

```
# Current rendering tree
Layouts.root        (HTML shell — rendered once per full page load ✓)
  Layouts.app       (flash only — rendered once per live_session ✓)
    LiveView.render (app_shell WITH nav + page content — re-renders on every nav ✗)
```

The `<.app_shell>` component — including the navbar, challenge selector, and auth
section — is embedded directly in every LiveView template. During live navigation the
entire shell is diffed and sent over the socket even though its content does not change.

In a SPA the chrome renders once and only the inner page content changes.

### Issue 3 — `/` is a traditional HTTP redirect via `PageController`

```elixir
get "/", PageController, :home   # HTTP GET → 302 → /leaderboard
```

A user arriving at `/` gets a conventional HTTP redirect *before* LiveSocket is
established. This is a minor issue (one extra round-trip on first load only) but
inconsistent with a full SPA approach.

---

## Migration Phases

### Phase 1 — Unify Live Sessions  *(High impact, Low risk)*

**Goal:** Eliminate WebSocket reconnects when navigating between public and
authenticated pages.

**Approach:** Merge `:public` and `:authenticated` into a single `live_session` with
`on_mount: {Auth, :optional}`. Protected LiveViews (`MyActivitiesLive`,
`OnboardingLive`) enforce auth themselves inside `mount/3` and redirect unauthenticated
visitors.

```elixir
# router.ex — after Phase 1
scope "/", SummerChallengeWeb do
  pipe_through :browser

  get "/", PageController, :home          # keep until Phase 3
  get "/auth/strava", ...
  get "/auth/strava/callback", ...
  delete "/auth/logout", ...

  # Single session covers both public and authenticated pages
  live_session :app, on_mount: {Auth, :optional} do
    live "/leaderboard",        LeaderboardLive,    :index
    live "/leaderboard/:sport", LeaderboardLive,    :index
    live "/milestone",          MilestoneLive,      :index
    live "/onboarding",         OnboardingLive,     :index
    live "/my/activities",      MyActivitiesLive,   :index
  end

  # Admin remains isolated (different auth level, rarely navigated to/from)
  live_session :admin, on_mount: {Auth, :require_admin} do
    live "/admin",                        Admin.ChallengesLive, :index
    live "/admin/challenges/new",         Admin.ChallengesLive, :new
    live "/admin/challenges/:id/edit",    Admin.ChallengesLive, :edit
    live "/admin/challenges/:id/clone",   Admin.ChallengesLive, :clone
  end
end
```

**Auth guards inside protected LiveViews:**

```elixir
# my_activities_live.ex — mount/3
def mount(_params, _session, socket) do
  if socket.assigns.current_scope.authenticated? do
    # ... existing logic ...
    {:ok, socket}
  else
    {:ok, push_navigate(socket, to: "/leaderboard")}
  end
end
```

`OnboardingLive` already has an equivalent guard; verify it still works.

**Files changed:** `router.ex`, `my_activities_live.ex`, `onboarding_live.ex`

**Test:** Open Network tab in browser. Navigate between Leaderboard and My Activities
while logged in — verify no new WebSocket connection is opened.

---

### Phase 2 — Persistent App Shell in the Layout  *(High impact, Medium effort)*

**Goal:** Move the nav/chrome out of individual LiveViews and into `Layouts.app/1` so
it renders exactly once per live_session connection, not on every page transition.

**How Phoenix layouts work:**

```
Layouts.root (HTML shell — only on full page load)
  Layouts.app (rendered once per live_session — THEN only diffed on navigate)
    LiveView content (only the page body)
```

The `app` layout receives **all socket assigns** (`@current_user`, `@current_scope`,
`@flash`, etc.) automatically because Phoenix LiveView passes the full socket assigns
to the layout component.

**Step 2a — Track current path via a layout hook**

Add an `attach_hook` in the auth `on_mount` (or a dedicated nav hook) to keep
`current_path` updated as the user navigates, so the layout can highlight the active
nav item without each LiveView manually assigning it.

```elixir
# hooks/auth.ex — add to existing on_mount implementations
def on_mount(:optional, _params, _session, socket) do
  socket =
    socket
    |> assign_auth(...)
    |> attach_hook(:active_path, :handle_params, fn _params, url, socket ->
      %{path: path} = URI.parse(url)
      {:cont, assign(socket, :current_path, path)}
    end)
  {:cont, socket}
end
```

**Step 2b — Expand `Layouts.app/1`**

```elixir
# components/layouts.ex
attr :flash,         :map,  required: true
attr :current_scope, :map,  default: %{authenticated?: false, is_admin: false}
attr :current_user,  :any,  default: nil
attr :current_path,  :string, default: ""

def app(assigns) do
  ~H"""
  <.flash_group flash={@flash} />
  <a href="#main-content" class="sr-only focus:not-sr-only ...">Skip to main content</a>
  <div class="sticky top-0 z-40 bg-brand-900/95 backdrop-blur-md ...">
    <div class="mx-auto max-w-5xl px-4">
      <.auth_section
        current_scope={@current_scope}
        current_user={@current_user}
        current_path={@current_path}
      />
    </div>
  </div>
  <main id="main-content" class="min-h-screen bg-gradient-to-b from-brand-50 ...">
    <%= @inner_content %>
  </main>
  """
end
```

**Step 2c — Simplify each LiveView's render**

Before:
```heex
<.app_shell>
  <:top_bar>
    <.auth_section current_scope={@current_scope} ... />
  </:top_bar>
  <:challenge_selector> ... </:challenge_selector>
  <!-- page content -->
</.app_shell>
```

After:
```heex
<div class="mx-auto max-w-5xl px-4 py-10">
  <div class="flex items-start justify-between gap-4 mb-8">
    <div class="flex-1">
      <!-- page-specific header copy -->
    </div>
    <.live_component module={ChallengeSelector} id="challenge-selector" ... />
  </div>
  <!-- page content -->
</div>
```

The `current_path` assign is no longer set in each LiveView (handled by the hook).
The `top_bar` slot is gone. The `challenge_selector` slot is replaced by a direct
inline call.

**Files changed:**
- `components/layouts.ex` — expand `app/1`
- `hooks/auth.ex` — add `attach_hook` for `:active_path`
- `live/leaderboard_live.ex` — remove `app_shell` wrapper
- `live/milestone_live.ex` — remove `app_shell` wrapper
- `live/my_activities_live.ex` — remove `app_shell` wrapper
- `live/onboarding_live.ex` — remove `app_shell` wrapper
- `live/admin/challenges_live.ex` — remove `app_shell` wrapper (keep admin session)
- `components/core_components.ex` — `app_shell` can be deprecated/removed

---

### Phase 3 — Replace PageController Route  *(Low impact, Easy)*

**Goal:** Remove the only non-LiveView route in the main flow.

**Option A (recommended) — router redirect:**

```elixir
# router.ex — replace PageController route
scope "/", SummerChallengeWeb do
  pipe_through :browser

  # Redirect / → /leaderboard at the router level, no controller needed
  get "/", Plug.Conn, :put_resp_header,  # not real — see below
end
```

Actually the cleanest approach is a tiny plug in the router pipeline, or just keeping
the controller redirect. The controller redirect still causes one extra HTTP round-trip
only on initial load when the user navigates directly to `/`. Once the LiveSocket is
open, it never fires again. This is acceptable — treat it as a low-priority polish item.

**Option B — convert to a LiveView redirect:**

```elixir
# router.ex
live_session :app, on_mount: {Auth, :optional} do
  live "/",               LeaderboardLive, :index   # simply mount leaderboard at /
  live "/leaderboard",    LeaderboardLive, :index
  ...
end
```

Then remove `PageController.home` entirely.

**Files changed:** `router.ex`, optionally delete `controllers/page_controller.ex`

---

### Phase 4 — Navigation Polish  *(Low impact, Quick win)*

**Goal:** Clean up the nav active-state logic now that `current_path` is maintained
centrally by the hook.

- `nav_item` in `core_components.ex` already uses `String.starts_with?` — no change
  needed to the component itself
- Remove all manual `assign(:current_path, ...)` lines from LiveView `mount/3` callbacks
- Verify that `attach_hook` fires correctly with `push_patch` (URL-only changes within
  the same LiveView, e.g. `/leaderboard/running_outdoor`)

---

## What Does NOT Change

| Area | Status |
|------|--------|
| Elixir / Phoenix / LiveView versions | Unchanged |
| Tailwind CSS + esbuild pipeline | Unchanged |
| `assets/js/app.js` | Unchanged |
| All context modules (Leaderboards, Activities, etc.) | Unchanged |
| Ecto schemas + migrations | Unchanged |
| Oban jobs | Unchanged |
| OAuth flow (OAuthController, Strava) | Unchanged |
| Auth hooks logic | Extended, not replaced |
| `CoreComponents` | Trimmed by removing `app_shell`, rest unchanged |
| All existing tests | Should pass without modification |

---

## File Change Checklist

### Phase 1
- [ ] `app/lib/summer_challenge_web/router.ex` — merge live_sessions
- [ ] `app/lib/summer_challenge_web/live/my_activities_live.ex` — add auth guard
- [ ] `app/lib/summer_challenge_web/live/onboarding_live.ex` — verify auth guard

### Phase 2
- [ ] `app/lib/summer_challenge_web/hooks/auth.ex` — add `attach_hook` for active path
- [ ] `app/lib/summer_challenge_web/components/layouts.ex` — expand `app/1`
- [ ] `app/lib/summer_challenge_web/live/leaderboard_live.ex` — remove `app_shell`
- [ ] `app/lib/summer_challenge_web/live/milestone_live.ex` — remove `app_shell`
- [ ] `app/lib/summer_challenge_web/live/my_activities_live.ex` — remove `app_shell`
- [ ] `app/lib/summer_challenge_web/live/onboarding_live.ex` — remove `app_shell`
- [ ] `app/lib/summer_challenge_web/live/admin/challenges_live.ex` — remove `app_shell`
- [ ] `app/lib/summer_challenge_web/components/core_components.ex` — deprecate `app_shell`

### Phase 3
- [ ] `app/lib/summer_challenge_web/router.ex` — remove/simplify `/` route
- [ ] `app/lib/summer_challenge_web/controllers/page_controller.ex` — delete or empty

### Phase 4
- [ ] All LiveViews — remove manual `assign(:current_path, ...)`

---

## Risk Assessment

| Phase | Risk Level | Key Concern | Mitigation |
|-------|-----------|-------------|------------|
| 1 — Merge sessions | Low | Protected pages bypass `on_mount` guard | Add explicit auth checks in `mount/3` |
| 2 — Persistent layout | Medium | Layout assigns not threaded correctly | Test with/without auth, test flash messages |
| 2 — `attach_hook` | Low | Hook doesn't fire on `push_patch` | Verify with leaderboard sport tabs |
| 3 — Remove controller | Low | `/` 404 if route removed carelessly | Keep controller or test route redirect first |
| 4 — Remove current_path | Very low | Nav active state breaks | Easy to revert |

---

## Definition of Done

- [ ] Navigating `/leaderboard` ↔ `/milestone` ↔ `/my/activities` produces **no new
  WebSocket connection** (verify in browser Network tab — WS frames only, no new HTTP
  request to `/live/websocket`)
- [ ] The navbar does **not** flash or disappear during page transitions
- [ ] Active nav item highlights correctly on every route
- [ ] Challenge selector persists its selection across navigation
- [ ] Auth state (logged in / logged out) renders correctly in the layout
- [ ] Admin nav item visible only for admin users
- [ ] Flash messages (info, error, warning) appear correctly on all pages
- [ ] `mix test` passes with zero failures
- [ ] `mix precommit` passes (compile, format, credo, tests)
