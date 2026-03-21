import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/payment_api.dart';

class PaymentsDemoScreen extends StatelessWidget {
  const PaymentsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments Demo')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              child: const Text('MixVy Navigation', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(title: const Text('Home Feed'), onTap: () => Navigator.pushNamed(context, '/home')),
            ListTile(title: const Text('Chats'), onTap: () => Navigator.pushNamed(context, '/chats')),
            ListTile(title: const Text('Friends'), onTap: () => Navigator.pushNamed(context, '/friends')),
            ListTile(title: const Text('Profile'), onTap: () => Navigator.pushNamed(context, '/profile')),
            ListTile(title: const Text('Payments'), onTap: () => Navigator.pushNamed(context, '/payments')),
            ListTile(title: const Text('Notifications'), onTap: () => Navigator.pushNamed(context, '/notifications')),
            ListTile(title: const Text('Live Room'), onTap: () => Navigator.pushNamed(context, '/live-room')),
            ListTile(title: const Text('Settings'), onTap: () => Navigator.pushNamed(context, '/settings')),
            ListTile(title: const Text('Moderation'), onTap: () => Navigator.pushNamed(context, '/moderation')),
            ListTile(title: const Text('Search'), onTap: () => Navigator.pushNamed(context, '/search')),
            ListTile(title: const Text('Invite Friends'), onTap: () => Navigator.pushNamed(context, '/invite-friends')),
          ],
        ),
      ),
        body: Column(
          children: [
            ElevatedButton(
              child: const Text('Start Payment'),
              onPressed: () async {
                // Stripe payment flow
                final amount = 1000; // Example amount in cents
                final clientSecret = await PaymentApi.createIntent(
                  amount: amount.toDouble(),
                  currency: 'usd',
                  recipientId: 'demo',
                );
                await Stripe.instance.initPaymentSheet(
                  paymentSheetParameters: SetupPaymentSheetParameters(
                    paymentIntentClientSecret: clientSecret,
                    merchantDisplayName: 'MixVy',
                  ),
                );
                await Stripe.instance.presentPaymentSheet();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment successful')),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('payments').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = (snapshot.data as QuerySnapshot<Map<String, dynamic>>).docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      return ListTile(
                        title: Text('Payment ${data['amount'] ?? ''}'),
                        subtitle: Text('Status: ${data['status'] ?? ''}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}