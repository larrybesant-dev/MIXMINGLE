# Mix & Mingle Full Smoke Test

A comprehensive Playwright-based smoke test for the Mix & Mingle Flutter web application.

## Features Tested

- **Authentication**: Checks if login is required and attempts automated login
- **Speed Dating**: Tests speed dating lobby access
- **Chat**: Tests direct messaging functionality
- **Events**: Tests event browsing and management
- **Profile**: Tests user profile management
- **Notifications**: Tests push notifications and alerts
- **Go Live**: Tests live streaming functionality
- **Messages**: Tests messages page and direct messaging

## Prerequisites

- Node.js 18+
- Playwright installed (`npm install`)

## Usage

### Run the Full Smoke Test

```bash
cd playwright-tests
npm run full-smoke-test
```

### Test Account Setup

Update the test credentials in `full-smoke-test.js`:

```javascript
const TEST_EMAIL = 'your-test-account@example.com';
const TEST_PASSWORD = 'YourTestPassword123!';
```

## Output

The test creates a `smoke-test-results/` directory containing:

- **`feature-status-report.csv`**: Detailed test results
- **`app-loaded.png`**: Screenshot of the loaded application
- **`<feature>-missing.png`**: Screenshots of missing features
- **`<feature>-error.png`**: Screenshots of features with errors (if any)
- **`<feature>-coming-soon.png`**: Screenshots of "Coming Soon" features (if any)

## CSV Report Format

```csv
Feature,Status,Details,Screenshot
"Authentication","Working","No login required",""
"Speed Dating","Missing","Feature not found in UI","C:\path\to\screenshot.png"
```

### Status Values

- **Working**: Feature is accessible and functional
- **Coming Soon**: Feature shows "Coming Soon" message
- **Missing**: Feature not found in the UI
- **Error**: Feature encountered an error during testing
- **Failed**: Test execution failed

## Test Flow

1. **App Loading**: Verifies the app loads with correct title
2. **Authentication**: Checks login requirements and attempts login if needed
3. **Feature Testing**: Tests each feature using multiple selector strategies
4. **Error Analysis**: Monitors and reports JavaScript console errors
5. **Report Generation**: Creates CSV report and screenshots

## Flutter Web Compatibility

This test is designed to work with Flutter Web applications that use HTML rendering. It uses multiple selector strategies to locate UI elements:

- ARIA labels and attributes
- CSS selectors with `:has()` pseudo-selectors
- Text content matching
- Data attributes and tooltips

## Flutter Web Test-Friendly Keys

The Flutter app has been updated with test-friendly keys for reliable UI element detection:

### Navigation Buttons (App Bar)

- `Key('browse-rooms-btn')` - Browse Rooms button
- `Key('speed-dating-btn')` - Speed Dating button
- `Key('search-btn')` - Search button
- `Key('notifications-btn')` - Notifications button
- `Key('profile-btn')` - Profile button

### Floating Action Button

- `Key('go-live-btn')` - Go Live button

### Messages Page

- `Key('messages-search-toggle-btn')` - Search/Messages toggle button in app bar
- `Key('messages-filter-btn')` - Filter button (shown when searching)
- `Key('discover-users-btn')` - Discover Users button (empty state)
- `Key('messages-retry-btn')` - Retry button (error state)
- `Key('conversation-{id}')` - Individual conversation tiles
- `Key('message-search-{id}')` - Message search result tiles
- `Key('messages-start-date-btn')` - Start date picker button (advanced search)
- `Key('messages-end-date-btn')` - End date picker button (advanced search)
- `Key('messages-clear-filters-btn')` - Clear filters button (advanced search dialog)
- `Key('messages-cancel-filters-btn')` - Cancel button (advanced search dialog)
- `Key('messages-apply-filters-btn')` - Apply filters button (advanced search dialog)

### Profile Page

- `Key('profile-edit-btn')` - Edit button in app bar
- `Key('profile-settings-btn')` - Settings button in app bar
- `Key('edit-profile-main-btn')` - Edit Profile button (main action)
- `Key('settings-main-btn')` - Settings button (main action)
- `Key('start-speed-dating-btn')` - Start Speed Dating button
- `Key('retry-matches-btn')` - Retry button (for loading matches)
- `Key('join-room-{id}')` - Join button for live rooms

### Speed Dating Lobby Page

- `Key('speed-dating-back-btn')` - Back button in app bar
- `Key('cancel-search-btn')` - Cancel button (when searching for match)
- `Key('cancel-waiting-btn')` - Cancel button (when waiting for partner)
- `Key('find-match-btn')` - Find Match button

### Usage in Flutter Code

```dart
IconButton(
  key: const Key('speed-dating-btn'),
  icon: Icon(Icons.favorite),
  onPressed: () => navigateToSpeedDating(),
  tooltip: 'Speed Dating',
)
```

### Playwright Selectors

The test uses multiple selector strategies, with test keys as the primary method:

```javascript
selectors: [
  '[data-testid="speed-dating-btn"]',  // Primary: Test key
  '[aria-label*="Speed Dating"]',      // Fallback: ARIA label
  'button:has-text("favorite")',       // Fallback: Icon text
  // ... more fallbacks
]
```

## Troubleshooting

### Features Not Found

If features are reported as "Missing":

1. Check if the Flutter app uses CanvasKit rendering (switch to HTML renderer)
2. Verify feature selectors in the `FEATURES` array
3. Add semantic labels to Flutter widgets for better testability

### Login Issues

- Ensure test credentials are valid
- Check if the app uses Google OAuth (may require additional setup)
- Verify login form selectors match your implementation

### Screenshots Not Saving

- Ensure write permissions in the output directory
- Check available disk space
- Verify Playwright browser launch permissions

## Configuration

### Browser Options

The test runs in non-headless mode for visibility. To run headless:

```javascript
browser = await chromium.launch({
  headless: true, // Change to true for headless
  args: ['--no-sandbox', '--disable-setuid-sandbox']
});
```

### Timeout Adjustments

Adjust timeouts as needed:

```javascript
await page.goto(APP_URL, {
  waitUntil: 'networkidle',
  timeout: 30000 // 30 seconds
});
```

## Integration with CI/CD

Add to your deployment pipeline:

```yaml
- name: Run Smoke Tests
  run: |
    cd playwright-tests
    npm run full-smoke-test
  continue-on-error: true # Don't fail deployment on test issues
```

## Extending the Test

### Adding New Features

Add to the `FEATURES` array:

```javascript
{
  name: 'New Feature',
  selectors: [
    '[aria-label*="New Feature"]',
    'button:has-text("New Feature")',
    'text=/New Feature/i'
  ],
  description: 'Description of the new feature'
}
```

### Custom Selectors

For complex Flutter apps, you may need custom selectors:

```javascript
selectors: [
  '.flutter-view >> button', // Flutter-specific selectors
  '[data-semantic-label*="Feature"]', // Custom semantic labels
  'xpath=//button[contains(@aria-label, "Feature")]' // XPath selectors
]
```

## Support

For issues with Flutter Web testing:

1. Ensure HTML renderer is enabled in `web/index.html`
2. Add semantic labels to interactive elements
3. Consider using Flutter integration tests for more reliable UI testing
