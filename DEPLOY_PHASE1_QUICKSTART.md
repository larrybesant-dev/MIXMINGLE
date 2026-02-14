# 🔥 PHASE 1 DEPLOYMENT - QUICK START

**Status:** ✅ Ready to deploy
**Estimated Time:** 15-30 minutes
**Risk Level:** 🔴 HIGH (Production deployment)

---

## 🚀 ONE-COMMAND DEPLOYMENT

### Option 1: Automated Script (Recommended)
```powershell
# Review what will be deployed (dry run)
.\deploy-phase1.ps1 -DryRun

# Deploy everything
.\deploy-phase1.ps1
```

### Option 2: Manual Deployment
```bash
# 1. Build functions
cd functions
npm install
npm run build
cd ..

# 2. Deploy functions
firebase deploy --only functions:onSpeedDatingSessionCreated,functions:submitSpeedDatingDecision,functions:leaveSpeedDatingSession

# 3. Deploy rules
firebase deploy --only firestore:rules

# 4. Deploy Flutter app
flutter build web --release
firebase deploy --only hosting
```

---

## ✅ PRE-DEPLOYMENT CHECKLIST

Before running deployment:

- [ ] Reviewed `PHASE_1_SPEED_DATING_HARDENED.md`
- [ ] Firebase CLI installed (`firebase --version` works)
- [ ] Logged into correct Firebase project (`firebase use`)
- [ ] Node.js installed (`node --version` >= 18)
- [ ] Firestore backup created (recommended)

---

## 🧪 POST-DEPLOYMENT TESTING (CRITICAL)

**Run ALL 5 tests before calling Phase 1 "done":**

### Test 1: Session Expiry ⏱️
```
1. Create 2 test accounts
2. Start speed dating session
3. Wait 5 minutes
4. ✅ PASS if: Both users auto-disconnected
5. ❌ FAIL if: Users still connected after 5 min
```

### Test 2: Late Decision ❌
```
1. Complete speed dating session
2. Wait for expiry
3. Try to submit decision
4. ✅ PASS if: Server rejects with "Session has expired"
5. ❌ FAIL if: Decision accepted
```

### Test 3: Firestore Security 🔒
```
1. Open Firebase Console
2. Try to create speed_dating_sessions document manually
3. ✅ PASS if: PERMISSION_DENIED error
4. ❌ FAIL if: Document created
```

### Test 4: Cross-User Decision 🚫
```
1. User A & B in session
2. User A tries API call to submit for User B
3. ✅ PASS if: permission-denied error
4. ❌ FAIL if: Decision submitted
```

### Test 5: Duplicate Decision 🔄
```
1. User A submits "keep"
2. User A tries to change to "pass"
3. ✅ PASS if: already-exists error
4. ❌ FAIL if: Decision changed
```

---

## 📊 MONITORING AFTER DEPLOYMENT

### Check Function Logs
```bash
# Watch for errors in real-time
firebase functions:log --only submitSpeedDatingDecision

# Check session creation
firebase functions:log --only onSpeedDatingSessionCreated
```

### Check Firestore Health
```bash
# List active sessions (should be empty after 10 minutes)
firebase firestore:get speed_dating_sessions --where status==active
```

### Watch for Red Flags 🚨
- Multiple "deadline-exceeded" errors → Users trying to submit late
- "permission-denied" spikes → Attempted rule bypass
- Sessions stuck on "active" → Timer not working

---

## 🔄 ROLLBACK PLAN (If Something Breaks)

### Rollback Functions
```bash
# List previous versions
firebase functions:list

# Rollback to previous version
firebase rollback functions:onSpeedDatingSessionCreated
firebase rollback functions:submitSpeedDatingDecision
firebase rollback functions:leaveSpeedDatingSession
```

### Rollback Rules
```bash
# Firestore rules are versioned automatically
# Rollback via Firebase Console:
# 1. Go to Firestore > Rules
# 2. Click "View History"
# 3. Select previous version
# 4. Click "Restore"
```

### Emergency Stop
```bash
# Disable functions temporarily
firebase functions:config:unset speed_dating.enabled
```

---

## 🎯 SUCCESS CRITERIA

Phase 1 deployment is ONLY successful if:

- ✅ All 5 abuse tests pass
- ✅ Zero sessions extend beyond 6 minutes in first 24 hours
- ✅ Zero Firestore security rule violations
- ✅ <1% error rate in Cloud Functions
- ✅ Client auto-disconnects work consistently

**If ANY fail → Investigate immediately**

---

## 📞 TROUBLESHOOTING

### "firebase: command not found"
```bash
npm install -g firebase-tools
firebase login
```

### "Permission denied" during deployment
```bash
# Make sure you're on correct project
firebase use --add

# Check permissions in Firebase Console
```

### Functions deploy fails
```bash
# Check TypeScript compilation
cd functions
npm run build

# Look for errors in output
```

### Rules validation error
```bash
# Test rules locally
firebase emulators:start --only firestore

# Check syntax in firestore.rules
```

---

## 📈 WHAT HAPPENS AFTER DEPLOYMENT

1. **Immediate (0-1 hour)**
   - Functions become callable
   - Rules take effect immediately
   - Existing sessions NOT affected (continue until natural end)

2. **Short-term (1-24 hours)**
   - New sessions use server timer
   - Old client-side only sessions expire naturally
   - Monitor for error patterns

3. **Long-term (24+ hours)**
   - All sessions server-authoritative
   - Abuse attempts show in logs
   - Ready for Phase 2 work

---

## 🚦 GO / NO-GO DECISION

**GREEN (Deploy):**
- All pre-deployment checks passed
- Team available to monitor deployment
- Non-peak hours (late night / weekend)
- Backup plan ready

**RED (Wait):**
- Missing tests
- Peak usage time
- No one available to monitor
- Rollback plan unclear

---

**Current Status:** 🟡 AWAITING DEPLOYMENT

**Next Action:** Run `.\deploy-phase1.ps1 -DryRun` to preview

**Expected Completion:** Within 30 minutes of starting

---

**Remember:** Speed dating is your highest legal risk feature.
Test everything. Deploy carefully. Monitor constantly.

You're past the "idea stage". This is real production infrastructure.
