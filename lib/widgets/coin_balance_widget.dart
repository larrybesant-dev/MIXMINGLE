import 'package:flutter/material.dart';

class CoinBalanceWidget extends StatelessWidget {
  final int balance;

  const CoinBalanceWidget({required this.balance, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.monetization_on),
        SizedBox(width: 4),
        Text(balance.toString()),
      ],
    );
  }
}
