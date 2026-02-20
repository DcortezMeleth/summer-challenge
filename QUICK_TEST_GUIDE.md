# Quick Test Guide - Page Loading Fix

## 🚀 Quick Start (30 seconds)

1. **Open the app:** http://localhost:4000/leaderboard
2. **Open DevTools:** Press `F12` (or `Cmd+Option+I` on Mac)
3. **Enable debug mode:** In console, type:
   ```javascript
   window.debugPageLoading = true;
   ```
4. **Test navigation:** Click between tabs and watch for:
   - ❌ No white flashes
   - ✅ Smooth transitions
   - ✅ Console logs (if debug enabled)

---

## 🎯 What to Look For

### ✅ GOOD Signs
- Background stays light gray during navigation
- Loading spinner appears only on slow navigations (>100ms)
- Smooth fade transitions
- Console shows: `[PageLoading]` messages (if debug enabled)
- No JavaScript errors

### ❌ BAD Signs
- White flash during navigation
- Overlay gets stuck on screen
- Console shows errors
- Classes not being added to `<body>`

---

## 🔍 Quick Checks

### Check 1: Main Navigation (10 sec)
Click: **Leaderboard** → **Milestone** → **My Activities**
- Should be smooth with no white flashes

### Check 2: Sport Tabs (10 sec)
On Leaderboard page, click: **Running** → **Cycling** → **Running**
- Should be smooth with no white flashes

### Check 3: Browser Console (5 sec)
Look for:
- ✅ `[PageLoading]` logs (if debug enabled)
- ❌ No red error messages

---

## 🐛 Debug Commands

### Enable Debug Logging
```javascript
window.debugPageLoading = true;
```

### Disable Debug Logging
```javascript
window.debugPageLoading = false;
```

### Check Current Body Classes
```javascript
document.body.className;
```

### Manually Trigger Loading State (Testing)
```javascript
// Add classes
document.body.classList.add("phx-page-loading", "phx-page-loading-delayed");

// Remove classes after 2 seconds
setTimeout(() => {
  document.body.classList.remove("phx-page-loading", "phx-page-loading-delayed");
}, 2000);
```

---

## 📊 Expected Debug Output

### Fast Navigation (<100ms)
```
[PageLoading] Navigation started {classes: "phx-page-loading", ...}
[PageLoading] Added phx-page-loading class {classes: "phx-page-loading", ...}
[PageLoading] Navigation completed {classes: "phx-page-loading", ...}
[PageLoading] Cleared loading timer (fast navigation) {classes: "phx-page-loading", ...}
[PageLoading] Removed all loading classes {classes: "", ...}
```

### Slow Navigation (>100ms)
```
[PageLoading] Navigation started {classes: "phx-page-loading", ...}
[PageLoading] Added phx-page-loading class {classes: "phx-page-loading", ...}
[PageLoading] Added phx-page-loading-delayed class (after 100ms) {classes: "phx-page-loading phx-page-loading-delayed", ...}
[PageLoading] Navigation completed {classes: "phx-page-loading phx-page-loading-delayed", ...}
[PageLoading] Removed all loading classes {classes: "", ...}
```

---

## 🔧 Troubleshooting

### Problem: Still seeing white flashes
**Solution:** Hard refresh the browser
- Mac: `Cmd + Shift + R`
- Windows/Linux: `Ctrl + Shift + R`

### Problem: No debug logs appearing
**Solution:** Make sure you enabled debug mode:
```javascript
window.debugPageLoading = true;
```

### Problem: Classes not being added
**Solution:** Check if LiveView is connected:
```javascript
window.liveSocket.isConnected();  // Should return true
```

### Problem: Overlay stuck on screen
**Solution:** Manually remove classes:
```javascript
document.body.classList.remove("phx-page-loading", "phx-page-loading-delayed");
```

---

## 📱 Test on Different Devices

### Desktop Browsers
- ✅ Chrome
- ✅ Firefox
- ✅ Safari
- ✅ Edge

### Mobile (Optional)
- Open http://localhost:4000 on mobile device (same network)
- Test navigation on touch interface

---

## ✅ Success Checklist

- [ ] No white flashes during navigation
- [ ] Loading overlay appears on slow navigations
- [ ] Console shows no errors
- [ ] Debug logs show correct sequence (if enabled)
- [ ] Body classes are added/removed correctly
- [ ] Navigation feels smooth and polished

---

## 📚 More Information

- **Technical Details:** See `NAVBAR_ENHANCEMENTS.md`
- **Full Test Plan:** See `PAGE_LOADING_TEST_PLAN.md`
- **Summary:** See `PAGE_LOADING_FIX_SUMMARY.md`

---

**Ready to test?** Start at http://localhost:4000/leaderboard 🚀
