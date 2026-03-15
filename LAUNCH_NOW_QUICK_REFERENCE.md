# 🚀 Mix & Mingle — Launch Now Quick Reference

**Your 5-minute command sheet to go live TODAY**

---

## ⚡ Ultra-Quick Launch (30 minutes)

### Web Deployment (10 minutes)

```powershell
# Build
flutter build web --release

# Deploy
firebase deploy --only hosting

# Get your URL
# Output: https://mixmingle-prod.web.app
```

✅ **Done! Share the link.**

---

### Android Deployment (20 minutes)

```powershell
# Build
flutter build appbundle --release

# Upload manually:
# 1. Go to play.google.com/console
# 2. Testing → Internal Testing
# 3. Upload: build/app/outputs/bundle/release/app-release.aab
# 4. Copy tester link
```

✅ **Done! Share the tester link.**

---

## 📱 Tester Invitation (Copy & Send)

```
🎉 Test Mix & Mingle Today!

Web (instant): https://mixmingle-prod.web.app
Android: [your tester link]

Create profile → Join room → Test features → Report bugs

Thanks! 🚀
```

---

## ✅ 5-Minute Verification

### Web

- [ ] Load site
- [ ] Sign in
- [ ] Join room

### Android

- [ ] Install app
- [ ] Sign in
- [ ] Join room

**If all 3 work → You're live!**

---

## 📊 What to Monitor (Day 1)

Open these dashboards:

1. [Firebase Realtime](https://console.firebase.google.com) → Analytics
2. [Firebase Crashlytics](https://console.firebase.google.com) → Crashlytics
3. [Play Console](https://play.google.com/console) → Android Vitals

**Watch for:**

- Users signing up ✅
- No crashes 🚫
- Features working ✅

---

## 🐛 If Something Breaks

### Critical Bug Fix

```powershell
# Fix code
# Update version in pubspec.yaml

# Redeploy web
flutter build web --release
firebase deploy --only hosting

# Redeploy Android
flutter build appbundle --release
# Upload to Play Console
```

---

## 📋 Complete Guides

**Everything is documented in:**

- [DEPLOYMENT_EXECUTION_PLAN.md](DEPLOYMENT_EXECUTION_PLAN.md) — Full deployment walkthrough
- [TESTER_ONBOARDING_MATERIALS.md](TESTER_ONBOARDING_MATERIALS.md) — All tester communications
- [VERIFICATION_CHECKLISTS.md](VERIFICATION_CHECKLISTS.md) — Complete testing checklists
- [POST_LAUNCH_MONITORING_GUIDE.md](POST_LAUNCH_MONITORING_GUIDE.md) — Operations playbook

---

## 🎯 Today's Goal

**Get it live. Get feedback. Iterate.**

Not perfect. Not polished. Just **shipped.**

---

## 🚀 Ready?

Run the commands above and **you're live in 30 minutes.**

Good luck, Larry! 🎉
