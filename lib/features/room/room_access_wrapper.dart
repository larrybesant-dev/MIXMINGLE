import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_profile.dart';
import '../../providers/all_providers.dart'; // currentUserProfileProvider
import '../../core/utils/app_logger.dart';
import 'room_access_gate.dart';
import '../../core/design_system/design_constants.dart';
import '../../core/routing/app_routes.dart';
import 'live/live_room_screen.dart';

/// Wrapper that enforces room access gating
/// Checks auth â†’ profile â†’ room permissions before rendering RoomPage
class RoomAccessWrapper extends ConsumerWidget {
  final Room room;
  final String userId;

  const RoomAccessWrapper({
    super.key,
    required this.room,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    return profileAsync.when(
      data: (userProfile) {
        final effectiveUserId =
          (userProfile?.id.trim().isNotEmpty == true) ? userProfile!.id : userId.trim();
        final profileDisplayName = userProfile?.displayName.trim() ?? '';
        final profileUsername = userProfile?.username.trim() ?? '';
        final displayName = profileDisplayName.isNotEmpty
          ? profileDisplayName
          : profileUsername.isNotEmpty
          ? profileUsername
          : 'Guest';
        final avatarUrl =
          (userProfile?.photoUrl.trim().isNotEmpty == true)
            ? userProfile!.photoUrl
            : null;
        // ...existing widget tree using effectiveUserId, displayName, avatarUrl...
        return Container(); // Placeholder
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, st) => const Text('Error loading profile'),
    );

    // Hosts should always be able to enter their own room immediately.
    if (room.hostId == effectiveUserId && effectiveUserId.isNotEmpty) {
      return LiveRoomScreen(
        roomId: room.id,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
    }

    final accessCheck = ref.watch(roomAccessCheckProvider((
      roomId: room.id,
      userId: effectiveUserId,
    )));

    return accessCheck.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(room.name ?? room.title),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking room access...'),
            ],
          ),
        ),
      ),
      data: (hasAccess) {
        return LiveRoomScreen(
          roomId:      room.id,
          displayName: displayName,
          avatarUrl:   avatarUrl,
        );
      },
      error: (error, stackTrace) {
        // Access denied - show appropriate error message
        var errorMessage = 'Access denied';

        if (error is RoomAccessDeniedException) {
          errorMessage = error.message;
          // Perform state-based redirect after the frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            switch (error.state) {
              case RoomAccessState.unauthenticated:
                Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.login);
              case RoomAccessState.profileIncomplete:
                Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.editProfile);
              default:
                break;
            }
          });
        } else {
          AppLogger.error('Room access error: $error');
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(room.name ?? room.title),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 64, color: DesignColors.accent),
                const SizedBox(height: 24),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: DesignTypography.body,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
