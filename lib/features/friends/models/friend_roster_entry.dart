import '../../../models/presence_model.dart';
import '../../../models/user_model.dart';
import 'friendship_model.dart';

class FriendRosterEntry {
  const FriendRosterEntry({
    required this.friendship,
    required this.user,
    required this.presence,
  });

  final FriendshipModel friendship;
  final UserModel user;
  final PresenceModel presence;

  String get friendId => user.id;
  bool get isOnline => presence.online;
  String? get roomId => presence.roomId;
  DateTime? get lastSeen => presence.lastSeen;
}