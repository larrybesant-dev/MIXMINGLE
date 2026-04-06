import 'package:freezed_annotation/freezed_annotation.dart';
part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String senderId,
    required String roomId,
    required String content,
    required DateTime sentAt,
    /// 'normal' | 'system' | 'announcement'
    @Default('normal') String type,
    /// Optional rich-text markup spans (JSON-encoded list of RichSpan).
    @Default('') String richText,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);
}
