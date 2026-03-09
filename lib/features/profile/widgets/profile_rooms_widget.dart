import 'package:flutter/material.dart';

class ProfileRoomsWidget extends StatelessWidget {
  final String userId;
  const ProfileRoomsWidget({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch and display rooms user is in
    return Container(child: Text('Rooms'));
  }
}
