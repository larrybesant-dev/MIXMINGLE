import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';

// Replace with your actual user repository/service
final userProvider = FutureProvider.family<User?, String>((ref, userId) async {
  // TODO: Replace with real user fetch logic (e.g., Firestore)
  // Example:
  // final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  // return doc.exists ? User.fromJson(doc.data()!) : null;
  return null;
});