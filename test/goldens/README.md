# Golden Tests for Mix & Mingle

This directory contains visual regression tests for the Mix & Mingle Flutter app using the `golden_toolkit` package.

## Overview

Golden tests capture screenshots of UI components and compare them against reference images to detect unintended visual changes. These tests ensure that UI elements render correctly across different screen sizes and states.

## Test Structure

The golden tests are organized in `test/golden_tests.dart` and cover the following components:

### HomePage Tests

- **Default**: Basic home page rendering
- **Mobile**: Home page on mobile screen size (375x812)
- **Tablet**: Home page on tablet screen size (768x1024)

### LoginPage Tests

- **Default**: Login form in initial state
- **Validation Error**: Login form with validation errors displayed
- **Filled**: Login form with sample data entered

### SignupPage Tests

- **Default**: Signup form in initial state
- **Validation Error**: Signup form with validation errors displayed
- **Partial Data**: Signup form with some fields filled

### ProfileEditPage Tests

- **Empty**: Profile edit form with no initial data
- **With Data**: Profile edit form pre-populated with user data
- **Validation Error**: Profile edit form showing validation errors

## Running Tests

### Update Golden Files

When UI changes are intentional, update the golden files:

```bash
flutter test test/golden_tests.dart --update-goldens
```

### Run Comparison Tests

To verify UI matches golden files:

```bash
flutter test test/golden_tests.dart
```

### Run Specific Test

```bash
flutter test test/golden_tests.dart -k "HomePage default"
```

## CI/CD Integration

Golden tests run automatically in the CI/CD pipeline:

1. **Golden Tests Job**: Runs on Ubuntu with Flutter stable
2. **Artifact Upload**: Screenshots are uploaded as artifacts for review
3. **Parallel Execution**: Runs alongside unit and integration tests
4. **Dependency**: Must pass before deployment to production

## Mock Components

Since golden tests need to run without Firebase dependencies, we use mock implementations:

- `MockHomePage`: Simplified home page without Firebase auth
- `MockLoginPage`: Login form with local validation
- `MockSignupPage`: Signup form with local validation
- `MockProfileEditPage`: Profile editing with mock user data

## Golden File Management

- **Location**: `test/goldens/`
- **Naming**: `{component}_{variant}.png`
- **CI Artifacts**: Uploaded with 30-day retention
- **Updates**: Only update when UI changes are intentional

## Troubleshooting

### Test Failures

If tests fail due to expected UI changes:

1. Review the diff in CI artifacts
2. Update golden files if changes are intentional
3. Fix code if changes are unexpected

### Font Loading Issues

The tests load app fonts using `loadAppFonts()` to ensure consistent rendering.

### Screen Size Testing

Tests use `surfaceSize` parameter to test responsive layouts on different screen sizes.
