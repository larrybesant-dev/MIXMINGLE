// lib/models/ai_summary_model.dart

class AISummaryModel {
  final String roomId;
  final String summaryText;
  final DateTime generatedAt;

  AISummaryModel({
    required this.roomId,
    required this.summaryText,
    required this.generatedAt,
  });
}
