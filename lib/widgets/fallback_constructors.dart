import 'package:flutter/material.dart';

class SafeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  const SafeButton({Key? key, required this.child, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: child);
  }
}
