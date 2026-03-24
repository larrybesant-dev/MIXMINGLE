import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinTransaction {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final DateTime timestamp;
  final String status; // sent, requested, completed

  CoinTransaction({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.timestamp,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
  };

  factory CoinTransaction.fromJson(Map<String, dynamic> json) =>
      CoinTransaction(
        id: json['id'],
        senderId: json['senderId'],
        receiverId: json['receiverId'],
        amount: (json['amount'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp']),
        status: json['status'],
      );
}

class PaymentApi {
    /// Ensures user document exists with default balance
    static Future<void> ensureUserExists(String uid, {double defaultBalance = 100.0}) async {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'balance': defaultBalance,
        });
      }
    }
  static final _firestore = FirebaseFirestore.instance;
  static final _uuid = Uuid();

  /// Creates a payment intent by calling a backend endpoint that integrates with Stripe
  static Future<String> createIntent({
    required double amount,
    required String currency,
    required String recipientId,
  }) async {
    // Replace with your actual backend endpoint
    final url = Uri.parse('https://us-central1-mixvy-app.cloudfunctions.net/createPaymentIntent');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount.toString(),
        'currency': currency,
        'recipientId': recipientId,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['clientSecret'] != null) {
        return data['clientSecret'] as String;
      } else {
        throw Exception('clientSecret missing in response');
      }
    } else {
      throw Exception('Failed to create payment intent: ${response.body}');
    }
  }

  /// Notifies backend of successful payment (records transaction in Firestore)
  static Future<void> notifySuccess({
    required String recipientId,
    required double amount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final senderId = user.uid;
    final transaction = CoinTransaction(
      id: _uuid.v4(),
      senderId: senderId,
      receiverId: recipientId,
      amount: amount,
      timestamp: DateTime.now(),
      status: 'completed',
    );
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toJson());
  }

  static Future<void> sendPayment(
    String receiverId,
    double amount,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final senderId = user.uid;
    // Ensure both users exist
    await ensureUserExists(senderId);
    await ensureUserExists(receiverId);

    // Run Firestore transaction for atomic balance update
    await _firestore.runTransaction((txn) async {
      final senderRef = _firestore.collection('users').doc(senderId);
      final receiverRef = _firestore.collection('users').doc(receiverId);
      final senderSnap = await txn.get(senderRef);
      final receiverSnap = await txn.get(receiverRef);
      final senderBalance = (senderSnap.data()?['balance'] ?? 0).toDouble();
      final receiverBalance = (receiverSnap.data()?['balance'] ?? 0).toDouble();
      if (senderBalance < amount) {
        throw Exception('Insufficient balance');
      }
      txn.update(senderRef, {'balance': senderBalance - amount});
      txn.update(receiverRef, {'balance': receiverBalance + amount});
      final transaction = CoinTransaction(
        id: _uuid.v4(),
        senderId: senderId,
        receiverId: receiverId,
        amount: amount,
        timestamp: DateTime.now(),
        status: 'sent',
      );
      txn.set(
        _firestore.collection('transactions').doc(transaction.id),
        transaction.toJson(),
      );
    });
  }

  static Future<void> requestPayment(
    String requesterId,
    String targetId,
    double amount,
  ) async {
    final transaction = CoinTransaction(
      id: _uuid.v4(),
      senderId: requesterId,
      receiverId: targetId,
      amount: amount,
      timestamp: DateTime.now(),
      status: 'requested',
    );
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toJson());
  }

  static Stream<List<CoinTransaction>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('senderId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CoinTransaction.fromJson(doc.data()))
              .toList(),
        );
  }
}
