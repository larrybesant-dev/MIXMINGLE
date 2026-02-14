# Playwright E2E Tests for Mix & Mingle

This directory contains comprehensive end-to-end tests for the Mix & Mingle Flutter web app using Playwright.

## Setup

1. **Install dependencies:**

   ```bash
   npm install
   ```

2. **Install Playwright browsers:**

   ```bash
   npx playwright install
   ```

## Running Tests

### All Tests

```bash
npm test
```

### Specific Test Files

```bash
# Authentication tests
npm run test:auth

# Home page tests
npm run test:home

# Rooms tests
npm run test:rooms

# Users tests
npm run test:users

# Messages tests
npm run test:messages

# Settings tests
npm run test:settings

# Happy path (complete user journey)
npm run test:happy-path
```

### Debug Mode

```bash
# Run tests in headed mode (see browser)
npm run test:headed

# Run tests with Playwright UI
npm run test:ui

# Run tests in debug mode
npm run test:debug
```

### CI Mode (for GitHub Actions)

```bash
npm run test:ci
```

## Test Coverage

The test suite covers:

- **Authentication:** Signup, login, validation, remember me
- **Home Page:** Navigation, search, "coming soon" features
- **Rooms:** Browsing, searching, filtering, joining, messaging
- **Users:** Discovery, profiles, following, messaging
- **Messages:** Conversations, chat functionality, reactions
- **Settings:** Account settings, privacy, notifications
- **Happy Path:** Complete user journey from signup to app usage

## Test Accounts

Tests use timestamp-based email addresses to avoid conflicts:

- Email: `testuser+{timestamp}@example.com`
- Password: `Test123!!`

## Configuration

Tests are configured in `playwright.config.js`:

- Base URL: `https://mix-and-mingle-62061.web.app`
- Parallel execution: 3 workers
- Retries: 2 on CI, 0 locally
- Screenshots and videos on failure
- Multiple browsers: Chromium, Firefox, WebKit
- Mobile viewports: Chrome Mobile, Safari Mobile

## Reports

After running tests, reports are generated in:

- `playwright-report/`: HTML report
- `test-results/`: Screenshots and videos

## CI/CD

Tests run automatically on:

- Push to main/master branches
- Pull requests to main/master branches
- Manual workflow dispatch

Reports are uploaded as artifacts for 30 days.

## Troubleshooting

### Common Issues

1. **Tests failing due to timing:**
   - Tests include appropriate waits and retries
   - Check network connectivity to Firebase Hosting

2. **Authentication issues:**
   - Ensure test accounts aren't rate-limited
   - Check Firebase Auth configuration

3. **Element not found:**
   - UI might have changed; update selectors in tests
   - Use Playwright's codegen to find new selectors:

     ```bash
     npx playwright codegen https://mix-and-mingle-62061.web.app
     ```

### Debugging

1. **Run in headed mode:**

   ```bash
   npm run test:headed
   ```

2. **Use Playwright UI:**

   ```bash
   npm run test:ui
   ```

3. **Debug specific test:**

   ```bash
   npx playwright test --debug auth.spec.js
   ```

## Contributing

When adding new tests:

1. Follow the existing pattern with `beforeEach` for authentication
2. Use descriptive test names
3. Include appropriate assertions
4. Handle both success and error cases
5. Add tests for "coming soon" features to verify placeholders

## Dependencies

- `@playwright/test`: ^1.40.0
- Node.js: LTS version
