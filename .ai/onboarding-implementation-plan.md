# View Implementation Plan — Onboarding (First Login)

## 1. Overview
The **Onboarding** view (`/onboarding`) is the **first-login, authenticated** step that converts a newly authorized Strava user into an active challenge participant. It:

- Collects and validates a **required display name** (length 1–80).
- Shows **Terms/Privacy notice** with links; **acceptance is implied by continuing**.
- Completes onboarding (persist display name + join metadata), then navigates back to the originally intended destination (e.g. public leaderboard) using an **allowlisted return path** to prevent open redirects.

This plan targets **Phoenix LiveView (Phoenix v1.8) + Tailwind CSS** with server-rendered state and `phx-submit` events (no SPA, no React).

## 2. View Routing
### Route
- **Path**: `/onboarding`
- **Access**: **authenticated-only**

### Router + authenticated session requirements
Because this view depends on a logged-in user, routes should be placed under an authenticated `live_session` that assigns `current_scope` (per project guidelines).

Recommended structure:
- Public routes remain in a public `live_session`.
- Authenticated routes go in a separate `live_session :authenticated` with an `on_mount` hook that:
  - loads the current user from session,
  - assigns `:current_scope` (and ideally `:current_user`/`user_dto`),
  - redirects unauthenticated users back to `/leaderboard/running` with a flash.

### Return path
Support an optional return path parameter:
- **Query param**: `return_to=/leaderboard/running` (or stored in session during OAuth entry)
- **Security**: only allowlisted in-app paths; reject anything with scheme/host or `//`.

## 3. Component Structure
High-level hierarchy (LiveView + function components):

```
OnboardingLive (route: /onboarding)
└─ <Layouts.app flash={@flash} current_scope={@current_scope}>
   └─ OnboardingShell
      └─ OnboardingCard
         ├─ OnboardingHeader
         ├─ DisplayNameForm
         │  ├─ <.input> (display_name)
         │  ├─ InlineError (field + submit errors)
         │  └─ PrimaryButton ("Continue")
         └─ TermsPrivacyNotice (inline)
```

## 4. Component Details

### `SummerChallengeWeb.OnboardingLive` (LiveView)
- **Purpose**: Orchestrates onboarding for first login: loads current user, prepares display name form, validates + saves, and navigates to a safe return destination.
- **Main elements**:
  - Must render inside `<Layouts.app flash={@flash} current_scope={@current_scope}>` (Phoenix v1.8 guideline).
  - Page container (centered card; desktop-first, responsive).
  - Renders `DisplayNameForm` and `TermsPrivacyNotice`.
- **Handled events**:
  - `handle_params/3`:
    - parses + sanitizes `return_to`,
    - redirects away if user is already onboarded (see conditions below).
  - `handle_event("validate", %{"onboarding" => params}, socket)`:
    - runs lightweight validation on the display name (length only; plus trimming/blank handling).
  - `handle_event("submit", %{"onboarding" => params}, socket)`:
    - persists onboarding completion (display name + join metadata),
    - on success: `push_navigate` to safe `return_to` (or default leaderboard),
    - on failure: re-renders with inline errors and focuses the invalid field.
- **Validation conditions (UI boundary)**:
  - **Display name required**:
    - after trimming, length is in `1..80`,
    - treat whitespace-only as empty (error),
    - show a clear inline error: `"Display name must be between 1 and 80 characters."`
  - **Open redirect prevention**:
    - `return_to` must be a **relative path** starting with `/`,
    - must not start with `//`,
    - must match an allowlist of known in-app paths (see Types section).
  - **First-login only**:
    - If current user already has a valid `display_name` and is already “joined” (see API conditions), redirect to `return_to` or `/leaderboard/running`.
- **Types used**:
  - Input/current user: `SummerChallenge.Model.Types.user_dto()`
  - Command: `SummerChallenge.Model.Types.update_display_name_command()`
  - New view models: `onboarding_page_vm()`, `onboarding_form_vm()` (defined in Types section)
- **Props**: none (route entrypoint).

### `OnboardingShell` (function component, can live in `core_components.ex` or a new `components/onboarding_components.ex`)
- **Purpose**: Layout wrapper for the onboarding page content (centering, max width, consistent spacing).
- **Main elements**:
  - `<main role="main">` and a centered `<section>`
  - uses Tailwind for spacing (`max-w-lg`, `mx-auto`, `py-10`, etc.)
- **Handled events**: none.
- **Validation**: none.
- **Types**: `Phoenix.Component.slot()`
- **Props**:
  - `:inner_block` slot

### `OnboardingCard` (function component)
- **Purpose**: Card UI presenting the onboarding flow as a single step.
- **Main elements**:
  - `<div class="rounded-2xl bg-white/90 ring-1 ... shadow-sport p-6">`
  - includes `OnboardingHeader`, `DisplayNameForm`, `TermsPrivacyNotice`
- **Handled events**: none.
- **Validation**: none.
- **Types**: none.
- **Props**:
  - `:inner_block` slot (or explicit child components)

### `OnboardingHeader` (function component)
- **Purpose**: Primary copy and brief instructions.
- **Main elements**:
  - `<h1>`: “You are joining the challenge.”
  - `<p>`: short helper text (e.g., “Choose a name that will appear on the public leaderboard.”)
- **Handled events**: none.
- **Validation**: none.
- **Types**: none.
- **Props**: none.

### `DisplayNameForm` (function component)
- **Purpose**: Collect and submit the display name.
- **Main elements**:
  - `<.form for={@form} phx-change="validate" phx-submit="submit">`
  - `<.input type="text" field={@form[:display_name]} ...>` (must use `<.input>` per project guidelines)
  - inline error rendering (use `<Layouts.error field={@form[:display_name]} />` or an equivalent error component available to the template)
  - submit button “Continue” (disabled while saving)
- **Handled events**:
  - `"validate"` (on change) — optional; recommended for immediate feedback
  - `"submit"` — final validation + save
- **Validation conditions**:
  - Display name in `1..80` after trimming
  - Prevent double-submit (disable button while saving)
- **Types**:
  - `Phoenix.HTML.Form.t()` (or `Phoenix.Component.form/1` assigns)
  - `onboarding_form_vm()` (wrapper providing `form`, `saving?`, `error_message`)
- **Props**:
  - `:form` (required) — the `Phoenix.HTML.Form` for display name
  - `:saving?` (required boolean)
  - `:submit_label` (optional string; default “Continue”)
  - `:form_id` (optional string; stable DOM id for focus management)

### `TermsPrivacyNotice` (function component)
- **Purpose**: Inline Terms/Privacy notice; informs users that continuing implies acceptance.
- **Main elements**:
  - `<p>` with links:
    - “By continuing you agree to our Terms and Privacy Policy.”
  - `<.link navigate={...}>` if internal routes exist, or `<a href="..." target="_blank" rel="noreferrer">` if external/static.
- **Handled events**: none.
- **Validation**: none (acceptance implied by submit).
- **Types**:
  - `terms_links_vm()` (optional; see Types section)
- **Props**:
  - `:terms_href` (string)
  - `:privacy_href` (string)

## 5. Types
This section defines the **DTOs already present** and the **additional view-model types** needed to implement Onboarding cleanly.

### Existing DTOs / commands (already defined)
- `SummerChallenge.Model.Types.user_dto()`:
  - used to determine whether the user is already onboarded and to prefill display name.
- `SummerChallenge.Model.Types.update_display_name_command()`:
  - `%{user_id: uuid(), display_name: String.t()}`

### New view models (add to `SummerChallengeWeb.ViewModels.Onboarding` or similar)

#### `onboarding_page_vm()`
Render-ready data for the Onboarding page.

- `@type onboarding_page_vm :: %{
    page_title: String.t(),
    return_to: safe_return_to_path(),
    form: onboarding_form_vm(),
    terms: terms_links_vm()
  }`

Notes:
- `return_to` must already be sanitized to a safe value.
- `page_title` should be “Onboarding” or “Join the challenge”.

#### `onboarding_form_vm()`
State for the onboarding form.

- `@type onboarding_form_vm :: %{
    form: Phoenix.HTML.Form.t(),
    saving?: boolean(),
    submit_error: String.t() | nil,
    focus_field: :display_name | nil
  }`

Notes:
- `focus_field` is used to drive focus management after validation failures.

#### `terms_links_vm()`
Configurable links for the notice.

- `@type terms_links_vm :: %{
    terms_href: String.t(),
    privacy_href: String.t()
  }`

Notes:
- If terms/privacy pages aren’t implemented yet, these can point to placeholders or static content routes.

#### `safe_return_to_path()`
Constrained, allowlisted return destinations (open redirect protection).

- `@type safe_return_to_path :: String.t()`

Required allowlist (minimum):
- `/leaderboard/running`
- `/leaderboard/cycling`
- `/milestone` (if implemented)
- `/my/activities` (future)
- `/teams` (future)
- `/settings` (future)
- `/admin` (future; admins only)

Rule:
- If `return_to` is missing or invalid, default to `/leaderboard/running`.

## 6. State Management
Use standard LiveView assigns (no custom hooks).

### Recommended assigns
- `:current_scope` — assigned by authenticated `live_session` hook (required by layout guideline).
- `:current_user` — `Types.user_dto()` (or a minimal subset), used to:
  - decide if onboarding is necessary,
  - prefill display name.
- `:return_to` — sanitized `safe_return_to_path()`.
- `:changeset` — changeset backing the display name form (recommended; enables inline errors cleanly).
- `:saving?` — boolean to disable the submit while in-flight.

### Prefill behavior
- Prefill `display_name` from the current user’s stored `display_name` if present; otherwise leave blank.

## 7. API Integration
This app is LiveView-first; “API calls” are **server-side context calls** executed in LiveView event handlers.

### Required context function(s)
Add/ensure a domain boundary (recommended: `SummerChallenge.Accounts`) with a single public onboarding completion function.

Recommended public API:

- `complete_onboarding/1`
  - **Request**: `complete_onboarding_command()`
  - **Response**:
    - `{:ok, Types.user_dto()}` on success
    - `{:error, Ecto.Changeset.t()}` for validation errors
    - `{:error, term()}` for unexpected failures

Suggested command shape (new type; can be in `SummerChallenge.Model.Types`):
- `%{
    user_id: uuid(),
    display_name: String.t(),
    accepted_terms: boolean(),
    return_to: safe_return_to_path() | nil
  }`

Persistence expectations (per PRD/UI plan):
- Always update `users.display_name`.
- Mark onboarding completion:
  - set `users.joined_at` (if nil) to now,
  - optionally store `accepted_terms_at` (new field) or store implied acceptance with `joined_at` if you want MVP-minimal.

## 8. User Interactions
- **Typing display name**
  - On change: validates length and shows inline error (optional but recommended).
  - Does not navigate.
- **Submitting “Continue”**
  - When valid:
    - saves onboarding completion
    - navigates to safe return destination
  - When invalid:
    - shows inline error under the input
    - focuses the display name input
  - While saving:
    - disable the button and input to prevent double submit.
- **Opening Terms/Privacy links**
  - Opens Terms/Privacy content without losing form state (prefer `target="_blank"` if external).

## 9. Conditions and Validation
### Conditions verified by the interface
- **Display name constraints (client-visible)**
  - `trim(display_name)` length is `1..80`.
  - Whitespace-only is invalid.
- **Authenticated-only**
  - If no authenticated user in `current_scope`, redirect to `/leaderboard/running` with flash: “Please sign in to continue.”
- **Return path safety**
  - Use allowlist (see `safe_return_to_path/0`).
  - Never accept absolute URLs or `//` prefixed paths.

### How these conditions affect interface state
- Invalid display name:
  - `form_vm.submit_error` remains nil; field-level error is shown
  - `form_vm.focus_field = :display_name`
  - button remains enabled after render
- Unauthenticated:
  - user is redirected; onboarding UI is not shown
- Invalid `return_to`:
  - silently default to `/leaderboard/running`

## 10. Error Handling
Potential error scenarios and handling:

- **Validation error (display name too short/long/blank)**:
  - show inline error via form errors
  - focus input
- **Persistence failure (DB error, unexpected exception)**:
  - show flash error: “Could not complete onboarding. Please try again.”
  - keep user on page with input preserved
- **Stale/invalid session (user missing)**:
  - redirect to `/leaderboard/running` with flash: “Session expired. Please sign in again.”
- **Return path not allowlisted**:
  - ignore and fallback to `/leaderboard/running` (no need to warn)

## 11. Implementation Steps
1. **Add routing**
   - Add `live "/onboarding", OnboardingLive, :index` under an authenticated `live_session`.
   - Ensure the session hook assigns `:current_scope` and enforces auth.
2. **Create `OnboardingLive`**
   - Implement `mount/3` (load current user, initialize changeset/form).
   - Implement `handle_params/3` to sanitize `return_to` and redirect away when already onboarded.
   - Implement `handle_event("validate", ...)` and `handle_event("submit", ...)`.
3. **Add ViewModel module**
   - Create `SummerChallengeWeb.ViewModels.Onboarding` defining the view model types and helpers:
     - `sanitize_return_to/1`
     - `build_page/…`
4. **Add/ensure domain API**
   - Introduce `SummerChallenge.Accounts.complete_onboarding/1` (or equivalent) that:
     - validates display name,
     - updates `users.display_name`,
     - sets onboarding metadata (`joined_at`, terms acceptance).
5. **Build UI components**
   - Implement `OnboardingShell`, `OnboardingCard`, `DisplayNameForm`, `TermsPrivacyNotice` as function components.
   - Use `<.input>` for the text field and an inline error component consistent with existing styles.
6. **Focus management**
   - Add JS focus behavior after failed submit (e.g., conditional `phx-mounted={JS.focus(...)}` when `focus_field == :display_name`).
7. **Verify end-to-end flow**
   - Start at public leaderboard, trigger OAuth (once implemented), ensure first login lands on `/onboarding`.
   - Submit valid display name → navigates back to leaderboard.
   - Invalid input → inline error + focused input.

