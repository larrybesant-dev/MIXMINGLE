import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StateProvider<bool>((ref) => false);

final currentUserIdProvider = Provider<String?>((ref) => null);
