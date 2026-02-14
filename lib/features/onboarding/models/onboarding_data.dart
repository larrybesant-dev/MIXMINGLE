/// Onboarding Data Model
///
/// Stores temporary onboarding state during the flow.
/// This data is used to create/update the user profile.
library;

class OnboardingData {
  final String? name;
  final int? age;
  final String? mood;
  final List<String> interests;
  final String? photoPath;
  final bool cameraPermissionGranted;
  final bool micPermissionGranted;
  final bool notificationPermissionGranted;
  final int currentStep;
  final int tutorialStep;

  const OnboardingData({
    this.name,
    this.age,
    this.mood,
    this.interests = const [],
    this.photoPath,
    this.cameraPermissionGranted = false,
    this.micPermissionGranted = false,
    this.notificationPermissionGranted = false,
    this.currentStep = 0,
    this.tutorialStep = 0,
  });

  OnboardingData copyWith({
    String? name,
    int? age,
    String? mood,
    List<String>? interests,
    String? photoPath,
    bool? cameraPermissionGranted,
    bool? micPermissionGranted,
    bool? notificationPermissionGranted,
    int? currentStep,
    int? tutorialStep,
  }) {
    return OnboardingData(
      name: name ?? this.name,
      age: age ?? this.age,
      mood: mood ?? this.mood,
      interests: interests ?? this.interests,
      photoPath: photoPath ?? this.photoPath,
      cameraPermissionGranted: cameraPermissionGranted ?? this.cameraPermissionGranted,
      micPermissionGranted: micPermissionGranted ?? this.micPermissionGranted,
      notificationPermissionGranted: notificationPermissionGranted ?? this.notificationPermissionGranted,
      currentStep: currentStep ?? this.currentStep,
      tutorialStep: tutorialStep ?? this.tutorialStep,
    );
  }

  bool get isProfileValid =>
    name != null &&
    name!.isNotEmpty &&
    age != null &&
    age! >= 18;

  bool get hasSelectedInterests => interests.length >= 3;

  @override
  String toString() {
    return 'OnboardingData(name: $name, age: $age, mood: $mood, interests: $interests, currentStep: $currentStep)';
  }
}

/// Mood options for the profile setup
class MoodOptions {
  static const List<String> moods = [
    'Chill 😌',
    'Flirty 😏',
    'Adventurous 🔥',
    'Social 🎉',
    'Deep Talks 💭',
    'Party Mode 🎊',
  ];

  static String getEmoji(String mood) {
    switch (mood) {
      case 'Chill 😌':
        return '😌';
      case 'Flirty 😏':
        return '😏';
      case 'Adventurous 🔥':
        return '🔥';
      case 'Social 🎉':
        return '🎉';
      case 'Deep Talks 💭':
        return '💭';
      case 'Party Mode 🎊':
        return '🎊';
      default:
        return '✨';
    }
  }
}

/// Interest categories for the interests screen
class InterestCategories {
  static const List<InterestItem> items = [
    InterestItem(id: 'music', label: 'Music', icon: '🎵'),
    InterestItem(id: 'flirting', label: 'Flirting', icon: '💋'),
    InterestItem(id: 'chill', label: 'Chill', icon: '☕'),
    InterestItem(id: 'after_hours', label: 'After Hours', icon: '🌙'),
    InterestItem(id: 'deep_talk', label: 'Deep Talk', icon: '💬'),
    InterestItem(id: 'speed_dating', label: 'Speed Dating', icon: '⚡'),
    InterestItem(id: 'social_rooms', label: 'Social Rooms', icon: '👥'),
    InterestItem(id: 'games', label: 'Games', icon: '🎮'),
    InterestItem(id: 'dating', label: 'Dating', icon: '❤️'),
    InterestItem(id: 'networking', label: 'Networking', icon: '🤝'),
    InterestItem(id: 'karaoke', label: 'Karaoke', icon: '🎤'),
    InterestItem(id: 'comedy', label: 'Comedy', icon: '😂'),
  ];
}

class InterestItem {
  final String id;
  final String label;
  final String icon;

  const InterestItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Tutorial steps
class TutorialSteps {
  static const List<TutorialStep> steps = [
    TutorialStep(
      title: 'Find Your Vibe',
      description: 'Join rooms that match your mood and interests',
      icon: '🎯',
      illustration: 'rooms',
    ),
    TutorialStep(
      title: 'Spotlight Someone',
      description: 'Tap a tile to highlight and connect with someone special',
      icon: '✨',
      illustration: 'spotlight',
    ),
    TutorialStep(
      title: 'Explore & Discover',
      description: 'Swipe through rooms to find new experiences',
      icon: '🔍',
      illustration: 'explore',
    ),
    TutorialStep(
      title: 'Go Live',
      description: 'Ready to host? Start your own room and shine',
      icon: '🔴',
      illustration: 'golive',
    ),
  ];
}

class TutorialStep {
  final String title;
  final String description;
  final String icon;
  final String illustration;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.illustration,
  });
}
