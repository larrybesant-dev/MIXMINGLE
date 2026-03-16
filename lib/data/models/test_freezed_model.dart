import 'package:freezed_annotation/freezed_annotation.dart';
part 'test_freezed_model.freezed.dart';
part 'test_freezed_model.g.dart';

@freezed
abstract class TestFreezedModel with _$TestFreezedModel {
  const factory TestFreezedModel({
    String? id,
    String? name,
  }) = _TestFreezedModel;

  factory TestFreezedModel.fromJson(Map<String, dynamic> json) => _$TestFreezedModelFromJson(json);
}
