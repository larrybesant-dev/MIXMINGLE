# Phase 11: Quick Reference Guide

## 🚀 Most Common Use Cases

### 1. Safe AsyncValue Handling

```dart
// For single values
final userAsync = ref.watch(userProvider);
return userAsync.buildSafe(
  builder: (user) => Text('Hello ${user.name}'),
  onRetry: () => ref.refresh(userProvider),
);

// For lists
final roomsAsync = ref.watch(roomsProvider);
return roomsAsync.buildListSafe(
  builder: (rooms) => ListView.builder(
    itemCount: rooms.length,
    itemBuilder: (context, index) => RoomCard(room: rooms[index]),
  ),
  emptyWidget: NoRoomsEmptyState(),
  onRetry: () => ref.refresh(roomsProvider),
);
```

### 2. Safe Navigation

```dart
// Pop
context.safePop();

// Push named route
await context.safePushNamed('/profile', arguments: userId);

// Push replacement
await context.safePushReplacementNamed('/home');

// Check if can pop
if (context.canSafePop) {
  context.safePop();
}
```

### 3. Safe Firestore Operations

```dart
// Write with retry
await SafeFirestore.safeSet(
  ref: roomRef,
  data: {'name': 'Room', 'status': 'active'},
);

// Update with retry
await SafeFirestore.safeUpdate(
  ref: roomRef,
  data: {'participantCount': 5},
);

// Safe field extraction
final name = SafeFirestore.getValueOrDefault(data, 'name', 'Unnamed');
final count = SafeFirestore.getValueOrDefault(data, 'count', 0);
```

### 4. Offline Handling

```dart
// Show offline banner
Scaffold(
  appBar: AppBar(
    title: Text('Rooms'),
    bottom: PreferredSize(
      preferredSize: Size.fromHeight(0),
      child: OfflineBanner(),
    ),
  ),
  body: MyContent(),
);

// Disable button when offline
OnlineOnly(
  child: ElevatedButton(
    onPressed: () => createRoom(),
    child: Text('Create Room'),
  ),
);
```

### 5. Logging

```dart
// Error logging
try {
  await operation();
} catch (e, stackTrace) {
  AppLogger.error('Operation failed', e, stackTrace);
}

// Warning
AppLogger.warning('Unexpected condition', details);

// Info
AppLogger.info('Operation completed successfully');
```

## 📋 Implementation Checklist

When adding a new feature:

- [ ] Use `SafeAsyncBuilder` for all AsyncValue widgets
- [ ] Use `SafeNavigation` or context extensions for navigation
- [ ] Use `SafeFirestore` for all Firestore operations
- [ ] Add `OfflineBanner` if screen needs network
- [ ] Wrap network-dependent actions with `OnlineOnly`
- [ ] Add `AppLogger` calls for debugging
- [ ] Provide `onRetry` callbacks for failed operations
- [ ] Handle empty states with branded widgets

## 🎯 Common Patterns

### Pattern 1: List Screen with Network

```dart
class MyListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Items'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: OfflineBanner(),
        ),
      ),
      body: itemsAsync.buildListSafe(
        builder: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => ItemCard(item: items[index]),
        ),
        emptyWidget: NoItemsEmptyState(),
        onRetry: () => ref.refresh(itemsProvider),
      ),
      floatingActionButton: OnlineOnly(
        child: FloatingActionButton(
          onPressed: () => _createItem(context),
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _createItem(BuildContext context) async {
    try {
      AppLogger.info('Creating item');

      final itemRef = FirebaseFirestore.instance.collection('items').doc();
      await SafeFirestore.safeSet(
        ref: itemRef,
        data: {'name': 'New Item', 'createdAt': FieldValue.serverTimestamp()},
      );

      if (context.mounted) {
        context.safePushNamed('/item', arguments: itemRef.id);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create item', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create item')),
        );
      }
    }
  }
}
```

### Pattern 2: Detail Screen with AsyncValue

```dart
class DetailScreen extends ConsumerWidget {
  final String id;

  const DetailScreen({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: OfflineBanner(),
        ),
      ),
      body: itemAsync.buildSafe(
        builder: (item) => ItemDetails(item: item),
        onRetry: () => ref.refresh(itemProvider(id)),
      ),
    );
  }
}
```

## 🔧 Key Files

- `lib/core/utils/app_logger.dart` - Logging
- `lib/core/utils/navigation_utils.dart` - Safe navigation
- `lib/core/utils/firestore_utils.dart` - Safe Firestore
- `lib/core/utils/async_value_utils.dart` - AsyncValue safety
- `lib/core/providers/connectivity_provider.dart` - Offline detection
- `lib/shared/widgets/offline_widgets.dart` - Offline UI
- `lib/shared/error_boundary.dart` - Error boundary
- `lib/PHASE_11_STABILITY_USAGE_EXAMPLES.dart` - Full examples

## ✅ Success Criteria

Your code is Phase 11 compliant when:

1. All AsyncValue.when() uses SafeAsyncBuilder ✓
2. All Navigator calls use SafeNavigation ✓
3. All Firestore operations use SafeFirestore ✓
4. Network screens show OfflineBanner ✓
5. Network buttons wrapped with OnlineOnly ✓
6. Errors logged with AppLogger ✓
7. All operations have onRetry callbacks ✓
8. Empty states use branded widgets ✓

## 🚨 Common Mistakes to Avoid

❌ **DON'T:**

```dart
// Direct Navigator call
Navigator.of(context).pushNamed('/profile');

// Unsafe AsyncValue
user.when(data: (u) => Text(u.name), loading: () => Container(), error: (e, s) => Text('Error'));

// Direct Firestore
await roomRef.set(data);
```

✅ **DO:**

```dart
// Safe navigation
context.safePushNamed('/profile');

// Safe AsyncValue
user.buildSafe(builder: (u) => Text(u.name), onRetry: () => ref.refresh(userProvider));

// Safe Firestore
await SafeFirestore.safeSet(ref: roomRef, data: data);
```

---

**Phase 11 Complete - Mix & Mingle is now crash-proof! 🎉**
