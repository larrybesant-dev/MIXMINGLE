import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'models.dart';

class StripePurchaseService {
  final FirebaseFirestore firestore;

  StripePurchaseService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  // Start Stripe checkout session (client-side)
  // Method removed due to undefined Pack type.

  // Handle Stripe webhook (backend)
  // This is handled in Cloud Functions, not client-side.
}
