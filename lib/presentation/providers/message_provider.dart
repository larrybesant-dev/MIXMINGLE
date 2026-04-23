
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/messagipackage:mixvy/features/messaging/models/message_model.dart';

final MessageModelListProvider = StateProvider<List<MessageModel>>((ref) => []);
