# 🚀 Mix & Mingle Routing Quick Reference

## 📱 Common Navigation Tasks

### Navigate to Page
```dart
Navigator.of(context).pushNamed(AppRoutes.matches);
```

### Navigate with Data
```dart
Navigator.of(context).pushNamed(
  AppRoutes.userProfile,
  arguments: {'userId': 'user123'},
);
```

### Replace Current Page
```dart
Navigator.of(context).pushReplacementNamed(AppRoutes.home);
```

### Clear Stack & Navigate
```dart
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.home,
  (route) => false,
);
```

## 🎯 Route Constants

### Public Routes (No Auth)
- `AppRoutes.splash` - `/`
- `AppRoutes.landing` - `/landing`
- `AppRoutes.login` - `/login`
- `AppRoutes.signup` - `/signup`
- `AppRoutes.forgotPassword` - `/forgot-password`

### Main Navigation (Bottom Bar)
- `AppRoutes.home` - `/home` 🏠
- `AppRoutes.matches` - `/matches` ❤️
- `AppRoutes.chats` - `/chats` 💬
- `AppRoutes.events` - `/events` 📅
- `AppRoutes.profile` - `/profile` 👤

### Profile Routes
- `AppRoutes.userProfile` - `/profile/user?userId={id}`
- `AppRoutes.editProfile` - `/profile/edit`
- `AppRoutes.createProfile` - `/create-profile`

### Chat Routes
- `AppRoutes.chat` - `/chat?chatId={id}` or `?userId={id}`
- `AppRoutes.messages` - `/messages`

### Event Routes
- `AppRoutes.eventDetails` - `/events/details?eventId={id}`
- `AppRoutes.createEvent` - `/events/create`

### Speed Dating
- `AppRoutes.speedDatingLobby` - `/speed-dating/lobby`
- `AppRoutes.speedDatingDecision` - `/speed-dating/decision?partnerId={id}`

### Room Routes
- `AppRoutes.room` - `/room?roomId={id}`
- `AppRoutes.browseRooms` - `/browse-rooms`
- `AppRoutes.createRoom` - `/create-room`

### Settings
- `AppRoutes.settings` - `/settings`
- `AppRoutes.privacySettings` - `/settings/privacy`
- `AppRoutes.notifications` - `/notifications`

### Other
- `AppRoutes.discoverUsers` - `/discover-users`
- `AppRoutes.buyCoins` - `/buy-coins`
- `AppRoutes.leaderboards` - `/leaderboards`
- `AppRoutes.achievements` - `/achievements`

## 🔐 Guards

### AuthGate
Ensures user is authenticated
- ✅ Passes: User logged in
- ❌ Redirects: → Login page

### ProfileGuard
Ensures profile is complete
- ✅ Passes: Has username, age, gender
- ❌ Redirects: → Create profile page

### EventGuard
Ensures event access
- ✅ Passes: Has active session or valid event
- ❌ Shows: "No active session" page

## 🔗 Deep Links

### Patterns
- Event: `https://mixmingle.app/e/{eventId}`
- Room: `https://mixmingle.app/r/{roomId}`
- Profile: `https://mixmingle.app/u/{userId}`
- Speed Dating: `https://mixmingle.app/sd/{sessionId}`

### Parse Deep Link
```dart
final uri = Uri.parse(url);
final result = AppRoutes.parseDeepLink(uri);

Navigator.of(context).pushNamed(
  result['route'],
  arguments: result['arguments'],
);
```

## 🎨 Transitions

### Types
- **Fade** - Smooth fade (Home, Error)
- **Slide Left** - Standard navigation
- **Slide Up** - Modals, Forms
- **Slide Down** - Notifications
- **Scale** - Speed Dating, Rooms

### Duration
All transitions: **300ms**

## 📋 Query Parameters

### Required Parameters
| Route | Parameter | Type |
|-------|-----------|------|
| userProfile | userId | String |
| chat | chatId OR userId | String |
| eventDetails | eventId | String |
| room | roomId OR room | String/Object |
| speedDatingDecision | partnerId | String |

### Example
```dart
Navigator.of(context).pushNamed(
  AppRoutes.eventDetails,
  arguments: {'eventId': 'evt_123'},
);
```

## ⚠️ Error Handling

### Missing Parameters
```dart
// Automatically shows error page with helpful message
Navigator.of(context).pushNamed(AppRoutes.eventDetails);
// Result: "Event ID is required"
```

### Custom Error
```dart
Navigator.of(context).pushNamed(
  AppRoutes.error,
  arguments: {'message': 'Custom error message'},
);
```

## 🧪 Testing

### Test Navigation
```dart
testWidgets('navigates to profile', (tester) async {
  await tester.pumpWidget(MyApp());

  final navigator = tester.state<NavigatorState>(
    find.byType(Navigator)
  );
  navigator.pushNamed(AppRoutes.profile);
  await tester.pumpAndSettle();

  expect(find.byType(ProfilePage), findsOneWidget);
});
```

## 💡 Best Practices

### ✅ DO
- Use `AppRoutes` constants
- Pass arguments as maps
- Handle navigation errors
- Use `pushReplacementNamed` for login/logout
- Test navigation flows

### ❌ DON'T
- Use string literals for routes
- Pass large objects as arguments (use IDs)
- Forget to handle missing parameters
- Create circular navigation loops
- Mix guard types unnecessarily

## 🔄 Common Patterns

### Login Flow
```dart
// After successful login
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.home,
  (route) => false,
);
```

### Logout Flow
```dart
// After logout
await FirebaseAuth.instance.signOut();
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.login,
  (route) => false,
);
```

### View Profile from Match
```dart
onTap: () {
  Navigator.of(context).pushNamed(
    AppRoutes.userProfile,
    arguments: {'userId': match.userId},
  );
}
```

### Open Chat from Profile
```dart
onPressed: () {
  Navigator.of(context).pushNamed(
    AppRoutes.chat,
    arguments: {'userId': profile.userId},
  );
}
```

### Join Event
```dart
onPressed: () {
  Navigator.of(context).pushNamed(
    AppRoutes.eventDetails,
    arguments: {'eventId': event.id},
  );
}
```

## 📱 Push Notifications

### Handle Notification Tap
```dart
void onNotificationTap(Map<String, dynamic> data) {
  switch (data['type']) {
    case 'new_match':
      Navigator.pushNamed(context, AppRoutes.matches);
      break;
    case 'new_message':
      Navigator.pushNamed(
        context,
        AppRoutes.chat,
        arguments: {'chatId': data['chatId']},
      );
      break;
    case 'event_starting':
      Navigator.pushNamed(
        context,
        AppRoutes.eventDetails,
        arguments: {'eventId': data['eventId']},
      );
      break;
  }
}
```

## 🎯 Quick Checklist

Before pushing navigation code:
- [ ] Using `AppRoutes` constant?
- [ ] Required parameters provided?
- [ ] Error handling in place?
- [ ] Correct guard level?
- [ ] Appropriate transition?
- [ ] Navigation tested?

## 📚 Full Documentation
- [Complete Routing System](ROUTING_SYSTEM.md)
- [Route Map & Accessibility](ROUTE_MAP.md)
- [Detailed Examples](ROUTING_EXAMPLES.md)
