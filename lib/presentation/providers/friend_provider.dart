import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/friend_model.dart';

final friendListProvider = StateProvider<List<FriendModel>>((ref) => []);
