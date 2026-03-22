import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/message_model.dart';

final messageListProvider = StateProvider<List<MessageModel>>(() => []);
