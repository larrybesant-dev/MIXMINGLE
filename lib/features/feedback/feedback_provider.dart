// Riverpod provider for Feedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feedback.dart';

final feedbackProvider = StateProvider<List<FeedbackItem>>((ref) => []);
