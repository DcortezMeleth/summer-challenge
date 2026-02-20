# Page Loading State - Test Plan

## Quick Start
1. Navigate to http://localhost:4000/leaderboard
2. Open browser DevTools (F12 or Cmd+Option+I)
3. Enable debug logging in console:
   ```javascript
   window.debugPageLoading = true;
   ```
4. Start testing navigation

## Test Cases

### Test 1: Main Navigation (Top Bar)
**Objective:** Verify smooth transitions between main pages

**Steps:**
1. Click "Leaderboard" (trophy icon)
2. Click "Milestone" (flag icon)
3. Click "My Activities" (chart icon)
4. Navigate back to "Leaderboard"

**Expected Results:**
- ✅ No white flashes during navigation
- ✅ Background color stays consistent (light gray)
- ✅ Loading overlay appears only on slower navigations (>100ms)
- ✅ Active navigation item is highlighted
- ✅ Console shows no errors

**Debug Log Pattern (Fast Navigation):**
```
[PageLoading] Navigation started
[PageLoading] Added phx-page-loading class
[PageLoading] Navigation completed
[PageLoading] Cleared loading timer (fast navigation)
[PageLoading] Removed all loading classes
```

**Debug Log Pattern (Slow Navigation):**
```
[PageLoading] Navigation started
[PageLoading] Added phx-page-loading class
[PageLoading] Added phx-page-loading-delayed class (after 100ms)
[PageLoading] Navigation completed
[PageLoading] Removed all loading classes
```

---

### Test 2: Sport Tabs (Leaderboard Page)
**Objective:** Verify smooth transitions between sport types

**Steps:**
1. Go to Leaderboard page
2. Click "Running (Outdoor)" tab
3. Click "Cycling (Outdoor)" tab
4. Switch back and forth several times

**Expected Results:**
- ✅ No white flashes during tab switches
- ✅ Active tab is highlighted with blue background
- ✅ Leaderboard data updates correctly
- ✅ URL updates to reflect selected sport
- ✅ Loading overlay behavior same as Test 1

---

### Test 3: Browser Navigation
**Objective:** Verify loading state works with browser back/forward

**Steps:**
1. Navigate: Leaderboard → Milestone → My Activities
2. Click browser back button twice
3. Click browser forward button twice

**Expected Results:**
- ✅ Loading state works correctly on back/forward
- ✅ No white flashes
- ✅ Page state is restored correctly
- ✅ Active navigation item updates

---

### Test 4: Challenge Selector
**Objective:** Verify loading state during challenge changes

**Steps:**
1. Click the challenge selector dropdown
2. Select a different challenge
3. Observe page reload

**Expected Results:**
- ✅ Loading overlay appears during data reload
- ✅ No white flashes
- ✅ Leaderboard data updates for new challenge
- ✅ Selected challenge is highlighted

---

### Test 5: Refresh Data Button
**Objective:** Verify loading state during manual refresh

**Steps:**
1. Go to Leaderboard page
2. Click "Refresh Data" button (requires authentication)
3. Wait for refresh to complete

**Expected Results:**
- ✅ Loading overlay appears during sync
- ✅ Flash message appears on completion
- ✅ Leaderboard data updates
- ✅ No white flashes

---

### Test 6: Direct URL Navigation
**Objective:** Verify loading state works with direct URL changes

**Steps:**
1. Type in address bar: http://localhost:4000/leaderboard/running_outdoor
2. Type in address bar: http://localhost:4000/milestone
3. Type in address bar: http://localhost:4000/my/activities

**Expected Results:**
- ✅ Pages load correctly
- ✅ Initial page load shows loading state
- ✅ No white flashes
- ✅ No console errors

---

### Test 7: Slow Network Simulation
**Objective:** Verify loading overlay appears on slow connections

**Steps:**
1. Open DevTools → Network tab
2. Set throttling to "Slow 3G"
3. Navigate between pages
4. Observe loading overlay behavior

**Expected Results:**
- ✅ Loading overlay appears more frequently
- ✅ Spinner is visible and animating
- ✅ Overlay has light gray background
- ✅ No white flashes even on slow connection

---

### Test 8: Fast Navigation Stress Test
**Objective:** Verify timer cleanup works correctly

**Steps:**
1. Rapidly click between navigation items (10+ times quickly)
2. Check console for errors
3. Verify no overlay "sticks" on screen

**Expected Results:**
- ✅ No JavaScript errors
- ✅ Loading overlay doesn't get stuck
- ✅ Timer is properly cleaned up
- ✅ Debug logs show "Cleared loading timer" messages

---

## DevTools Inspection Checklist

### Elements Tab
- [ ] `<body>` element has `phx-page-loading` class during navigation
- [ ] `phx-page-loading-delayed` class added after 100ms (slow nav only)
- [ ] Both classes removed when navigation completes
- [ ] No orphaned classes left on body

### Console Tab
- [ ] No JavaScript errors
- [ ] Debug logs show correct sequence (if enabled)
- [ ] LiveView connection messages appear
- [ ] No warnings about missing elements

### Network Tab
- [ ] WebSocket connection to `/live` is established
- [ ] LiveView messages flow during navigation
- [ ] No failed requests (except expected 404s for favicon, etc.)
- [ ] Assets (app.js, app.css) load correctly

### Performance Tab (Optional)
- [ ] No layout thrashing during navigation
- [ ] Smooth 60fps during transitions
- [ ] No long tasks blocking the main thread

---

## Known Issues / Limitations

1. **Overlay only appears after 100ms delay**
   - This is intentional to prevent flashing on fast navigations
   - If you want to always see the overlay, reduce the delay in `app.js`

2. **First page load doesn't show overlay**
   - LiveView page loading events only fire on navigation, not initial load
   - This is expected Phoenix LiveView behavior

3. **Overlay might not appear on very fast navigations**
   - If navigation completes in <100ms, overlay is intentionally skipped
   - This provides the smoothest user experience

---

## Success Criteria

All tests pass with:
- ✅ No white flashes during any navigation
- ✅ Loading overlay appears only when appropriate (>100ms)
- ✅ No JavaScript console errors
- ✅ Classes are properly added/removed from body element
- ✅ Background color remains consistent throughout navigation
- ✅ User experience feels smooth and polished

---

## Rollback Plan

If issues are found, revert the changes:

```bash
cd /Users/bsadel/summer-challange/app
git checkout app/assets/js/app.js
mix assets.deploy
```

The Phoenix dev server will automatically detect the changes and rebuild.
