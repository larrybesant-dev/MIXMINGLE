import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'router/stitch_prototype_router.dart';

class StitchPrototypeApp extends StatelessWidget {
  const StitchPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MixVy Stitch Prototype',
      theme: midnightCreativeTheme,
      routerConfig: StitchPrototypeRouter.router,
    );
  }
}
