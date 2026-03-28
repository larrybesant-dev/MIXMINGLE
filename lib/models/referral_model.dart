class ReferralCodeModel {
  const ReferralCodeModel({
    required this.code,
    required this.ownerUserId,
    this.isActive = true,
    this.createdAt,
  });

  final String code;
  final String ownerUserId;
  final bool isActive;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'ownerUserId': ownerUserId,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory ReferralCodeModel.fromJson(Map<String, dynamic> json) {
    return ReferralCodeModel(
      code: json['code'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

class ReferralAttributionModel {
  const ReferralAttributionModel({
    required this.id,
    required this.referrerUserId,
    required this.referredUserId,
    required this.referralCode,
    this.subscriptionStatus = 'pending',
    this.rewardStatus = 'pending',
    this.createdAt,
    this.conversionAt,
  });

  final String id;
  final String referrerUserId;
  final String referredUserId;
  final String referralCode;
  final String subscriptionStatus;
  final String rewardStatus;
  final DateTime? createdAt;
  final DateTime? conversionAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrerUserId': referrerUserId,
      'referredUserId': referredUserId,
      'referralCode': referralCode,
      'subscriptionStatus': subscriptionStatus,
      'rewardStatus': rewardStatus,
      'createdAt': createdAt?.toIso8601String(),
      'conversionAt': conversionAt?.toIso8601String(),
      'participantIds': [referrerUserId, referredUserId],
    };
  }

  factory ReferralAttributionModel.fromJson(Map<String, dynamic> json) {
    return ReferralAttributionModel(
      id: json['id'] as String? ?? '',
      referrerUserId: json['referrerUserId'] as String? ?? '',
      referredUserId: json['referredUserId'] as String? ?? '',
      referralCode: json['referralCode'] as String? ?? '',
      subscriptionStatus: json['subscriptionStatus'] as String? ?? 'pending',
      rewardStatus: json['rewardStatus'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      conversionAt: DateTime.tryParse(json['conversionAt'] as String? ?? ''),
    );
  }
}

class ReferralEarningModel {
  const ReferralEarningModel({
    required this.id,
    required this.referralId,
    required this.beneficiaryUserId,
    required this.sourceUserId,
    required this.amount,
    this.currency = 'usd',
    this.status = 'pending',
    this.createdAt,
  });

  final String id;
  final String referralId;
  final String beneficiaryUserId;
  final String sourceUserId;
  final double amount;
  final String currency;
  final String status;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referralId': referralId,
      'beneficiaryUserId': beneficiaryUserId,
      'sourceUserId': sourceUserId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory ReferralEarningModel.fromJson(Map<String, dynamic> json) {
    return ReferralEarningModel(
      id: json['id'] as String? ?? '',
      referralId: json['referralId'] as String? ?? '',
      beneficiaryUserId: json['beneficiaryUserId'] as String? ?? '',
      sourceUserId: json['sourceUserId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'usd',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}