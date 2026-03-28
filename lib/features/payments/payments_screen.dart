import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import 'stripe_web_payment_widget.dart';
import 'payments_controller.dart';
import 'payment_recipient_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/coin_transaction_provider.dart';
import '../../presentation/providers/wallet_provider.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController(text: '10');
  UserModel? _selectedRecipient;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool requestOnly}) async {
    final recipientId = _selectedRecipient?.id;
    final amount = double.tryParse(_amountController.text.trim());

    if (recipientId == null || amount == null || amount <= 0 || amount > 100000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a recipient and enter a valid amount (max 100000).')),
      );
      return;
    }

    final controller = ref.read(paymentControllerProvider.notifier);
    if (requestOnly) {
      await controller.requestCoins(targetId: recipientId, amount: amount);
    } else {
      await controller.sendCoins(receiverId: recipientId, amount: amount);
    }

    if (!mounted) {
      return;
    }

    final state = ref.read(paymentControllerProvider);
    final message = state.error ?? state.successMessage;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _selectRecipient(UserModel recipient) {
    final safeName = recipient.username.isNotEmpty ? recipient.username : 'MixVy user';
    setState(() {
      _selectedRecipient = recipient;
      _recipientController.text = safeName;
      _recipientController.selection = TextSelection.collapsed(
        offset: _recipientController.text.length,
      );
    });
  }

  void _clearRecipient() {
    setState(() {
      _selectedRecipient = null;
      _recipientController.clear();
    });
  }

  void _setQuickAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
      _amountController.selection = TextSelection.collapsed(offset: _amountController.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payments')),
        body: const SafeArea(child: StripeWebPaymentWidget()),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final paymentState = ref.watch(paymentControllerProvider);
    final walletAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(
      coinTransactionStreamProvider(user?.uid ?? ''),
    );
    final recipientsAsync = ref.watch(
      paymentRecipientSearchProvider(
        _selectedRecipient == null ? _recipientController.text : '',
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined),
                  SizedBox(width: 10),
                  Expanded(child: Text('Send or request coins with trusted members only. Double-check recipient before confirming.')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Wallet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          walletAsync.when(
            data: (balance) => Text('Current balance: ${balance.toStringAsFixed(2)}'),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Balance unavailable: $e'),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _recipientController,
            onChanged: (value) {
              if (_selectedRecipient == null) {
                setState(() {});
                return;
              }

              final selectedLabel = _selectedRecipient!.username.isNotEmpty
                  ? _selectedRecipient!.username
                  : 'MixVy user';
              if (value != selectedLabel) {
                setState(() {
                  _selectedRecipient = null;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Search recipient',
              hintText: 'Enter a username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedRecipient != null)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    _selectedRecipient!.username.isNotEmpty
                        ? _selectedRecipient!.username[0].toUpperCase()
                        : 'M',
                  ),
                ),
                title: Text(
                  _selectedRecipient!.username.isNotEmpty
                      ? _selectedRecipient!.username
                      : 'MixVy user',
                ),
                subtitle: const Text('Recipient selected'),
                trailing: IconButton(
                  onPressed: _clearRecipient,
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear recipient',
                ),
              ),
            )
          else
            recipientsAsync.when(
              data: (recipients) {
                if (recipients.isEmpty) {
                  if (_recipientController.text.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return const Text('No matching users found.');
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _recipientController.text.trim().isEmpty
                          ? 'Suggested recipients'
                          : 'Matching users',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...recipients.take(6).map(
                      (recipient) => Card(
                        child: ListTile(
                          onTap: () => _selectRecipient(recipient),
                          leading: CircleAvatar(
                            child: Text(
                              recipient.username.isNotEmpty
                                  ? recipient.username[0].toUpperCase()
                                  : 'M',
                            ),
                          ),
                          title: Text(
                            recipient.username.isNotEmpty
                                ? recipient.username
                                : 'MixVy user',
                          ),
                          subtitle: const Text('Community member'),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Unable to load recipients: $e'),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: const Text('10'), onPressed: () => _setQuickAmount(10)),
              ActionChip(label: const Text('25'), onPressed: () => _setQuickAmount(25)),
              ActionChip(label: const Text('50'), onPressed: () => _setQuickAmount(50)),
              ActionChip(label: const Text('100'), onPressed: () => _setQuickAmount(100)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: paymentState.isLoading ? null : () => _submit(requestOnly: false),
                  child: paymentState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Coins'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: paymentState.isLoading ? null : () => _submit(requestOnly: true),
                  child: const Text('Request Coins'),
                ),
              ),
            ],
          ),
          if (paymentState.error != null) ...[
            const SizedBox(height: 12),
            Text(paymentState.error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 32),
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Text('No transactions yet.');
              }

              return Column(
                children: transactions.map((tx) {
                  final isSent = tx.senderId == user?.uid;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isSent ? Icons.call_made : Icons.call_received,
                        color: isSent ? Colors.red : Colors.green,
                      ),
                      title: Text('${isSent ? '-' : '+'}${tx.amount.toStringAsFixed(2)}'),
                      subtitle: Text('To: ${tx.receiverId}\nStatus: ${tx.status}'),
                      trailing: Text(
                        '${tx.timestamp.month}/${tx.timestamp.day}\n${tx.timestamp.hour.toString().padLeft(2, '0')}:${tx.timestamp.minute.toString().padLeft(2, '0')}',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  );
                }).toList(growable: false),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Unable to load transactions: $e'),
          ),
        ],
      ),
    );
  }
}
