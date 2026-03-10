import 'package:flutter/material.dart';

class ParticipantListSidebar extends StatelessWidget {
  const ParticipantListSidebar({Key? key}) : super(key: key);

  @override
  final List<String>? participantIds;
  final String? roomId;
  const ParticipantListSidebar({Key? key, this.participantIds, this.roomId = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ids = participantIds ?? <String>[];
    return Drawer(
      child: ListView.builder(
        itemCount: ids.length,
        itemBuilder: (_, i) => ListTile(title: Text(ids[i])),
      ),
    );
  }
}
