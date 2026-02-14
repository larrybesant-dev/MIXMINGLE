# 🤖 AI Auto-Fix Workflow Prompt for VS Code Chat

## **Copy & Paste This Into VS Code Chat to Start Auto-Fixing**

---

```
You are now in AI Auto-Fix mode. Your mission: Fix the MIXMINGLE Flutter app
until it's 100% MVP-ready (all tests pass, health checks pass, builds succeed).

Follow this exact workflow:

═══════════════════════════════════════════════════════════════════════════════

### PHASE 1: COMPREHENSIVE ERROR SCAN
═══════════════════════════════════════════════════════════════════════════════

1. Search the entire lib/ folder for compilation errors:
   - Missing imports (Riverpod, models, services, UI widgets)
   - Undefined types: ChatMessage, Participant, Friend, VideoGroup, VideoQuality
   - Invalid Container/BoxDecoration parameters
   - Deprecated API calls (NotificationService v20, old Agora methods)
   - Incorrect async/await usage
   - Type mismatches

2. Search test/ folder for similar compilation/import errors.

3. Generate a numbered list with:
   - File path
   - Line number
   - Error description
   - Suggested fix

4. DO NOT fix yet — just report all errors found.

ACTION: Run this search across lib/ and test/. Report findings.

═══════════════════════════════════════════════════════════════════════════════

### PHASE 2: AUTO-FIX ALL IDENTIFIED ERRORS
═══════════════════════════════════════════════════════════════════════════════

For each error from Phase 1:

IF missing import:
  → Add the import statement at the top of the file.
  → Ensure no duplicate imports.

IF undefined type (ChatMessage, Participant, etc.):
  → Check if it exists in lib/models/ folder.
  → If missing, create the minimal model class with required properties.
  → Update imports in the file that uses it.

IF invalid Container/BoxDecoration:
  → Replace with correct Flutter widget syntax.
  → Example: Container(decoration: BoxDecoration(border: Border.all()))

IF deprecated Agora/NotificationService API:
  → Replace with current method signature.
  → Check lib/services/ for latest implementation.

IF type mismatch or async issue:
  → Fix type casting or wrap in proper async context.
  → Add null safety checks if needed.

ACTION: Apply ALL fixes systematically. Save each file after fixing.

═══════════════════════════════════════════════════════════════════════════════

### PHASE 3: VERIFY FIXES & RUN TESTS
═══════════════════════════════════════════════════════════════════════════════

1. After all fixes applied → Run:
   flutter test test/unit/ test/widget/ test/integration/

2. Capture output and identify:
   - Tests passed: X/Y
   - Tests failed: List each failure
   - Reason for each failure

3. For each failed test:
   - Determine if it's a compilation issue (go back to Phase 2)
   - Or a logic issue (fix in the actual implementation)

ACTION: Report test results. If failures exist, loop back to Phase 2.

═══════════════════════════════════════════════════════════════════════════════

### PHASE 4: HEALTH CHECK VERIFICATION
═══════════════════════════════════════════════════════════════════════════════

Verify these services are properly initialized (check lib/main.dart and main files):

✓ Firebase initialization
✓ Firestore configuration
✓ Riverpod providers (no missed dependencies)
✓ Agora SDK initialization (web context properly handled)
✓ NotificationService setup
✓ Auth service configuration
✓ Deep linking setup (if applicable)

For each service:
- Confirm import exists
- Confirm initialization in main() or equivalent
- Confirm no runtime null pointer risks

ACTION: Report health check status. Flag any missing initializations.

═══════════════════════════════════════════════════════════════════════════════

### PHASE 5: LOOP UNTIL STABLE
═══════════════════════════════════════════════════════════════════════════════

If tests failed or health checks failed:
  → Go back to PHASE 1 and scan for NEW errors created by fixes
  → Apply fixes
  → Re-run tests
  → Repeat until:
     ✓ All tests pass (100%)
     ✓ No compilation errors
     ✓ All health checks pass

If stable:
  → Proceed to PHASE 6

═══════════════════════════════════════════════════════════════════════════════

### PHASE 6: BUILD VERIFICATION
═══════════════════════════════════════════════════════════════════════════════

Run production builds to ensure no build-time issues:

1. flutter build web --release
2. flutter build apk --release
3. flutter build ios --release (if on macOS)

Capture output. Report:
- Build success/failure
- Any warnings to address
- Final artifact paths

═══════════════════════════════════════════════════════════════════════════════

### PHASE 7: FINAL REPORT
═══════════════════════════════════════════════════════════════════════════════

Generate summary:

📋 FILES MODIFIED: [List all files touched]
✅ TEST STATUS: X/Y tests passing (100% = PASS)
✅ HEALTH CHECKS: All critical services initialized
🏗️ BUILD STATUS: Web/APK/iOS build success
🎯 MVP STATUS: Ready for deployment

List any remaining minor warnings or recommendations.

═══════════════════════════════════════════════════════════════════════════════

### RULES
═══════════════════════════════════════════════════════════════════════════════

1. Do NOT skip Phase 1 → You MUST scan for errors before fixing
2. Do NOT fix partially → Fix ALL detected errors before testing
3. Do NOT guess types → Check existing models/ folder first
4. Do NOT ignore test failures → Loop until 100% pass rate
5. Do NOT skip health checks → Every service must be properly initialized
6. Do NOT build without testing → Tests must pass before build attempt
7. Be VERBOSE → Report each step, each fix, each test result
8. Be SYSTEMATIC → Follow the phases in order

═══════════════════════════════════════════════════════════════════════════════

### START NOW
═══════════════════════════════════════════════════════════════════════════════

Begin with PHASE 1: Scan lib/ and test/ folders for ALL compilation errors.
Report what you find, then wait for my confirmation before proceeding to Phase 2.

Ready? Start scanning.
```

---

## **How to Use This Prompt**

1. **Copy the entire block** between the triple backticks (starting with "You are now in AI Auto-Fix mode..." and ending with "Ready? Start scanning.")

2. **Open VS Code Chat** (Ctrl+Shift+I)

3. **Paste the prompt** into the chat input

4. **Press Enter** to execute

5. The AI will start Phase 1 (scanning for errors) and report back

6. Review the findings, then say **"Continue to Phase 2"** to proceed with fixes

7. Once Phase 2 is done, the AI will automatically run tests and report

8. The loop continues until all tests pass and health checks are verified

---

## **Expected Timeline**

- **Phase 1 (Scan):** 2-3 minutes
- **Phase 2 (Fix all errors):** 5-10 minutes
- **Phase 3 (Test):** 3-5 minutes
- **Phase 4 (Health Check):** 2-3 minutes
- **Phase 5 (Loop if needed):** 5-15 minutes (depending on failures)
- **Phase 6 (Build):** 3-5 minutes per platform

**Total: ~20-50 minutes** for fully MVP-ready app

---

## **What Success Looks Like**

```
✅ All 424+ tests passing
✅ 0 compilation errors
✅ All health checks green
✅ Flutter Web build succeeds
✅ Flutter APK build succeeds
✅ No critical warnings
✅ App ready for deployment
```

---

## **Next Steps**

1. **Copy the prompt above**
2. **Paste into VS Code Chat**
3. **Let it run automatically**
4. **Check back periodically** for phase completions
5. **Approve proceeding** to next phase when ready

---

**Let me know when you're ready to paste this into VS Code Chat!** 🚀
