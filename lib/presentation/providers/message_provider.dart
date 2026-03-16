import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/message_model.dart';

final messageListProvider = StateProvider<List<MessageModel>>((ref) => []);
