import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/events_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../shared/widgets/events_widgets.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../shared/widgets/social_graph_widgets.dart';
import '../../../shared/auth_guard.dart';
import '../../../shared/models/room.dart';
import '../../room/screens/voice_room_page.dart';

class EventDetailsPage extends ConsumerWidget {
  final String eventId;

  const EventDetailsPage({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailsProvider(eventId));
    final currentUser = ref.watch(currentUserProvider).value;

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Event Details'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: eventAsync.when(
          data: (event) {
            if (event == null) {
              return const Center(
                child: Text(
                  'Event not found',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            final hostAsync = ref.watch(userProfileProvider(event.hostId));

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event image (if available)
                  if (event.imageUrl.isNotEmpty)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(event.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and online badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (event.isOnline)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFFD700)),
                                ),
                                child: const Text(
                                  'ONLINE',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Host info
                        hostAsync.when(
                          data: (host) {
                            if (host == null) return const SizedBox.shrink();
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: host.photoUrl != null ? NetworkImage(host.photoUrl!) : null,
                                  child: host.photoUrl == null
                                      ? Text(
                                          host.displayName?.isNotEmpty == true
                                              ? host.displayName![0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(fontSize: 16),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hosted by',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      host.displayName ?? host.nickname ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 24),

                        // Date and time
                        _InfoRow(
                          icon: Icons.access_time,
                          label: 'Date & Time',
                          value: '${DateFormat('EEEE, MMMM d, y').format(event.startTime)}\n'
                              '${DateFormat('h:mm a').format(event.startTime)} - '
                              '${DateFormat('h:mm a').format(event.endTime)}',
                        ),

                        const SizedBox(height: 16),

                        // Location
                        _InfoRow(
                          icon: event.isOnline ? Icons.videocam : Icons.location_on,
                          label: 'Location',
                          value: event.location,
                        ),

                        const SizedBox(height: 16),

                        // Category
                        _InfoRow(
                          icon: Icons.category,
                          label: 'Category',
                          value: event.category,
                        ),

                        const SizedBox(height: 16),

                        // Stats
                        Row(
                          children: [
                            _StatChip(
                              icon: Icons.people,
                              label: '${event.attendeesCount} Going',
                              color: const Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 12),
                            _StatChip(
                              icon: Icons.star_outline,
                              label: '${event.interestedCount} Interested',
                              color: Colors.white70,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Description
                        if (event.description.isNotEmpty) ...[
                          const Text(
                            'About',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Friends attending banner
                        if (currentUser != null) FriendsAttendingBanner(eventId: eventId),

                        const SizedBox(height: 16),

                        // RSVP buttons
                        if (currentUser != null) EventRsvpButtons(eventId: eventId),

                        const SizedBox(height: 24),

                        // Join room button (if online and has roomId)
                        if (event.isOnline && event.roomId != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final roomDoc =
                                      await FirebaseFirestore.instance.collection('rooms').doc(event.roomId).get();
                                  if (!roomDoc.exists) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Room not found')),
                                      );
                                    }
                                    return;
                                  }
                                  final room = Room.fromFirestore(roomDoc);
                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AuthGuard(child: VoiceRoomPage(room: room)),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error joining room: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.videocam),
                              label: const Text('Join Event Room'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Chat with attendees button
                        if (currentUser != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/event-chat',
                                  arguments: {
                                    'eventId': eventId,
                                    'eventTitle': event.title,
                                  },
                                );
                              },
                              icon: const Icon(Icons.chat),
                              label: const Text('Chat with Attendees'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFFD700),
                                side: const BorderSide(color: Color(0xFFFFD700)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Attendees section
                        const Text(
                          'Attendees',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _AttendeesList(eventId: eventId),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Error loading event',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(eventDetailsProvider(eventId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeesList extends ConsumerWidget {
  final String eventId;

  const _AttendeesList({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(eventAttendeesProvider((eventId: eventId, status: 'going')));

    return attendeesAsync.when(
      data: (attendees) {
        if (attendees.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No attendees yet',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attendees.length,
          itemBuilder: (context, index) {
            final attendee = attendees[index];
            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: attendee.photoUrl != null ? NetworkImage(attendee.photoUrl!) : null,
                    child: attendee.photoUrl == null
                        ? Text(
                            attendee.displayName?.isNotEmpty == true ? attendee.displayName![0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 18),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: PresenceIndicator(userId: attendee.id, size: 12),
                  ),
                ],
              ),
              title: Text(
                attendee.displayName ?? attendee.nickname ?? 'Unknown',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: attendee.bio != null && attendee.bio!.isNotEmpty
                  ? Text(
                      attendee.bio!,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: FollowButton(userId: attendee.id, compact: true),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error loading attendees',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}
