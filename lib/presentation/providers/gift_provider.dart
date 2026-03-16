import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gift_model.dart';

final giftListProvider = StateProvider<List<GiftModel>>((ref) => []);
