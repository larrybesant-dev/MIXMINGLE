import 'package:flutter/material.dart';
import 'room_list_page.dart';
import 'room_details_page.dart';
import 'room_page.dart';

Route<dynamic> generateRoomRoutes(RouteSettings settings) {
  switch (settings.name) {
    case '/roomList':
      return MaterialPageRoute(builder: (_) => const RoomListPage());
    case '/roomDetails':
      final roomId = settings.arguments as String;
      return MaterialPageRoute(builder: (_) => RoomDetailsPage(roomId: roomId));
    case '/room':
      final roomId = settings.arguments as String;
      return MaterialPageRoute(builder: (_) => RoomPage(roomId: roomId));
    default:
      return MaterialPageRoute(builder: (_) => const RoomListPage());
  }
}
