// Removed: Use lib/models/room_model.dart instead.
import 'package:freezed_annotation/freezed_annotation.dart';
part 'room_model.freezed.dart';
part 'room_model.g.dart';

@freezed
abstract class RoomModel with _$RoomModel {
  const factory RoomModel({
    String? id,
    String? name,
    String? hostId,
    List<String>? participantIds,
    bool? isLive,
    DateTime? createdAt,
  }) = _RoomModel;

  factory RoomModel.fromJson(Map<String, dynamic> json) => _$RoomModelFromJson(json);
}
