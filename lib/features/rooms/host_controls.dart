import 'package:flutter/material.dart';
import '../../models/room_member_model.dart';

class HostControls extends StatelessWidget {
  final RoomMember member;
  final void Function(RoomMemberRole) onRoleChange;
  final VoidCallback onMute;
  final VoidCallback onRemove;

  const HostControls({super.key, 
    required this.member,
    required this.onRoleChange,
    required this.onMute,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<RoomMemberRole>(
          value: member.role,
          items: RoomMemberRole.values.map((role) => DropdownMenuItem(
            value: role,
            child: Text(role.toString().split('.').last),
          )).toList(),
          onChanged: (role) {
            if (role != null) onRoleChange(role);
          },
        ),
        IconButton(
          icon: const Icon(Icons.volume_off),
          onPressed: onMute,
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
