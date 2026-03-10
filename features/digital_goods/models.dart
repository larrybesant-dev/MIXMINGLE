import 'package:cloud_firestore/cloud_firestore.dart';


// Enums
enum PackType { overlay, emoji }
enum PackAssetKind { frame, entryEffect, emoji, sticker }
enum PackAssetFormat { png, svg, lottie }
enum UserTier { free, premium, creatorPro }
enum TierRequired { free, premium, creatorPro }
enum PriceType { free, oneTime, includedInTier }

// Enum helpers for string serialization
T _enumFromString<T>(String value, List<T> values) =>
  values.firstWhere((e) => e.toString().split('.').last == value);

extension UserTierX on UserTier {
  int get level => index;
}

extension TierRequiredX on TierRequired {
  int get level => index;
}

bool hasTierOrAbove(UserTier current, TierRequired required) =>
  current.level >= required.level;

// PackAsset
class PackAsset {
  final String url;
  final PackAssetKind kind;
  final PackAssetFormat format;

  const PackAsset({
    required this.url,
    required this.kind,
    required this.format,
  });

  factory PackAsset.fromJson(Map<String, dynamic> json) => PackAsset(
    url: json['url'] ?? '',
    kind: _enumFromString(json['kind'] ?? 'frame', PackAssetKind.values),
    format: _enumFromString(json['format'] ?? 'png', PackAssetFormat.values),
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'kind': kind.name,
    'format': format.name,
  };
}

// Pack
class Pack {
    String get id => uid;
  final String uid;
  final PackType type;
  final String name;
  final String description;
  final TierRequired tierRequired;
  final PriceType priceType;
  final String? stripeProductId;
  final bool isOfficial;
  final String? username;
  final String previewImageUrl;
  final List<PackAsset> assets;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;

  const Pack({
    required this.uid,
    required this.type,
    required this.name,
    required this.description,
    required this.tierRequired,
    required this.priceType,
    this.stripeProductId,
    required this.isOfficial,
    this.username,
    required this.previewImageUrl,
    required this.assets,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublished,
  });

  factory Pack.fromJson(Map<String, dynamic> json, String uid) => Pack(
    uid: uid,
    type: _enumFromString(json['type'] ?? 'overlay', PackType.values),
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    tierRequired: _enumFromString(json['tierRequired'] ?? 'free', TierRequired.values),
    priceType: _enumFromString(json['priceType'] ?? 'free', PriceType.values),
    stripeProductId: json['stripeProductId'],
    isOfficial: json['isOfficial'] ?? false,
    username: json['username'],
    previewImageUrl: json['previewImageUrl'] ?? '',
    assets: (json['assets'] as List<dynamic>? ?? [])
      .map((a) => PackAsset.fromJson(a as Map<String, dynamic>)).toList(),
    createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isPublished: json['isPublished'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'name': name,
    'description': description,
    'tierRequired': tierRequired.name,
    'priceType': priceType.name,
    'stripeProductId': stripeProductId,
    'isOfficial': isOfficial,
    'username': username,
    'previewImageUrl': previewImageUrl,
    'assets': assets.map((a) => a.toJson()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'isPublished': isPublished,
  };


}

// UserPurchase
class UserPurchase {
  final String uid;
  final DateTime purchasedAt;
  final String email;
  final PriceType priceType;
  final String source;

  const UserPurchase({
    required this.uid,
    required this.purchasedAt,
    required this.email,
    required this.priceType,
    required this.source,
  });

  factory UserPurchase.fromJson(Map<String, dynamic> json) => UserPurchase(
    uid: json['uid'] ?? '',
    purchasedAt: (json['purchasedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    email: json['email'] ?? '',
    priceType: _enumFromString(json['priceType'] ?? 'oneTime', PriceType.values),
    source: json['source'] ?? 'direct',
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'purchasedAt': Timestamp.fromDate(purchasedAt),
    'email': email,
    'priceType': priceType.name,
    'source': source,
  };


}

// UserCreation
class UserCreation {
  final String uid;
  final String? onboardingComplete;
  final PackType type;
  final String name;
  final String description;
  final List<PackAsset> assets;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserCreation({
    required this.uid,
    this.onboardingComplete,
    required this.type,
    required this.name,
    required this.description,
    required this.assets,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserCreation.fromJson(Map<String, dynamic> json, String uid) => UserCreation(
    uid: uid,
    onboardingComplete: json['onboardingComplete'],
    type: _enumFromString(json['type'] ?? 'overlay', PackType.values),
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    assets: (json['assets'] as List<dynamic>? ?? [])
      .map((a) => PackAsset.fromJson(a as Map<String, dynamic>)).toList(),
    isPublished: json['isPublished'] ?? false,
    createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'onboardingComplete': onboardingComplete,
    'type': type.name,
    'name': name,
    'description': description,
    'assets': assets.map((a) => a.toJson()).toList(),
    'isPublished': isPublished,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };


}

// UserTier
class UserTierModel {
  final UserTier tier;
  final DateTime tierUpdatedAt;

  const UserTierModel({
    required this.tier,
    required this.tierUpdatedAt,
  });

  factory UserTierModel.fromJson(Map<String, dynamic> json) => UserTierModel(
    tier: _enumFromString(json['tier'] ?? 'free', UserTier.values),
    tierUpdatedAt: (json['tierUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'tier': tier.name,
    'tierUpdatedAt': Timestamp.fromDate(tierUpdatedAt),
  };


}

// Unlock helper
bool isPackUnlocked({
  required UserTier tier,
  required Pack pack,
  required Set<String> purchasedPackIds,
}) {
  if (pack.priceType == PriceType.free) return true;
  if (hasTierOrAbove(tier, pack.tierRequired)) return true;
  if (purchasedPackIds.contains(pack.id)) return true;
  return false;
}

