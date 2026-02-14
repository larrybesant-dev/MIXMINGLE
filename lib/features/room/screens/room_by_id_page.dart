import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mix_and_mingle/shared/models/room.dart';
import 'room_page.dart';
import 'package:mix_and_mingle/shared/widgets/loading_widgets.dart';
import 'package:mix_and_mingle/features/error/error_page.dart';

/// Loads a room by Firestore document id and renders RoomPage
class RoomByIdPage extends ConsumerWidget {
  final String roomId;
  const RoomByIdPage({super.key, required this.roomId});

  Future<Room?> _fetchRoom() async {
    final doc = await FirebaseFirestore.instance.collection('rooms').doc(roomId).get();
    if (!doc.exists) return null;
    return Room.fromDocument(doc);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Room?>(
      future: _fetchRoom(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: LoadingSpinner()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: ErrorPage(errorMessage: 'Failed to load room'),
          );
        }
        final room = snapshot.data;
        if (room == null) {
          return const Scaffold(
            body: Center(child: Text('Room not found')),
          );
        }
        return RoomPage(room: room);
      },
    );
  }
}
