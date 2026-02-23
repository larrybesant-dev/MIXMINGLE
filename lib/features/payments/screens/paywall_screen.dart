/// Paywall Screen
///
/// Premium membership selection screen with Neon Club + VIP Lounge aesthetic.
/// Features animated spotlight, gold trim, and neon glow effects.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/membership_tier.dart';
import '../controllers/coin_controller.dart';
import '../services/membership_service.dart';
import '../widgets/neon_tier_card.dart';
import '../../../core/design_system/design_constants.dart';

/// Paywall screen for membership upgrades
class PaywallScreen extends ConsumerStatefulWidget {
  final bool showCloseButton;
  final String? source;

  const PaywallScreen({
    super.key,
    this.showCloseButton = true,
    this.source,
  });

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  MembershipTier? _selectedTier;
  bool _isYearly = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Log paywall viewed
    MembershipService.instance.logPaywallViewed();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = ref.watch(currentTierProvider);
    final purchaseState = ref.watch(purchaseProvider);

    return Scaffold(
      backgroundColor: DesignColors.background,
      body: Stack(
        children: [
          // Background gradient
          _PaywallBackground(),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),

                            // Title
                            _buildTitle(),

                            const SizedBox(height: 24),

                            // Billing toggle
                            _buildBillingToggle(),

                            const SizedBox(height: 20),

                            // Tier cards
                            _buildTierCards(currentTier),

                            const SizedBox(height: 24),

                            // CTA Button
                            _buildCtaButton(purchaseState),

                            const SizedBox(height: 16),

                            // Restore purchases
                            _buildRestoreButton(),

                            const SizedBox(height: 16),

                            // Terms and conditions
                            _buildTerms(),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (purchaseState.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.showCloseButton)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                color: Colors.white.withAlpha(179),
              ),
            )
          else
            const SizedBox(width: 48),

          // VIP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignColors.gold.withAlpha(51),
                  const Color(0xFFFF7A3C).withAlpha(51),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: DesignColors.gold.withAlpha(128),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: DesignColors.gold,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'VIP LOUNGE',
                  style: TextStyle(
                    color: DesignColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              DesignColors.gold,
              const Color(0xFFFF7A3C),
              DesignColors.gold,
            ],
          ).createShader(bounds),
          child: const Text(
            'Unlock Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join the exclusive community',
          style: TextStyle(
            color: Colors.white.withAlpha(179),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withAlpha(26),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BillingOption(
            label: 'Monthly',
            isSelected: !_isYearly,
            onTap: () => setState(() => _isYearly = false),
          ),
          _BillingOption(
            label: 'Yearly',
            isSelected: _isYearly,
            showSavings: true,
            onTap: () => setState(() => _isYearly = true),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCards(MembershipTier currentTier) {
    return Column(
      children: [
        // VIP+ Card (featured)
        NeonTierCard(
          tier: MembershipTier.vipPlus,
          isSelected: _selectedTier == MembershipTier.vipPlus,
          isCurrentTier: currentTier == MembershipTier.vipPlus,
          isYearly: _isYearly,
          showSpotlight: true,
          onTap: () => setState(() => _selectedTier = MembershipTier.vipPlus),
        ),

        // VIP Card
        NeonTierCard(
          tier: MembershipTier.vip,
          isSelected: _selectedTier == MembershipTier.vip,
          isCurrentTier: currentTier == MembershipTier.vip,
          isYearly: _isYearly,
          onTap: () => setState(() => _selectedTier = MembershipTier.vip),
        ),

        // Free tier option (only if currently free)
        if (currentTier == MembershipTier.free)
          FreeTierCard(
            isSelected: _selectedTier == MembershipTier.free,
            onTap: () => setState(() => _selectedTier = MembershipTier.free),
          ),
      ],
    );
  }

  Widget _buildCtaButton(PurchaseState purchaseState) {
    final canPurchase = _selectedTier != null &&
        _selectedTier != MembershipTier.free &&
        !purchaseState.isLoading;

    return _PulsingCtaButton(
      label: _getCtaLabel(),
      enabled: canPurchase,
      onTap: canPurchase ? _handlePurchase : null,
    );
  }

  String _getCtaLabel() {
    if (_selectedTier == null) {
      return 'Select a plan';
    }
    if (_selectedTier == MembershipTier.free) {
      return 'Continue with Free';
    }
    final pricing = _selectedTier!.pricing;
    if (pricing == null) return 'Subscribe';

    final price = _isYearly ? pricing.yearlyPriceDisplay : pricing.monthlyPriceDisplay;
    return 'Subscribe for $price${_isYearly ? "/year" : "/month"}';
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: _handleRestore,
      child: Text(
        'Restore Purchases',
        style: TextStyle(
          color: Colors.white.withAlpha(128),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Payment will be charged to your App Store account. '
        'Subscription automatically renews unless canceled at least '
        '24 hours before the end of the current period.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withAlpha(77),
          fontSize: 10,
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
              'Processing...',
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
    if (_selectedTier == null || _selectedTier == MembershipTier.free) {
      Navigator.of(context).pop();
      return;
    }

    final success = await ref.read(purchaseProvider.notifier).purchaseSubscription(
      _selectedTier!,
      isYearly: _isYearly,
    );

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      final error = ref.read(purchaseProvider).error;
      if (error != null) {
        _showErrorSnackbar(error);
      }
    }
  }

  Future<void> _handleRestore() async {
    final success = await ref.read(purchaseProvider.notifier).restorePurchases();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Purchases restored successfully!'),
            backgroundColor: const Color(0xFF00FF88),
          ),
        );
      } else {
        final error = ref.read(purchaseProvider).error;
        _showErrorSnackbar(error ?? 'Failed to restore purchases');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SuccessDialog(
        tier: _selectedTier!,
        onDismiss: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop(true);
        },
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF1744),
      ),
    );
  }
}

/// Paywall background with gradient and effects
class _PaywallBackground extends StatelessWidget {
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
          // Top gold glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignColors.gold.withAlpha(26),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom neon orange glow
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF7A3C).withAlpha(20),
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

/// Billing period option toggle
class _BillingOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool showSavings;
  final VoidCallback onTap;

  const _BillingOption({
    required this.label,
    required this.isSelected,
    this.showSavings = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? DesignColors.gold.withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: DesignColors.gold.withAlpha(128), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? DesignColors.gold : Colors.white.withAlpha(128),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (showSavings && isSelected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withAlpha(51),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SAVE 30%',
                  style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pulsing CTA button with neon effect
class _PulsingCtaButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _PulsingCtaButton({
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  State<_PulsingCtaButton> createState() => _PulsingCtaButtonState();
}

class _PulsingCtaButtonState extends State<_PulsingCtaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseValue = widget.enabled ? _pulseAnimation.value : 0.0;

        return GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.enabled
                    ? [
                        DesignColors.gold,
                        const Color(0xFFFF7A3C),
                      ]
                    : [
                        Colors.grey.withAlpha(102),
                        Colors.grey.withAlpha(128),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: DesignColors.gold.withAlpha((50 + 30 * pulseValue).round()),
                        blurRadius: 16 + 8 * pulseValue,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.enabled ? Colors.black : Colors.white.withAlpha(128),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Success dialog after purchase
class _SuccessDialog extends StatefulWidget {
  final MembershipTier tier;
  final VoidCallback onDismiss;

  const _SuccessDialog({
    required this.tier,
    required this.onDismiss,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1520),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.tier.primaryColor.withAlpha(128),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.tier.primaryColor.withAlpha(77),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.tier.primaryColor.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: widget.tier.primaryColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Welcome to ${widget.tier.displayName}!',
                style: TextStyle(
                  color: widget.tier.primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'You now have access to all premium features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(179),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Continue button
              GestureDetector(
                onTap: widget.onDismiss,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.tier.primaryColor,
                        widget.tier.secondaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to show paywall from anywhere
Future<bool?> showPaywall(BuildContext context, {String? source}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PaywallScreen(source: source),
    ),
  );
}
