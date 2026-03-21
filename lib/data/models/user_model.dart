import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import 'package:flutter/material.dart'; // For Widget, VoidCallback
// Plain Dart UserModel for Firestore compatibility. Freezed removed.
class UserModel {
  final String? id;
  final String? email;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final List<String>? interests;
  final DateTime? createdAt;

  UserModel({
    this.id,
    this.email,
    this.username,
    this.avatarUrl,
    this.bio,
    this.interests,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      interests: (json['interests'] as List?)?.map((e) => e as String).toList(),
      createdAt: json['createdAt'] == null
          ? null
          : (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : (json['createdAt'] is String
                  ? DateTime.tryParse(json['createdAt'])
                  : (json['createdAt'] is Timestamp
                      ? (json['createdAt'] as Timestamp).toDate()
                      : null))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'interests': interests,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
