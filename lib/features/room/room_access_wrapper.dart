import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/room.dart';
import '../../shared/providers/auth_providers.dart';
import '../../core/utils/app_logger.dart';
import 'room_access_gate.dart';
import '../../core/design_system/design_constants.dart';
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
    final appUser = ref.watch(currentUserProvider).asData?.value;
    final effectiveUserId =
        (appUser?.id.trim().isNotEmpty == true) ? appUser!.id : userId.trim();

    final profileDisplayName = appUser?.displayName?.trim() ?? '';
    final profileUsername = appUser?.username.trim() ?? '';
    final displayName = profileDisplayName.isNotEmpty
      ? profileDisplayName
      : profileUsername.isNotEmpty
        ? profileUsername
        : 'Guest';
    final avatarUrl =
        (appUser?.avatarUrl.trim().isNotEmpty == true)
            ? appUser!.avatarUrl
            : null;

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
          // TODO: Handle redirects based on error.state
          // - RoomAccessState.profileIncomplete -> redirect to profile completion
          // - RoomAccessState.unauthenticated -> redirect to login
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
