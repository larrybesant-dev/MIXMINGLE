import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/features/room/widgets/live_room_media_action_strip.dart';

void main() {
  group('shouldTrackMicLevel', () {
    test('returns true only when call is ready and mic is live', () {
      expect(
        shouldTrackMicLevel(
          isCallReady: true,
          hasRtcService: true,
          isMicMuted: false,
        ),
        isTrue,
      );

      expect(
        shouldTrackMicLevel(
          isCallReady: false,
          hasRtcService: true,
          isMicMuted: false,
        ),
        isFalse,
      );

      expect(
        shouldTrackMicLevel(
          isCallReady: true,
          hasRtcService: false,
          isMicMuted: false,
        ),
        isFalse,
      );

      expect(
        shouldTrackMicLevel(
          isCallReady: true,
          hasRtcService: true,
          isMicMuted: true,
        ),
        isFalse,
      );
    });
  });
}
