import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user/user_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) return const Stream.empty();
  final service = ref.watch(userServiceProvider);
  return service.watchUser(auth.uid);
});

final currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authStateProvider).value;
  return auth?.uid;
});
