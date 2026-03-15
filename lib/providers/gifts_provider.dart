import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gift_service.dart';
import '../models/gift_model.dart';

final giftsProvider = StreamProvider<List<Gift>>((ref) {
  return GiftService().streamGifts();
});
