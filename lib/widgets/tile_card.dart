import 'package:flutter/material.dart';

class TileCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TileCard({required this.child, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(onTap: onTap, child: child),
    );
  }
}
