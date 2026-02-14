# 🚀 Manual Deployment Steps - Mix & Mingle

Follow these steps in order. Each command should complete before moving to the next.

---

## Prerequisites

✅ Ensure you're in the project directory:
```powershell
cd c:\Users\LARRY\MIXMINGLE
```

---

## Step 1: Clean Build (30 seconds)

Run this command and wait for it to complete:
```powershell
flutter clean
```

**Expected output:** "Deleting build...", "Deleting .dart_tool...", etc.

✅ **Success indicator:** Command completes with no errors

---

## Step 2: Get Dependencies (1 minute)

Run this command:
```powershell
flutter pub get
```

**Expected output:** "Resolving dependencies...", "Got dependencies!"

✅ **Success indicator:** "Got dependencies!" message appears

---

## Step 3: Build Web Release (2-3 minutes)

Run this command:
```powershell
flutter build web --release
```

**What happens:**
- Compiling Dart code
- Minifying JavaScript
- Optimizing assets
- Creating production build

**Expected output:** Progress bars, then "Built build\web"

✅ **Success indicator:** "Built build\web" message with timing

---

## Step 4: Verify Build (10 seconds)

Check that the build folder was created:
```powershell
dir build\web
```

**Expected:** You should see index.html, main.dart.js, assets/, etc.

✅ **Success indicator:** index.html file exists

---

## Step 5: Deploy to Firebase (1 minute)

Run this command:
```powershell
firebase hosting:channel:deploy live
```

**Expected output:**
- "✔ hosting:live:  Deploy complete!"
- URL to your live app

✅ **Success indicator:** Deployment URL is shown

---

## Step 6: Verify Deployment (30 seconds)

Open the deployment URL in your browser, or:
```powershell
firebase hosting:channel:open live
```

**Test checklist:**
- [ ] Login screen appears
- [ ] Can create account
- [ ] Can create room
- [ ] Can join room with another account
- [ ] Video/audio works
- [ ] No console errors (F12)

---

## Alternative: Use the Scripts

### Option A: Batch Script (Windows)
Double-click: `deploy-production.bat`

### Option B: PowerShell Script
Right-click → Run with PowerShell: `deploy-production.ps1`

Or from terminal:
```powershell
powershell -ExecutionPolicy Bypass -File deploy-production.ps1
```

---

## Troubleshooting

### If flutter clean fails:
```powershell
rmdir /s /q build
rmdir /s /q .dart_tool
```

### If flutter pub get fails:
```powershell
flutter pub cache repair
flutter pub get
```

### If flutter build web fails:
```powershell
flutter clean
flutter pub get
flutter build web --release --verbose
```
(The --verbose flag shows detailed error messages)

### If firebase deploy fails:
```powershell
firebase login
firebase use default
firebase hosting:channel:deploy live
```

---

## Quick Reference Commands

```powershell
# Full build and deploy (copy all at once)
cd c:\Users\LARRY\MIXMINGLE
flutter clean
flutter pub get
flutter build web --release
firebase hosting:channel:deploy live
```

---

## Expected Timeline

| Step | Duration |
|------|----------|
| Clean | 30s |
| Pub get | 1min |
| Build | 2-3min |
| Deploy | 1min |
| **Total** | **~5 minutes** |

---

## After Deployment

### Check logs:
```powershell
firebase functions:log --only generateAgoraToken
```

### View performance:
```powershell
firebase performance:view
```

### Check errors:
```powershell
firebase crashlytics:view
```

---

## Success Criteria

You'll know it worked when:

✅ Build completes with "Built build\web"
✅ Firebase shows deployment URL
✅ App opens in browser
✅ Login screen appears
✅ No console errors

---

**Status:** Ready to deploy!

**Next:** Open a new PowerShell terminal and run the commands in Step 1-5
