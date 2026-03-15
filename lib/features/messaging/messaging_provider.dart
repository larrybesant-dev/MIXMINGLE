// Riverpod provider for Messaging
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'message.dart';

final messagingProvider = StateProvider<List<Message>>((ref) => []);
