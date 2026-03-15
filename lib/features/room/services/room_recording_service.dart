import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recording state enum
enum RecordingState { idle, recording, paused, completed }

/// Recording information model
class RecordingInfo {
  final String id;
  final String roomId;
  final String recordedBy;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final String filePath;
  final int fileSize; // in bytes
  final RecordingState state;
  final bool isPublic;

  RecordingInfo({
    required this.id,
    required this.roomId,
    required this.recordedBy,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.filePath,
    required this.fileSize,
    required this.state,
    required this.isPublic,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'recordedBy': recordedBy,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inSeconds,
      'filePath': filePath,
      'fileSize': fileSize,
      'state': state.toString(),
      'isPublic': isPublic,
    };
  }
}

/// Room Recording Service
/// Handles recording functionality for voice rooms
class RoomRecordingService {
  RecordingInfo? _currentRecording;
  DateTime? _recordingStartTime;

  RecordingInfo? get currentRecording => _currentRecording;
  bool get isRecording => _currentRecording?.state == RecordingState.recording;

  /// Start recording a room
  Future<RecordingInfo> startRecording({
    required String roomId,
    required String userId,
  }) async {
    _recordingStartTime = DateTime.now();
    final recordingId =
        'recording_${roomId}_${_recordingStartTime!.millisecondsSinceEpoch}';

    _currentRecording = RecordingInfo(
      id: recordingId,
      roomId: roomId,
      recordedBy: userId,
      startTime: _recordingStartTime!,
      duration: Duration.zero,
      filePath: 'recordings/$recordingId.m4a',
      fileSize: 0,
      state: RecordingState.recording,
      isPublic: false,
    );

    return _currentRecording!;
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (_currentRecording != null &&
        _currentRecording!.state == RecordingState.recording) {
      _currentRecording = _currentRecording!.copyWith(
        state: RecordingState.paused,
      );
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (_currentRecording != null &&
        _currentRecording!.state == RecordingState.paused) {
      _currentRecording = _currentRecording!.copyWith(
        state: RecordingState.recording,
      );
    }
  }

  /// Stop recording
  Future<RecordingInfo> stopRecording({
    required int finalFileSize,
  }) async {
    if (_currentRecording == null || _recordingStartTime == null) {
      throw Exception('No active recording');
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(_recordingStartTime!);

    _currentRecording = _currentRecording!.copyWith(
      endTime: endTime,
      duration: duration,
      fileSize: finalFileSize,
      state: RecordingState.completed,
    );

    return _currentRecording!;
  }

  /// Set recording as public
  void setRecordingPublic(bool isPublic) {
    if (_currentRecording != null) {
      _currentRecording = _currentRecording!.copyWith(
        isPublic: isPublic,
      );
    }
  }

  /// Get recording duration
  Duration getRecordingDuration() {
    if (_recordingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Clear current recording
  void clearRecording() {
    _currentRecording = null;
    _recordingStartTime = null;
  }
}

/// Extension for copyWith method
extension RecordingInfoCopyWith on RecordingInfo {
  RecordingInfo copyWith({
    String? id,
    String? roomId,
    String? recordedBy,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? filePath,
    int? fileSize,
    RecordingState? state,
    bool? isPublic,
  }) {
    return RecordingInfo(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      recordedBy: recordedBy ?? this.recordedBy,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      state: state ?? this.state,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

/// Provider for Room Recording Service
final roomRecordingServiceProvider =
    NotifierProvider<RoomRecordingServiceNotifier, RecordingInfo?>(
  RoomRecordingServiceNotifier.new,
);

/// Notifier for managing recording state
class RoomRecordingServiceNotifier extends Notifier<RecordingInfo?> {
  final _service = RoomRecordingService();

  @override
  RecordingInfo? build() => null;

  Future<void> startRecording({
    required String roomId,
    required String userId,
  }) async {
    final recording = await _service.startRecording(
      roomId: roomId,
      userId: userId,
    );
    state = recording;
  }

  Future<void> pauseRecording() async {
    await _service.pauseRecording();
    state = _service.currentRecording;
  }

  Future<void> resumeRecording() async {
    await _service.resumeRecording();
    state = _service.currentRecording;
  }

  Future<void> stopRecording({required int finalFileSize}) async {
    final recording = await _service.stopRecording(
      finalFileSize: finalFileSize,
    );
    state = recording;
  }

  void setRecordingPublic(bool isPublic) {
    _service.setRecordingPublic(isPublic);
    state = _service.currentRecording;
  }

  Duration getRecordingDuration() {
    return _service.getRecordingDuration();
  }

  void clearRecording() {
    _service.clearRecording();
    state = null;
  }
}
