import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

abstract class PaymentFunctionsGateway {
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> payload,
  );
}

class FirebasePaymentFunctionsGateway implements PaymentFunctionsGateway {
  FirebasePaymentFunctionsGateway({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final callable = _functions.httpsCallable(name);
    final result = await callable.call<Map<String, dynamic>>(payload);
    return Map<String, dynamic>.from(result.data);
  }
}

abstract class PaymentAuthGateway {
  User? get currentUser;
}

class FirebasePaymentAuthGateway implements PaymentAuthGateway {
  FirebasePaymentAuthGateway({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  User? get currentUser => _auth.currentUser;
}

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

class RefundRequest {
  final String id;
  final String transactionId;
  final String requesterId;
  final double amount;
  final String status;
  final String reason;
  final DateTime? createdAt;

  const RefundRequest({
    required this.id,
    required this.transactionId,
    required this.requesterId,
    required this.amount,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    return RefundRequest(
      id: (json['id'] as String?)?.trim() ?? '',
      transactionId: (json['transactionId'] as String?)?.trim() ?? '',
      requesterId: (json['requesterId'] as String?)?.trim() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: (json['status'] as String?)?.trim() ?? 'pending',
      reason: (json['reason'] as String?)?.trim() ?? '',
      createdAt: createdAt,
    );
  }
}

class StripeConnectStatus {
  const StripeConnectStatus({
    required this.hasAccount,
    required this.chargesEnabled,
    required this.payoutsEnabled,
    required this.detailsSubmitted,
    required this.onboardingComplete,
    this.accountId,
    this.country,
  });

  final bool hasAccount;
  final bool chargesEnabled;
  final bool payoutsEnabled;
  final bool detailsSubmitted;
  final bool onboardingComplete;
  final String? accountId;
  final String? country;

  factory StripeConnectStatus.fromJson(Map<String, dynamic> json) {
    return StripeConnectStatus(
      hasAccount: json['hasAccount'] as bool? ?? ((json['accountId'] as String?)?.isNotEmpty ?? false),
      chargesEnabled: json['chargesEnabled'] as bool? ?? false,
      payoutsEnabled: json['payoutsEnabled'] as bool? ?? false,
      detailsSubmitted: json['detailsSubmitted'] as bool? ?? false,
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      accountId: (json['accountId'] as String?)?.trim(),
      country: (json['country'] as String?)?.trim(),
    );
  }
}

class PaymentApi {
  static final _firestore = FirebaseFirestore.instance;
  static PaymentFunctionsGateway? _functionsGateway;
  static PaymentAuthGateway? _authGateway;

  static PaymentFunctionsGateway get _resolvedFunctionsGateway =>
    _functionsGateway ??= FirebasePaymentFunctionsGateway();

  static PaymentAuthGateway get _resolvedAuthGateway =>
    _authGateway ??= FirebasePaymentAuthGateway();

  @visibleForTesting
  static void configureForTesting({
    PaymentFunctionsGateway? functionsGateway,
    PaymentAuthGateway? authGateway,
  }) {
    if (functionsGateway != null) {
      _functionsGateway = functionsGateway;
    }
    if (authGateway != null) {
      _authGateway = authGateway;
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _functionsGateway = null;
    _authGateway = null;
  }

  static Future<T> _callFunction<T>(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final result = await _resolvedFunctionsGateway.call(name, payload);
    return result as T;
  }

  /// Creates a payment intent by calling a backend endpoint that integrates with Stripe
  static Future<String> createIntent({
    required double amount,
    required String currency,
    required String recipientId,
  }) async {
    final data = await _callFunction<Map<String, dynamic>>('createPaymentIntent', {
      'amount': amount,
      'currency': currency,
      'recipientId': recipientId,
    });
    final clientSecret = data['clientSecret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('clientSecret missing in response');
    }
    return clientSecret;
  }

  /// Notifies backend of successful payment (records transaction in Firestore)
  static Future<void> notifySuccess({
    required String recipientId,
    required double amount,
  }) async {
    final user = _resolvedAuthGateway.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await _callFunction<Map<String, dynamic>>('recordStripePaymentSuccess', {
      'recipientId': recipientId,
      'amount': amount,
    });
  }

  static Future<void> sendPayment(
    String receiverId,
    double amount,
  ) async {
    final user = _resolvedAuthGateway.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await _callFunction<Map<String, dynamic>>('sendCoinTransfer', {
      'receiverId': receiverId,
      'amount': amount,
    });
  }

  static Future<void> requestPayment(
    String requesterId,
    String targetId,
    double amount,
  ) async {
    final user = _resolvedAuthGateway.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    if (user.uid != requesterId) {
      throw Exception('Authenticated user does not match requesterId');
    }
    await _callFunction<Map<String, dynamic>>('requestCoinTransfer', {
      'targetId': targetId,
      'amount': amount,
    });
  }

  static Future<StripeConnectStatus> getStripeConnectStatus() async {
    final user = _resolvedAuthGateway.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final data = await _callFunction<Map<String, dynamic>>('getStripeConnectStatus', {});
    return StripeConnectStatus.fromJson(data);
  }

  static Future<String> createStripeConnectOnboardingLink() async {
    final user = _resolvedAuthGateway.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final data = await _callFunction<Map<String, dynamic>>('createStripeConnectOnboardingLink', {});
    final url = (data['url'] as String?)?.trim();
    if (url == null || url.isEmpty) {
      throw Exception('Onboarding URL missing in response');
    }
    return url;
  }

  static Future<String> createStripeConnectDashboardLink() async {
    final user = _resolvedAuthGateway.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final data = await _callFunction<Map<String, dynamic>>('createStripeConnectDashboardLink', {});
    final url = (data['url'] as String?)?.trim();
    if (url == null || url.isEmpty) {
      throw Exception('Dashboard URL missing in response');
    }
    return url;
  }

  static Future<void> requestRefund({
    required String transactionId,
    required String reason,
  }) async {
    final user = _resolvedAuthGateway.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final normalizedTransactionId = transactionId.trim();
    if (normalizedTransactionId.isEmpty) {
      throw Exception('Transaction id is required');
    }

    final normalizedReason = reason.trim();
    if (normalizedReason.length < 10) {
      throw Exception('Refund reason must be at least 10 characters.');
    }

    await _callFunction<Map<String, dynamic>>('requestRefund', {
      'transactionId': normalizedTransactionId,
      'reason': normalizedReason,
    });
  }

  static Stream<List<RefundRequest>> getMyRefundRequests(String userId) {
    if (userId.trim().isEmpty) {
      return const Stream<List<RefundRequest>>.empty();
    }

    return _firestore
        .collection('refund_requests')
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => RefundRequest.fromJson(doc.data()))
              .toList(growable: false)
            ..sort((a, b) {
              final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });
          return requests;
        });
  }

  static Stream<List<CoinTransaction>> getTransactions(String userId) {
    if (userId.trim().isEmpty) {
      return const Stream<List<CoinTransaction>>.empty();
    }

    return _firestore
        .collection('transactions')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) {
            final transactions = snapshot.docs
                .map((doc) => CoinTransaction.fromJson(doc.data()))
                .toList(growable: false)
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return transactions;
          },
        );
  }
}
