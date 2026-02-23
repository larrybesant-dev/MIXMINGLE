import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/reporting_service.dart';

/// Admin page for reviewing and moderating reports
class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  final _firestore = FirebaseFirestore.instance;
  ReportStatus _selectedStatus = ReportStatus.pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
        actions: [
          // Status filter dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<ReportStatus>(
              value: _selectedStatus,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.filter_list),
              items: ReportStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusText(status)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('reports')
            .where('status', isEqualTo: _selectedStatus.name)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading reports', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data?.docs ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${_getStatusText(_selectedStatus).toLowerCase()} reports',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: reports.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final report = reports[index];
              final data = report.data() as Map<String, dynamic>;
              return _buildReportCard(context, report.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String reportId, Map<String, dynamic> data) {
    final theme = Theme.of(context);

    final type = data['type'] as String?;
    final reason = data['reason'] as String?;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final additionalInfo = data['additionalInfo'] as String?;
    final reportedId = data['reportedId'] as String?;
    final reporterEmail = data['reporterEmail'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: _getTypeIcon(type),
        title: Text(
          _getReasonDisplayText(reason),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Type: ${_getTypeText(type)}'),
            if (createdAt != null)
              Text(
                'Submitted: ${DateFormat('MMM d, yyyy â€¢ h:mm a').format(createdAt)}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reporter info
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Reporter',
                  value: reporterEmail ?? 'Unknown',
                ),
                const SizedBox(height: 8),

                // Reported content
                _buildInfoRow(
                  icon: Icons.flag_outlined,
                  label: 'Reported ID',
                  value: reportedId ?? 'Unknown',
                ),
                const SizedBox(height: 8),

                // Additional info
                if (additionalInfo != null && additionalInfo.isNotEmpty) ...[
                  _buildInfoRow(
                    icon: Icons.notes,
                    label: 'Additional Info',
                    value: additionalInfo,
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(),
                const SizedBox(height: 16),

                // Actions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _updateReportStatus(
                        reportId,
                        ReportStatus.investigating,
                      ),
                      icon: const Icon(Icons.search),
                      label: const Text('Investigate'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _updateReportStatus(
                        reportId,
                        ReportStatus.resolved,
                        actionTaken: 'Content removed',
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Resolve'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _updateReportStatus(
                        reportId,
                        ReportStatus.dismissed,
                        actionTaken: 'No violation found',
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Dismiss'),
                    ),
                    if (reportedId != null && type == 'user')
                      OutlinedButton.icon(
                        onPressed: () => _viewReportedUser(reportedId),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('View User'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? actionTaken,
  }) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
        if (actionTaken != null) 'actionTaken': actionTaken,
        if (newStatus != ReportStatus.pending) 'reviewedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report marked as ${_getStatusText(newStatus).toLowerCase()}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating report: $e')),
        );
      }
    }
  }

  void _viewReportedUser(String userId) {
    // Navigate to user profile
    // Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: userId)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User profile view not implemented yet')),
    );
  }

  Icon _getTypeIcon(String? type) {
    switch (type) {
      case 'user':
        return const Icon(Icons.person, color: Colors.red);
      case 'event':
        return const Icon(Icons.event, color: Colors.orange);
      case 'message':
        return const Icon(Icons.message, color: Colors.blue);
      case 'photo':
        return const Icon(Icons.photo, color: Colors.purple);
      default:
        return const Icon(Icons.flag, color: Colors.grey);
    }
  }

  String _getTypeText(String? type) {
    switch (type) {
      case 'user':
        return 'User Report';
      case 'event':
        return 'Event Report';
      case 'message':
        return 'Message Report';
      case 'photo':
        return 'Photo Report';
      default:
        return 'Unknown';
    }
  }

  String _getReasonDisplayText(String? reason) {
    if (reason == null) return 'Unknown Reason';

    try {
      final reasonEnum = ReportReason.values.firstWhere(
        (r) => r.name == reason,
        orElse: () => ReportReason.other,
      );
      return ReportingService.getReasonText(reasonEnum);
    } catch (e) {
      return reason;
    }
  }

  String _getStatusText(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.investigating:
        return 'Investigating';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }
}
