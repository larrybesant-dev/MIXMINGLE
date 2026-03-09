import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  final usersRef = firestore.collection('users');
  final now = DateTime.now();
  final today = DateFormat('yyyy-MM-dd').format(now);
  final log = StringBuffer();
  int verified = 0, fixed = 0;

  final users = await usersRef.get();
  for (final doc in users.docs) {
    final data = doc.data();
    final updates = <String, dynamic>{};
    bool changed = false;
    // Required fields
    if (!data.containsKey('uid') || data['uid'] != doc.id) {
      updates['uid'] = doc.id;
      changed = true;
    }
    if (!data.containsKey('username')) {
      updates['username'] = '';
      changed = true;
    }
    if (!data.containsKey('email')) {
      updates['email'] = '';
      changed = true;
    }
    if (!data.containsKey('createdAt')) {
      updates['createdAt'] = FieldValue.serverTimestamp();
      changed = true;
    }
    if (!data.containsKey('onboardingComplete')) {
      updates['onboardingComplete'] = false;
      changed = true;
    }
    if (!data.containsKey('ageVerified')) {
      updates['ageVerified'] = false;
      changed = true;
    }
    if (changed) {
      await usersRef.doc(doc.id).update(updates);
      log.writeln('Fixed user ${doc.id}: $updates');
      fixed++;
    } else {
      log.writeln('Verified user ${doc.id}: OK');
      verified++;
    }
  }
  final report = 'Date: $today\nUsers verified: $verified\nUsers fixed: $fixed\n\n${log.toString()}';
  await firestore.collection('beta_reports').doc(today).set({'report': report, 'timestamp': FieldValue.serverTimestamp()});
  print(report);
}
