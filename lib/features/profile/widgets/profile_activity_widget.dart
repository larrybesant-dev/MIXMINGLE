import 'package:flutter/material.dart';

class ProfileActivityWidget extends StatelessWidget {
  final String userId;
  const ProfileActivityWidget({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch and display user activity
    return Container(child: Text('Activity'));
  }
}
