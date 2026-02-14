# Mix & Mingle Routing System Documentation

## Overview
Complete routing system with authentication guards, profile completeness checks, event guards, animated transitions, deep linking support, and query parameter handling.

## Architecture

### Route Guards
1. **AuthGate** - Ensures user is authenticated
2. **ProfileGuard** - Ensures user has completed profile setup
3. **EventGuard** - Ensures user has access to event-related features

### Route Categories

#### Public Routes (No Authentication Required)
- `/` - Splash screen
- `/landing` - Landing page
- `/login` - Login page (slide up transition)
- `/signup` - Signup page (slide up transition)
- `/forgot-password` - Password reset
- `/error` - Error page with custom message

#### Protected Routes (Authentication Required)
All routes below require authentication via `AuthGate`.

#### Profile Routes (Requires Profile Completeness)
- `/home` - Home page (fade transition)
- `/profile` - Current user's profile
- `/profile/user?userId={id}` - Other user's profile
- `/profile/edit` - Edit profile (slide up transition)
- `/create-profile` - Profile creation wizard

#### Matching Routes
- `/matches` - Matches and likes list
- `/discover-users` - Discover new users
- `/match-preferences` - Match preferences settings

#### Chat Routes
- `/chats` - Chat list
- `/chat?chatId={id}` - Open specific chat
- `/chat?userId={id}` - Open chat with user (creates if doesn't exist)
- `/messages` - Messages inbox

#### Speed Dating Routes (Requires Event Guard)
- `/speed-dating/lobby` - Speed dating lobby (requires active session)
- `/speed-dating/decision?partnerId={id}` - Decision page after match

#### Events Routes
- `/events` - Events list
- `/events/details?eventId={id}` - Event details
- `/events/create` - Create new event (slide up transition)

#### Room Routes
- `/room?roomId={id}` - Join room by ID
- `/room?room={object}` - Join room with Room object
- `/browse-rooms` - Browse available rooms
- `/discover-rooms` - Discover rooms
- `/create-room` - Create new room (slide up transition)
- `/go-live` - Go live in a room

#### Settings Routes
- `/settings` - Settings page
- `/settings/privacy` - Privacy settings
- `/settings/camera-permissions` - Camera permissions

#### Notification Routes
- `/notifications` - Notifications list (slide down transition)

#### Gamification Routes
- `/leaderboards` - Leaderboards
- `/achievements` - User achievements

#### Payment Routes
- `/buy-coins` - Coin purchase (slide up transition)
- `/withdrawal` - Withdrawal page
- `/withdrawal-history` - Withdrawal history

#### Admin Routes
- `/admin` - Admin dashboard (requires admin role)

## Deep Links

### Supported Deep Link Patterns

#### Event Deep Link
- Pattern: `/e/{eventId}`
- Example: `https://mixmingle.app/e/event123`
- Routes to: Event details page

#### Room Deep Link
- Pattern: `/r/{roomId}`
- Example: `https://mixmingle.app/r/room456`
- Routes to: Room page

#### Profile Deep Link
- Pattern: `/u/{userId}`
- Example: `https://mixmingle.app/u/user789`
- Routes to: User profile page

#### Speed Dating Deep Link
- Pattern: `/sd/{sessionId}`
- Example: `https://mixmingle.app/sd/session123`
- Routes to: Speed dating lobby

### Deep Link Implementation

```dart
// Parse deep link in app initialization
final uri = Uri.parse(deepLinkUrl);
final result = AppRoutes.parseDeepLink(uri);

if (result != null) {
  Navigator.of(context).pushNamed(
    result['route'],
    arguments: result['arguments'],
  );
}
```

## Query Parameters

### How to Navigate with Query Parameters

```dart
// Navigate to user profile
Navigator.of(context).pushNamed(
  AppRoutes.userProfile,
  arguments: {'userId': 'user123'},
);

// Navigate to event details
Navigator.of(context).pushNamed(
  AppRoutes.eventDetails,
  arguments: {'eventId': 'event456'},
);

// Navigate to chat
Navigator.of(context).pushNamed(
  AppRoutes.chat,
  arguments: {
    'chatId': 'chat789',
    // OR
    'userId': 'user123', // Will create/find chat
  },
);
```

## Animated Transitions

### Transition Types

1. **Fade Transition** - Smooth fade in/out
   - Used for: Home, error pages, discover pages

2. **Slide Transition** - Slide from direction
   - Directions: left, right, up, down
   - Used for: Most navigation (left), modals (up), notifications (down)

3. **Scale Transition** - Scale with fade
   - Used for: Speed dating, room entry

### Transition Configuration

```dart
// Default values
static const Duration transitionDuration = Duration(milliseconds: 300);
static const Curve transitionCurve = Curves.easeInOutCubic;
```

## Route Guard Flow

### Authentication Flow
```
User navigates to protected route
  → AuthGate checks authentication
    → If not authenticated → Redirect to Login
    → If authenticated → Check profile completeness
      → ProfileGuard checks profile data
        → If incomplete → Redirect to CreateProfile
        → If complete → Show requested page
```

### Event Guard Flow
```
User navigates to speed dating
  → AuthGate → ProfileGuard → EventGuard
    → Check for active session
      → If no session → Show "No Active Session" page
      → If has session → Allow access
```

## Error Handling

### Missing Required Parameters
If required query parameters are missing, the system redirects to ErrorPage with a helpful message.

Example:
```dart
// Missing eventId
Navigator.pushNamed(AppRoutes.eventDetails); // No arguments

// Result: Shows ErrorPage with "Event ID is required"
```

### 404 Not Found
Any unmatched route shows ErrorPage with the attempted route name.

### Error Page Features
- Custom error message
- "Go Back" button
- Optional retry callback
- Consistent styling with app theme

## Navigation Best Practices

### 1. Use Named Routes
```dart
// Good
Navigator.of(context).pushNamed(AppRoutes.matches);

// Avoid
Navigator.push(context, MaterialPageRoute(builder: (_) => MatchesPage()));
```

### 2. Pass Arguments as Maps
```dart
Navigator.of(context).pushNamed(
  AppRoutes.chat,
  arguments: {
    'chatId': chatId,
    'userId': userId,
  },
);
```

### 3. Handle Navigation Errors
```dart
try {
  await Navigator.of(context).pushNamed(AppRoutes.room);
} catch (e) {
  // Handle navigation error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Navigation failed: $e')),
  );
}
```

### 4. Use Replacement for Login/Logout
```dart
// After logout
Navigator.of(context).pushReplacementNamed(AppRoutes.login);

// After login
Navigator.of(context).pushReplacementNamed(AppRoutes.home);
```

## Testing Routes

### Test Navigation
```dart
testWidgets('navigates to profile', (tester) async {
  await tester.pumpWidget(MyApp());

  // Trigger navigation
  await tester.tap(find.byIcon(Icons.person));
  await tester.pumpAndSettle();

  // Verify route
  expect(find.byType(ProfilePage), findsOneWidget);
});
```

### Test Deep Links
```dart
test('parses event deep link', () {
  final uri = Uri.parse('https://mixmingle.app/e/event123');
  final result = AppRoutes.parseDeepLink(uri);

  expect(result?['route'], AppRoutes.eventDetails);
  expect(result?['arguments']['eventId'], 'event123');
});
```

## Route Reachability Matrix

All routes are reachable through:
- Direct navigation from home page
- Bottom navigation bar (home, matches, chats, profile)
- Deep links
- Push notifications
- In-app navigation flows

### Unreachable Routes Check
✅ All routes have at least one entry point
✅ All routes have proper guard protection
✅ All routes handle missing parameters
✅ All routes have fallback error handling

## Performance Considerations

1. **Lazy Loading** - Routes are only built when accessed
2. **Guard Caching** - Profile data is cached after first check
3. **Transition Duration** - 300ms balances smoothness and speed
4. **Deep Link Parsing** - Efficient string operations

## Future Enhancements

- [ ] Route analytics tracking
- [ ] A/B testing different transitions
- [ ] Route preloading for anticipated navigation
- [ ] Breadcrumb navigation for complex flows
- [ ] Custom transition curves per route type
