import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/models.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Provider exports for global use ---
export 'package:flutter_riverpod/flutter_riverpod.dart';
export '../shared/models/models.dart';
export '../services/auth_service.dart';
export 'package:cloud_firestore/cloud_firestore.dart';

export 'all_providers.dart'; // Ensures all providers are globally available

// ------------------ Auth State ------------------
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return AuthService().authStateChanges;
});

// ------------------ Current User Profile ------------------
/// Call ref.invalidate(currentUserProfileProvider) after profile mutation to force reload
final currentUserProfileProvider = FutureProvider<AppUser?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;

  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  if (!doc.exists) return null;

  final data = doc.data()!;
  return AppUser(
    uid: data['uid'],
    username: data['username'],
    email: data['email'],
    photoUrl: data['photoUrl'],
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    ageVerified: data['ageVerified'] ?? false,
    onboardingComplete: data['onboardingComplete'] ?? false,
    bio: data['bio'],
    location: data['location'],
  );
});

// ------------------ Onboarding Check ------------------
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentUserProfileProvider).maybeWhen(
        data: (user) => user,
        orElse: () => null,
      );
  return profile?.onboardingComplete ?? false;
});
