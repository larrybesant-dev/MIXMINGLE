import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed unused import

class ModerationActions extends ConsumerWidget {
  final String roomId;
  final String userId;

  const ModerationActions({required this.roomId, required this.userId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Semantics(
          label: 'Report User button',
          button: true,
          child: ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('moderation_reports').add({
                'roomId': roomId,
                'userId': userId,
                'type': 'Violation',
                'timestamp': DateTime.now(),
              });
            },
            child: Text('Report User', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 18 : 16)),
          ),
        ),
        Semantics(
          label: 'Block User button',
          button: true,
          child: ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('moderation_blocks').add({
                'roomId': roomId,
                'userId': userId,
                'timestamp': DateTime.now(),
              });
            },
            child: const Text('Block User'),
          ),
        ),
      ],
    );
  }
}
