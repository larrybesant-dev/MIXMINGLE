/// Service for classifying rooms based on their tags.
class CategoryService {
  /// Category mapping with priority order: Music > Gaming > Chat > Live > Other
  static const Map<String, List<String>> _categoryKeywords = {
    'Music': ['music', 'dj', 'beats', 'mix'],
    'Gaming': ['gaming', 'game', 'esports', 'play'],
    'Chat': ['chat', 'talk', 'hangout'],
    'Live': ['live', 'stream', 'broadcast'],
  };

  /// Priority order for categories (highest to lowest)
  static const List<String> _categoryPriority = [
    'Music',
    'Gaming',
    'Chat',
    'Live',
  ];

  /// Default category when no tags match
  static const String defaultCategory = 'Other';

  /// Classifies a room based on its tags.
  ///
  /// Priority order: Music > Gaming > Chat > Live > Other
  ///
  /// Example:
  /// ```dart
  /// final category = CategoryService.classifyRoom(['music', 'gaming']);
  /// // Returns 'Music' (higher priority)
  /// ```
  String classifyRoom(List<String> tags) {
    if (tags.isEmpty) {
      return defaultCategory;
    }

    // Normalize tags to lowercase for case-insensitive matching
    final normalizedTags = tags.map((tag) => tag.toLowerCase().trim()).toSet();

    // Check each category in priority order
    for (final category in _categoryPriority) {
      final keywords = _categoryKeywords[category];
      if (keywords != null) {
        // Check if any keyword matches any tag
        if (keywords.any((keyword) => normalizedTags.contains(keyword))) {
          return category;
        }
      }
    }

    return defaultCategory;
  }

  /// Validates if a category is valid.
  bool isValidCategory(String category) {
    return _categoryPriority.contains(category) || category == defaultCategory;
  }

  /// Returns all available categories including 'Other'.
  List<String> getAllCategories() {
    return [..._categoryPriority, defaultCategory];
  }

  /// Returns the keywords associated with a category.
  List<String> getCategoryKeywords(String category) {
    return _categoryKeywords[category] ?? [];
  }

  /// Suggests category based on partial tag input.
  String? suggestCategory(String partialTag) {
    if (partialTag.isEmpty) {
      return null;
    }

    final normalized = partialTag.toLowerCase().trim();

    // Check each category for matching keywords
    for (final category in _categoryPriority) {
      final keywords = _categoryKeywords[category];
      if (keywords != null) {
        if (keywords.any((keyword) => keyword.contains(normalized))) {
          return category;
        }
      }
    }

    return null;
  }

  /// Normalizes tags by trimming whitespace and converting to lowercase.
  List<String> normalizeTags(List<String> tags) {
    return tags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Validates tags to ensure they meet requirements.
  ///
  /// Returns null if valid, otherwise returns an error message.
  String? validateTags(List<String> tags) {
    if (tags.isEmpty) {
      return 'At least one tag is required';
    }

    final normalized = normalizeTags(tags);

    if (normalized.isEmpty) {
      return 'At least one valid tag is required';
    }

    if (normalized.length > 10) {
      return 'Maximum 10 tags allowed';
    }

    for (final tag in normalized) {
      if (tag.length > 20) {
        return 'Tags must be 20 characters or less';
      }

      if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(tag)) {
        return 'Tags can only contain letters, numbers, hyphens, and underscores';
      }
    }

    return null;
  }
}


