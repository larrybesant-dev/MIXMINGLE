// lib/core/qa/qa_scenarios.dart

import 'dart:async';
import 'qa_checks.dart';

class QAScenarios {
  static Future<void> simulateMultiUserJoinLeave({required int cycles, required Function join, required Function leave}) async {
    for (int i = 0; i < cycles; i++) {
      QAChecks.logQAEvent('Cycle $i: join');
      await join();
      await Future.delayed(const Duration(milliseconds: 300));
      QAChecks.logQAEvent('Cycle $i: leave');
      await leave();
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  static Future<void> simulateNetworkDegradation(Function onDegrade) async {
    QAChecks.logQAEvent('Simulating network degradation');
    await onDegrade();
  }

  static Future<void> simulateTokenExpiry(Function onExpire) async {
    QAChecks.logQAEvent('Simulating token expiry');
    await onExpire();
  }

  static Future<void> simulateRapidToggle(Function toggle) async {
    for (int i = 0; i < 10; i++) {
      QAChecks.logQAEvent('Rapid toggle $i');
      await toggle();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
