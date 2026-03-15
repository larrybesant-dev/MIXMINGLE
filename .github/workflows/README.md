# GitHub Actions CI/CD Workflows

This repository uses GitHub Actions for automated testing, building, and deployment.

## 🔄 Workflows

### 1. CI - Quality Checks (`ci.yml`)

**Triggers:** Every push/PR to `main` or `develop`

**What it does:**

- ✅ Runs `flutter analyze` to catch code issues
- ✅ Verifies code formatting
- ✅ Runs all tests
- ✅ Generates coverage reports
- ✅ Blocks commits with build artifacts

**Status:** Auto-runs on every commit

---

### 2. Build & Release APK (`build-android.yml`)

**Triggers:**

- Git tags like `v1.0.0`, `v1.0.1`, etc.
- Manual trigger via Actions tab

**What it does:**

- 🔨 Builds release APKs (split per ABI)
- 📦 Builds App Bundle (AAB) for Play Store
- 📤 Uploads artifacts (30-day retention)
- 🎉 Creates GitHub Release with downloadable APKs

**How to use:**

```bash
# Create a new release
git tag v1.0.0
git push origin v1.0.0
```

**Output:** GitHub Release with:

- `app-arm64-v8a-release.apk` (most devices)
- `app-armeabi-v7a-release.apk` (older devices)
- `app-x86_64-release.apk` (emulators)
- `app-release.aab` (Play Store upload)

---

### 3. Deploy Flutter Web (`deploy-web.yml`)

**Triggers:**

- Every push to `main`
- Manual trigger via Actions tab

**What it does:**

- 🌐 Builds Flutter web (CanvasKit renderer)
- 🚀 Deploys to GitHub Pages
- 🔄 Auto-updates on every push to main

**Live URL:**
Will be available at: `https://larrybesant.github.io/MIXMINGLE/`

**Setup required:**

1. Go to repo Settings → Pages
2. Set Source to "GitHub Actions"
3. Save

---

## 🎯 Quick Commands

### Release a new version

```bash
# Update version in pubspec.yaml first
# Then create and push a tag
git tag v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### Manual workflow trigger

1. Go to Actions tab on GitHub
2. Select the workflow
3. Click "Run workflow"
4. Choose branch and run

### View deployment

- **CI Status:** Check the Actions tab
- **Web App:** `https://larrybesant.github.io/MIXMINGLE/`
- **Releases:** Check Releases section for APKs

---

## 🔒 Security

- ✅ No build artifacts in repository
- ✅ All builds happen in CI
- ✅ APKs distributed via GitHub Releases
- ✅ Credentials never committed

---

## 📊 Badges (Optional)

Add to README.md:

```markdown
[![CI](https://github.com/larrybesant/MIXMINGLE/actions/workflows/ci.yml/badge.svg)](https://github.com/larrybesant/MIXMINGLE/actions/workflows/ci.yml)
[![Deploy Web](https://github.com/larrybesant/MIXMINGLE/actions/workflows/deploy-web.yml/badge.svg)](https://github.com/larrybesant/MIXMINGLE/actions/workflows/deploy-web.yml)
```

---

## 🐛 Troubleshooting

**CI failing?**

- Check `flutter analyze` output
- Fix any linting errors
- Ensure tests pass locally first

**Build failing?**

- Verify Flutter version matches (3.24.3)
- Check Android build configuration
- Review build logs in Actions tab

**Web deploy not working?**

- Enable GitHub Pages in repo settings
- Set source to "GitHub Actions"
- Check Actions tab for errors

---

## 🚀 Next Steps

1. **Enable GitHub Pages** for web deployment
2. **Create your first release** with a version tag
3. **Monitor CI** on every commit
4. **Share APKs** via Releases page

Every commit is now automatically tested and validated. 🎉
