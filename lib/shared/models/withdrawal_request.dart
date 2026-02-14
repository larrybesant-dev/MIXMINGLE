import 'package:cloud_firestore/cloud_firestore.dart';

enum WithdrawalStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

class WithdrawalRequest {
  final String id;
  final String userId;
  final String userName;
  final int coinAmount;
  final double usdAmount;
  final double platformFee;
  final double payoutAmount;
  final WithdrawalStatus status;
  final String? stripeAccountId;
  final String? stripeTransferId;
  final String? failureReason;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.coinAmount,
    required this.usdAmount,
    required this.platformFee,
    required this.payoutAmount,
    required this.status,
    this.stripeAccountId,
    this.stripeTransferId,
    this.failureReason,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
  });

  factory WithdrawalRequest.fromMap(Map<String, dynamic> map) {
    return WithdrawalRequest(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      coinAmount: map['coinAmount'] ?? 0,
      usdAmount: (map['usdAmount'] ?? 0).toDouble(),
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      payoutAmount: (map['payoutAmount'] ?? 0).toDouble(),
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      stripeAccountId: map['stripeAccountId'],
      stripeTransferId: map['stripeTransferId'],
      failureReason: map['failureReason'],
      requestedAt: (map['requestedAt'] as Timestamp).toDate(),
      processedAt: map['processedAt'] != null ? (map['processedAt'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'coinAmount': coinAmount,
      'usdAmount': usdAmount,
      'platformFee': platformFee,
      'payoutAmount': payoutAmount,
      'status': status.name,
      'stripeAccountId': stripeAccountId,
      'stripeTransferId': stripeTransferId,
      'failureReason': failureReason,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  WithdrawalRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    int? coinAmount,
    double? usdAmount,
    double? platformFee,
    double? payoutAmount,
    WithdrawalStatus? status,
    String? stripeAccountId,
    String? stripeTransferId,
    String? failureReason,
    DateTime? requestedAt,
    DateTime? processedAt,
    DateTime? completedAt,
  }) {
    return WithdrawalRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      coinAmount: coinAmount ?? this.coinAmount,
      usdAmount: usdAmount ?? this.usdAmount,
      platformFee: platformFee ?? this.platformFee,
      payoutAmount: payoutAmount ?? this.payoutAmount,
      status: status ?? this.status,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      stripeTransferId: stripeTransferId ?? this.stripeTransferId,
      failureReason: failureReason ?? this.failureReason,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WithdrawalRequest &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.coinAmount == coinAmount &&
        other.usdAmount == usdAmount &&
        other.platformFee == platformFee &&
        other.payoutAmount == payoutAmount &&
        other.status == status &&
        other.stripeAccountId == stripeAccountId &&
        other.stripeTransferId == stripeTransferId &&
        other.failureReason == failureReason &&
        other.requestedAt == requestedAt &&
        other.processedAt == processedAt &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        userName.hashCode ^
        coinAmount.hashCode ^
        usdAmount.hashCode ^
        platformFee.hashCode ^
        payoutAmount.hashCode ^
        status.hashCode ^
        (stripeAccountId?.hashCode ?? 0) ^
        (stripeTransferId?.hashCode ?? 0) ^
        (failureReason?.hashCode ?? 0) ^
        requestedAt.hashCode ^
        (processedAt?.hashCode ?? 0) ^
        (completedAt?.hashCode ?? 0);
  }

  @override
  String toString() {
    return 'WithdrawalRequest(id: $id, userId: $userId, coinAmount: $coinAmount, usdAmount: \$$usdAmount, status: $status, requestedAt: $requestedAt)';
  }
}
