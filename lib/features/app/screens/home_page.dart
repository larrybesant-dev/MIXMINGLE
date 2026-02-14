import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mix_and_mingle/services/auth_service.dart';
import 'package:mix_and_mingle/services/profile_service.dart';
import 'package:mix_and_mingle/shared/models/user_profile.dart';
import 'package:mix_and_mingle/shared/widgets/club_background.dart';
import 'profile_edit_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService().getCurrentUserProfile();
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditPage(initialProfile: _profile),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() => _profile = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text("Mix & Mingle"),
          actions: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _editProfile,
              tooltip: 'Edit Profile',
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => AuthService().logout(),
            )
          ],
        ),
        body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome, ${_profile?.displayName ?? user?.email ?? "Guest"}",
                      style: TextStyle(fontSize: 22),
                    ),
                    if (_profile?.bio != null && _profile!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _profile!.bio!,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_profile?.location != null && _profile!.location!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "📍 ${_profile!.location!}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                    if (_profile?.interests != null && _profile!.interests!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Interests: ${_profile!.interests!.join(", ")}",
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
