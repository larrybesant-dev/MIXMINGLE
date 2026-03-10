import 'package:flutter/material.dart';

class ParticipantListWidget extends StatelessWidget {
  final List<String>? participantIds;
  const ParticipantListWidget({Key? key, this.participantIds}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ids = participantIds ?? <String>[];
    return ListView.builder(
      itemCount: ids.length,
      itemBuilder: (_, i) => ParticipantCardWidget(userId: ids[i]),
      shrinkWrap: true,
    );
  }
}
