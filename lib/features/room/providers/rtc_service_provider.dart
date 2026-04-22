import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/rtc_room_service.dart';

/// Holds the live [RtcRoomService] instance for a room session.
///
/// Written by [LiveRoomScreen] after the RTC channel connects.
/// Cleared on screen dispose so child widgets see null immediately.
/// Keyed by roomId so concurrent rooms (future feature) stay isolated.
final rtcServiceProvider =
    StateProvider.family<RtcRoomService?, String>((ref, roomId) => null);
