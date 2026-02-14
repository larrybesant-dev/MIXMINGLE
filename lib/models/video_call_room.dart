import 'package:cloud_firestore/cloud_firestore.dart';

enum VideoCallStatus {
  waiting,
  connecting,
  connected,
  ended,
}

class VideoCallRoom {
  final String id;
  final String callerId;
  final String receiverId;
  final VideoCallStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? roomId;
  final Map<String, dynamic> iceCandidates;
  final Map<String, dynamic> offers;
  final Map<String, dynamic> answers;

  VideoCallRoom({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.roomId,
    required this.iceCandidates,
    required this.offers,
    required this.answers,
  });

  factory VideoCallRoom.fromMap(Map<String, dynamic> map) {
    return VideoCallRoom(
      id: map['id'] as String,
      callerId: map['callerId'] as String,
      receiverId: map['receiverId'] as String,
      status: VideoCallStatus.values.firstWhere(
        (e) => e.toString() == 'VideoCallStatus.${map['status']}',
      ),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      roomId: map['roomId'] as String?,
      iceCandidates: map['iceCandidates'] as Map<String, dynamic>? ?? {},
      offers: map['offers'] as Map<String, dynamic>? ?? {},
      answers: map['answers'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callerId': callerId,
      'receiverId': receiverId,
      'status': status.toString().split('.').last,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'roomId': roomId,
      'iceCandidates': iceCandidates,
      'offers': offers,
      'answers': answers,
    };
  }
}
