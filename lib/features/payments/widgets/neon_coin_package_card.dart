/// Neon Coin Package Card Widget
///
/// Displays coin package for purchase with neon styling.
/// Features gold glow effects and bonus coin indicators.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/coin_package.dart';
import '../../../../core/design_system/design_constants.dart';

/// Neon styled coin package card
class NeonCoinPackageCard extends StatefulWidget {
  final CoinPackage package;
  final bool isSelected;
  final bool isVipPlus;
  final VoidCallback onTap;

  const NeonCoinPackageCard({
    super.key,
    required this.package,
    this.isSelected = false,
    this.isVipPlus = false,
    required this.onTap,
  });

  @override
  State<NeonCoinPackageCard> createState() => _NeonCoinPackageCardState();
}

class _NeonCoinPackageCardState extends State<NeonCoinPackageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalCoins = widget.package.getTotalCoins(widget.isVipPlus);
    final hasBonus = (widget.package.bonusCoins ?? 0) > 0;
    final hasVipBonus =
        widget.isVipPlus && widget.package.vipPlusBonusCoins > 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowIntensity = widget.isSelected ? _glowAnimation.value : 0.3;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignColors.gold.withAlpha(widget.isSelected ? 38 : 20),
                  const Color(0xFFFF7A3C)
                      .withAlpha(widget.isSelected ? 38 : 20),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected
                    ? DesignColors.gold
                    : DesignColors.gold.withAlpha(77),
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (widget.isSelected)
                  BoxShadow(
                    color: DesignColors.gold
                        .withAlpha((60 * glowIntensity).round()),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Coin icon with glow
                      _CoinIcon(
                        size: 48,
                        isSelected: widget.isSelected,
                        glowIntensity: glowIntensity,
                      ),
                      const SizedBox(height: 12),

                      // Total coins
                      Text(
                        totalCoins.toString(),
                        style: TextStyle(
                          color: DesignColors.gold,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          shadows: widget.isSelected
                              ? [
                                  Shadow(
                                    color: DesignColors.gold.withAlpha(128),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'coins',
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Bonus breakdown
                      if (hasBonus || hasVipBonus)
                        Column(
                          children: [
                            Text(
                              '${widget.package.coins} base',
                              style: TextStyle(
                                color: Colors.white.withAlpha(128),
                                fontSize: 10,
                              ),
                            ),
                            if (hasBonus)
                              Text(
                                '+${widget.package.bonusCoins} bonus',
                                style: TextStyle(
                                  color: const Color(0xFF00FF88).withAlpha(179),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (hasVipBonus)
                              Text(
                                '+${widget.package.vipPlusBonusCoins} VIP+ bonus',
                                style: TextStyle(
                                  color: const Color(0xFF9D4EDD).withAlpha(230),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? DesignColors.gold.withAlpha(51)
                              : Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.isSelected
                                ? DesignColors.gold.withAlpha(128)
                                : Colors.white.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.package.priceDisplay,
                          style: TextStyle(
                            color: widget.isSelected
                                ? DesignColors.gold
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Best value badge
                if (widget.package.isBestValue)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignColors.gold,
                            Color(0xFFFF7A3C),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(14),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'BEST',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // Selection indicator
                if (widget.isSelected)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: DesignColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Animated coin icon
class _CoinIcon extends StatefulWidget {
  final double size;
  final bool isSelected;
  final double glowIntensity;

  const _CoinIcon({
    required this.size,
    required this.isSelected,
    required this.glowIntensity,
  });

  @override
  State<_CoinIcon> createState() => _CoinIconState();
}

class _CoinIconState extends State<_CoinIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotateAnimation =
        Tween<double>(begin: 0, end: 1).animate(_rotateController);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, child) {
        // Subtle 3D rotation effect
        final rotationValue = _rotateAnimation.value;
        const perspective = 0.002;
        final rotateY = widget.isSelected
            ? math.sin(rotationValue * 2 * math.pi) * 0.1
            : 0.0;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, perspective)
            ..rotateY(rotateY),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  DesignColors.gold,
                  Color(0xFFCD9B00),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: DesignColors.gold
                      .withAlpha((77 * widget.glowIntensity).round()),
                  blurRadius: widget.isSelected ? 16 : 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner ring
                Container(
                  width: widget.size * 0.85,
                  height: widget.size * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFCD9B00),
                      width: 2,
                    ),
                  ),
                ),
                // Coin symbol
                Text(
                  'Â¢',
                  style: TextStyle(
                    color: const Color(0xFF7D5600),
                    fontSize: widget.size * 0.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact coin package card for horizontal list
class CompactCoinPackageCard extends StatelessWidget {
  final CoinPackage package;
  final bool isSelected;
  final bool isVipPlus;
  final VoidCallback onTap;

  const CompactCoinPackageCard({
    super.key,
    required this.package,
    this.isSelected = false,
    this.isVipPlus = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalCoins = package.getTotalCoins(isVipPlus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignColors.gold.withAlpha(26)
              : Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? DesignColors.gold : Colors.white.withAlpha(51),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on,
              color: DesignColors.gold,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              totalCoins.toString(),
              style: const TextStyle(
                color: DesignColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              package.priceDisplay,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coin balance display widget
class CoinBalanceDisplay extends StatelessWidget {
  final int balance;
  final VoidCallback? onTap;
  final bool compact;

  const CoinBalanceDisplay({
    super.key,
    required this.balance,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: DesignColors.gold.withAlpha(26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DesignColors.gold.withAlpha(77),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                color: DesignColors.gold,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _formatBalance(balance),
                style: const TextStyle(
                  color: DesignColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.add_circle_outline,
                  color: DesignColors.gold.withAlpha(179),
                  size: 14,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DesignColors.gold.withAlpha(26),
              const Color(0xFFFF7A3C).withAlpha(26),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DesignColors.gold.withAlpha(102),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignColors.gold.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on,
                color: DesignColors.gold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatBalance(balance),
                  style: const TextStyle(
                    color: DesignColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'coins',
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignColors.gold.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: DesignColors.gold,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatBalance(int balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(1)}K';
    }
    return balance.toString();
  }
}
