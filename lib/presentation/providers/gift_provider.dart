
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/gift_model.dart';

final giftListProvider = StateProvider<List<GiftModel>>((ref) => []);
