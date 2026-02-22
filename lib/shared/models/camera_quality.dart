import 'camera_state.dart';

class CameraQualitySettings {
  final CameraQuality quality;
  final int resolution; // pixels (360, 720, 1080)
  final int fps; // frames per second
  final int bitrate; // kbps
  final int bandwidth; // estimated MB/s

  const CameraQualitySettings._({
    required this.quality,
    required this.resolution,
    required this.fps,
    required this.bitrate,
    required this.bandwidth,
  });

  static const low = CameraQualitySettings._(
    quality: CameraQuality.low,
    resolution: 360,
    fps: 15,
    bitrate: 500,
    bandwidth: 1,
  );

  static const medium = CameraQualitySettings._(
    quality: CameraQuality.medium,
    resolution: 720,
    fps: 24,
    bitrate: 1000,
    bandwidth: 2,
  );

  static const high = CameraQualitySettings._(
    quality: CameraQuality.high,
    resolution: 1080,
    fps: 30,
    bitrate: 2000,
    bandwidth: 4,
  );

  static CameraQualitySettings forQuality(CameraQuality quality) {
    return switch (quality) {
      CameraQuality.low => low,
      CameraQuality.medium => medium,
      CameraQuality.high => high,
    };
  }

  String get displayName {
    switch (quality) {
      case CameraQuality.low:
        return '360p (Low)';
      case CameraQuality.medium:
        return '720p (Medium)';
      case CameraQuality.high:
        return '1080p (High)';
    }
  }

  @override
  String toString() => 'CameraQualitySettings($displayName, ${resolution}p, ${bitrate}kbps)';
}


