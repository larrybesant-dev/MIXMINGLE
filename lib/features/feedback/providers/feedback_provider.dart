import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/feedback_model.dart';

final feedbackControllerProvider = NotifierProvider<FeedbackNotifier, FeedbackState>(FeedbackNotifier.new);


class FeedbackState {
  final bool isLoading;
  final String? screenshotUrl;
  final String? error;

  const FeedbackState({
    this.isLoading = false,
    this.screenshotUrl,
    this.error,
  });

  FeedbackState copyWith({
    bool? isLoading,
    String? screenshotUrl,
    String? error,
  }) {
    return FeedbackState(
      isLoading: isLoading ?? this.isLoading,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      error: error ?? this.error,
    );
  }
}

class FeedbackNotifier extends Notifier<FeedbackState> {
  @override
  FeedbackState build() => const FeedbackState();

  Future<String?> uploadScreenshot({required String userId, required String timestamp, required Uint8List bytes}) async {
    try {
      final ref = FirebaseStorage.instance
          .ref('feedback_screenshots/$userId/$timestamp.png');
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      state = state.copyWith(screenshotUrl: url, error: null);
      return url;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> submitFeedback({
    required FeedbackModel feedback,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .add(feedback.toMap());
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
