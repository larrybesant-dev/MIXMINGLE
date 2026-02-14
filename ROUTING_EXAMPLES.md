# Mix & Mingle Routing Usage Examples

## Basic Navigation

### Navigate to a Simple Route
```dart
// Navigate to home
Navigator.of(context).pushNamed(AppRoutes.home);

// Navigate to matches
Navigator.of(context).pushNamed(AppRoutes.matches);

// Navigate to settings
Navigator.of(context).pushNamed(AppRoutes.settings);
```

### Navigate with Query Parameters
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

// Navigate to chat by chatId
Navigator.of(context).pushNamed(
  AppRoutes.chat,
  arguments: {'chatId': 'chat789'},
);

// Navigate to chat by userId (creates chat if needed)
Navigator.of(context).pushNamed(
  AppRoutes.chat,
  arguments: {'userId': 'user456'},
);
```

### Navigate and Replace Current Route
```dart
// After logout
Navigator.of(context).pushReplacementNamed(AppRoutes.login);

// After successful login
Navigator.of(context).pushReplacementNamed(AppRoutes.home);

// After profile creation
Navigator.of(context).pushReplacementNamed(AppRoutes.home);
```

### Navigate and Clear Stack
```dart
// Go to home and clear all previous routes
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.home,
  (route) => false,
);

// Go to login and clear all routes
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.login,
  (route) => false,
);
```

## Deep Link Handling

### Parse and Navigate from Deep Link
```dart
// In your app's deep link handler
void handleDeepLink(String deepLinkUrl) {
  final uri = Uri.parse(deepLinkUrl);
  final result = AppRoutes.parseDeepLink(uri);

  if (result != null) {
    Navigator.of(context).pushNamed(
      result['route'] as String,
      arguments: result['arguments'] as Map<String, dynamic>,
    );
  } else {
    // Invalid deep link
    Navigator.of(context).pushNamed(
      AppRoutes.error,
      arguments: {'message': 'Invalid link'},
    );
  }
}

// Example deep link URLs
handleDeepLink('https://mixmingle.app/e/summer-party');
handleDeepLink('https://mixmingle.app/u/johndoe');
handleDeepLink('https://mixmingle.app/r/room123');
```

### Generate Deep Links
```dart
// Generate event deep link
String generateEventLink(String eventId) {
  return 'https://mixmingle.app${AppRoutes.deepLinkEventPrefix}$eventId';
}

// Generate profile deep link
String generateProfileLink(String userId) {
  return 'https://mixmingle.app${AppRoutes.deepLinkProfilePrefix}$userId';
}

// Share deep link
void shareEvent(String eventId) async {
  final link = generateEventLink(eventId);
  await Share.share('Check out this event: $link');
}
```

## Push Notification Navigation

### Handle Notification Tap
```dart
// In your notification handler
void onNotificationTapped(Map<String, dynamic> data) {
  final type = data['type'] as String?;

  switch (type) {
    case 'new_match':
      Navigator.of(context).pushNamed(AppRoutes.matches);
      break;

    case 'new_message':
      final chatId = data['chatId'] as String?;
      if (chatId != null) {
        Navigator.of(context).pushNamed(
          AppRoutes.chat,
          arguments: {'chatId': chatId},
        );
      }
      break;

    case 'event_starting':
      final eventId = data['eventId'] as String?;
      if (eventId != null) {
        Navigator.of(context).pushNamed(
          AppRoutes.eventDetails,
          arguments: {'eventId': eventId},
        );
      }
      break;

    case 'speed_dating_match':
      final partnerId = data['partnerId'] as String?;
      if (partnerId != null) {
        Navigator.of(context).pushNamed(
          AppRoutes.speedDatingDecision,
          arguments: {'partnerId': partnerId},
        );
      }
      break;

    default:
      Navigator.of(context).pushNamed(AppRoutes.notifications);
  }
}
```

## Widget-Based Navigation

### From a Button
```dart
ElevatedButton(
  onPressed: () {
    Navigator.of(context).pushNamed(AppRoutes.editProfile);
  },
  child: const Text('Edit Profile'),
)
```

### From a List Tile
```dart
ListTile(
  leading: const Icon(Icons.settings),
  title: const Text('Settings'),
  onTap: () {
    Navigator.of(context).pushNamed(AppRoutes.settings);
  },
)
```

### From a Card Tap
```dart
GestureDetector(
  onTap: () {
    Navigator.of(context).pushNamed(
      AppRoutes.userProfile,
      arguments: {'userId': match.userId},
    );
  },
  child: Card(
    child: // ... card content
  ),
)
```

### From FAB
```dart
FloatingActionButton(
  onPressed: () {
    Navigator.of(context).pushNamed(AppRoutes.createEvent);
  },
  child: const Icon(Icons.add),
)
```

## Bottom Navigation Bar Integration

```dart
class MainNavigation extends StatefulWidget {
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.matches);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.chats);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.events);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
```

## Error Handling

### Navigate to Error Page
```dart
// With custom message
Navigator.of(context).pushNamed(
  AppRoutes.error,
  arguments: {'message': 'Something went wrong'},
);

// With retry callback (for programmatic navigation)
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ErrorPage(
      message: 'Failed to load data',
      onRetry: () {
        // Retry logic
        Navigator.of(context).pop();
        _loadData();
      },
    ),
  ),
);
```

### Try-Catch Navigation
```dart
try {
  await Navigator.of(context).pushNamed(
    AppRoutes.room,
    arguments: {'room': room},
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Navigation failed: $e')),
  );
  Navigator.of(context).pushNamed(AppRoutes.browseRooms);
}
```

## Conditional Navigation

### Navigate Based on User State
```dart
void navigateToProfile(String userId, String currentUserId) {
  if (userId == currentUserId) {
    // Navigate to own profile
    Navigator.of(context).pushNamed(AppRoutes.profile);
  } else {
    // Navigate to other user's profile
    Navigator.of(context).pushNamed(
      AppRoutes.userProfile,
      arguments: {'userId': userId},
    );
  }
}
```

### Navigate Based on Auth State
```dart
void navigateAfterAction() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  } else {
    Navigator.of(context).pushNamed(AppRoutes.home);
  }
}
```

## Riverpod Integration

### Navigate from Provider
```dart
class NavigationController extends StateNotifier<void> {
  NavigationController() : super(null);

  void navigateToMatch(String matchId, BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.userProfile,
      arguments: {'userId': matchId},
    );
  }

  void navigateToChat(String chatId, BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.chat,
      arguments: {'chatId': chatId},
    );
  }
}

final navigationControllerProvider =
    StateNotifierProvider<NavigationController, void>((ref) {
  return NavigationController();
});
```

### Use in Widget
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ref.read(navigationControllerProvider.notifier)
           .navigateToMatch('user123', context);
      },
      child: const Text('View Profile'),
    );
  }
}
```

## Guard Testing

### Test AuthGate Redirect
```dart
testWidgets('redirects to login when not authenticated', (tester) async {
  await FirebaseAuth.instance.signOut();

  await tester.pumpWidget(MyApp());

  // Try to navigate to protected route
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  navigator.pushNamed(AppRoutes.home);
  await tester.pumpAndSettle();

  // Should be redirected to login
  expect(find.byType(LoginPage), findsOneWidget);
});
```

### Test ProfileGuard Redirect
```dart
testWidgets('redirects to create profile when incomplete', (tester) async {
  // Setup: User authenticated but no profile
  await FirebaseAuth.instance.signInAnonymously();

  await tester.pumpWidget(MyApp());

  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  navigator.pushNamed(AppRoutes.home);
  await tester.pumpAndSettle();

  // Should be redirected to create profile
  expect(find.byType(CreateProfilePage), findsOneWidget);
});
```

## Advanced Patterns

### Modal Bottom Sheet Navigation
```dart
void showUserActions(BuildContext context, String userId) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('View Profile'),
          onTap: () {
            Navigator.pop(context); // Close sheet
            Navigator.of(context).pushNamed(
              AppRoutes.userProfile,
              arguments: {'userId': userId},
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.message),
          title: const Text('Send Message'),
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).pushNamed(
              AppRoutes.chat,
              arguments: {'userId': userId},
            );
          },
        ),
      ],
    ),
  );
}
```

### Dialog with Navigation
```dart
void showDeleteConfirmation(BuildContext context, String itemId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: const Text('Are you sure you want to delete this?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context); // Close dialog
            await deleteItem(itemId);
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
```

### Nested Navigation
```dart
class HomePageWithTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Feed'),
              Tab(text: 'Discover'),
              Tab(text: 'Live'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FeedTab(),
            DiscoverTab(),
            LiveTab(),
          ],
        ),
      ),
    );
  }
}

// Each tab can navigate independently
class DiscoverTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.discoverUsers);
        },
        child: const Text('Discover More'),
      ),
    );
  }
}
```

## Migration from Old Routing

### Before (Old System)
```dart
// Old way - direct widget navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EventDetailsPage(event: event),
  ),
);
```

### After (New System)
```dart
// New way - named routes with arguments
Navigator.of(context).pushNamed(
  AppRoutes.eventDetails,
  arguments: {'eventId': event.id},
);
```

### Update Guide
1. Replace all `MaterialPageRoute` with `pushNamed`
2. Pass objects as IDs in arguments map
3. Remove direct widget imports from navigation code
4. Use `AppRoutes` constants instead of string literals
5. Add error handling for missing arguments
