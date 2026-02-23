library;
import 'dart:js_util' as js_util;
import 'package:mixmingle/helpers/helpers.dart';
/// Onboarding Data Model
///
/// Stores temporary onboarding state during the flow.
/// This data is used to create/update the user profile.

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
    'Chill ðŸ˜Œ',
    'Flirty ðŸ˜',
    'Adventurous ðŸ”¥',
    'Social ðŸŽ‰',
    'Deep Talks ðŸ’­',
    'Party Mode ðŸŽŠ',
  ];

  static String getEmoji(String mood) {
    switch (mood) {
      case 'Chill ðŸ˜Œ':
        return 'ðŸ˜Œ';
      case 'Flirty ðŸ˜':
        return 'ðŸ˜';
      case 'Adventurous ðŸ”¥':
        return 'ðŸ”¥';
      case 'Social ðŸŽ‰':
        return 'ðŸŽ‰';
      case 'Deep Talks ðŸ’­':
        return 'ðŸ’­';
      case 'Party Mode ðŸŽŠ':
        return 'ðŸŽŠ';
      default:
        return 'âœ¨';
    }
  }
}

/// Interest categories for the interests screen
class InterestCategories {
  static const List<InterestItem> items = [
    InterestItem(id: 'music', label: 'Music', icon: 'ðŸŽµ'),
    InterestItem(id: 'flirting', label: 'Flirting', icon: 'ðŸ’‹'),
    InterestItem(id: 'chill', label: 'Chill', icon: 'â˜•'),
    InterestItem(id: 'after_hours', label: 'After Hours', icon: 'ðŸŒ™'),
    InterestItem(id: 'deep_talk', label: 'Deep Talk', icon: 'ðŸ’¬'),
    InterestItem(id: 'speed_dating', label: 'Speed Dating', icon: 'âš¡'),
    InterestItem(id: 'social_rooms', label: 'Social Rooms', icon: 'ðŸ‘¥'),
    InterestItem(id: 'games', label: 'Games', icon: 'ðŸŽ®'),
    InterestItem(id: 'dating', label: 'Dating', icon: 'â¤ï¸'),
    InterestItem(id: 'networking', label: 'Networking', icon: 'ðŸ¤'),
    InterestItem(id: 'karaoke', label: 'Karaoke', icon: 'ðŸŽ¤'),
    InterestItem(id: 'comedy', label: 'Comedy', icon: 'ðŸ˜‚'),
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
      icon: 'ðŸŽ¯',
      illustration: 'rooms',
    ),
    TutorialStep(
      title: 'Spotlight Someone',
      description: 'Tap a tile to highlight and connect with someone special',
      icon: 'âœ¨',
      illustration: 'spotlight',
    ),
    TutorialStep(
      title: 'Explore & Discover',
      description: 'Swipe through rooms to find new experiences',
      icon: 'ðŸ”',
      illustration: 'explore',
    ),
    TutorialStep(
      title: 'Go Live',
      description: 'Ready to host? Start your own room and shine',
      icon: 'ðŸ”´',
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


