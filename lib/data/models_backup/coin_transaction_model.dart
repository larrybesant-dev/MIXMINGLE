import 'package:freezed_annotation/freezed_annotation.dart';
part 'coin_transaction_model.freezed.dart';
part 'coin_transaction_model.g.dart';

@freezed
abstract class CoinTransactionModel with _$CoinTransactionModel {
	const factory CoinTransactionModel({
		String? id,
		String? userId,
		int? amount,
		String? type,
		DateTime? createdAt,
	}) = _CoinTransactionModel;

	factory CoinTransactionModel.fromJson(Map<String, dynamic> json) => _$CoinTransactionModelFromJson(json);
}
