import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEnabled   = 'after_dark_enabled';
const _kPinStored = 'after_dark_pin';
const _kDobYes    = 'after_dark_dob_confirmed';

// ── Session state — cleared when app is closed ───────────────────────────────
final afterDarkSessionProvider = StateProvider<bool>((ref) => false);

// ── Persistent enable flag — reads from SharedPreferences ────────────────────
final afterDarkEnabledProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kEnabled) ?? false;
});

// ── Controller ────────────────────────────────────────────────────────────────
final afterDarkControllerProvider = Provider<AfterDarkController>((ref) {
  return AfterDarkController(ref);
});

class AfterDarkController {
  AfterDarkController(this._ref);
  final Ref _ref;

  // ── Activation (called after age gate + PIN setup) ────────────────────────
  Future<void> enable(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, true);
    await prefs.setBool(_kDobYes, true);
    await prefs.setString(_kPinStored, _obfuscate(pin));
    // Persist consent on Firestore user doc
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'adultModeEnabled': true,
        'adultConsentAccepted': true,
        'adultModeEnabledAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    _ref.invalidate(afterDarkEnabledProvider);
    _ref.read(afterDarkSessionProvider.notifier).state = true;
  }

  // ── Verify PIN → activate session ─────────────────────────────────────────
  Future<bool> unlock(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kPinStored);
    if (stored == null) return false;
    final valid = _obfuscate(pin) == stored;
    if (valid) {
      _ref.read(afterDarkSessionProvider.notifier).state = true;
    }
    return valid;
  }

  // ── Lock session (stays enabled but requires PIN again) ───────────────────
  void lock() {
    _ref.read(afterDarkSessionProvider.notifier).state = false;
  }

  // ── Full disable ──────────────────────────────────────────────────────────
  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEnabled);
    await prefs.remove(_kPinStored);
    await prefs.remove(_kDobYes);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'adultModeEnabled': false,
      }, SetOptions(merge: true));
    }
    _ref.invalidate(afterDarkEnabledProvider);
    _ref.read(afterDarkSessionProvider.notifier).state = false;
  }

  // ── Simple obfuscation (prevents plain-text PIN in prefs) ────────────────
  static String _obfuscate(String pin) {
    const salt = 'mx_afterdark_2026';
    final bytes = utf8.encode(pin + salt);
    return base64Url.encode(bytes);
  }
}
