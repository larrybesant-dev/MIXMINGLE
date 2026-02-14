/// Alpha Invite Widget
///
/// Displays alpha tester invitation status and provides
/// quick access to the feedback form.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'internal_alpha_service.dart';

/// Widget showing alpha invite status
class AlphaInviteWidget extends StatefulWidget {
  final String? userEmail;
  final String? feedbackFormUrl;
  final VoidCallback? onFeedbackTap;

  const AlphaInviteWidget({
    super.key,
    this.userEmail,
    this.feedbackFormUrl,
    this.onFeedbackTap,
  });

  @override
  State<AlphaInviteWidget> createState() => _AlphaInviteWidgetState();
}

class _AlphaInviteWidgetState extends State<AlphaInviteWidget> {
  final InternalAlphaService _alphaService = InternalAlphaService.instance;

  TesterStatus? _status;
  bool _isLoading = true;
  AlphaTester? _tester;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    if (widget.userEmail == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final testers = await _alphaService.getTesters();
      final tester = testers.firstWhere(
        (t) => t.email.toLowerCase() == widget.userEmail?.toLowerCase(),
        orElse: () => const AlphaTester(id: '', email: '', status: TesterStatus.removed),
      );

      if (tester.id.isNotEmpty) {
        setState(() {
          _status = tester.status;
          _tester = tester;
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStatusSection(),
              if (_status == TesterStatus.active) ...[
                const SizedBox(height: 16),
                _buildFeedbackSection(),
              ],
              if (_tester != null && _tester!.feedbackCount > 0) ...[
                const SizedBox(height: 12),
                _buildStatsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.science_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Internal Alpha',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Early access testing program',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (_status) {
      case TesterStatus.invited:
        badgeColor = Colors.amber;
        badgeText = 'Invited';
        badgeIcon = Icons.mail_outline;
        break;
      case TesterStatus.active:
        badgeColor = Colors.green;
        badgeText = 'Active';
        badgeIcon = Icons.check_circle_outline;
        break;
      case TesterStatus.inactive:
        badgeColor = Colors.orange;
        badgeText = 'Inactive';
        badgeIcon = Icons.pause_circle_outline;
        break;
      default:
        badgeColor = Colors.grey;
        badgeText = 'Not a tester';
        badgeIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 16),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    String message;

    switch (_status) {
      case TesterStatus.invited:
        message = 'You\'ve been invited to help test Mix & Mingle! '
            'Download the latest build and start exploring.';
        break;
      case TesterStatus.active:
        message = 'Thank you for being an alpha tester! '
            'Your feedback helps shape the future of Mix & Mingle.';
        break;
      case TesterStatus.inactive:
        message = 'We miss you! Come back and check out the latest updates.';
        break;
      default:
        message = 'The alpha program is currently invite-only. '
            'Stay tuned for the public beta!';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openFeedbackForm,
            icon: const Icon(Icons.feedback_outlined),
            label: const Text('Submit Feedback'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _openBugReport,
          icon: const Icon(Icons.bug_report_outlined),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
          ),
          tooltip: 'Report a bug',
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            icon: Icons.chat_bubble_outline,
            value: '${_tester!.feedbackCount}',
            label: 'Feedback',
          ),
          _buildStat(
            icon: Icons.timer_outlined,
            value: '${_tester!.sessionsCount}',
            label: 'Sessions',
          ),
          _buildStat(
            icon: Icons.star_outline,
            value: _getEngagementLevel(),
            label: 'Level',
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _getEngagementLevel() {
    final count = _tester?.feedbackCount ?? 0;
    if (count >= 10) return 'Gold';
    if (count >= 5) return 'Silver';
    if (count >= 1) return 'Bronze';
    return 'New';
  }

  void _openFeedbackForm() {
    if (widget.onFeedbackTap != null) {
      widget.onFeedbackTap!();
      return;
    }

    if (widget.feedbackFormUrl != null) {
      launchUrl(Uri.parse(widget.feedbackFormUrl!));
    } else {
      // Show in-app feedback dialog
      showDialog(
        context: context,
        builder: (context) => const AlphaFeedbackDialog(),
      );
    }
  }

  void _openBugReport() {
    showDialog(
      context: context,
      builder: (context) => const AlphaFeedbackDialog(isBugReport: true),
    );
  }
}

/// Simple alpha feedback dialog
class AlphaFeedbackDialog extends StatefulWidget {
  final bool isBugReport;

  const AlphaFeedbackDialog({
    super.key,
    this.isBugReport = false,
  });

  @override
  State<AlphaFeedbackDialog> createState() => _AlphaFeedbackDialogState();
}

class _AlphaFeedbackDialogState extends State<AlphaFeedbackDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isBugReport ? Icons.bug_report : Icons.feedback,
            color: widget.isBugReport ? Colors.red : const Color(0xFF6366F1),
          ),
          const SizedBox(width: 8),
          Text(widget.isBugReport ? 'Report a Bug' : 'Send Feedback'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.isBugReport
                ? 'Describe the bug you encountered:'
                : 'Share your thoughts about Mix & Mingle:',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: widget.isBugReport
                  ? 'What happened? What did you expect?'
                  : 'Your feedback...',
              border: const OutlineInputBorder(),
              filled: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isBugReport ? Colors.red : const Color(0xFF6366F1),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    // Would submit through InternalAlphaService
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// Compact status indicator for app bar
class AlphaStatusIndicator extends StatelessWidget {
  final TesterStatus status;

  const AlphaStatusIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'ALPHA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
