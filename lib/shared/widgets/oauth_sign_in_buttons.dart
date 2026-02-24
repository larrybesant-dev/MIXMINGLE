// ============================================================================
// OAUTH SIGN-IN BUTTONS
// ============================================================================
// Beautiful, reusable OAuth sign-in buttons for Google, Facebook, and Apple
// Fully integrated with OAuthService
// Production-ready with loading states and error handling
// ============================================================================

import 'package:flutter/material.dart';
import '../../services/auth/oauth_service.dart';
import '../../core/design_system/design_constants.dart';

/// OAuth Sign-In Buttons Widget
/// Use this in your login/signup pages for quick OAuth integration
class OAuthSignInButtons extends StatefulWidget {
  final Function(String userId, String email) onSignInSuccess;
  final Function(String error, String message) onSignInError;
  final bool showApple;
  final bool showGoogle;
  final bool showFacebook;
  final String? actionText; // 'Sign in' or 'Sign up' or 'Continue'

  const OAuthSignInButtons({
    super.key,
    required this.onSignInSuccess,
    required this.onSignInError,
    this.showApple = true,
    this.showGoogle = true,
    this.showFacebook = false, // Disabled by default until implemented
    this.actionText,
  });

  @override
  State<OAuthSignInButtons> createState() => _OAuthSignInButtonsState();
}

class _OAuthSignInButtonsState extends State<OAuthSignInButtons> {
  // All OAuth removed for launch

  @override
  Widget build(BuildContext context) {
    // Unused for launch: final action = widget.actionText ?? 'Continue';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Divider with "OR" text
        _buildOrDivider(),

        const SizedBox(height: 24),

        // OAuth buttons DISABLED FOR LAUNCH
        _buildDisabledOAuthNotice(),

        // DISABLED - Google Sign-In Button
        // if (widget.showGoogle)
        //   _OAuthButton(
        //     onPressed: null,
        //     isLoading: false,
        //     icon: _buildGoogleIcon(),
        //     label: '$action with Google (Coming Soon)',
        //     backgroundColor: Colors.white,
        //     textColor: Colors.black87,
        //   ),

        // DISABLED - Apple Sign-In Button
        // if (widget.showApple)
        //   _OAuthButton(
        //     onPressed: null,
        //     isLoading: false,
        //     icon: const Icon(Icons.apple, color: Colors.white, size: 24),
        //     label: '$action with Apple (Coming Soon)',
        //     backgroundColor: Colors.black,
        //     textColor: Colors.white,
        //   ),

        // DISABLED - Facebook Sign-In Button
        // if (widget.showFacebook)
        //   _OAuthButton(
        //     onPressed: null,
        //     isLoading: false,
        //     icon: const Icon(Icons.facebook, color: Colors.white, size: 24),
        //     label: '$action with Facebook (Coming Soon)',
        //     backgroundColor: const Color(0xFF1877F2),
        //     textColor: Colors.white,
        //   ),
      ],
    );
  }

  Widget _buildDisabledOAuthNotice() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'Social sign-in coming soon. Use email for now.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: Color(0xFF2A2D3A),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Color(0xFF2A2D3A),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // DISABLED FOR LAUNCH - All OAuth sign-in handlers removed
  /*
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    ...
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isAppleLoading = true);
    ...
  }
  */
}

// REMOVED: _OAuthButton class - unused after OAuth disabled for launch

/// Account Linking Buttons (for settings page)
/// Use this in settings to allow users to link/unlink OAuth providers
class OAuthAccountLinkingSection extends StatefulWidget {
  final Function() onAccountUpdated;

  const OAuthAccountLinkingSection({
    super.key,
    required this.onAccountUpdated,
  });

  @override
  State<OAuthAccountLinkingSection> createState() => _OAuthAccountLinkingSectionState();
}

class _OAuthAccountLinkingSectionState extends State<OAuthAccountLinkingSection> {
  final OAuthService _oauthService = OAuthService();

  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connected Accounts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        _buildLinkButton(
          icon: const Icon(Icons.g_mobiledata, color: Colors.white),
          label: 'Google',
          isLoading: _isGoogleLoading,
          onLink: _handleLinkGoogle,
        ),

        const SizedBox(height: 12),

        _buildLinkButton(
          icon: const Icon(Icons.apple, color: Colors.white),
          label: 'Apple',
          isLoading: _isAppleLoading,
          onLink: _handleLinkApple,
        ),
      ],
    );
  }

  Widget _buildLinkButton({
    required Widget icon,
    required String label,
    required bool isLoading,
    required VoidCallback onLink,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2D3A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignConstants.accentPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isLoading)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: onLink,
              style: TextButton.styleFrom(
                foregroundColor: DesignConstants.accentPurple,
              ),
              child: const Text('Link Account'),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLinkGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final result = await _oauthService.linkGoogleAccount();

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google account linked successfully')),
        );
        widget.onAccountUpdated();
      } else {
        _showError(result.message ?? 'Failed to link Google account');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error linking Google account: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleLinkApple() async {
    setState(() => _isAppleLoading = true);

    try {
      final result = await _oauthService.linkAppleAccount();

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apple account linked successfully')),
        );
        widget.onAccountUpdated();
      } else {
        _showError(result.message ?? 'Failed to link Apple account');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error linking Apple account: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isAppleLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
      ),
    );
  }
}
