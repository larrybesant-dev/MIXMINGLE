import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../shared/models/user_profile.dart';
import '../providers/events_controller.dart';
import '../providers/profile_controller.dart';

class EventDetailsPage extends ConsumerStatefulWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends ConsumerState<EventDetailsPage> {
  bool _isAttending = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAttendanceStatus();
  }

  void _checkAttendanceStatus() {
    final currentUserId = ref.read(currentUserProfileProvider).value?.id;
    if (currentUserId != null) {
      setState(() {
        _isAttending = widget.event.attendees.contains(currentUserId);
      });
    }
  }

  Future<void> _toggleAttendance() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final controller = ref.read(eventsControllerProvider);
      if (_isAttending) {
        await controller.leaveEvent(widget.event.id);
        setState(() => _isAttending = false);
      } else {
        await controller.joinEvent(widget.event.id);
        setState(() => _isAttending = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update attendance: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final controller = ref.read(eventsControllerProvider);
        await controller.deleteEvent(widget.event.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete event: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserProfileProvider).value?.id;
    final isHost = currentUserId == widget.event.hostId;
    final now = DateTime.now();
    final isPast = widget.event.endTime.isBefore(now);
    final isOngoing = widget.event.startTime.isBefore(now) && widget.event.endTime.isAfter(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          if (isHost && !isPast)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    // TODO: Navigate to edit event page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit event not implemented yet')),
                    );
                    break;
                  case 'delete':
                    _deleteEvent();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Event'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Event'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            if (widget.event.imageUrl.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(widget.event.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Event Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(isPast, isOngoing),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(isPast, isOngoing),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Category
            Chip(
              label: Text(widget.event.category),
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.description,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),

            // Date and Time
            _buildInfoSection(
              'Date & Time',
              Icons.access_time,
              '${DateFormat('EEEE, MMMM dd, yyyy').format(widget.event.startTime)}\n'
                  '${DateFormat('HH:mm').format(widget.event.startTime)} - ${DateFormat('HH:mm').format(widget.event.endTime)}',
            ),
            const SizedBox(height: 16),

            // Location
            _buildInfoSection(
              'Location',
              Icons.location_on,
              widget.event.location,
            ),
            const SizedBox(height: 16),

            // Host
            FutureBuilder<UserProfile?>(
              future: ref.read(profileServiceProvider).getUserProfile(widget.event.hostId),
              builder: (context, snapshot) {
                final hostName = snapshot.data?.displayName ?? 'Unknown Host';
                return _buildInfoSection(
                  'Host',
                  Icons.person,
                  hostName,
                );
              },
            ),
            const SizedBox(height: 16),

            // Attendees
            _buildAttendeesSection(),
            const SizedBox(height: 24),

            // Action Button
            if (!isPast && !isHost)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleAttendance,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isAttending ? Colors.red : Theme.of(context).primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isAttending ? 'Leave Event' : 'Join Event',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),

            // Speed Dating Button (if applicable)
            if (widget.event.category.toLowerCase().contains('speed') ||
                widget.event.category.toLowerCase().contains('dating'))
              const SizedBox(height: 16),
            if (widget.event.category.toLowerCase().contains('speed') ||
                widget.event.category.toLowerCase().contains('dating'))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to speed dating
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Speed dating not implemented yet')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Start Speed Dating',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(
              'Attendees (${widget.event.attendees.length}/${widget.event.maxAttendees})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.event.attendees.isEmpty)
          Text(
            'No attendees yet',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.event.attendees.map((attendeeId) {
              return FutureBuilder<UserProfile?>(
                future: ref.read(profileServiceProvider).getUserProfile(attendeeId),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return Chip(
                    avatar: user?.photos.isNotEmpty == true
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(user!.photos.first),
                            radius: 12,
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.person, size: 16),
                          ),
                    label: Text(user?.displayName ?? 'Unknown'),
                    backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                  );
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Color _getStatusColor(bool isPast, bool isOngoing) {
    if (isPast) return Colors.grey;
    if (isOngoing) return Colors.green;
    return Colors.blue;
  }

  String _getStatusText(bool isPast, bool isOngoing) {
    if (isPast) return 'Past';
    if (isOngoing) return 'Ongoing';
    return 'Upcoming';
  }
}
