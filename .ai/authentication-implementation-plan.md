# Authentication Implementation Plan — Strava OAuth Integration

## 1. Overview
The **Authentication** system enables users to sign in with Strava OAuth, creating secure sessions and enabling access to personal features. It:

- Provides a "Sign in with Strava" button on public pages
- Handles the complete OAuth 2.0 flow with Strava
- Creates/updates user accounts with Strava profile data
- Manages secure session storage
- Redirects first-time users to onboarding
- Determines admin status via email allowlist

This plan targets **Phoenix 1.8 + OAuth2 library** with server-side session management and secure token storage.

## 2. Authentication Flow
### Current State
- Leaderboard pages are public (no auth required)
- Onboarding requires authentication
- No OAuth implementation exists

### Target Flow
```
Public Leaderboard → Click "Sign in with Strava" → Strava OAuth → Callback → Check User Status → Redirect
                                                                             ↓
                                                                First Time: → Onboarding
                                                                Returning: → Leaderboard (with auth features)
```

### OAuth Implementation Strategy
- Use `oauth2` Elixir library (already in deps via Swoosh)
- Store access/refresh tokens encrypted in database
- Handle token refresh automatically
- Use broader scopes initially for private activities

## 3. Component Structure
High-level additions to existing structure:

```
LeaderboardLive (existing)
└─ <Layouts.app flash={@flash}>
   └─ <AuthSection /> (NEW - shows sign-in button when not authenticated)
      └─ <SignInButton />

OAuthController (NEW)
└─ Strava OAuth callback handling

Auth.Plug (NEW)
└─ Session management and user loading
```

## 4. Component Details

### `SummerChallengeWeb.AuthSection` (function component)
**Purpose**: Conditionally shows authentication UI on public pages.

**Main elements**:
- When unauthenticated: Shows "Sign in with Strava" button
- When authenticated: Shows user menu (future) or nothing
- Positioned appropriately in the leaderboard layout

**Props**:
- `:current_scope` (from auth hook)
- `:current_user` (optional, for future user menu)

### `SummerChallengeWeb.SignInButton` (function component)
**Purpose**: OAuth initiation button with Strava branding.

**Main elements**:
- Strava-branded button (orange, "Connect with Strava" text)
- Links to `/auth/strava`
- Proper accessibility attributes

**Props**: none

### `SummerChallengeWeb.OAuthController` (controller)
**Purpose**: Handles Strava OAuth flow and callbacks.

**Routes**:
- `GET /auth/strava` - Initiate OAuth flow
- `GET /auth/strava/callback` - Handle OAuth callback

**Actions**:
- `request/2`: Redirects to Strava OAuth authorization URL
- `callback/2`: Processes OAuth response, creates/updates user, sets session

**Error Handling**:
- OAuth failures: Flash error, redirect to leaderboard
- Network errors: Retry logic with exponential backoff
- Invalid state: Security error, redirect to leaderboard

## 5. Database Schema Extensions

### User Creation/Update Logic
When OAuth callback succeeds:

1. **Find or create user** by `strava_athlete_id`
2. **Set/update profile data**:
   - `strava_athlete_id`
   - Default `display_name` (first name + initial, per US-030)
   - `is_admin` (check email allowlist)
3. **Create/update credentials**:
   - Encrypt and store `access_token`, `refresh_token`
   - Store `expires_at` timestamp

### Default Display Name Logic (US-030)
```
if first_name && last_name:
  display_name = first_name + " " + last_name[0] + "."
elif first_name:
  display_name = first_name
elif email:
  display_name = email.split("@")[0]
else:
  display_name = "Athlete " + strava_athlete_id
```

## 6. Session Management

### Session Storage
- Store minimal `user_id` in session
- Load full user data via auth hooks (already implemented)
- Session expires on browser close (no remember me)

### Session Security
- Use Phoenix session protection
- CSRF protection on all forms
- Secure cookie settings in production

## 7. OAuth Configuration

### Environment Variables
```bash
STRAVA_CLIENT_ID=your_client_id
STRAVA_CLIENT_SECRET=your_client_secret
ADMIN_EMAILS=admin1@company.com,admin2@company.com
```

### OAuth Scopes
Start with broader scopes (can reduce later):
- `read` - Basic profile access
- `read_all` - All activities (including private)
- `profile:read_all` - Full profile access

### Strava App Setup
- Register app at https://developers.strava.com/
- Set redirect URI to: `http://localhost:4000/auth/strava/callback`
- Configure webhook for activity updates (future)

## 8. API Integration

### Required Context Functions
Add to `SummerChallenge.Accounts`:

```elixir
@spec find_or_create_user_from_strava(map()) :: {:ok, Types.user_dto()} | {:error, term()}
def find_or_create_user_from_strava(strava_profile) do
  # Find by strava_athlete_id or create new user
  # Set default display_name from profile
  # Check admin status
end

@spec store_credentials(uuid(), map()) :: :ok | {:error, term()}
def store_credentials(user_id, token_data) do
  # Encrypt and store OAuth tokens
end
```

### Token Refresh Logic
```elixir
@spec refresh_token_if_needed(uuid()) :: :ok | {:error, term()}
def refresh_token_if_needed(user_id) do
  # Check if token expires soon
  # Refresh via Strava API if needed
  # Update stored credentials
end
```

## 9. Error Handling

### OAuth Error Scenarios
- **Network timeout**: Retry with backoff, show user-friendly message
- **User denies access**: Clear message, stay on leaderboard
- **Invalid client**: Configuration error, admin notification
- **Rate limiting**: Queue and retry, user notification

### User Experience
- Loading states during OAuth flow
- Clear error messages for all failure cases
- Seamless redirect back to originating page
- Session persistence across OAuth flow

## 10. Implementation Steps

### Step 1: OAuth Setup & Configuration
1. **Add OAuth2 dependency** (already present via Swoosh)
2. **Create OAuth strategy module** (`SummerChallenge.OAuth.Strava`)
3. **Add environment configuration** for Strava credentials
4. **Configure OAuth client** with proper scopes and redirect URI

### Step 2: Authentication UI Components
1. **Create `AuthSection` component** for leaderboard
2. **Create `SignInButton` component** with Strava branding
3. **Update `LeaderboardLive`** to include auth section
4. **Style components** with Tailwind CSS

### Step 3: OAuth Controller Implementation
1. **Create `OAuthController`** with request/callback actions
2. **Add OAuth routes** to router
3. **Implement OAuth flow**:
   - Redirect to Strava authorization
   - Handle callback and validate state
   - Process user creation/update
   - Set session and redirect

### Step 4: User Management Logic
1. **Extend `Accounts` context** with OAuth functions
2. **Implement user creation/update** from Strava profile
3. **Add admin email checking** logic
4. **Handle default display name** generation

### Step 5: Session & Security Integration
1. **Update auth hooks** to work with real user data
2. **Implement session management** in OAuth callback
3. **Add flash messages** for success/error states
4. **Test session persistence** across OAuth flow

### Step 6: Post-Authentication Flow
1. **Implement first-time user detection**
2. **Redirect new users to onboarding**
3. **Redirect returning users to leaderboard**
4. **Handle terms/privacy acceptance** (implied by continuing)

### Step 7: Testing & Polish
1. **Test complete OAuth flow** end-to-end
2. **Verify error handling** for all scenarios
3. **Test session management** and security
4. **Polish UI/UX** for authentication states

## 11. Security Considerations

### Token Storage
- Encrypt tokens at rest using Cloak or similar
- Never log or expose tokens in responses
- Implement secure key management

### OAuth Security
- Validate state parameter to prevent CSRF
- Use PKCE if supported by Strava
- Validate redirect URI matches expected domain
- Handle token expiration and refresh securely

### Session Security
- Use secure, httpOnly session cookies
- Implement session timeout
- Clear session on logout
- Protect against session fixation

## 12. Success Criteria

### Functional
- ✅ User can click "Sign in with Strava" on leaderboard
- ✅ OAuth flow completes successfully
- ✅ First-time users redirected to onboarding
- ✅ Returning users see authenticated features
- ✅ Admin users identified correctly
- ✅ Secure token storage and refresh

### User Experience
- ✅ Seamless OAuth flow with loading states
- ✅ Clear error messages for failures
- ✅ Proper redirects maintain user context
- ✅ Session persists across browser refreshes
- ✅ Mobile-responsive authentication UI

### Technical
- ✅ Secure token handling and encryption
- ✅ Proper error handling and logging
- ✅ Configurable admin email allowlist
- ✅ OAuth state validation
- ✅ Session security best practices

## 13. Dependencies & Prerequisites

### Required Setup
- Strava Developer Account & App registration
- Environment variables configured
- Database migrations for user_credentials table (already exists)
- Cloak encryption setup (for token storage)

### External Services
- Strava OAuth API (developers.strava.com)
- HTTPS in production (OAuth requirement)

### Testing Requirements
- Strava test account for development
- OAuth callback URL configuration
- Environment variable setup in development

This implementation plan provides a complete, secure authentication system that integrates seamlessly with the existing onboarding flow and leaderboard functionality.