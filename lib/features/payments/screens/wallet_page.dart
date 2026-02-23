/// Wallet Page
///
/// Comprehensive wallet screen showing coin balance, transaction history,
/// and quick actions for coin management.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/coin_controller.dart';
import '../models/coin_package.dart';
import '../../../core/design_system/design_constants.dart';
import 'coin_store_screen.dart';

/// Main wallet page
class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinBalance = ref.watch(currentCoinBalanceProvider);
    final transactions = ref.watch(coinTransactionHistoryProvider);

    return Scaffold(
      backgroundColor: DesignColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Wallet',
          style: TextStyle(
            color: DesignColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: DesignColors.accent),
            onPressed: () => _showTransactionHistory(context, transactions),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            ScaleTransition(
              scale: _scaleAnim,
              child: _buildBalanceCard(coinBalance),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(context),

            const SizedBox(height: 24),

            // Recent Transactions
            _buildRecentTransactions(transactions),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(int balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignColors.accent,
            DesignColors.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DesignColors.accent.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Coin Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.monetization_on,
                color: DesignColors.gold,
                size: 40,
              ),
              const SizedBox(width: 12),
              Text(
                balance.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '\$${(balance * 0.01).toStringAsFixed(2)} estimated value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: DesignColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_circle,
                label: 'Buy Coins',
                color: DesignColors.success,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoinStoreScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.card_giftcard,
                label: 'Send Gift',
                color: DesignColors.secondary,
                onTap: () => _showSendGiftInfo(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.star,
                label: 'VIP',
                color: DesignColors.gold,
                onTap: () => _showVipInfo(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(AsyncValue<List<CoinTransaction>> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: DesignColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _showTransactionHistory(context, transactions),
              child: const Text(
                'See All',
                style: TextStyle(color: DesignColors.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        transactions.when(
          data: (txns) => txns.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: txns.take(5).map(_buildTransactionTile).toList(),
                ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: DesignColors.accent),
            ),
          ),
          error: (e, _) => Center(
            child: Text(
              'Failed to load: $e',
              style: const TextStyle(color: DesignColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long,
            color: DesignColors.textGray,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: DesignColors.textGray,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Buy coins or send gifts to see activity here',
            style: TextStyle(
              color: DesignColors.textGray,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(CoinTransaction txn) {
    final isCredit = txn.amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isCredit ? DesignColors.success : DesignColors.secondary)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.add : Icons.remove,
              color: isCredit ? DesignColors.success : DesignColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description ?? _getDefaultDescription(txn.type),
                  style: const TextStyle(
                    color: DesignColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(txn.timestamp),
                  style: const TextStyle(
                    color: DesignColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}${txn.amount}',
            style: TextStyle(
              color: isCredit ? DesignColors.success : DesignColors.secondary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.monetization_on,
            color: DesignColors.gold,
            size: 16,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  String _getDefaultDescription(CoinTransactionType type) {
    switch (type) {
      case CoinTransactionType.purchase:
        return 'Coin purchase';
      case CoinTransactionType.bonus:
        return 'Bonus coins';
      case CoinTransactionType.giftSent:
        return 'Gift sent';
      case CoinTransactionType.giftReceived:
        return 'Gift received';
      case CoinTransactionType.spotlight:
        return 'Spotlight activation';
      case CoinTransactionType.refund:
        return 'Refund';
      case CoinTransactionType.other:
        return 'Transaction';
    }
  }

  void _showTransactionHistory(
      BuildContext context, AsyncValue<List<CoinTransaction>> transactions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignColors.surfaceDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Transaction History',
              style: TextStyle(
                color: DesignColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: transactions.when(
                data: (txns) => txns.isEmpty
                    ? Center(child: _buildEmptyState())
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: txns.length,
                        itemBuilder: (_, i) => _buildTransactionTile(txns[i]),
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: DesignColors.accent),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: DesignColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendGiftInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Join a room to send gifts to other users!'),
        backgroundColor: DesignColors.secondary,
      ),
    );
  }

  void _showVipInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('VIP members get bonus coins on purchases!'),
        backgroundColor: DesignColors.gold,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
