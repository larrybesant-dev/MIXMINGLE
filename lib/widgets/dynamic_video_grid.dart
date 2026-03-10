import 'package:flutter/material.dart';

class DynamicVideoGrid extends StatelessWidget {
  final List<String>? userIds;
  final String? roomId;
  const DynamicVideoGrid({Key? key, this.userIds, this.roomId = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ids = userIds ?? <String>[];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      children: ids.map((id) => VideoTile(userId: id, roomId: roomId)).toList(),
    );
  }
}
