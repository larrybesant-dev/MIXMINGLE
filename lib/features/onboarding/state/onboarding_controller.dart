/// Onboarding Controller
///
/// Manages onboarding flow state, progress tracking, and completion.
/// Uses SharedPreferences to persist onboarding completion status.
/// Integrates with OnboardingOptimizationService for funnel tracking
/// and WelcomeRoomService for auto-join functionality.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_data.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/engagement/onboarding_optimization_service.dart';
import '../../../core/engagement/welcome_room_service.dart';

class OnboardingController extends ChangeNotifier {
  static const String _onboardingCompleteKey = 'onboarding_complete_v2';

  final AnalyticsService _analytics = AnalyticsService.instance;
  final OnboardingOptimizationService _optimization = OnboardingOptimizationService.instance;
  final WelcomeRoomService _welcomeRoom = WelcomeRoomService.instance;

  OnboardingData _data = const OnboardingData();
  bool _isLoading = false;
  String? _errorMessage;
  bool _onboardingStartTracked = false;

  // Getters
  OnboardingData get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentStep => _data.currentStep;

  // Total steps in the onboarding flow
  static const int totalSteps = 6;

  /// Check if onboarding has been completed
  static Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompleteKey) ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }

  /// Mark onboarding as complete
  /// Optionally auto-joins the welcome room for new users
  Future<String?> completeOnboarding({String? userId, String? userName}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);

      // Track onboarding completion
      await _analytics.logOnboardingCompleted();
      await _analytics.logNewUserActivationStep(step: 2, stepName: 'onboarding_completed');

      // Track funnel completion with optimization service
      if (userId != null) {
        await _optimization.trackOnboardingComplete(userId);
      }

      // Auto-join welcome room after completion
      String? welcomeRoomId;
      if (userId != null && userName != null) {
        welcomeRoomId = await _welcomeRoom.joinWelcomeRoom(userId, userName);
        if (welcomeRoomId != null) {
          debugPrint('✅ Auto-joined welcome room: $welcomeRoomId');
        }
      }

      debugPrint('✅ Onboarding marked as complete');
      return welcomeRoomId;
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      _errorMessage = 'Failed to save progress';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset onboarding (for testing purposes)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompleteKey);
      debugPrint('🔄 Onboarding reset');
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
    }
  }

  // Profile Setup Methods
  void setName(String name) {
    _data = _data.copyWith(name: name);
    notifyListeners();
  }

  void setAge(int age) {
    _data = _data.copyWith(age: age);
    notifyListeners();
  }

  void setMood(String mood) {
    _data = _data.copyWith(mood: mood);
    notifyListeners();
  }

  void setPhotoPath(String? path) {
    _data = _data.copyWith(photoPath: path);
    notifyListeners();
  }

  // Interest Methods
  void toggleInterest(String interest) {
    final currentInterests = List<String>.from(_data.interests);
    if (currentInterests.contains(interest)) {
      currentInterests.remove(interest);
    } else {
      currentInterests.add(interest);
    }
    _data = _data.copyWith(interests: currentInterests);
    notifyListeners();
  }

  void setInterests(List<String> interests) {
    _data = _data.copyWith(interests: interests);
    notifyListeners();
  }

  // Permission Methods
  void setCameraPermission(bool granted) {
    _data = _data.copyWith(cameraPermissionGranted: granted);
    notifyListeners();
  }

  void setMicPermission(bool granted) {
    _data = _data.copyWith(micPermissionGranted: granted);
    notifyListeners();
  }

  void setNotificationPermission(bool granted) {
    _data = _data.copyWith(notificationPermissionGranted: granted);
    notifyListeners();
  }

  // Navigation Methods
  void goToStep(int step, {String? userId}) {
    if (step >= 0 && step < totalSteps) {
      // Track onboarding started when first navigating
      if (!_onboardingStartTracked && step == 0) {
        _onboardingStartTracked = true;
        _analytics.logOnboardingStarted();
        _analytics.logNewUserActivationStep(step: 1, stepName: 'onboarding_started');
        // Track with optimization service for funnel analysis
        _optimization.trackOnboardingStart(userId);
      }

      _data = _data.copyWith(currentStep: step);
      _analytics.logOnboardingStepViewed(step);

      // Track step with optimization service
      if (userId != null) {
        _optimization.trackOnboardingStep(
          userId: userId,
          stepIndex: step,
          stepName: _getStepName(step),
        );
      }

      notifyListeners();
    }
  }

  /// Get step name for analytics
  String _getStepName(int step) {
    switch (step) {
      case 0: return 'welcome';
      case 1: return 'profile_setup';
      case 2: return 'interests';
      case 3: return 'permissions';
      case 4: return 'tutorial';
      case 5: return 'first_room';
      default: return 'unknown';
    }
  }

  void nextStep() {
    if (_data.currentStep < totalSteps - 1) {
      _data = _data.copyWith(currentStep: _data.currentStep + 1);
      _analytics.logOnboardingStepViewed(_data.currentStep);
      notifyListeners();
    }
  }

  void previousStep() {
    if (_data.currentStep > 0) {
      _data = _data.copyWith(currentStep: _data.currentStep - 1);
      notifyListeners();
    }
  }

  // Tutorial Methods
  void setTutorialStep(int step) {
    _data = _data.copyWith(tutorialStep: step);
    notifyListeners();
  }

  void nextTutorialStep() {
    if (_data.tutorialStep < TutorialSteps.steps.length - 1) {
      _data = _data.copyWith(tutorialStep: _data.tutorialStep + 1);
      notifyListeners();
    }
  }

  void previousTutorialStep() {
    if (_data.tutorialStep > 0) {
      _data = _data.copyWith(tutorialStep: _data.tutorialStep - 1);
      notifyListeners();
    }
  }

  // Validation
  bool canProceedFromStep(int step) {
    switch (step) {
      case 0: // Welcome
        return true;
      case 1: // Profile Setup
        return _data.isProfileValid;
      case 2: // Interests
        return _data.hasSelectedInterests;
      case 3: // Permissions
        return true; // Permissions are optional
      case 4: // Tutorial
        return _data.tutorialStep >= TutorialSteps.steps.length - 1;
      case 5: // First Room
        return true;
      default:
        return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset controller
  void reset() {
    _data = const OnboardingData();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
