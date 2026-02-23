import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mixmingle/providers/providers.dart';
import 'package:mixmingle/shared/models/user.dart' as user_model;
import 'package:mixmingle/shared/widgets/club_background.dart';
import 'package:mixmingle/shared/widgets/glow_text.dart';
import 'package:mixmingle/shared/widgets/neon_button.dart';
import 'package:mixmingle/shared/widgets/async_value_view.dart';
import 'package:mixmingle/app_routes.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return ClubBackground(
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AsyncValueView(
            value: currentUserAsync,
            onRetry: () => ref.invalidate(currentUserProvider),
            data: (user) {
              if (user == null) {
                return const Center(child: Text('User not found'));
              }
              return _buildProfileContent(user);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(user_model.User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cover Photo (optional) - Placeholder for now
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8F00FF), Color(0xFF00E6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.camera_alt,
                color: Colors.white54,
                size: 40,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Profile Picture + 3. Display Name + Age + 4. Location
          Row(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                child: user.avatarUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white54) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlowText(
                      text: user.displayName ?? 'Anonymous',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    Text(
                      user.location.isNotEmpty ? user.location : 'Location not set',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 5. Short Bio
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151A26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.bio.isNotEmpty ? user.bio : 'No bio yet...',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),

          _buildDivider(),

          // 6. Photo Gallery (up to 6) + 7. Edit Profile Button
          Row(
            children: [
              const GlowText(
                text: 'Photo Gallery',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              const Spacer(),
              NeonButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                label: 'Edit Profile',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: user.recentMediaUrls.length + 1,
              itemBuilder: (context, index) {
                if (index == user.recentMediaUrls.length) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151A26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.add_a_photo,
                      color: Colors.white54,
                      size: 40,
                    ),
                  );
                }
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(user.recentMediaUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),

          _buildDivider(),

          // 8. Interests (chips)
          const GlowText(
            text: 'Interests',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.interests
                .map((interest) => Chip(
                      label: Text(interest),
                      backgroundColor: const Color(0xFF8F00FF).withValues(alpha: 0.2),
                      labelStyle: const TextStyle(color: Colors.white),
                    ))
                .toList(),
          ),

          const SizedBox(height: 16),

          // 9. Looking For + 10. Age Range + 11. Distance
          _buildPreferenceRow('Looking For', user.lookingFor ?? 'Not specified'),
          _buildPreferenceRow(
            'Age Range',
            user.minAgePreference != null && user.maxAgePreference != null
                ? '${user.minAgePreference} - ${user.maxAgePreference} years'
                : 'Not specified',
          ),
          _buildPreferenceRow(
            'Distance',
            user.maxDistancePreference != null ? '${user.maxDistancePreference} km' : 'Not specified',
          ),

          _buildDivider(),

          // 12. Profile Stats
          const GlowText(
            text: 'Profile Stats',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 12),
          _buildStatRow('Joined', DateFormat('MMM yyyy').format(user.createdAt)),
          _buildStatRow('Last Active', 'Recently'),
          _buildStatRow('Verification', 'âœ“ Verified'),

          _buildDivider(),

          // 13. Navigation Buttons
          const GlowText(
            text: 'Settings',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 12),
          _buildSettingsButton('Privacy Settings', Icons.privacy_tip, () {
            Navigator.pushNamed(context, '/settings/privacy');
          }),
          _buildSettingsButton('Notifications', Icons.notifications, () {
            Navigator.pushNamed(context, '/notifications');
          }),
          _buildSettingsButton('Account Settings', Icons.settings, () {
            Navigator.pushNamed(context, '/settings');
          }),

          _buildDivider(),

          // 14. Logout / Delete Account
          const SizedBox(height: 24),
          NeonButton(
            onPressed: _showLogoutDialog,
            label: 'Logout',
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _showDeleteAccountDialog,
            child: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Divider(color: Colors.white24),
    );
  }

  Widget _buildPreferenceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151A26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00E6FF)),
        title: Text(text, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: onPressed,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151A26),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151A26),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              try {
                await ref.read(authServiceProvider).deleteAccount();
                if (mounted) {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(content: Text('Account deleted successfully')),
                  );
                  navigator.pop();
                  // Navigate to login or home
                  // ignore: use_build_context_synchronously
                  navigator.pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                  navigator.pop();
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
