import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

enum AppErrorType {
  network,
  auth,
  permission,
  notFound,
  conflict,
  validation,
  unknown,
}

class AppError {
  final String message;
  final AppErrorType type;
  final String? code;
  final Object? original;

  const AppError({
    required this.message,
    required this.type,
    this.code,
    this.original,
  });

  static AppError from(Object error) {
    // Firebase core exceptions
    if (error is FirebaseException) {
      switch (error.code) {
        case 'network-request-failed':
        case 'unavailable':
          return AppError(
            message: 'Network error. Please check your connection.',
            type: AppErrorType.network,
            code: error.code,
            original: error,
          );
        case 'permission-denied':
          return AppError(
            message: 'Permission denied. Please try again later.',
            type: AppErrorType.permission,
            code: error.code,
            original: error,
          );
        case 'not-found':
          return AppError(
            message: 'Resource not found.',
            type: AppErrorType.notFound,
            code: error.code,
            original: error,
          );
        case 'already-exists':
          return AppError(
            message: 'Resource already exists.',
            type: AppErrorType.conflict,
            code: error.code,
            original: error,
          );
        default:
          return AppError(
            message: error.message ?? 'An unexpected error occurred.',
            type: AppErrorType.unknown,
            code: error.code,
            original: error,
          );
      }
    }

    // Firebase auth exceptions
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return const AppError(
            message: 'Network error. Please try again.',
            type: AppErrorType.network,
          );
        case 'user-not-found':
        case 'user-disabled':
        case 'invalid-credential':
        case 'invalid-email':
        case 'wrong-password':
          return AppError(
            message: error.message ?? 'Authentication error.',
            type: AppErrorType.auth,
            code: error.code,
            original: error,
          );
        default:
          return AppError(
            message: error.message ?? 'Authentication error.',
            type: AppErrorType.auth,
            code: error.code,
            original: error,
          );
      }
    }

    // Platform exceptions (permissions, etc.)
    if (error is PlatformException) {
      if ((error.code).toLowerCase().contains('permission')) {
        return AppError(
          message: error.message ?? 'Permission denied.',
          type: AppErrorType.permission,
          code: error.code,
          original: error,
        );
      }
      return AppError(
        message: error.message ?? 'An unexpected error occurred.',
        type: AppErrorType.unknown,
        code: error.code,
        original: error,
      );
    }

    // Common Dart errors
    if (error is SocketException) {
      return AppError(
        message: 'No internet connection.',
        type: AppErrorType.network,
        original: error,
      );
    }
    if (error is TimeoutException) {
      return AppError(
        message: 'Request timed out. Please try again.',
        type: AppErrorType.network,
        original: error,
      );
    }
    if (error is FormatException) {
      return AppError(
        message: 'Invalid data format.',
        type: AppErrorType.validation,
        original: error,
      );
    }

    return AppError(
      message: 'An unexpected error occurred.',
      type: AppErrorType.unknown,
      original: error,
    );
  }
}


