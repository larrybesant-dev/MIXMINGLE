import 'package:flutter/material.dart';
import 'package:mixmingle/widgets/participant_list_sidebar.dart';
import 'package:mixmingle/widgets/raised_hands_panel.dart';
import 'package:mixmingle/widgets/video_tile.dart';
import 'package:mixmingle/widgets/dynamic_video_grid.dart';

/// Adapter functions to help call-sites that expect function-style helpers.
/// Use these where code currently calls a widget name as if it were a function.
Widget buildParticipantListSidebar({List<String>? participantIds, String? roomId}) =>
    ParticipantListSidebar(participantIds: participantIds, roomId: roomId);

Widget buildRaisedHandsPanel({List<String>? raisedByIds, String? roomId}) =>
    RaisedHandsPanel(raisedByIds: raisedByIds, roomId: roomId);

Widget buildVideoTile({String? userId, String? roomId, String? streamId}) =>
    VideoTile(userId: userId, roomId: roomId, streamId: streamId);

Widget buildDynamicVideoGrid({List<String>? userIds, String? roomId}) =>
    DynamicVideoGrid(userIds: userIds, roomId: roomId);
