import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'referral_provider.dart';

class ReferralWidget extends ConsumerWidget {
  final String userId;

  const ReferralWidget({required this.userId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralService = ref.read(referralServiceProvider);
    final emailController = TextEditingController();
    return Column(
      children: [
        Semantics(
          label: 'Referral Email input field',
          child: TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Referral Email'),
          ),
        ),
        Semantics(
          label: 'Generate Referral Code button',
          button: true,
          child: ElevatedButton(
            onPressed: () async {
              final code = await referralService.generateReferralCode(userId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Referral code: $code')),
              );
            },
            child: Text('Generate Referral Code', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 18 : 16)),
          ),
        ),
        Semantics(
          label: 'Redeem Referral button',
          button: true,
          child: ElevatedButton(
            onPressed: () async {
              final success = await referralService.redeemReferral(emailController.text, userId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'Referral redeemed!' : 'Failed to redeem referral')),
              );
            },
            child: Text('Redeem Referral', style: TextStyle(fontSize: MediaQuery.of(context).size.width > 400 ? 18 : 16)),
          ),
        ),
      ],
    );
  }
}
