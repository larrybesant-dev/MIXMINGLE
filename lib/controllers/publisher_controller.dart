import '../models/publisher_state_model.dart';

class PublisherController {
  PublisherStateModel publisherState;

  PublisherController(this.publisherState);

  // Start publishing
  Future<void> startPublishing() async {
    publisherState = publisherState.copyWith(status: PublisherStatus.publishing);
    // Integrate with Agora SDK here
    // e.g., await agoraEngine.startPublishing();
  }

  // Stop publishing
  Future<void> stopPublishing() async {
    publisherState = publisherState.copyWith(status: PublisherStatus.idle);
    // e.g., await agoraEngine.stopPublishing();
  }

  // Pause publishing
  Future<void> pausePublishing() async {
    publisherState = publisherState.copyWith(status: PublisherStatus.paused);
    // e.g., await agoraEngine.pausePublishing();
  }

  // Toggle audio
  void toggleAudio() {
    publisherState = publisherState.copyWith(
      isAudioEnabled: !publisherState.isAudioEnabled,
    );
    // e.g., agoraEngine.muteLocalAudioStream(!publisherState.isAudioEnabled);
  }

  // Toggle video
  void toggleVideo() {
    publisherState = publisherState.copyWith(
      isVideoEnabled: !publisherState.isVideoEnabled,
    );
    // e.g., agoraEngine.muteLocalVideoStream(!publisherState.isVideoEnabled);
  }

  // Adjust bitrate
  void setBitrate(int newBitrate) {
    publisherState = publisherState.copyWith(bitrate: newBitrate);
    // e.g., agoraEngine.setVideoEncoderConfiguration(bitrate: newBitrate);
  }

  // Adjust resolution
  void setResolution(double newResolution) {
    publisherState = publisherState.copyWith(resolution: newResolution);
    // e.g., agoraEngine.setVideoEncoderConfiguration(resolution: newResolution);
  }

  // Adjust frame rate
  void setFrameRate(int newFrameRate) {
    publisherState = publisherState.copyWith(frameRate: newFrameRate);
    // e.g., agoraEngine.setVideoEncoderConfiguration(frameRate: newFrameRate);
  }

  // Handle errors
  void onError(String error) {
    publisherState = publisherState.copyWith(
      status: PublisherStatus.error,
      errorMessage: error,
    );
  }

  // Auto-adjust for bandwidth
  void adjustForBandwidth(bool isLowBandwidth) {
    if (isLowBandwidth) {
      setResolution(0.5);
      setFrameRate(15);
      setBitrate(256);
    } else {
      setResolution(1.0);
      setFrameRate(30);
      setBitrate(512);
    }
  }

  // Getters
  bool get isPublishing => publisherState.status == PublisherStatus.publishing;
  bool get isPaused => publisherState.status == PublisherStatus.paused;
  bool get hasError => publisherState.status == PublisherStatus.error;
}
