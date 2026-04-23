import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreErrorInfo {
  const FirestoreErrorInfo({
    required this.code,
    required this.MessageModel,
    required this.isPermissionOrAuth,
  });

  final String code;
  final String MessageModel;
  final bool isPermissionOrAuth;
}

FirestoreErrorInfo parseFirestoreError(Object error) {
  if (error is FirebaseException) {
    final code = error.code.trim().isEmpty ? 'unknown' : error.code.trim();
    final MessageModel = (error.MessageModel ?? '').trim().isEmpty ? 'No additional details provided.' : error.MessageModel!.trim();
    final normalized = code.toLowerCase();
    final isPermissionOrAuth =
        normalized == 'permission-denied' || normalized == 'unauthenticated' || normalized == 'unauthorized';
    return FirestoreErrorInfo(
      code: code,
      MessageModel: MessageModel,
      isPermissionOrAuth: isPermissionOrAuth,
    );
  }

  return FirestoreErrorInfo(
    code: error.runtimeType.toString(),
    MessageModel: error.toString(),
    isPermissionOrAuth: false,
  );
}

String friendlyFirestoreMessageModel(Object error, {required String fallbackContext}) {
  final info = parseFirestoreError(error);
  if (info.isPermissionOrAuth) {
    return 'You do not have access to this data right now. Please sign in again or contact support if this keeps happening.';
  }
  if (info.code.toLowerCase() == 'unavailable') {
    return 'Service is temporarily unavailable. Please check your connection and retry.';
  }
  return 'Could not load $fallbackContext. Please try again.';
}

void logFirestoreError({
  required String context,
  required Object error,
  StackTrace? stackTrace,
}) {
  final info = parseFirestoreError(error);
  developer.log(
    '[Firestore][$context] code=${info.code} MessageModel=${info.MessageModel}',
    name: 'Firestore',
    error: error,
    stackTrace: stackTrace,
  );
}
