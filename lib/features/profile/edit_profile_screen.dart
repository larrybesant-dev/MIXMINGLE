import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: Semantics(
          label: 'Edit Profile Screen',
          child: Text('Edit Profile Screen', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 20 : 18)),
        ),
      ),
    );
  }
}
