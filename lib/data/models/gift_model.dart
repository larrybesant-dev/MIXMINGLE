import 'package:freezed_annotation/freezed_annotation.dart';
part 'gift_model.freezed.dart';
part 'gift_model.g.dart';

@freezed
abstract class GiftModel with _$GiftModel {
  const factory GiftModel({
    String? id,
    String? senderId,
    String? receiverId,
    int? amount,
    String? type,
    DateTime? sentAt,
  }) = _GiftModel;

  factory GiftModel.fromJson(Map<String, dynamic> json) => _$GiftModelFromJson(json);
}
