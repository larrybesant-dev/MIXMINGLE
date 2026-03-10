import 'package:flutter/material.dart';

class ParticipantCardWidget extends StatelessWidget {
  final String? userId;
  final String? name;
  const ParticipantCardWidget({Key? key, this.userId, this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(backgroundImage: name != null ? NetworkImage(name!) : null),
        const SizedBox(width: 8),
        Text(name ?? userId ?? 'Participant'),
      ],
    );
  }
}
