import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../presentation/providers/coin_transaction_provider.dart';
// Unused import removed: '../services/payment_api.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final transactionsAsync = ref.watch(coinTransactionStreamProvider(userId));
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet.'));
          }
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isSent = tx.senderId == userId;
              final isReceived = tx.receiverId == userId;
              final color = isSent
                  ? Colors.red
                  : isReceived
                      ? Colors.green
                      : Colors.grey;
              final sign = isSent ? '-' : '+';
              return ListTile(
                leading: Icon(
                  isSent ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                ),
                title: Text(
                  '$sign${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'From: ${tx.senderId}\nTo: ${tx.receiverId}\nStatus: ${tx.status}',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Text(
                  _formatTimestamp(tx.timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final date = timestamp.toLocal();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}\n${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
