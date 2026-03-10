import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentRoomIdProvider = StateProvider<String?>((ref) => null);

final roomParticipantsProvider = StateProvider<List<String>>((ref) => []);
