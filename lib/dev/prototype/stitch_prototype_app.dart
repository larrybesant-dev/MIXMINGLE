import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'stitch_prototype_viewer.dart';

class StitchPrototypeApp extends StatelessWidget {
  const StitchPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MixVy Stitch Prototype',
      theme: midnightCreativeTheme,
      home: const StitchPrototypeViewer(),
    );
  }
}
