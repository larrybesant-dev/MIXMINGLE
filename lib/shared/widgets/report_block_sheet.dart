import 'package:flutter/material.dart';
import '../../core/services/report_block_service.dart';
import '../../core/utils/app_logger.dart';

/// Phase 13: Report & Block UI Components
/// Bottom sheet and dialogs for reporting and blocking users

class ReportBlockSheet {
  /// Show report/block options bottom sheet
  static Future<void> showOptionsSheet(
    BuildContext context, {
    required String userId,
    required String displayName,
    String? contentId,
    String? contentType,
  }) async {
    if (!context.mounted) return;

    final isBlocked = await ReportBlockService.isUserBlocked(userId);

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),

            // Report option
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('Report User'),
              subtitle: const Text('Report inappropriate behavior'),
              onTap: () {
                Navigator.pop(context);
                showReportSheet(
                  context,
                  userId: userId,
                  displayName: displayName,
                  contentId: contentId,
                  contentType: contentType,
                );
              },
            ),

            // Block/Unblock option
            ListTile(
              leading: Icon(
                isBlocked ? Icons.block : Icons.block_outlined,
                color: Colors.red,
              ),
              title: Text(isBlocked ? 'Unblock User' : 'Block User'),
              subtitle: Text(
                isBlocked ? 'Allow this user to contact you' : 'Prevent this user from contacting you',
              ),
              onTap: () {
                Navigator.pop(context);
                if (isBlocked) {
                  _confirmUnblock(context, userId, displayName);
                } else {
                  _confirmBlock(context, userId, displayName);
                }
              },
            ),

            // Cancel
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show report reasons bottom sheet
  static Future<void> showReportSheet(
    BuildContext context, {
    required String userId,
    required String displayName,
    String? contentId,
    String? contentType,
  }) async {
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Report $displayName',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help us understand the problem',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Report reasons list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: ReportBlockService.reportReasons.length,
                  itemBuilder: (context, index) {
                    final reason = ReportBlockService.reportReasons[index];
                    final description = ReportBlockService.reportReasonDescriptions[reason];

                    return ListTile(
                      leading: const Icon(Icons.report_outlined),
                      title: Text(reason),
                      subtitle: Text(description ?? ''),
                      onTap: () {
                        Navigator.pop(context);
                        _showReportConfirmation(
                          context,
                          userId: userId,
                          displayName: displayName,
                          reason: reason,
                          contentId: contentId,
                          contentType: contentType,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show report confirmation dialog with optional description
  static Future<void> _showReportConfirmation(
    BuildContext context, {
    required String userId,
    required String displayName,
    required String reason,
    String? contentId,
    String? contentType,
  }) async {
    if (!context.mounted) return;

    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reporting: $displayName'),
            const SizedBox(height: 8),
            Text(
              'Reason: $reason',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Additional details (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Provide more context...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _submitReport(
        context,
        userId: userId,
        displayName: displayName,
        reason: reason,
        description: descriptionController.text.trim(),
        contentId: contentId,
        contentType: contentType,
      );
    }
  }

  /// Submit report
  static Future<void> _submitReport(
    BuildContext context, {
    required String userId,
    required String displayName,
    required String reason,
    String? description,
    String? contentId,
    String? contentType,
  }) async {
    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await ReportBlockService.reportUser(
        reportedUserId: userId,
        reason: reason,
        description: description,
        contentId: contentId,
        contentType: contentType,
      );

      if (!context.mounted) return;

      // Close loading
      Navigator.pop(context);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reported $displayName successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stack) {
      AppLogger.error('Error submitting report', e, stack);

      if (!context.mounted) return;

      // Close loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit report. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Confirm block dialog
  static Future<void> _confirmBlock(
    BuildContext context,
    String userId,
    String displayName,
  ) async {
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Block $displayName?'),
            const SizedBox(height: 16),
            const Text(
              'This will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('â€¢ Prevent them from contacting you'),
            const Text('â€¢ Remove them from your followers'),
            const Text('â€¢ Remove you from their followers'),
            const Text('â€¢ Hide their content from you'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _executeBlock(context, userId, displayName);
    }
  }

  /// Execute block
  static Future<void> _executeBlock(
    BuildContext context,
    String userId,
    String displayName,
  ) async {
    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await ReportBlockService.blockUser(userId);

      if (!context.mounted) return;

      // Close loading
      Navigator.pop(context);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blocked $displayName successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stack) {
      AppLogger.error('Error blocking user', e, stack);

      if (!context.mounted) return;

      // Close loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to block user. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Confirm unblock dialog
  static Future<void> _confirmUnblock(
    BuildContext context,
    String userId,
    String displayName,
  ) async {
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Unblock $displayName? They will be able to contact you again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _executeUnblock(context, userId, displayName);
    }
  }

  /// Execute unblock
  static Future<void> _executeUnblock(
    BuildContext context,
    String userId,
    String displayName,
  ) async {
    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await ReportBlockService.unblockUser(userId);

      if (!context.mounted) return;

      // Close loading
      Navigator.pop(context);

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unblocked $displayName successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stack) {
      AppLogger.error('Error unblocking user', e, stack);

      if (!context.mounted) return;

      // Close loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to unblock user. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
