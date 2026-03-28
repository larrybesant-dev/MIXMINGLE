class WalletModel {
  const WalletModel({
    required this.userId,
    this.coinBalance = 0,
    this.cashBalance = 0,
    this.referralEarnings = 0,
    this.roomEarnings = 0,
    this.giftEarnings = 0,
    this.pendingCashOut = 0,
    this.updatedAt,
  });

  final String userId;
  final int coinBalance;
  final double cashBalance;
  final double referralEarnings;
  final double roomEarnings;
  final double giftEarnings;
  final double pendingCashOut;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'coinBalance': coinBalance,
      'cashBalance': cashBalance,
      'referralEarnings': referralEarnings,
      'roomEarnings': roomEarnings,
      'giftEarnings': giftEarnings,
      'pendingCashOut': pendingCashOut,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: json['userId'] as String? ?? '',
      coinBalance: (json['coinBalance'] as num?)?.toInt() ?? 0,
      cashBalance: (json['cashBalance'] as num?)?.toDouble() ?? 0,
      referralEarnings: (json['referralEarnings'] as num?)?.toDouble() ?? 0,
      roomEarnings: (json['roomEarnings'] as num?)?.toDouble() ?? 0,
      giftEarnings: (json['giftEarnings'] as num?)?.toDouble() ?? 0,
      pendingCashOut: (json['pendingCashOut'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

class WalletLedgerEntry {
  const WalletLedgerEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    this.referenceId,
    this.metadata = const <String, dynamic>{},
    this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final double amount;
  final String currency;
  final String status;
  final String? referenceId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'status': status,
      'referenceId': referenceId,
      'metadata': metadata,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory WalletLedgerEntry.fromJson(Map<String, dynamic> json) {
    return WalletLedgerEntry(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'usd',
      status: json['status'] as String? ?? 'pending',
      referenceId: json['referenceId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? const <String, dynamic>{}),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}