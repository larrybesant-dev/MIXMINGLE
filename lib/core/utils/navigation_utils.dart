import 'package:flutter/material.dart';
import 'app_logger.dart';

/// Safe navigation utilities with mounted checks
/// Prevents "BuildContext used after disposal" errors
class SafeNavigation {
  /// Safely pop the current route
  static void safePop<T>(BuildContext context, [T? result]) {
    if (!context.mounted) {
      AppLogger.warning('Attempted to pop with unmounted context');
      return;
    }

    try {
      Navigator.of(context).pop(result);
    } catch (e, stackTrace) {
      AppLogger.navigationError('pop', e);
      AppLogger.error('Stack trace', stackTrace);
    }
  }

  /// Safely push a named route
  static Future<T?> safePushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (!context.mounted) {
      AppLogger.warning('Attempted to push $routeName with unmounted context');
      return null;
    }

    try {
      return await Navigator.of(context).pushNamed<T>(
        routeName,
        arguments: arguments,
      );
    } catch (e, stackTrace) {
      AppLogger.navigationError('pushNamed: $routeName', e);
      AppLogger.error('Stack trace', stackTrace);
      return null;
    }
  }

  /// Safely push and replace the current route
  static Future<T?> safePushReplacementNamed<T, TO>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) async {
    if (!context.mounted) {
      AppLogger.warning('Attempted to pushReplacement $routeName with unmounted context');
      return null;
    }

    try {
      return await Navigator.of(context).pushReplacementNamed<T, TO>(
        routeName,
        arguments: arguments,
        result: result,
      );
    } catch (e, stackTrace) {
      AppLogger.navigationError('pushReplacementNamed: $routeName', e);
      AppLogger.error('Stack trace', stackTrace);
      return null;
    }
  }

  /// Safely push and remove all previous routes
  static Future<T?> safePushNamedAndRemoveUntil<T>(
    BuildContext context,
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) async {
    if (!context.mounted) {
      AppLogger.warning('Attempted to pushNamedAndRemoveUntil $routeName with unmounted context');
      return null;
    }

    try {
      return await Navigator.of(context).pushNamedAndRemoveUntil<T>(
        routeName,
        predicate,
        arguments: arguments,
      );
    } catch (e, stackTrace) {
      AppLogger.navigationError('pushNamedAndRemoveUntil: $routeName', e);
      AppLogger.error('Stack trace', stackTrace);
      return null;
    }
  }

  /// Safely push a route
  static Future<T?> safePush<T>(
    BuildContext context,
    Route<T> route,
  ) async {
    if (!context.mounted) {
      AppLogger.warning('Attempted to push route with unmounted context');
      return null;
    }

    try {
      return await Navigator.of(context).push<T>(route);
    } catch (e, stackTrace) {
      AppLogger.navigationError('push', e);
      AppLogger.error('Stack trace', stackTrace);
      return null;
    }
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    if (!context.mounted) {
      return false;
    }
    return Navigator.of(context).canPop();
  }

  /// Safely pop until predicate
  static void safePopUntil(BuildContext context, RoutePredicate predicate) {
    if (!context.mounted) {
      AppLogger.warning('Attempted to popUntil with unmounted context');
      return;
    }

    try {
      Navigator.of(context).popUntil(predicate);
    } catch (e, stackTrace) {
      AppLogger.navigationError('popUntil', e);
      AppLogger.error('Stack trace', stackTrace);
    }
  }
}

/// Extension methods for easier access
extension SafeNavigatorExtension on BuildContext {
  /// Safely pop with mounted check
  void safePop<T>([T? result]) => SafeNavigation.safePop(this, result);

  /// Safely push named route
  Future<T?> safePushNamed<T>(String routeName, {Object? arguments}) =>
      SafeNavigation.safePushNamed<T>(this, routeName, arguments: arguments);

  /// Safely push replacement named route
  Future<T?> safePushReplacementNamed<T, TO>(String routeName, {TO? result, Object? arguments}) =>
      SafeNavigation.safePushReplacementNamed<T, TO>(this, routeName, result: result, arguments: arguments);

  /// Check if can pop safely
  bool get canSafePop => SafeNavigation.canPop(this);
}
