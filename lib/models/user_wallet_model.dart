import 'package:cloud_firestore/cloud_firestore.dart';

class UserWallet {
  final String userId;
  final int coins;
  final Timestamp lastUpdated;

  UserWallet({
    required this.userId,
    required this.coins,
    required this.lastUpdated,
  });

  factory UserWallet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserWallet(
      userId: doc.id,
      coins: data['coins'] ?? 0,
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coins': coins,
      'lastUpdated': lastUpdated,
    };
  }
}
