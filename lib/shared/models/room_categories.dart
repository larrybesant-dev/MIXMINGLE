/// Room Categories Helper
/// Centralized room category constants and utilities
library;

class RoomCategories {
  // Private constructor to prevent instantiation
  RoomCategories._();

  // Standard categories
  static const String music = 'music';
  static const String gaming = 'gaming';
  static const String dating = 'dating';
  static const String fitness = 'fitness';
  static const String business = 'business';
  static const String education = 'education';
  static const String entertainment = 'entertainment';
  static const String socializing = 'socializing';
  static const String events = 'events';
  static const String general = 'general';

  /// All available categories
  static const List<String> all = [
    music,
    gaming,
    dating,
    fitness,
    business,
    education,
    entertainment,
    socializing,
    events,
    general,
  ];

  /// Get display name for category
  static String getDisplayName(String category) {
    switch (category.toLowerCase()) {
      case music:
        return '🎵 Music';
      case gaming:
        return '🎮 Gaming';
      case dating:
        return '💕 Dating';
      case fitness:
        return '💪 Fitness';
      case business:
        return '💼 Business';
      case education:
        return '📚 Education';
      case entertainment:
        return '🎬 Entertainment';
      case socializing:
        return '👥 Socializing';
      case events:
        return '🎉 Events';
      case general:
        return '💬 General';
      default:
        return '💬 ${category[0].toUpperCase()}${category.substring(1)}';
    }
  }

  /// Get emoji for category
  static String getEmoji(String category) {
    switch (category.toLowerCase()) {
      case music:
        return '🎵';
      case gaming:
        return '🎮';
      case dating:
        return '💕';
      case fitness:
        return '💪';
      case business:
        return '💼';
      case education:
        return '📚';
      case entertainment:
        return '🎬';
      case socializing:
        return '👥';
      case events:
        return '🎉';
      case general:
        return '💬';
      default:
        return '💬';
    }
  }

  /// Check if category is valid
  static bool isValid(String category) {
    return all.contains(category.toLowerCase());
  }
}
