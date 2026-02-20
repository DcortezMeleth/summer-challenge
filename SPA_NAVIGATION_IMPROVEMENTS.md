# SPA Navigation Improvements

## Problem
Navigation between Leaderboard, Milestone, and My Activities tabs was causing:
- Flash of unstyled content (FOUC)
- White screen flashes
- Inconsistent loading states
- Poor UX on slower connections

**Root Cause**: Each tab was a separate LiveView in different `live_session` blocks, causing full page remounts on navigation.

## Solution: True SPA Architecture with LiveView

Converted the app to use **live_patch** navigation, creating a single-page application experience where:
- The LiveView connection stays alive during navigation
- Only content updates, CSS and JS remain loaded
- No page reloads or remounts between main navigation items

## Changes Made

### 1. Unified Live Session (`router.ex`)

**Before:**
```elixir
live_session :public, on_mount: {Auth, :optional} do
  live "/leaderboard", LeaderboardLive, :index
  live "/milestone", MilestoneLive, :index
end

live_session :authenticated, on_mount: {Auth, :require_authenticated_user} do
  live "/my/activities", MyActivitiesLive, :index
end
```

**After:**
```elixir
live_session :main_app, on_mount: {Auth, :optional} do
  live "/leaderboard", LeaderboardLive, :index
  live "/leaderboard/:sport", LeaderboardLive, :index
  live "/milestone", MilestoneLive, :index
  live "/my/activities", MyActivitiesLive, :index
end
```

✅ **Benefit**: All main views share the same WebSocket connection and can use live_patch

### 2. Changed Navigation to Use `patch=` (`core_components.ex`)

**Before:**
```elixir
<.link navigate={@path} class="...">
```

**After:**
```elixir
<.link patch={@path} class="...">
```

✅ **Benefit**: Navigation uses `pushState` instead of full page loads

### 3. Added Auth Check to MyActivitiesLive (`my_activities_live.ex`)

Since MyActivitiesLive is now in an `:optional` auth session, added explicit auth check:

```elixir
def mount(_params, _session, socket) do
  if socket.assigns.current_scope.authenticated? do
    # Load activities
  else
    {:ok, push_navigate(socket, to: "/leaderboard")}
  end
end
```

✅ **Benefit**: Maintains security while allowing flexible navigation

### 4. Simplified CSS (`app.css`)

**Removed**: Complex overlay, spinner, and loading animations

**Added**: Simple fade effect during patch navigation:
```css
.phx-page-loading main[role="main"] > div {
  opacity: 0.7;
  transition: opacity 0.15s ease-in-out;
}
```

✅ **Benefit**: Minimal, clean loading indication using LiveView's built-in topbar

### 5. Simplified JavaScript (`app.js`)

**Removed**: Manual loading class management and click handlers

**Kept**: LiveView topbar configuration with brand colors

✅ **Benefit**: Relies on LiveView's proven loading indicators

## Results

### Before (Multiple LiveView Mounts)
```
User clicks "Milestone" 
  → Unmount LeaderboardLive
  → Disconnect WebSocket
  → Create new WebSocket
  → Mount MilestoneLive
  → Reload CSS/JS (causes FOUC)
  → Render content
```

### After (Single LiveView with Patches)
```
User clicks "Milestone"
  → Update URL (pushState)
  → Patch content via existing WebSocket
  → Update only changed DOM elements
  → CSS/JS stay loaded
  → Instant, smooth transition
```

## Testing

1. **Hard refresh** your browser: `Cmd + Shift + R` (Mac) or `Ctrl + Shift + R` (Windows/Linux)

2. **Test navigation:**
   - Click between Leaderboard, Milestone, and My Activities
   - Switch between Running and Cycling on Leaderboard
   - Test on throttled 3G connection (DevTools Network tab)

3. **Expected behavior:**
   - ✅ No white flashes
   - ✅ No unstyled content
   - ✅ Smooth transitions
   - ✅ Topbar loading indicator shows for slower loads
   - ✅ Subtle content fade during updates
   - ✅ Instant response on fast connections

## Additional Benefits

1. **Performance**: Eliminates unnecessary LiveView mounts and WebSocket reconnections
2. **User Experience**: Smooth, app-like navigation
3. **Browser History**: Back/forward buttons work perfectly
4. **Maintainability**: Simpler code without complex loading state management
5. **Scalability**: Ready for additional views with same SPA experience

## Future Enhancements

- Add route-based code splitting if needed
- Implement preloading for anticipated navigation
- Add skeleton screens for slower data loads
- Consider adding page transitions for enhanced UX
