/// Coin Store Screen
///
/// Coin purchase screen with neon styling and animated effects.
/// Features coin rain animation on successful purchase.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coin_package.dart';
import '../models/membership_tier.dart';
import '../controllers/coin_controller.dart';
import '../widgets/neon_coin_package_card.dart';
import '../../../core/design_system/design_constants.dart';

/// Coin store screen
class CoinStoreScreen extends ConsumerStatefulWidget {
  const CoinStoreScreen({super.key});

  @override
  ConsumerState<CoinStoreScreen> createState() => _CoinStoreScreenState();
}

class _CoinStoreScreenState extends ConsumerState<CoinStoreScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  CoinPackage? _selectedPackage;
  bool _showCoinRain = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinBalance = ref.watch(currentCoinBalanceProvider);
    final currentTier = ref.watch(currentTierProvider);
    final purchaseState = ref.watch(purchaseProvider);
    final packages = ref.watch(coinPackagesProvider);
    final isVipPlus = currentTier == MembershipTier.vipPlus;

    return Scaffold(
      backgroundColor: DesignColors.background,
      body: Stack(
        children: [
          // Background
          _CoinStoreBackground(),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header
                  _buildHeader(coinBalance),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Title
                          _buildTitle(),

                          const SizedBox(height: 8),

                          // VIP+ bonus notice
                          if (isVipPlus) _buildVipPlusBonusNotice(),

                          const SizedBox(height: 24),

                          // Package grid
                          _buildPackageGrid(packages, isVipPlus),

                          const SizedBox(height: 24),

                          // Purchase button
                          _buildPurchaseButton(purchaseState),

                          const SizedBox(height: 16),

                          // Transaction history button
                          _buildHistoryButton(),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (purchaseState.isLoading) _buildLoadingOverlay(),

          // Coin rain effect
          if (_showCoinRain) _CoinRainEffect(onComplete: _onCoinRainComplete),
        ],
      ),
    );
  }

  Widget _buildHeader(int coinBalance) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white.withAlpha(179),
            ),
          ),
          const Spacer(),

          // Current balance
          CoinBalanceDisplay(
            balance: coinBalance,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              DesignColors.gold,
              const Color(0xFFFF7A3C),
            ],
          ).createShader(bounds),
          child: const Text(
            'Coin Store',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Get coins to send gifts and use premium features',
          style: TextStyle(
            color: Colors.white.withAlpha(153),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildVipPlusBonusNotice() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9D4EDD).withAlpha(26),
            const Color(0xFF9D4EDD).withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF9D4EDD).withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: const Color(0xFF9D4EDD),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'VIP+ members get 20% bonus coins on every purchase!',
              style: TextStyle(
                color: const Color(0xFF9D4EDD).withAlpha(230),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageGrid(List<CoinPackage> packages, bool isVipPlus) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        return NeonCoinPackageCard(
          package: package,
          isSelected: _selectedPackage?.id == package.id,
          isVipPlus: isVipPlus,
          onTap: () => setState(() => _selectedPackage = package),
        );
      },
    );
  }

  Widget _buildPurchaseButton(PurchaseState purchaseState) {
    final canPurchase = _selectedPackage != null && !purchaseState.isLoading;

    return GestureDetector(
      onTap: canPurchase ? _handlePurchase : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: canPurchase
              ? LinearGradient(
                  colors: [
                    DesignColors.gold,
                    const Color(0xFFFF7A3C),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: canPurchase ? null : Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          boxShadow: canPurchase
              ? [
                  BoxShadow(
                    color: DesignColors.gold.withAlpha(51),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          _getPurchaseButtonLabel(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: canPurchase ? Colors.black : Colors.white.withAlpha(128),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getPurchaseButtonLabel() {
    if (_selectedPackage == null) {
      return 'Select a package';
    }
    return 'Buy for ${_selectedPackage!.priceDisplay}';
  }

  Widget _buildHistoryButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _showTransactionHistory,
        icon: Icon(
          Icons.history,
          color: Colors.white.withAlpha(128),
          size: 18,
        ),
        label: Text(
          'Transaction History',
          style: TextStyle(
            color: Colors.white.withAlpha(128),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withAlpha(179),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(DesignColors.gold),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Processing purchase...',
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase() async {
    if (_selectedPackage == null) return;

    final success = await ref
        .read(purchaseProvider.notifier)
        .purchaseCoinPackage(_selectedPackage!);

    if (success && mounted) {
      setState(() => _showCoinRain = true);
    } else if (mounted) {
      final error = ref.read(purchaseProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFFF1744),
          ),
        );
      }
    }
  }

  void _onCoinRainComplete() {
    setState(() {
      _showCoinRain = false;
      _selectedPackage = null;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ref.read(purchaseProvider).successMessage ?? 'Coins added!'),
        backgroundColor: const Color(0xFF00FF88),
      ),
    );

    ref.read(purchaseProvider.notifier).reset();
  }

  void _showTransactionHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _TransactionHistorySheet(),
    );
  }
}

/// Coin store background
class _CoinStoreBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignColors.background,
            const Color(0xFF0D1520),
            DesignColors.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Gold glow top right
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignColors.gold.withAlpha(20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Orange glow bottom left
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF7A3C).withAlpha(15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coin rain animation effect
class _CoinRainEffect extends StatefulWidget {
  final VoidCallback onComplete;

  const _CoinRainEffect({required this.onComplete});

  @override
  State<_CoinRainEffect> createState() => _CoinRainEffectState();
}

class _CoinRainEffectState extends State<_CoinRainEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_CoinParticle> _particles;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    // Generate coin particles
    _particles = List.generate(30, (index) {
      return _CoinParticle(
        startX: _random.nextDouble(),
        delay: _random.nextDouble() * 0.3,
        speed: 0.5 + _random.nextDouble() * 0.5,
        size: 20 + _random.nextDouble() * 20,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _CoinRainPainter(
            progress: _controller.value,
            particles: _particles,
          ),
        ),
      ),
    );
  }
}

class _CoinParticle {
  final double startX;
  final double delay;
  final double speed;
  final double size;
  final double rotation;
  final double rotationSpeed;

  _CoinParticle({
    required this.startX,
    required this.delay,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _CoinRainPainter extends CustomPainter {
  final double progress;
  final List<_CoinParticle> particles;

  _CoinRainPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final adjustedProgress = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);

      if (adjustedProgress <= 0) continue;

      final x = particle.startX * size.width;
      final y = -particle.size + adjustedProgress * (size.height + particle.size * 2) * particle.speed;

      // Fade out at the end
      final opacity = adjustedProgress < 0.8 ? 1.0 : 1.0 - (adjustedProgress - 0.8) / 0.2;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + progress * particle.rotationSpeed * math.pi);

      // Draw coin
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            Color.fromRGBO(255, 215, 0, opacity), // Gold
            Color.fromRGBO(205, 155, 0, opacity), // Darker gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size));

      canvas.drawCircle(Offset.zero, particle.size / 2, paint);

      // Draw coin border
      final borderPaint = Paint()
        ..color = Color.fromRGBO(150, 100, 0, opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset.zero, particle.size / 2 * 0.8, borderPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CoinRainPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Transaction history bottom sheet
class _TransactionHistorySheet extends ConsumerWidget {
  const _TransactionHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(coinTransactionHistoryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: Colors.white.withAlpha(26),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: DesignColors.gold,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Transaction History',
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: Colors.white.withAlpha(26),
            height: 1,
          ),

          // Transactions list
          Expanded(
            child: historyAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(DesignColors.gold),
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Failed to load history',
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                  ),
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.white.withAlpha(51),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: Colors.white.withAlpha(128),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.white.withAlpha(13),
                    height: 24,
                  ),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _TransactionItem(transaction: transaction);
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

/// Single transaction item
class _TransactionItem extends StatelessWidget {
  final CoinTransaction transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPositive = transaction.amount > 0;

    return Row(
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isPositive
                    ? const Color(0xFF00FF88)
                    : const Color(0xFFFF7A3C))
                .withAlpha(26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            transaction.type.icon,
            color: isPositive
                ? const Color(0xFF00FF88)
                : const Color(0xFFFF7A3C),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.description ?? transaction.type.displayName,
                style: TextStyle(
                  color: Colors.white.withAlpha(230),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(transaction.timestamp),
                style: TextStyle(
                  color: Colors.white.withAlpha(102),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Amount
        Text(
          '${isPositive ? '+' : ''}${transaction.amount}',
          style: TextStyle(
            color: isPositive
                ? const Color(0xFF00FF88)
                : const Color(0xFFFF7A3C),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Helper to show coin store from anywhere
Future<void> showCoinStore(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const CoinStoreScreen(),
    ),
  );
}
