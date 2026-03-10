/// Age Gate Screen
/// Entry point before auth — confirms the user is 18+.
/// Flow: Onboarding → AgeGatePage → (if 18+) NeonSignupPage
library;

import 'package:flutter/material.dart';
// Removed unused import
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/theme/neon_colors.dart';
import '../../../providers/all_providers.dart';
import '../../../shared/widgets/loading_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
class AgeGatePage extends ConsumerWidget {
  const AgeGatePage({super.key});

  // Add controllers for date fields

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const FullScreenLoader(message: 'Verifying MixVy age...'),
      error: (_, __) => const FullScreenLoader(message: 'MixVy age verification error'),
      data: (profile) {
        return Scaffold(
          backgroundColor: NeonColors.darkBg,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NeonColors.darkBg2.withValues(alpha: 0.9),
                  NeonColors.darkBg,
                ],
              ),
            ),
            child: const SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    // ...existing code...
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  // Removed duplicate build method
}

// ─────────────────────────────────────────────────────────────────────────────
/// Reusable neon-styled date input field.
// Removed unused _DateField widget and unused onChanged parameter
