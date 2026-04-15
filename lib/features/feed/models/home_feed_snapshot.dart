import 'package:mixvy/models/room_model.dart';
import 'package:mixvy/models/social_activity_model.dart';
import 'package:mixvy/models/user_model.dart';

class HomeFeedSnapshot {
  const HomeFeedSnapshot({
    this.activities = const <SocialActivity>[],
    this.liveRooms = const <RoomModel>[],
    this.suggestedUsers = const <UserModel>[],
  });

  final List<SocialActivity> activities;
  final List<RoomModel> liveRooms;
  final List<UserModel> suggestedUsers;

  String get headline {
    if (activities.isNotEmpty) {
      return 'Your people are moving right now';
    }
    if (liveRooms.isNotEmpty) {
      return '${liveRooms.length} rooms are live right now';
    }
    if (suggestedUsers.isNotEmpty) {
      return 'Fresh connections are waiting';
    }
    return 'Your circle is quiet right now.';
  }

  String get subheadline {
    if (activities.isNotEmpty) {
      return 'Jump back in while the room energy is still warm.';
    }
    if (liveRooms.isNotEmpty) {
      return 'Join a live room or discover someone new tonight.';
    }
    if (suggestedUsers.isNotEmpty) {
      return 'Explore new profiles and build your circle.';
    }
    return 'Start the vibe and give people something to join.';
  }
}
