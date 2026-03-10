/// Automated script to verify analytics event logging and FCM push notification delivery for all web beta testers.
/// Logs results to analytics_verification_report.txt and fcm_verification_report.txt.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

Future<void> main() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final messaging = FirebaseMessaging.instance;

  final analyticsReport = StringBuffer();
  final fcmReport = StringBuffer();

  analyticsReport.writeln('Analytics Event Verification Report');
  analyticsReport.writeln('===================================');
  fcmReport.writeln('FCM Push Notification Verification Report');
  fcmReport.writeln('==========================================');

  // 1. Get all web beta testers (users with platform 'Web' and beta flag)
  final usersSnap = await firestore.collection('users')
      .where('platform', isEqualTo: 'Web')
      .where('beta', isEqualTo: true)
      .get();

  for (final doc in usersSnap.docs) {
    final user = doc.data();
    final uid = doc.id;
    analyticsReport.writeln('User: $uid');
    fcmReport.writeln('User: $uid');

    // 2. Check analytics events
    final eventsSnap = await firestore.collection('analytics_events')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();
    if (eventsSnap.docs.isEmpty) {
      analyticsReport.writeln('  ❌ No analytics events found');
    } else {
      analyticsReport.writeln('  ✅ Recent analytics events:');
      for (final event in eventsSnap.docs) {
        analyticsReport.writeln('    - ${event.data()['event']} at ${event.data()['timestamp']}');
      }
    }

    // 3. Check FCM tokens
    final tokensSnap = await firestore.collection('users').doc(uid).collection('tokens').get();
    if (tokensSnap.docs.isEmpty) {
      fcmReport.writeln('  ❌ No FCM tokens found');
      continue;
    }
    fcmReport.writeln('  ✅ FCM tokens:');
    for (final tokenDoc in tokensSnap.docs) {
      fcmReport.writeln('    - ${tokenDoc.data()['token']}');
    }

    // 4. Check recent notifications
    final notifSnap = await firestore.collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    if (notifSnap.docs.isEmpty) {
      fcmReport.writeln('  ❌ No notifications found');
    } else {
      fcmReport.writeln('  ✅ Recent notifications:');
      for (final notif in notifSnap.docs) {
        fcmReport.writeln('    - ${notif.data()['title']} at ${notif.data()['createdAt']}');
      }
    }
  }

  // Write reports
  await File('analytics_verification_report.txt').writeAsString(analyticsReport.toString());
  await File('fcm_verification_report.txt').writeAsString(fcmReport.toString());

  print('Verification complete. Reports generated.');
}
