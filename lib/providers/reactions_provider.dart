import 'package:flutter_riverpod/flutter_riverpod.dart';

final reactionsProvider = StateProvider<Map<String, int>>((ref) => {});
// Key: reaction type, Value: count
