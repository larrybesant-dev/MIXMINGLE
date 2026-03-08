/// Age Gate Provider
/// Holds the verified birthdate for the current onboarding session.
/// This state lives only in memory — it is not persisted to disk.
/// It is passed to the signup flow to write to Firestore at account creation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
class AgeGateState {
  final DateTime? birthdate;
  final bool isVerified;
  final int? computedAge;

  const AgeGateState({
    this.birthdate,
    this.isVerified = false,
    this.computedAge,
  });

  AgeGateState copyWith({
    DateTime? birthdate,
    bool? isVerified,
    int? computedAge,
  }) =>
      AgeGateState(
        birthdate: birthdate ?? this.birthdate,
        isVerified: isVerified ?? this.isVerified,
        computedAge: computedAge ?? this.computedAge,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
  @override
  AgeGateState build() => const AgeGateState();
class AgeGateNotifier extends Notifier<AgeGateState> {
  @override
  AgeGateState build() => const AgeGateState();

  // ── Static utility ────────────────────────────────────────────────────────
  static int computeAge(DateTime birthdate) {
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  // ── Verify and store birthdate ────────────────────────────────────────────
  /// Returns true if birth date yields age >= 18. State is set regardless so
  /// callers can inspect [computedAge] even on failure.
  bool setAndVerifyBirthdate(DateTime birthdate) {
    final age = computeAge(birthdate);
    state = AgeGateState(
      birthdate: birthdate,
      isVerified: age >= 18,
      computedAge: age,
    );
    return state.isVerified;
  }

  /// Clear state (e.g. when the user goes back from signup to age gate).
  void reset() => state = const AgeGateState();
}

// ─────────────────────────────────────────────────────────────────────────────
final ageGateProvider = NotifierProvider<AgeGateNotifier, AgeGateState>(AgeGateNotifier.new);
