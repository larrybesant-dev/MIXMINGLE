import 'package:flutter/material.dart';

/// Show a simple moderation panel placeholder.
Future<void> showModerationPanel(BuildContext context, {String? roomId}) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Moderation Panel'),
      content: Text('Moderation tools for room: ${roomId ?? 'unknown'}'),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
    ),
  );
}

/// Show a simple voice room chat placeholder.
Future<void> showVoiceRoomChat(BuildContext context, {String? roomId}) async {
  await showModalBottomSheet(
    context: context,
    builder: (_) => SizedBox(
      height: 300,
      child: Center(child: Text('Voice room chat for room: ${roomId ?? 'unknown'}')),
    ),
  );
}
