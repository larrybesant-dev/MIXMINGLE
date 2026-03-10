import 'package:flutter/material.dart';
import '../placeholders/global_placeholders.dart';
import '../utils/ui_helpers.dart';

class RoomCardWidget extends StatelessWidget {
  final String? roomId;
  final String? title;
  const RoomCardWidget({Key? key, this.roomId = '', this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null),
      title: Text(title ?? 'Room ${roomId ?? ''}'),
      subtitle: Text('Host: ${displayName ?? 'Unknown'}'),
      onTap: () => showModerationPanel(context, roomId: roomId),
    );
  }
}
