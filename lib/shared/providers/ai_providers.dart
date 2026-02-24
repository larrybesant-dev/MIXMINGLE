// lib/providers/ai_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_summary_service.dart';
import '../../services/ai_moderation_service.dart';
import '../models/ai_summary_model.dart';

final aiSummaryServiceProvider = Provider<AISummaryService>((ref) => AISummaryService());
final aiSummaryProvider = Provider.family<AISummaryModel?, String>((ref, roomId) => ref.read(aiSummaryServiceProvider).getSummary(roomId));

final aiModerationServiceProvider = Provider<AIModerationService>((ref) => AIModerationService());
final aiModerationStatusProvider = Provider.family<String, String>((ref, roomId) => ref.read(aiModerationServiceProvider).getModerationStatus(roomId));
