# MixMingle VS Code Workflow (Single Source of Truth)

## Setup (one-time only)

### 1. Open workspace correctly
```powershell
cd C:\Users\LARRY\MIXMINGLE
code .
```

**Do not open random folders. This is the only correct entry point.**

---

### 2. Install required extensions

When VS Code prompts to install recommended extensions, **click "Install All"**.

If it doesn't prompt, press:
- `Ctrl+Shift+P` → `Extensions: Show Recommended Extensions` → Install these:

✅ **Essential (non-negotiable):**
- Dart
- Flutter
- Firebase Tools (`toba.vsfire`)
- PowerShell
- ESLint

⚠️ **Optional (enable later):**
- Error Lens (inline errors)
- GitLens (version control)

❌ **Do NOT install:**
- AI Copilots (wait until app is stable)
- Themes/icon packs (performance hit)
- YAML/Prettier (conflicts with Dart formatter)

---

### 3. Verify Flutter environment

In VS Code terminal (`Ctrl+`` backtick):
```powershell
flutter doctor -v
```

Must show:
- ✅ Flutter (Channel stable)
- ✅ Chrome (for web debugging)
- ✅ VS Code

If anything shows ❌, fix it before proceeding.

---

## Daily workflow (how to actually use this)

### Start the app (the ONLY correct way)

1. Press **F5**
2. VS Code will:
   - Run `flutter pub get` (if needed)
   - Launch Chrome
   - Attach debugger
   - Show console logs in DEBUG CONSOLE tab

**Do NOT manually run `flutter run` in a terminal anymore.**

---

### If you need to clean build

`Ctrl+Shift+P` → `Tasks: Run Task` → `Flutter: Clean Build`

This runs: `flutter clean && flutter pub get`

---

### View console logs

After pressing F5, check:
- **DEBUG CONSOLE** tab (bottom panel) — Flutter app logs
- **TERMINAL** tab — Build output
- **PROBLEMS** tab — Static analysis errors

**Browser console (F12) is separate** — use for frontend JS errors.

---

### Hot reload vs Hot restart

- **Hot reload**: `Ctrl+F5` (keeps app state)
- **Hot restart**: `Ctrl+Shift+F5` (resets app state)

⚠️ **Auto-save on hot reload is DISABLED** for MixMingle (breaks Agora sessions).
Save manually: `Ctrl+S`

---

### Stop the app

- Press: `Shift+F5`
- Or: Red square button in debug toolbar

**Do NOT close Chrome directly** — always stop via VS Code.

---

## Testing with Firebase Emulators

### Start emulators first

In VS Code terminal:
```powershell
firebase emulators:start --only auth,storage
```

Keep this running in one terminal tab.

### Launch app with emulator config

`Ctrl+Shift+D` (Debug sidebar) → Select:
- `🔥 Flutter: Debug with Firebase Emulators`

Press F5.

---

## Common issues (and fixes)

### "Flutter: No device detected"
→ Chrome not found. Run: `flutter devices`
→ Must show `chrome (web)` in list.

### "Could not resolve path to Flutter SDK"
→ VS Code opened wrong folder.
→ Close VS Code. Run: `cd C:\Users\LARRY\MIXMINGLE && code .`

### "Gradle build failed" (Android)
→ Android config broken (known issue).
→ Stick to web (`-d chrome`) for now.

### Debug console shows nothing
→ Check **DEBUG CONSOLE** tab (not TERMINAL).
→ Make sure you pressed F5, not manually ran `flutter run`.

### Hot reload doesn't work
→ App crashed. Check DEBUG CONSOLE for stack trace.
→ Stop (Shift+F5) and restart (F5).

---

## Terminal commands (use sparingly)

Only run these when the UI doesn't provide the option:

```powershell
# Check Flutter health
flutter doctor

# Update dependencies
flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test

# Clean build artifacts
flutter clean
```

**Everything else should go through F5 or VS Code tasks.**

---

## File structure (where things are)

```
.vscode/
├── launch.json       — F5 debug configurations
├── tasks.json        — Build tasks (Ctrl+Shift+P → Run Task)
├── settings.json     — Dart/Flutter settings
└── extensions.json   — Required extensions

lib/
└── main.dart         — App entry point (what F5 runs)

functions/
└── index.js          — Firebase Cloud Functions

test/
└── *_test.dart       — Flutter tests
```

---

## Rules (enforce these)

1. **Always open via `code .` from C:\Users\LARRY\MIXMINGLE**
2. **Always start app with F5** (not manual commands)
3. **Always use VS Code terminal** (Ctrl+`)
4. **Never close browser directly** (stop via Shift+F5)
5. **Post exact errors** (from DEBUG CONSOLE, not guesses)

---

## Next steps

1. Press F5
2. If it fails, copy the **exact error** from DEBUG CONSOLE
3. Paste error here
4. Get targeted fix

No more "it's broken" — only "here's the error at line X".
