// ignore_for_file: file_names
/// Phase 11: Stability Engine - Usage Examples
///
/// This file demonstrates how to use all the stability features
/// implemented in Phase 11 for crash-proof, error-resilient code.
library;

// ============================================================================
// 1. GLOBAL ERROR BOUNDARY
// ============================================================================

// Already integrated in main.dart - automatically catches all unhandled errors

// ============================================================================
// 2. ASYNC VALUE SAFETY
// ============================================================================

// Example: Using SafeAsyncBuilder for any AsyncValue
/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/async_value_utils.dart';

class ExampleWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    // Safe way - handles loading, error, null, and data states
    return userAsync.buildSafe(
      builder: (user) => Text('Hello ${user.name}'),
      loadingWidget: const CircularProgressIndicator(),
      emptyMessage: 'User not found',
      onRetry: () => ref.refresh(currentUserProvider),
    );
  }
}
*/

// Example: Using SafeAsyncBuilder for lists
/*
class RoomsListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(browseRoomsProvider);

    return roomsAsync.buildListSafe(
      builder: (rooms) => ListView.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) => RoomCard(room: rooms[index]),
      ),
      emptyWidget: NoRoomsEmptyState(),
      emptyMessage: 'No active rooms',
      onRetry: () => ref.refresh(browseRoomsProvider),
    );
  }
}
*/

// ============================================================================
// 3. OFFLINE MODE
// ============================================================================

// Example: Show offline banner in scaffold
/*
import '../shared/widgets/offline_widgets.dart';

Scaffold(
  appBar: AppBar(
    title: Text('Browse Rooms'),
    bottom: PreferredSize(
      preferredSize: Size.fromHeight(0),
      child: OfflineBanner(),
    ),
  ),
  body: MyContent(),
);
*/

// Example: Disable button when offline
/*
OnlineOnly(
  child: ElevatedButton(
    onPressed: () => createRoom(),
    child: Text('Create Room'),
  ),
  onOfflineTap: () {
    // Custom message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cannot create room while offline')),
    );
  },
);
*/

// Example: Show full-screen offline state
/*
OfflineInterceptor(
  child: MyMainContent(),
  showOverlay: true, // Shows full-screen offline message
);
*/

// ============================================================================
// 4. NAVIGATION SAFETY
// ============================================================================

// Example: Safe navigation with mounted checks
/*
import '../core/utils/navigation_utils.dart';

// Safe pop
context.safePop();

// Safe push
await context.safePushNamed('/profile', arguments: userId);

// Safe push replacement
await context.safePushReplacementNamed('/home');

// Check if can pop
if (context.canSafePop) {
  context.safePop();
} else {
  context.safePushReplacementNamed('/home');
}
*/

// Example: Using SafeNavigation class directly
/*
SafeNavigation.safePop(context);
SafeNavigation.safePushNamed(context, '/settings');
SafeNavigation.safePushNamedAndRemoveUntil(
  context,
  '/home',
  (route) => false,
);
*/

// ============================================================================
// 5. FIRESTORE SAFETY
// ============================================================================

// Example: Safe Firestore write with retry
/*
import '../core/utils/firestore_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);

// Safe set with automatic retry on failure
await SafeFirestore.safeSet(
  ref: roomRef,
  data: {
    'name': 'My Room',
    'createdAt': FieldValue.serverTimestamp(),
  },
);

// Safe update
await SafeFirestore.safeUpdate(
  ref: roomRef,
  data: {'status': 'active'},
);

// Safe delete
await SafeFirestore.safeDelete(ref: roomRef);

// Safe get
final snapshot = await SafeFirestore.safeGet(ref: roomRef);
if (snapshot != null && snapshot.exists) {
  final data = snapshot.data() as Map<String, dynamic>;
  // Use data...
}

// Safe query
final query = FirebaseFirestore.instance
    .collection('rooms')
    .where('status', isEqualTo: 'active');

final querySnapshot = await SafeFirestore.safeQuery(query: query);
if (querySnapshot != null) {
  for (var doc in querySnapshot.docs) {
    // Process doc...
  }
}
*/

// Example: Safe field extraction with defaults
/*
final data = snapshot.data() as Map<String, dynamic>;

// Get value with safe default
final name = SafeFirestore.getValueOrDefault(data, 'name', 'Unnamed Room');
final count = SafeFirestore.getValueOrDefault(data, 'participantCount', 0);
final isActive = SafeFirestore.getValueOrDefault(data, 'isActive', false);

// Get nullable value with type safety
final description = SafeFirestore.getNullableValue<String>(data, 'description');
final timestamp = SafeFirestore.getNullableValue<Timestamp>(data, 'createdAt');
*/

// ============================================================================
// 6. LOGGING
// ============================================================================

// Example: Using AppLogger
/*
import '../core/utils/app_logger.dart';

// Log errors
try {
  await someOperation();
} catch (e, stackTrace) {
  AppLogger.error('Operation failed', e, stackTrace);
  rethrow;
}

// Log warnings
if (user == null) {
  AppLogger.warning('User not found', userId);
}

// Log info
AppLogger.info('Room created successfully');

// Log null values
if (room.description == null) {
  AppLogger.nullWarning('description', 'Room model');
}

// Log provider failures
AppLogger.providerError('roomProvider', error, stackTrace);

// Log navigation errors
AppLogger.navigationError('/profile', error);

// Log Firestore errors
AppLogger.firestoreError('update room', error, stackTrace);

// Log network errors
AppLogger.networkError('fetch rooms', error);

// Log unexpected states
AppLogger.unexpectedState('loading', 'room page');
*/

// ============================================================================
// 7. ERROR HANDLER
// ============================================================================

// Example: Using ErrorHandler
/*
import '../shared/error_boundary.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorHandler = ref.watch(errorHandlerProvider);

    return ElevatedButton(
      onPressed: () async {
        try {
          await performAction();
        } catch (e, stackTrace) {
          errorHandler.handleError(context, e, stackTrace);
        }
      },
      child: Text('Perform Action'),
    );
  }
}
*/

// ============================================================================
// 8. COMPLETE EXAMPLE
// ============================================================================

/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/async_value_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/firestore_utils.dart';
import '../shared/widgets/offline_widgets.dart';
import '../shared/widgets/empty_states.dart';

class StableRoomListPage extends ConsumerWidget {
  const StableRoomListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(browseRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        // Show offline banner
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: OfflineBanner(),
        ),
      ),
      body: OfflineInterceptor(
        showOverlay: false, // Don't block UI, just show banner
        child: roomsAsync.buildListSafe(
          builder: (rooms) => ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return ListTile(
                title: Text(room.name),
                onTap: () => _openRoom(context, room.id),
              );
            },
          ),
          emptyWidget: NoRoomsEmptyState(
            onCreateRoom: () => _createRoom(context),
          ),
          onRetry: () => ref.refresh(browseRoomsProvider),
        ),
      ),
      floatingActionButton: OnlineOnly(
        child: FloatingActionButton(
          onPressed: () => _createRoom(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _openRoom(BuildContext context, String roomId) async {
    try {
      // Fetch the room from Firestore
      final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
      if (!roomDoc.exists) {
        AppLogger.error('Room not found: $roomId');
        return;
      }

      final room = Room.fromFirestore(roomDoc);
      // Safe navigation with mounted check - use push() for complex objects
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AuthGuard(child: VoiceRoomPage(room: room)),
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to open room', e, stackTrace);
    }
  }

  Future<void> _createRoom(BuildContext context) async {
    try {
      AppLogger.info('Creating room');

      final roomRef = FirebaseFirestore.instance.collection('rooms').doc();

      // Safe Firestore write with retry
      await SafeFirestore.safeSet(
        ref: roomRef,
        data: {
          'name': 'New Room',
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      AppLogger.info('Room created successfully');

      if (context.mounted) {
        // Fetch the created room to pass to the route
        final roomDoc = await roomRef.get();
        final room = Room.fromFirestore(roomDoc);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AuthGuard(child: VoiceRoomPage(room: room)),
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to create room', e, stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create room. Please try again.'),
            backgroundColor: Color(0xFFFF4C4C),
          ),
        );
      }
    }
  }
}
*/


