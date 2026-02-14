# 🧹 Project Cleanup — Quick Start

## What This Does

Removes EVERYTHING your app doesn't need:
- ✅ Stub/old/deprecated Dart files
- ✅ Unused imports & code
- ✅ Unused assets (images, etc.)
- ✅ Build cache & temporary files
- ✅ Unused dependencies
- ✅ Identifies code quality issues

---

## Run Cleanup

### Option 1: VS Code Terminal
```powershell
.\cleanup_project.ps1
```

### Option 2: PowerShell Directly
```powershell
pwsh -ExecutionPolicy Bypass -File cleanup_project.ps1
```

---

## What You Get

### Report Files (automatically generated)
```
cleanup_report_TIMESTAMP.md          ← Full cleanup report
flutter_analyze_TIMESTAMP.txt        ← Code quality issues
pubspec_deps_TIMESTAMP.txt           ← Dependency analysis
cleanup_backup_TIMESTAMP/            ← Backup of original files
```

### Review the Report
```powershell
# View cleanup report
cat cleanup_report_*.md

# View code issues
cat flutter_analyze_*.txt

# View dependencies
cat pubspec_deps_*.txt
```

---

## After Cleanup: Fix Remaining Issues

### 1. Fix Code Quality Issues
Review `flutter_analyze_*.txt` and fix:
- ❌ **Errors** (must fix before building)
- ⚠️ **Warnings** (should fix)
- ℹ️ **Info** (optional improvements)

```powershell
# View errors
cat flutter_analyze_*.txt | Select-String "error"
```

### 2. Remove Unused Packages
```powershell
# List all dependencies
flutter pub deps

# Remove unused package
flutter pub remove package_name
flutter pub get
```

### 3. Delete Unused Assets
If cleanup found unused assets:
```powershell
Remove-Item "assets/path/unused/image.png" -Force
```

### 4. Verify Build Works
```powershell
flutter clean
flutter pub get
flutter build web --release
# or
flutter build apk --release
```

---

## If Something Breaks

Restore from backup:
```powershell
# List available backups
ls cleanup_backup_*/

# Restore specific backup
Copy-Item "cleanup_backup_20260206_120000/lib_backup" -Destination "lib" -Recurse -Force
Copy-Item "cleanup_backup_20260206_120000/pubspec.yaml.backup" -Destination "pubspec.yaml" -Force
flutter clean
flutter pub get
```

---

## Common Findings & Fixes

### "error: undefined name 'xxx'"
- Likely from removed file
- Either restore from backup or implement missing code

### "Unused import"
- Already removed by `dart fix --apply`
- Run `flutter analyze` again

### "Unused class/function"
- Remove or use (implement if needed for future)
- Safe to delete if not used

### "Unused assets"
- Cleanup script identifies them
- Delete only if you're sure they're not needed
- Check Firebase Storage, Cloud Functions for references

---

## Production Checklist After Cleanup

- [ ] No ERROR-level issues in flutter analyze
- [ ] All WARNING messages reviewed & addressed
- [ ] Unused packages removed
- [ ] Unused assets deleted
- [ ] Build successful: `flutter build web --release`
- [ ] Build successful: `flutter build apk --release`
- [ ] All tests pass: `flutter test`

---

## Timeline

| Step | Duration |
|------|----------|
| Backup creation | 1-2 min |
| Remove stub files | 1 sec |
| Apply Dart fixes | 30 sec |
| Asset analysis | 1-2 min |
| Code analysis | 2-3 min |
| Clean & refresh | 5-10 min |
| **Total** | **10-20 min** |

---

## Output Summary

After running, you'll see:
```
✅ Removed X stub/old/deprecated files
✅ Applied Dart fixes
✅ Identified Y unused assets
✅ Found Z code quality issues
✅ Cleaned Flutter project
✅ Generated cleanup report
```

---

## Next: Production Build

Once cleanup is verified:
```powershell
.\ultimate_production.ps1
```

This will:
1. Build Android APK/AAB
2. Build Web
3. Deploy Web to Firebase
4. Run tests
5. Generate production report

---

**Ready?**
```powershell
.\cleanup_project.ps1
```

Then review `cleanup_report_*.md` for next steps.
