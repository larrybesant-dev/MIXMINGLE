/// Stub for non-web platforms. Device enumeration is not available.
class MediaDeviceInfo {
  final String deviceId;
  final String label;
  final String kind; // 'audioinput' | 'videoinput'
  const MediaDeviceInfo({
    required this.deviceId,
    required this.label,
    required this.kind,
  });
}

Future<List<MediaDeviceInfo>> enumerateMediaDevices() async => const [];
