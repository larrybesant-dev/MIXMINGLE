/// Age Gate Screen
/// Entry point before auth — confirms the user is 18+.
/// Flow: Onboarding → AgeGatePage → (if 18+) NeonSignupPage
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/neon_colors.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/providers/auth_providers.dart';
import '../providers/age_gate_provider.dart';
import '../../../providers/all_providers.dart';
import '../../../shared/widgets/loading_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
class AgeGatePage extends ConsumerWidget {
  const AgeGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const FullScreenLoader(message: 'Verifying age...'),
      error: (_, __) => const FullScreenLoader(message: 'Age verification error'),
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
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
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

  Future<void> _verifyAge(WidgetRef ref, BuildContext context) async {
    // Validate input controllers (assume they exist in widget)
    final dayStr   = _dayController.text.trim();
    final monthStr = _monthController.text.trim();
    final yearStr  = _yearController.text.trim();

    final day   = int.tryParse(dayStr);
    final month = int.tryParse(monthStr);
    final year  = int.tryParse(yearStr);
    if (day == null || day < 1 || day > 31 ||
        month == null || month < 1 || month > 12 ||
        year == null || year < 1900 || year > DateTime.now().year) {
      // Show error overlay or message
      showDialog(
        context: context,
        builder: (_) => const FullScreenLoader(message: 'Please enter a valid date of birth.'),
      );
      return;
    }
    DateTime birthdate;
    try {
      birthdate = DateTime(year, month, day);
      if (birthdate.day != day || birthdate.month != month) {
        throw const FormatException('Invalid date');
      }
    } catch (_) {
      showDialog(
        context: context,
        builder: (_) => const FullScreenLoader(message: 'Please enter a valid date of birth.'),
      );
      return;
    }
    final notifier = ref.read(ageGateProvider.notifier);
    final isAdult  = notifier.setAndVerifyBirthdate(birthdate);
    if (!isAdult) {
      FirebaseAnalytics.instance.logEvent(
        name: AnalyticsEvents.ageGateBlockedUnderage,
      );
      showDialog(
        context: context,
        builder: (_) => const FullScreenLoader(message: 'You must be at least 18 years old to use MixVy.'),
      );
      return;
    }
    FirebaseAnalytics.instance.logEvent(name: AnalyticsEvents.ageGatePassedAdult);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'ageVerified': true});
        await ref.invalidate(currentUserProfileProvider); // Force reload profile
        final profile = await ref.read(currentUserProfileProvider.future);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (profile != null && !profile.onboardingComplete) {
            Navigator.pushNamed(context, AppRoutes.onboarding);
          } else {
            Navigator.pushNamed(context, AppRoutes.home);
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, AppRoutes.signup);
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.signup);
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.when(
      loading: () => const FullScreenLoader(message: 'Verifying age...'),
      error: (_, __) => const FullScreenLoader(message: 'Age verification error'),
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
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
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
}

// ─────────────────────────────────────────────────────────────────────────────
/// Reusable neon-styled date input field.
class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final int maxLength;
  final ValueChanged<String>? onChanged;

  const _DateField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: maxLength,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: 16,
          letterSpacing: 1,
        ),
        counterText: '',
        filled: true,
        fillColor: NeonColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: NeonColors.neonPink.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: NeonColors.neonPink,
            width: 2,
          ),
        ),
      ),
    );
  }
}
