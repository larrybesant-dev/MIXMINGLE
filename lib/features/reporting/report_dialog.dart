import 'package:flutter/material.dart';
import '../../services/events/reporting_service.dart';

/// Dialog for submitting a report
class ReportDialog extends StatefulWidget {
  final ReportType type;
  final String reportedId;
  final String? reportedName; // User name, event title, etc.

  const ReportDialog({
    super.key,
    required this.type,
    required this.reportedId,
    this.reportedName,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason? _selectedReason;
  final _additionalInfoController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportingService = ReportingService();

      await reportingService.submitReport(
        type: widget.type,
        reportedId: widget.reportedId,
        reason: _selectedReason!,
        additionalInfo: _additionalInfoController.text.trim().isEmpty ? null : _additionalInfoController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted. Thank you for helping keep our community safe.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    String subtitle;
    switch (widget.type) {
      case ReportType.user:
        title = 'Report User';
        subtitle = widget.reportedName != null ? 'Report ${widget.reportedName}' : 'Report this user';
        break;
      case ReportType.event:
        title = 'Report Event';
        subtitle = widget.reportedName != null ? 'Report "${widget.reportedName}"' : 'Report this event';
        break;
      case ReportType.message:
        title = 'Report Message';
        subtitle = 'Report this message';
        break;
      case ReportType.photo:
        title = 'Report Photo';
        subtitle = 'Report this photo';
        break;
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        color: theme.colorScheme.onErrorContainer,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why are you reporting this?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your report is anonymous. Our team will review it.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Report reasons
                    // ignore: deprecated_member_use, deprecated_member_use_from_same_package
                    ...ReportReason.values.map((reason) {
                      return RadioListTile<ReportReason>(
                        value: reason,
                        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
                        groupValue: _selectedReason,
                        // ignore: deprecated_member_use, deprecated_member_use_from_same_package
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedReason = value;
                                });
                              },
                        title: Text(
                          ReportingService.getReasonText(reason),
                          style: theme.textTheme.bodyLarge,
                        ),
                        subtitle: Text(
                          ReportingService.getReasonDescription(reason),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      );
                    }),

                    const SizedBox(height: 16),

                    // Additional info
                    Text(
                      'Additional Information (Optional)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _additionalInfoController,
                      enabled: !_isSubmitting,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Provide any additional context that might help our review...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitReport,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? 'Submitting...' : 'Submit Report'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a report dialog
Future<bool?> showReportDialog({
  required BuildContext context,
  required ReportType type,
  required String reportedId,
  String? reportedName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ReportDialog(
      type: type,
      reportedId: reportedId,
      reportedName: reportedName,
    ),
  );
}
