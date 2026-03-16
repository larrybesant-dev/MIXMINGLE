import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get users => _firestore.collection('users');
  CollectionReference get rooms => _firestore.collection('rooms');
  CollectionReference get events => _firestore.collection('events');
  CollectionReference get messages => _firestore.collection('messages');
  CollectionReference get transactions => _firestore.collection('transactions');
}
