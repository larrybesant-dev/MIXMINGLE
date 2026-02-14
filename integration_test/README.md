# Flutter Integration Tests for Mix & Mingle

This directory contains comprehensive integration tests for the Mix & Mingle Flutter app, covering authentication, profile management, and UI interactions.

## Test Coverage

### Authentication Tests (`auth_integration_test.dart`)
- ✅ Login page rendering and form validation
- ✅ Signup page rendering and form validation
- ✅ Navigation between login and signup pages
- ✅ Form field validation (empty fields, invalid email, password requirements)
- ✅ Error message display

### Profile Management Tests
- ✅ Profile edit page rendering with all form elements
- ✅ Profile form validation (required fields)
- ✅ Text input handling in all profile fields
- ✅ Profile picture UI elements and interactions

### Navigation Tests
- ✅ Splash screen navigation flow
- ✅ App bar and navigation elements
- ✅ Page transitions and routing

### UI/UX Tests
- ✅ Keyboard input handling
- ✅ Form field text input
- ✅ Button presence and styling
- ✅ App responsiveness

## Running the Tests

### Prerequisites
1. Ensure you have Flutter installed and configured
2. Set up a physical device or emulator (iOS Simulator/Android Emulator)
3. Make sure the device is connected and recognized by Flutter

### Running Integration Tests
```bash
# Run all integration tests
flutter test integration_test/

# Run specific test file
flutter test integration_test/auth_integration_test.dart

# Run tests on specific device
flutter test integration_test/ --device-id=<device-id>
```

### Available Devices
```bash
flutter devices
```

### Test Structure
Each test follows this pattern:
1. **Setup**: Pump the app widget with ProviderScope
2. **Navigation**: Navigate to the page being tested
3. **Interaction**: Perform user interactions (taps, text input)
4. **Verification**: Assert expected UI state and behavior

## Test Categories

### Widget Rendering Tests
Verify that all UI elements are present and correctly displayed:
- Form fields, buttons, labels
- Icons and images
- Navigation elements

### Form Validation Tests
Test input validation and error handling:
- Required field validation
- Email format validation
- Password strength requirements
- Error message display

### Navigation Tests
Test app navigation and routing:
- Page transitions
- Back button functionality
- Deep linking

### User Interaction Tests
Test user interactions and app responses:
- Button taps
- Text input
- Keyboard events
- Form submissions

## Best Practices

### Test Organization
- Group related tests using `group()` blocks
- Use descriptive test names that explain what is being tested
- Keep tests focused on a single feature or behavior

### Test Reliability
- Use `pumpAndSettle()` for animations and async operations
- Wait for navigation to complete before assertions
- Use appropriate timeouts for network operations

### Assertions
- Use specific finders (`find.text()`, `find.byType()`, etc.)
- Verify both presence and absence of elements
- Test error states and success states

## Troubleshooting

### Common Issues
1. **"No connected devices"**: Ensure a device/emulator is running
2. **Test timeouts**: Increase timeout values for slower operations
3. **Widget not found**: Check that navigation completed before assertions

### Debug Tips
- Add `await tester.pump()` calls to see intermediate states
- Use `print()` statements to debug test flow
- Check the Flutter driver logs for detailed error information

## Future Enhancements

- Add mock Firebase services for more comprehensive testing
- Implement screenshot comparison tests
- Add performance benchmarking tests
- Expand test coverage for edge cases and error scenarios