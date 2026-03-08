import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String category;
  final String description;
  final String browser;
  final String os;
  final String screen;
  final String userId;
  final String appVersion;
  final String? screenshotUrl;
  final Timestamp timestamp;

  FeedbackModel({
    required this.category,
    required this.description,
    required this.browser,
    required this.os,
    required this.screen,
    required this.userId,
    required this.appVersion,
    this.screenshotUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'description': description,
      'browser': browser,
      'os': os,
      'screen': screen,
      'userId': userId,
      'appVersion': appVersion,
      'screenshotUrl': screenshotUrl,
      'timestamp': timestamp,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      browser: map['browser'] ?? '',
      os: map['os'] ?? '',
      screen: map['screen'] ?? '',
      userId: map['userId'] ?? '',
      appVersion: map['appVersion'] ?? '',
      screenshotUrl: map['screenshotUrl'],
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
