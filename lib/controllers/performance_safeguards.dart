import '../shared/models/room_video_state_model.dart';
import '../features/video_room/controllers/publisher_controller.dart';

class PerformanceSafeguards {
  static const int maxPublishers = 12;
  static const int lowBandwidthBitrate = 256;
  static const int normalBitrate = 512;
  static const double lowBandwidthResolution = 0.5;
  static const double normalResolution = 1.0;
  static const int lowBandwidthFrameRate = 15;
  static const int normalFrameRate = 30;

  // Publisher limit enforcement
  static bool canAddPublisher(RoomVideoStateModel roomState) {
    final activeCount = roomState.activePublishers;
    return activeCount < maxPublishers;
  }

  static void enforcePublisherLimit(List<PublisherController> publishers) {
    final activePublishers = publishers
        .where((p) => p.isPublishing)
        .toList();

    if (activePublishers.length > maxPublishers) {
      // Disable oldest publishers
      activePublishers
          .sort((a, b) => a.publisherState.lastPublishedAt!
              .compareTo(b.publisherState.lastPublishedAt!));

      for (int i = maxPublishers; i < activePublishers.length; i++) {
        activePublishers[i].stopPublishing();
      }
    }
  }

  // Auto-mute on join
  static void applyAutoMute(PublisherController publisher, bool autoMute) {
    if (autoMute && publisher.publisherState.isAudioEnabled) {
      publisher.toggleAudio();
    }
  }

  // Bandwidth-based adjustments
  static void adjustForBandwidth(
    PublisherController publisher,
    bool isLowBandwidth,
  ) {
    if (isLowBandwidth) {
      publisher.setBitrate(lowBandwidthBitrate);
      publisher.setResolution(lowBandwidthResolution);
      publisher.setFrameRate(lowBandwidthFrameRate);
    } else {
      publisher.setBitrate(normalBitrate);
      publisher.setResolution(normalResolution);
      publisher.setFrameRate(normalFrameRate);
    }
  }

  // Resolution throttling
  static void throttleResolution(
    List<PublisherController> publishers,
    int maxActiveHighRes,
  ) {
    final highResPublishers = publishers
        .where((p) => p.publisherState.resolution >= 1.0 && p.isPublishing)
        .toList();

    if (highResPublishers.length > maxActiveHighRes) {
      // Throttle excess to low res
      for (int i = maxActiveHighRes; i < highResPublishers.length; i++) {
        highResPublishers[i].setResolution(lowBandwidthResolution);
      }
    }
  }

  // Frame rate throttling
  static void throttleFrameRate(
    List<PublisherController> publishers,
    int maxActiveHighFps,
  ) {
    final highFpsPublishers = publishers
        .where((p) => p.publisherState.frameRate >= 30 && p.isPublishing)
        .toList();

    if (highFpsPublishers.length > maxActiveHighFps) {
      // Throttle excess to low fps
      for (int i = maxActiveHighFps; i < highFpsPublishers.length; i++) {
        highFpsPublishers[i].setFrameRate(lowBandwidthFrameRate);
      }
    }
  }

  // Auto-disable video on low bandwidth
  static void autoDisableVideoOnLowBandwidth(
    PublisherController publisher,
    bool isLowBandwidth,
    bool autoDisable,
  ) {
    if (isLowBandwidth && autoDisable && publisher.publisherState.isVideoEnabled) {
      publisher.toggleVideo();
    }
  }

  // Monitor system resources
  static Future<bool> detectLowBandwidth() async {
    // Placeholder for bandwidth detection
    // In real implementation, use network monitoring
    // For now, return false
    return false;
  }

  static Future<bool> detectHighCpuUsage() async {
    // Placeholder for CPU monitoring
    // In real implementation, use system metrics
    return false;
  }

  // Apply all safeguards
  static Future<void> applyAllSafeguards(
    RoomVideoStateModel roomState,
    List<PublisherController> publishers,
  ) async {
    final isLowBandwidth = await detectLowBandwidth();
    final isHighCpu = await detectHighCpuUsage();

    enforcePublisherLimit(publishers);

    for (final publisher in publishers) {
      applyAutoMute(publisher, roomState.autoMuteOnJoin);
      adjustForBandwidth(publisher, isLowBandwidth);
      autoDisableVideoOnLowBandwidth(
        publisher,
        isLowBandwidth,
        roomState.autoDisableVideoOnLowBandwidth,
      );
    }

    if (isHighCpu || isLowBandwidth) {
      throttleResolution(publishers, 4); // Allow 4 high-res streams
      throttleFrameRate(publishers, 6); // Allow 6 high-fps streams
    }
  }
}

