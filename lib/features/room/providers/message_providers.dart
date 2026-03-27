// Minimal stub for message providers
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messageStreamProvider = Provider.autoDispose.family<dynamic, String>((ref, roomId) => []);
final sendMessageProvider = Provider.autoDispose.family<Future<void> Function(String), String>((ref, roomId) => (String message) async {});
