import 'package:flutter/material.dart';
import 'router/app_router.dart';
import '../core/theme.dart';

class MixVyApp extends StatelessWidget {
  const MixVyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MixVy',
      theme: midnightCreativeTheme,
      routerConfig: AppRouter.router,
    );
  }
}
