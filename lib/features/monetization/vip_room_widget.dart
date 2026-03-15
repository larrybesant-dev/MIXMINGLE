import 'package:flutter/material.dart';

class VipRoomWidget extends StatelessWidget {
  final bool isVip;
  const VipRoomWidget({super.key, required this.isVip});

  @override
  Widget build(BuildContext context) {
    return isVip
        ? Container(
            color: Colors.amber,
            child: const Center(child: Text('VIP Room', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          )
        : const SizedBox.shrink();
  }
}
