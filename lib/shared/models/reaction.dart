class Reaction {
  final String id;
  final ReactionType type;
  final String fromUserId;
  final String toUserId;
  final String? roomId;
  final DateTime timestamp;
  final int? coinCost;

  Reaction({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.toUserId,
    this.roomId,
    required this.timestamp,
    this.coinCost,
  });

  factory Reaction.fromMap(Map<String, dynamic> map) {
    return Reaction(
      id: map['id'] ?? '',
      type: ReactionType.values.firstWhere(
        (e) => e.toString() == 'ReactionType.${map['type']}',
        orElse: () => ReactionType.wave,
      ),
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      roomId: map['roomId'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      coinCost: map['coinCost'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'roomId': roomId,
      'timestamp': timestamp.toIso8601String(),
      'coinCost': coinCost,
    };
  }
}

enum ReactionType {
  wave, // 👋 Free
  heart, // ❤️ Free
  celebrate, // 🎉 Free
  fire, // 🔥 5 coins
  rose, // 🌹 10 coins
  diamond, // 💎 25 coins
  crown, // 👑 50 coins
  trophy, // 🏆 100 coins
}

extension ReactionTypeExtension on ReactionType {
  String get emoji {
    switch (this) {
      case ReactionType.wave:
        return '👋';
      case ReactionType.heart:
        return '❤️';
      case ReactionType.celebrate:
        return '🎉';
      case ReactionType.fire:
        return '🔥';
      case ReactionType.rose:
        return '🌹';
      case ReactionType.diamond:
        return '💎';
      case ReactionType.crown:
        return '👑';
      case ReactionType.trophy:
        return '🏆';
    }
  }

  int get coinCost {
    switch (this) {
      case ReactionType.wave:
      case ReactionType.heart:
      case ReactionType.celebrate:
        return 0;
      case ReactionType.fire:
        return 5;
      case ReactionType.rose:
        return 10;
      case ReactionType.diamond:
        return 25;
      case ReactionType.crown:
        return 50;
      case ReactionType.trophy:
        return 100;
    }
  }

  String get name {
    switch (this) {
      case ReactionType.wave:
        return 'Wave';
      case ReactionType.heart:
        return 'Heart';
      case ReactionType.celebrate:
        return 'Celebrate';
      case ReactionType.fire:
        return 'Fire';
      case ReactionType.rose:
        return 'Rose';
      case ReactionType.diamond:
        return 'Diamond';
      case ReactionType.crown:
        return 'Crown';
      case ReactionType.trophy:
        return 'Trophy';
    }
  }
}
