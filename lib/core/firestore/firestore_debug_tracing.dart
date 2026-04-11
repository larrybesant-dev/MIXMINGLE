import 'dart:async';

import '../telemetry/app_telemetry.dart';

typedef FirestoreItemCount<T> = int Function(T value);

Stream<T> traceFirestoreStream<T>({
  required String key,
  required String query,
  required Stream<T> stream,
  required FirestoreItemCount<T> itemCount,
  String? roomId,
  String? userId,
}) {
  return Stream<T>.multi((controller) {
    AppTelemetry.listenerStarted(
      key: key,
      query: query,
      roomId: roomId,
      userId: userId,
    );

    final subscription = stream.listen(
      (value) {
        AppTelemetry.recordFirestoreSnapshot(
          key: key,
          query: query,
          count: itemCount(value),
          roomId: roomId,
          userId: userId,
        );
        controller.add(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        AppTelemetry.recordFirestoreError(
          key: key,
          query: query,
          error: error,
          stackTrace: stackTrace,
          roomId: roomId,
          userId: userId,
        );
        controller.addError(error, stackTrace);
      },
      onDone: controller.close,
    );

    controller.onCancel = () async {
      await subscription.cancel();
      AppTelemetry.listenerStopped(
        key: key,
        query: query,
        roomId: roomId,
        userId: userId,
      );
    };
  });
}

Future<T> traceFirestoreRead<T>({
  required String path,
  required String operation,
  required Future<T> Function() action,
  String? roomId,
  String? userId,
}) async {
  AppTelemetry.recordFirestoreRead(
    path: path,
    operation: operation,
    roomId: roomId,
    userId: userId,
  );
  try {
    return await action();
  } catch (error, stackTrace) {
    AppTelemetry.logAction(
      level: 'error',
      domain: 'firestore',
      action: operation,
      message: 'Firestore read failed.',
      roomId: roomId,
      userId: userId,
      result: 'error',
      metadata: <String, Object?>{'path': path},
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

Future<T> traceFirestoreWrite<T>({
  required String path,
  required String operation,
  required Future<T> Function() action,
  String? roomId,
  String? userId,
  Map<String, Object?> metadata = const <String, Object?>{},
}) async {
  AppTelemetry.recordFirestoreWrite(
    path: path,
    operation: operation,
    roomId: roomId,
    userId: userId,
    metadata: metadata,
  );
  try {
    return await action();
  } catch (error, stackTrace) {
    AppTelemetry.logAction(
      level: 'error',
      domain: 'firestore',
      action: operation,
      message: 'Firestore write failed.',
      roomId: roomId,
      userId: userId,
      result: 'error',
      metadata: <String, Object?>{'path': path, ...metadata},
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}