import 'package:flutter/material.dart';

class RaisedHandsPanel extends StatelessWidget {
  const RaisedHandsPanel({Key? key}) : super(key: key);

  @override
  final List<String>? raisedByIds;
  final String? roomId;
  const RaisedHandsPanel({Key? key, this.raisedByIds, this.roomId = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ids = raisedByIds ?? <String>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: ids.map((id) => ListTile(title: Text(id))).toList(),
    );
  }
}
