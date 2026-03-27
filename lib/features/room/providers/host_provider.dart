import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Host {
  final String userId;
  Host(this.userId);
}

final hostProvider = StreamProvider.autoDispose.family<Host?, String>((ref, roomId) async* {
  // TODO: Replace with actual Firestore logic to get the host
  yield null;
});
