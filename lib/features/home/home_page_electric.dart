/// Home Page Electric
/// Main landing page after onboarding completion
/// Shows: Live Rooms, Speed Dating, Discovery, Chats
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_constants.dart';
import '../../shared/widgets/club_background.dart';
import '../../shared/widgets/neon_components.dart';
import '../../providers/all_providers.dart';

/// Home Page with Electric theme - main post-onboarding landing
class HomePageElectric extends ConsumerStatefulWidget {
  const HomePageElectric({super.key});

  @override
  ConsumerState<HomePageElectric> createState() => _HomePageElectricState();
}

class _HomePageElectricState extends ConsumerState<HomePageElectric> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.speed_outlined),
      selectedIcon: Icon(Icons.speed),
      label: 'Speed Dating',
    ),
    NavigationDestination(
      icon: Icon(Icons.video_call_outlined),
      selectedIcon: Icon(Icons.video_call),
      label: 'Rooms',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Chats',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: NeonText(
            'MIX & MINGLE',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            textColor: DesignColors.white,
            glowColor: DesignColors.gold,
          ),
          backgroundColor: DesignColors.background,
          elevation: 0,
          actions: [
            // Notifications icon
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // TODO: Navigate to notifications
              },
            ),
            // Settings icon
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: _destinations,
          backgroundColor: DesignColors.background,
          indicatorColor: DesignColors.accent.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSpeedDatingTab();
      case 2:
        return _buildRoomsTab();
      case 3:
        return _buildChatsTab();
      case 4:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  /// Home Tab - Quick actions and featured content
  Widget _buildHomeTab() {
    final user = ref.watch(currentUserProfileProvider);

    return user.when(
      data: (profile) {
        if (profile == null) {
          return const Center(child: Text('Profile not found'));
        }

        return CustomScrollView(
          slivers: [
            // Welcome header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: DesignColors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    NeonText(
                      (profile.displayName ?? 'User').toUpperCase(),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      textColor: DesignColors.white,
                      glowColor: DesignColors.gold,
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        color: DesignColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),

            // Live Rooms Preview
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🔥 Live Rooms',
                          style: TextStyle(
                            color: DesignColors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedIndex = 2);
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildLiveRoomsPreview(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: NeonGlowCard(
            glowColor: DesignColors.gold,
            onTap: () {
              Navigator.pushNamed(context, '/speed-dating/lobby');
            },
            child: Column(
              children: [
                Icon(
                  Icons.speed,
                  size: 40,
                  color: DesignColors.gold,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Speed Dating',
                  style: TextStyle(
                    color: DesignColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NeonGlowCard(
            glowColor: DesignColors.accent,
            onTap: () {
              setState(() => _selectedIndex = 2);
            },
            child: Column(
              children: [
                Icon(
                  Icons.video_call,
                  size: 40,
                  color: DesignColors.accent,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join Room',
                  style: TextStyle(
                    color: DesignColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveRoomsPreview() {
    final rooms = ref.watch(liveRoomsProvider).take(3).toList();

    if (rooms.isEmpty) {
      return const Center(
        child: Text(
          'No live rooms right now',
          style: TextStyle(color: DesignColors.white),
        ),
      );
    }

    return Column(
      children: rooms
          .map((room) => NeonGlowCard(
                glowColor: DesignColors.accent,
                onTap: () {
                  Navigator.pushNamed(context, '/room', arguments: room.id);
                },
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: DesignColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.video_call,
                        color: DesignColors.accent,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.title,
                            style: const TextStyle(
                              color: DesignColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${room.viewerCount} watching',
                            style: TextStyle(
                              color: DesignColors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  /// Speed Dating Tab
  Widget _buildSpeedDatingTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.speed,
              size: 80,
              color: DesignColors.gold,
            ),
            const SizedBox(height: 20),
            NeonText(
              'SPEED DATING',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              textColor: DesignColors.white,
              glowColor: DesignColors.gold,
            ),
            const SizedBox(height: 12),
            const Text(
              '5-minute video dates with matched singles',
              style: TextStyle(color: DesignColors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            NeonButton(
              label: 'START SPEED DATING',
              onPressed: () {
                Navigator.pushNamed(context, '/speed-dating/lobby');
              },
              glowColor: DesignColors.gold,
              height: 54,
            ),
          ],
        ),
      ),
    );
  }

  /// Rooms Tab
  Widget _buildRoomsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Rooms feature - See rooms list',
            style: TextStyle(color: DesignColors.white),
          ),
          const SizedBox(height: 20),
          NeonButton(
            label: 'BROWSE ROOMS',
            onPressed: () {
              Navigator.pushNamed(context, '/rooms');
            },
            glowColor: DesignColors.accent,
          ),
        ],
      ),
    );
  }

  /// Chats Tab
  Widget _buildChatsTab() {
    return const Center(
      child: Text(
        'Chats feature coming soon',
        style: TextStyle(color: DesignColors.white),
      ),
    );
  }

  /// Profile Tab
  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Profile feature',
            style: TextStyle(color: DesignColors.white),
          ),
          const SizedBox(height: 20),
          NeonButton(
            label: 'EDIT PROFILE',
            onPressed: () {
              Navigator.pushNamed(context, '/profile/edit');
            },
            glowColor: DesignColors.gold,
          ),
        ],
      ),
    );
  }
}
