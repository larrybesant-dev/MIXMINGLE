import 'package:freezed_annotation/freezed_annotation.dart';
part 'presence_model.freezed.dart';
part 'presence_model.g.dart';

@freezed
abstract class PresenceModel with _$PresenceModel {
  const factory PresenceModel({
    String? id,
    String? userId,
    bool? isOnline,
    DateTime? lastSeen,
  }) = _PresenceModel;

  factory PresenceModel.fromJson(Map<String, dynamic> json) => _$PresenceModelFromJson(json);
}
