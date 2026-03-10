/// Represents a remote user in a video channel
class RemoteUser {
  final int uid;
  bool videoEnabled;
  bool audioEnabled;
  final String? name;

  RemoteUser({
    required this.uid,
    this.videoEnabled = true,
    this.audioEnabled = true,
    this.name,
  });

  factory RemoteUser.fromMap(Map<String, dynamic> map) {
    return RemoteUser(
      uid: map['uid'] as int? ?? 0,
      videoEnabled: map['videoEnabled'] as bool? ?? true,
      audioEnabled: map['audioEnabled'] as bool? ?? true,
      name: map['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'videoEnabled': videoEnabled,
      'audioEnabled': audioEnabled,
      'name': name,
    };
  }

  RemoteUser copyWith({
    int? uid,
    bool? videoEnabled,
    bool? audioEnabled,
    String? name,
  }) {
    return RemoteUser(
      uid: uid ?? this.uid,
      videoEnabled: videoEnabled ?? this.videoEnabled,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      name: name ?? this.name,
    );
  }

  @override
  String toString() =>
      'RemoteUser(uid: $uid, video: $videoEnabled, audio: $audioEnabled, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}


