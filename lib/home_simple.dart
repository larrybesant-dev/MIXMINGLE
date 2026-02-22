import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleHomePage extends StatefulWidget {
  const SimpleHomePage({super.key});

  @override
  State<SimpleHomePage> createState() => _SimpleHomePageState();
}

class _SimpleHomePageState extends State<SimpleHomePage> {
  int _selectedNavIndex = 0;

  void _navigateTo(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: const Text('MIX & MINGLE'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateTo(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            const _UserProfileHeader(),
            const SizedBox(height: 20),

            // Welcome Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Welcome to Mix & Mingle',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Navigation Grid - ALWAYS VISIBLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _NavCard(
                    icon: Icons.videocam,
                    title: 'Rooms',
                    subtitle: 'Join live rooms',
                    onTap: () => _navigateTo(context, '/discover-rooms'),
                  ),
                  _NavCard(
                    icon: Icons.favorite,
                    title: 'Speed Dating',
                    subtitle: 'Play speed dating',
                    onTap: () => _navigateTo(context, '/speed-dating/lobby'),
                  ),
                  _NavCard(
                    icon: Icons.chat,
                    title: 'Messages',
                    subtitle: 'Chat with friends',
                    onTap: () => _navigateTo(context, '/chats'),
                  ),
                  _NavCard(
                    icon: Icons.event,
                    title: 'Events',
                    subtitle: 'Upcoming events',
                    onTap: () => _navigateTo(context, '/events'),
                  ),
                  _NavCard(
                    icon: Icons.person,
                    title: 'Profile',
                    subtitle: 'Your profile',
                    onTap: () => _navigateTo(context, '/profile'),
                  ),
                  _NavCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Updates & alerts',
                    onTap: () => _navigateTo(context, '/notifications'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Activity Feed Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _ActivityFeed(),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey.shade900,
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedNavIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: 'Rooms'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Likes'),
        ],
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          switch (index) {
            case 0:
              break; // Already home
            case 1:
              _navigateTo(context, '/discover-rooms');
              break;
            case 2:
              _navigateTo(context, '/chats');
              break;
            case 3:
              _navigateTo(context, '/matches');
              break;
          }
        },
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFD700), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFFFFD700)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
/// User Profile Header Widget - Always shows with fallback
class _UserProfileHeader extends StatelessWidget {
  const _UserProfileHeader();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // If not logged in, show placeholder
    if (currentUser == null) {
      return Container(
        color: Colors.grey.shade900,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFFFD700),
              child: const Icon(Icons.person, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guest User',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('Sign in to see your profile',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.edit, color: const Color(0xFFFFD700)),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Default values from Firebase Auth
        String displayName = currentUser.displayName ?? 'User';
        String? photoUrl = currentUser.photoURL;
        int matchesCount = 0;
        int followersCount = 0;

        // Override with Firestore data if available
        if (snapshot.hasData && snapshot.data != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null) {
            displayName = userData['displayName'] as String? ?? displayName;
            photoUrl = userData['photoUrl'] as String? ?? photoUrl;
            matchesCount = userData['matchesCount'] as int? ?? 0;
            followersCount = userData['followersCount'] as int? ?? 0;
          }
        }

        return Container(
          color: Colors.grey.shade900,
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Profile Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFFFD700),
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Profile Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$matchesCount Matches',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          ' â€¢ ',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                          ),
                        ),
                        Text(
                          '$followersCount Followers',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit Profile Button
              IconButton(
                icon: const Icon(Icons.edit),
                color: const Color(0xFFFFD700),
                onPressed: () {
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Activity Feed Widget - Shows recent user activity
class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Show sign-in prompt if not logged in
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: Border.all(color: const Color(0xFFFFD700), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, color: Color(0xFFFFD700), size: 32),
            SizedBox(height: 8),
            Text(
              'Sign in to see your activity',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activity')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Container(
            height: 100,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  color: const Color(0xFFFFD700),
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No recent activity yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        final activityDoc = snapshot.data!.docs.first;
        final activity = activityDoc.data() as Map<String, dynamic>;

        final type = activity['type'] as String? ?? 'match';
        final timestamp = (activity['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final userName = activity['userName'] as String? ?? 'Someone';
        final userPhoto = activity['userPhoto'] as String?;

        String activityMessage = '';
        IconData activityIcon = Icons.person;
        Color activityIconColor = const Color(0xFFFFD700);

        switch (type) {
          case 'match':
            activityMessage = 'Matched with $userName';
            activityIcon = Icons.favorite;
            activityIconColor = const Color(0xFFFF4C4C);
            break;
          case 'follow':
            activityMessage = '$userName followed you';
            activityIcon = Icons.person_add;
            activityIconColor = const Color(0xFFFFD700);
            break;
          case 'message':
            activityMessage = '$userName sent a message';
            activityIcon = Icons.message;
            activityIconColor = const Color(0xFF4C9FFF);
            break;
          case 'notification':
            activityMessage = activity['message'] as String? ?? 'New notification';
            activityIcon = Icons.notifications;
            activityIconColor = const Color(0xFFFFD700);
            break;
          default:
            activityMessage = '$userName was active';
        }

        final timeAgo = _getTimeAgo(timestamp);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            border: Border.all(
              color: const Color(0xFFFFD700),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (userPhoto != null && userPhoto.isNotEmpty)
                CircleAvatar(
                  backgroundImage: NetworkImage(userPhoto),
                  radius: 24,
                  backgroundColor: Colors.grey.shade800,
                )
              else
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade800,
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFFFFD700),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(activityIcon, color: activityIconColor, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            activityMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFFFD700),
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).toStringAsFixed(0)}w ago';
    }
  }
}
