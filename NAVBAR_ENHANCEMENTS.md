# Navigation Loading State Fix

## Summary
Fixed the page loading overlay to properly display during LiveView navigation, preventing white flashes and providing smooth transitions between pages.

## Issue
The page loading overlay was not displaying correctly during LiveView navigation between tabs (Leaderboard, Milestone, My Activities). The CSS defined styles for `.phx-page-loading.phx-page-loading-delayed` but the JavaScript was only adding the `phx-page-loading-delayed` class, missing the base `phx-page-loading` class.

### Root Causes

1. **Incorrect navigation type:** The main navigation links used `patch` instead of `navigate`. In Phoenix LiveView:
   - `patch` is for same-LiveView navigation (URL changes within the same module)
   - `navigate` is for cross-LiveView navigation (navigating between different LiveView modules)
   - Using `patch` for cross-LiveView navigation causes the entire LiveView to remount, which is slower and more jarring

2. **Missing CSS classes:** The CSS selector `.phx-page-loading.phx-page-loading-delayed::before` requires BOTH classes to be present on the body element for the overlay to show. However, the JavaScript event handler was only adding `phx-page-loading-delayed`, so the overlay never appeared, causing white flashes during navigation.

## Changes Made

### File: `app/lib/summer_challenge_web/components/core_components.ex`

**Issue:** Navigation links were using `patch={@path}` instead of `navigate={@path}`. The `patch` attribute is meant for navigation within the same LiveView module, but the main navigation links go to different LiveView modules (LeaderboardLive, MilestoneLive, MyActivitiesLive). Using `patch` for cross-LiveView navigation causes unnecessary remounting and contributes to white flashes.

**Fix:** Changed line 834 from `patch={@path}` to `navigate={@path}` in the `nav_item` component.

**Before:**
```elixir
<.link
  patch={@path}
  class={[...]}
>
```

**After:**
```elixir
<.link
  navigate={@path}
  class={[...]}
>
```

### File: `app/assets/js/app.js`

**Before:**
```javascript
liveSocket.on("phx:page-loading-start", () => {
  loadingTimer = setTimeout(() => {
    document.body.classList.add("phx-page-loading-delayed");
  }, 100);
});

liveSocket.on("phx:page-loading-stop", () => {
  if (loadingTimer) {
    clearTimeout(loadingTimer);
    loadingTimer = null;
  }
  document.body.classList.remove("phx-page-loading-delayed");
});
```

**After:**
```javascript
liveSocket.on("phx:page-loading-start", () => {
  // Add base class immediately
  document.body.classList.add("phx-page-loading");
  
  // Add delayed class after 100ms to show the overlay
  loadingTimer = setTimeout(() => {
    document.body.classList.add("phx-page-loading-delayed");
  }, 100);
});

liveSocket.on("phx:page-loading-stop", () => {
  if (loadingTimer) {
    clearTimeout(loadingTimer);
    loadingTimer = null;
  }
  document.body.classList.remove("phx-page-loading", "phx-page-loading-delayed");
});
```

## Phoenix LiveView Navigation: `patch` vs `navigate`

### When to use `navigate`
Use `navigate` when navigating between **different LiveView modules**:
- Leaderboard → Milestone (different modules)
- Milestone → My Activities (different modules)
- Any cross-module navigation

**Behavior:**
- Maintains the LiveView connection
- Efficiently swaps out the LiveView module
- Triggers `phx:page-loading-start` and `phx:page-loading-stop` events
- Better for cross-module navigation

### When to use `patch`
Use `patch` when staying within the **same LiveView module**:
- Changing sport tabs on Leaderboard (same LeaderboardLive module)
- Updating URL parameters (e.g., `/leaderboard/running` → `/leaderboard/cycling`)
- Filtering or sorting within the same page

**Behavior:**
- Stays in the same LiveView module
- Only updates `handle_params/3`
- Faster for same-module navigation
- No full remount

### Our Fix
Changed main navigation from `patch` to `navigate` because:
- `/leaderboard` → `LeaderboardLive`
- `/milestone` → `MilestoneLive`
- `/my/activities` → `MyActivitiesLive`

These are different modules, so `navigate` is the correct choice.

## How It Works

1. **On navigation start (`phx:page-loading-start`):**
   - Immediately adds `phx-page-loading` class to body
   - After 100ms delay, adds `phx-page-loading-delayed` class
   - The delay prevents the overlay from flashing on fast navigations

2. **On navigation complete (`phx:page-loading-stop`):**
   - Clears the timer if navigation completes before 100ms
   - Removes both classes from body

3. **CSS behavior:**
   - `.phx-page-loading` provides the base structure
   - `.phx-page-loading.phx-page-loading-delayed` shows the overlay with opacity transition
   - The overlay is a light gray background (ui-50) with a centered spinner

## Testing Instructions

### Enable Debug Logging (Optional)
To see detailed logging of the page loading behavior, open the browser console and run:
```javascript
window.debugPageLoading = true;
```

This will log:
- When navigation starts/stops
- Which classes are added/removed
- Whether the timer was cleared (fast navigation)
- Current body classes and timestamps

### Main Navigation (Top Bar)
1. Navigate to http://localhost:4000/leaderboard (requires authentication)
2. Open browser console (F12 or Cmd+Option+I)
3. Enable debug logging (optional, see above)
4. Click between main navigation items in the top bar:
   - **Leaderboard** (trophy icon)
   - **Milestone** (flag icon)
   - **My Activities** (chart icon)
5. Observe the following:
   - **Fast navigations (<100ms):** No overlay should appear (smooth transition)
   - **Slower navigations (>100ms):** A subtle gray overlay with spinner should appear
   - **No white flash:** The background should remain consistent during navigation
   - **Browser console:** Check for any JavaScript errors
   - **Debug logs:** If enabled, verify classes are being applied correctly

### Sport Tabs (Leaderboard Page)
4. On the Leaderboard page, test the sport tabs:
   - Click between Running and Cycling tabs
   - Observe smooth transitions without white flashes

### Additional Scenarios
5. Test other navigation scenarios:
   - Use browser back/forward buttons
   - Click "Refresh Data" button (if authenticated)
   - Change challenge using the challenge selector
   - Navigate using URL directly (e.g., /leaderboard/cycling_outdoor)

## Expected Behavior

- Smooth transitions between tabs without white flashes
- Loading indicator only appears for navigations that take longer than 100ms
- No console errors related to phx-page-loading classes
- Background color remains consistent (ui-50) throughout navigation

## Browser DevTools Inspection

### Elements Tab
1. Inspect the `<body>` element during navigation
2. Watch for these classes being added/removed:
   - `phx-page-loading` - Added immediately on navigation start
   - `phx-page-loading-delayed` - Added after 100ms (only on slow navigations)
   - Both classes removed when navigation completes

### Console Tab
1. Check for JavaScript errors
2. If debug logging is enabled, verify the sequence:
   ```
   [PageLoading] Navigation started
   [PageLoading] Added phx-page-loading class
   [PageLoading] Added phx-page-loading-delayed class (after 100ms)  // Only on slow nav
   [PageLoading] Navigation completed
   [PageLoading] Cleared loading timer (fast navigation)  // Only on fast nav
   [PageLoading] Removed all loading classes
   ```

### Network Tab
1. Monitor the WebSocket connection (should show "live" connection)
2. Watch for LiveView messages during navigation
3. Verify no failed requests or errors

## Files Modified

- `app/lib/summer_challenge_web/components/core_components.ex` - Changed `patch` to `navigate` for main navigation
- `app/assets/js/app.js` - Fixed page loading class application
- `app/priv/static/assets/app.js` - Rebuilt asset (auto-generated)

## Related Files (No Changes Needed)

- `app/assets/css/app.css` - Already has correct CSS definitions
- `app/lib/summer_challenge_web/live/leaderboard_live.ex` - Uses patch navigation
- `app/lib/summer_challenge_web/components/core_components.ex` - Sport switch and nav_item components

## Troubleshooting

### Issue: Still seeing white flashes
1. Hard refresh the browser (Cmd+Shift+R or Ctrl+Shift+R) to clear cached assets
2. Verify the new `app.js` is loaded by checking the file size in DevTools Network tab
3. Check browser console for JavaScript errors
4. Enable debug logging to verify classes are being applied

### Issue: Overlay appears on every navigation
This is expected behavior for navigations that take longer than 100ms. If it appears too frequently:
1. Check network speed (slow connections will trigger the overlay more often)
2. Verify database queries are optimized (check Phoenix logs for slow queries)
3. Consider adjusting the 100ms delay in `app.js` if needed

### Issue: Classes not being applied
1. Check that LiveView is connected (look for WebSocket connection in DevTools)
2. Verify `window.liveSocket` is available in console
3. Check for JavaScript errors that might prevent event handlers from registering
4. Ensure Phoenix server is running and assets are compiled

### Issue: Overlay doesn't disappear
1. Check browser console for errors
2. Verify the `phx:page-loading-stop` event is firing (use debug logging)
3. Check if navigation actually completed (look for Phoenix logs)
4. Try refreshing the page
