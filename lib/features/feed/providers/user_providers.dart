import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';

final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (!doc.exists) return null;
  final data = doc.data();
  if (data == null) return null;
  return UserModel.fromJson({
    ...data,
    'id': doc.id,
  });
});