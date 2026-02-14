# Mix & Mingle CI/CD Pipeline

This repository uses GitHub Actions for comprehensive CI/CD with automated testing, quality checks, and deployment.

## 🚀 Pipeline Overview

The CI/CD pipeline runs on every push and pull request to `main` and `develop` branches:

### Jobs

1. **Unit Tests** - Flutter widget and unit tests with coverage reporting
2. **Authentication Tests** - Dedicated testing for login/signup flows
3. **Integration Tests** - Full app integration tests with Firebase emulators
4. **E2E Tests** - Playwright browser tests against built Flutter Web app
5. **Build Check** - Cross-platform build verification
6. **Golden Tests** - Visual regression testing
7. **Deploy to Firebase** - Automatic deployment on main branch pushes

## 📋 Prerequisites

### Required Secrets

Set these in your GitHub repository settings:

- `FIREBASE_SERVICE_ACCOUNT` - Firebase service account JSON (for deployment)

### Required Dependencies

- Flutter SDK (automatically installed)
- Node.js (for Playwright tests)
- Android SDK (for integration tests)
- Firebase CLI (automatically installed)

## 🧪 Test Coverage

### Unit Tests (`flutter test`)

- Widget rendering tests
- Business logic tests
- Authentication flow tests (mocked)
- Form validation tests

### Authentication Tests (`flutter test test/mocked_login_flow_test.dart`)

- Login success scenarios
- Login failure scenarios
- Form validation
- Error message display

### Integration Tests (`flutter test integration_test/`)

- Full app flows with Firebase emulators
- Android emulator testing
- Real authentication testing

### E2E Tests (Playwright)

- Browser-based testing of Flutter Web
- User journey validation
- Cross-browser compatibility
- Firebase emulator integration

## 🔧 Local Development

### Run Tests Locally

```bash
# All tests
flutter test

# Specific test files
flutter test test/mocked_login_flow_test.dart
flutter test test/login_flow_test.dart

# With coverage
flutter test --coverage
```

### Run Playwright Tests Locally

```bash
# Install dependencies
cd playwright-tests
npm install

# Install browsers
npx playwright install

# Run tests
npm test
```

### Run Local CI Pipeline

```powershell
# Windows
.\ci-pipeline.ps1
```

```bash
# Linux/macOS
chmod +x ci-pipeline.sh
./ci-pipeline.sh
```

## 📊 Coverage Reporting

- **Codecov Integration**: Unit test coverage uploaded automatically
- **Test Results**: Playwright results saved as artifacts
- **Golden Screenshots**: Visual regression screenshots saved

## 🚀 Deployment

### Automatic Deployment

- Triggers on pushes to `main` branch
- Requires all tests to pass
- Deploys to Firebase Hosting
- Uses production build configuration

### Manual Deployment

```bash
# Build for production
flutter build web --release --dart-define=ENVIRONMENT=production

# Deploy to Firebase
firebase deploy --only hosting
```

## 🔍 Monitoring & Debugging

### View Test Results

- **GitHub Actions**: Check the Actions tab for detailed logs
- **Coverage Reports**: View on Codecov (link in PR comments)
- **Test Artifacts**: Download screenshots and test results from Actions

### Common Issues

#### Tests Timeout

- Increase timeout in workflow files
- Check for async operations not completing
- Verify Firebase emulator startup

#### Playwright Browser Issues

- Ensure browsers are installed: `npx playwright install --with-deps`
- Check Node.js version compatibility
- Verify Flutter Web build is accessible

#### Firebase Deployment Fails

- Check `FIREBASE_SERVICE_ACCOUNT` secret is set
- Verify Firebase project permissions
- Ensure `firebase.json` is configured correctly

## 🛠️ Workflow Customization

### Adding New Tests

1. Create test files in `test/` directory
2. Update workflow jobs if needed
3. Add to CI pipeline documentation

### Modifying Deployment

1. Update `deploy-to-firebase` job in `flutter-cicd.yml`
2. Modify build commands for different environments
3. Update Firebase configuration

### Environment Variables

Add environment variables to workflow jobs:

```yaml
env:
  MY_VAR: ${{ secrets.MY_SECRET }}
```

## 📈 Best Practices

- **Fast Feedback**: Unit tests run first for quick feedback
- **Parallel Jobs**: Tests run in parallel to reduce CI time
- **Artifact Upload**: Save test results and screenshots for debugging
- **Conditional Deployment**: Only deploy when all tests pass
- **Coverage Tracking**: Monitor code coverage over time

## 🔗 Related Files

- `.github/workflows/flutter-cicd.yml` - Main CI/CD pipeline
- `.github/workflows/flutter-tests.yml` - Testing-focused workflow
- `.github/workflows/firebase-hosting.yml` - Deployment workflow
- `ci-pipeline.ps1` / `ci-pipeline.sh` - Local CI pipeline scripts
- `playwright-tests/` - E2E test suite
- `test/` - Flutter unit and widget tests
