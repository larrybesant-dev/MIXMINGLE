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
        return 'ðŸŽµ Music';
      case gaming:
        return 'ðŸŽ® Gaming';
      case dating:
        return 'ðŸ’• Dating';
      case fitness:
        return 'ðŸ’ª Fitness';
      case business:
        return 'ðŸ’¼ Business';
      case education:
        return 'ðŸ“š Education';
      case entertainment:
        return 'ðŸŽ¬ Entertainment';
      case socializing:
        return 'ðŸ‘¥ Socializing';
      case events:
        return 'ðŸŽ‰ Events';
      case general:
        return 'ðŸ’¬ General';
      default:
        return 'ðŸ’¬ ${category[0].toUpperCase()}${category.substring(1)}';
    }
  }

  /// Get emoji for category
  static String getEmoji(String category) {
    switch (category.toLowerCase()) {
      case music:
        return 'ðŸŽµ';
      case gaming:
        return 'ðŸŽ®';
      case dating:
        return 'ðŸ’•';
      case fitness:
        return 'ðŸ’ª';
      case business:
        return 'ðŸ’¼';
      case education:
        return 'ðŸ“š';
      case entertainment:
        return 'ðŸŽ¬';
      case socializing:
        return 'ðŸ‘¥';
      case events:
        return 'ðŸŽ‰';
      case general:
        return 'ðŸ’¬';
      default:
        return 'ðŸ’¬';
    }
  }

  /// Check if category is valid
  static bool isValid(String category) {
    return all.contains(category.toLowerCase());
  }
}
