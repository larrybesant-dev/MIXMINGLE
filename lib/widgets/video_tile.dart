import 'package:flutter/material.dart';

class VideoTile extends StatelessWidget {
  final String? userId;
  final String? roomId;
  final String? streamId;
  const VideoTile({Key? key, this.userId, this.roomId = '', this.streamId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      child: Center(child: Text(userId ?? 'Video')),
    );
  }
}
