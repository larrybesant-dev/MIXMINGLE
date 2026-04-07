import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mixvy/router/app_router.dart';

class BetaFeedbackOverlay extends StatelessWidget {
  const BetaFeedbackOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 16,
          bottom: 24,
          child: FloatingActionButton.small(
            heroTag: 'beta-feedback-fab',
            tooltip: 'Report Issue',
            child: const Icon(Icons.bug_report_outlined),
            onPressed: () {
              final navigatorContext = rootNavigatorKey.currentContext;
              if (navigatorContext == null) return;

              showModalBottomSheet<void>(
                context: navigatorContext,
                useRootNavigator: true,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const _BetaFeedbackSheet(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BetaFeedbackSheet extends StatefulWidget {
  const _BetaFeedbackSheet();

  @override
  State<_BetaFeedbackSheet> createState() => _BetaFeedbackSheetState();
}

class _BetaFeedbackSheetState extends State<_BetaFeedbackSheet> {
  final TextEditingController _messageController = TextEditingController();
  String _category = 'bug';
  bool _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String route = 'unknown';
      try {
        route = GoRouterState.of(context).uri.toString();
      } catch (_) {
        route = ModalRoute.of(context)?.settings.name ?? 'unknown';
      }

      await FirebaseFirestore.instance.collection('beta_feedback').add({
        'category': _category,
        'message': message,
        'route': route,
        'uid': user?.uid,
        'email': user?.email,
        'platform': defaultTargetPlatform.name,
        'isWeb': kIsWeb,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks. Feedback submitted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit feedback: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Beta Issue',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'bug', child: Text('Bug')),
              DropdownMenuItem(value: 'ux', child: Text('UX Issue')),
              DropdownMenuItem(value: 'performance', child: Text('Performance')),
              DropdownMenuItem(value: 'feature-request', child: Text('Feature request')),
            ],
            onChanged: _submitting
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            minLines: 4,
            maxLines: 6,
            enabled: !_submitting,
            decoration: const InputDecoration(
              labelText: 'What happened?',
              hintText: 'Describe what you did and what you expected.',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_submitting ? 'Submitting...' : 'Submit feedback'),
            ),
          ),
        ],
      ),
    );
  }
}
