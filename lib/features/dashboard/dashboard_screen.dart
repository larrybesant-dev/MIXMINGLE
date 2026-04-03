import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/widgets/top_app_bar.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../feed/providers/feed_providers.dart';
import '../feed/screens/discovery_feed_screen.dart';
import '../feed/models/post_model.dart';
import '../profile/profile_completion.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_screen.dart';
import '../../widgets/mixvy_drawer.dart';

import '../../models/room_model.dart';
import '../feed/models/event_model.dart';
import '../../core/firestore/firestore_error_utils.dart';


  class DashboardScreen extends StatefulWidget {
    const DashboardScreen({super.key});

    @override
    State<DashboardScreen> createState() => _DashboardScreenState();
  }

  class _DashboardScreenState extends State<DashboardScreen> {
    int _currentIndex = 0;

    @override
    Widget build(BuildContext context) {
      const titles = ['MixVy', 'Discover', 'Profile'];

      return Scaffold(
        appBar: TopAppBar(title: titles[_currentIndex]),
        drawer: const MixVyDrawer(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Home Feed Tab
            Consumer(
              builder: (context, ref, _) {
                final postsAsync = ref.watch(postsStreamProvider);
                final roomsAsync = ref.watch(roomsStreamProvider);
                final eventsAsync = ref.watch(eventsStreamProvider);
                final profileState = ref.watch(profileControllerProvider);
                final setupItems = ProfileCompletion.guidedSetupItems(profileState);
                final profileCompletion = ProfileCompletion.completeness(profileState);
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (setupItems.isNotEmpty)
                        _profileNudgeCard(
                          completion: profileCompletion,
                          missingCount: setupItems.length,
                          firstAction: setupItems.first,
                        ),
                      if (setupItems.isNotEmpty) const SizedBox(height: 12),
                      _quickActions(context),
                      const SizedBox(height: 20),
                      const Text('Live Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      postsAsync.when(
                        data: (posts) => posts.isEmpty
                            ? const Text('No posts yet.')
                            : Column(children: posts.map((p) => _postCard(p)).toList()),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => firestoreErrorCard(
                          section: 'posts',
                          error: e,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Active Rooms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      roomsAsync.when(
                        data: (rooms) => rooms.isEmpty
                            ? const Text('No active rooms.')
                            : Column(children: rooms.map((r) => _roomCard(r)).toList()),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => firestoreErrorCard(
                          section: 'active rooms',
                          error: e,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      eventsAsync.when(
                        data: (events) => events.isEmpty
                            ? const Text('No upcoming events.')
                            : Column(children: events.map((e) => _eventCard(e)).toList()),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => firestoreErrorCard(
                          section: 'events',
                          error: e,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const DiscoveryFeedContent(),
            const ProfileFormView(),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      );
    }

    // Card widget for posts
    Widget _postCard(PostModel p) => Card(
          child: ListTile(
            title: Text(p.text),
            subtitle: Text('Posted • ${p.createdAt}'),
          ),
        );

    Widget _quickActions(BuildContext context) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.search, size: 18),
            label: const Text('Discover People'),
            onPressed: () {
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.flash_on, size: 18),
            label: const Text('Speed Dating'),
            onPressed: () => context.go('/speed-dating'),
          ),
          ActionChip(
            avatar: const Icon(Icons.notifications, size: 18),
            label: const Text('Notifications'),
            onPressed: () => context.go('/notifications'),
          ),
          ActionChip(
            avatar: const Icon(Icons.payments, size: 18),
            label: const Text('Payments'),
            onPressed: () => context.go('/payments'),
          ),
        ],
      );
    }

    Widget _profileNudgeCard({
      required double completion,
      required int missingCount,
      required String firstAction,
    }) {
      final pct = (completion * 100).round();
      final isAlmostDone = pct >= 70;
      final Color accent = isAlmostDone ? Colors.green : Colors.deepPurple;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.18),
              accent.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withValues(alpha: 0.18),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAlmostDone
                        ? 'Almost there! $missingCount step${missingCount == 1 ? '' : 's'} left'
                        : 'Complete your profile ($pct%)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Go to profile',
                  onPressed: () => setState(() => _currentIndex = 2),
                  icon: Icon(Icons.arrow_forward_ios, size: 14, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: completion,
                minHeight: 8,
                backgroundColor: accent.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Next: $firstAction',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Midnight Error Card pattern
    Widget midnightErrorCard(String message) => Card(
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.redAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );

    Widget firestoreErrorCard({required String section, required Object error}) {
      final info = parseFirestoreError(error);
      final friendly = friendlyFirestoreMessage(error, fallbackContext: section);

      return Card(
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                info.isPermissionOrAuth ? Icons.lock_outline : Icons.error_outline,
                color: info.isPermissionOrAuth ? Colors.amberAccent : Colors.redAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friendly,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (error is FirebaseException)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Firestore (${error.code}): ${error.message ?? 'No additional details'}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Card widget for rooms
    Widget _roomCard(RoomModel r) => Card(
          child: ListTile(
            title: Text(r.name.isNotEmpty ? r.name : 'Room'),
            subtitle: const Text('Live room'),
            trailing: const Icon(Icons.circle, color: Colors.green, size: 12),
            onTap: () => context.go('/room/${r.id}'),
          ),
        );

    // Card widget for events (dynamic fallback)
    Widget _eventCard(dynamic e) => Card(
          child: ListTile(
            title: e is EventModel
                ? Text(e.title.toString().trim().isNotEmpty ? e.title : 'Event')
                : Text(e.toString()),
            subtitle: e is EventModel ? Text('Event • ${e.date}') : null,
          ),
        );
  }
