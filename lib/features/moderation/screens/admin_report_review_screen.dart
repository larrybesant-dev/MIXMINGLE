import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/report_service.dart';

class AdminReportReviewScreen extends StatefulWidget {
  final String adminId;

  const AdminReportReviewScreen({
    super.key,
    required this.adminId,
  });

  @override
  State<AdminReportReviewScreen> createState() =>
      _AdminReportReviewScreenState();
}

class _AdminReportReviewScreenState extends State<AdminReportReviewScreen> {
  final ReportService _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Review'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reportService.streamOpenReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final reports = snapshot.data?.docs ?? [];

          if (reports.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No open reports'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final data = report.data() as Map<String, dynamic>;
              return _ReportCard(
                reportId: report.id,
                data: data,
                adminId: widget.adminId,
                reportService: _reportService,
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> data;
  final String adminId;
  final ReportService reportService;

  const _ReportCard({
    required this.reportId,
    required this.data,
    required this.adminId,
    required this.reportService,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _isExpanded = false;
  bool _isLoading = false;

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _markAsReviewed() async {
    setState(() => _isLoading = true);
    try {
      await widget.reportService.updateReportStatus(
        reportId: widget.reportId,
        status: 'reviewed',
        reviewedBy: widget.adminId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report marked as reviewed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _isLoading = true);
    try {
      await widget.reportService.updateReportStatus(
        reportId: widget.reportId,
        status: 'dismissed',
        reviewedBy: widget.adminId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report dismissed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _banUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: Text(
          'Are you sure you want to ban user ${widget.data['reportedUserId']}? This action cannot be easily undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ban User'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await widget.reportService.banUser(
          userId: widget.data['reportedUserId'],
          bannedBy: widget.adminId,
          reason: widget.data['reason'] ?? 'Reported by users',
        );
        await widget.reportService.updateReportStatus(
          reportId: widget.reportId,
          status: 'reviewed',
          reviewedBy: widget.adminId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User banned and report marked as reviewed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.flag, color: Colors.white),
            ),
            title: Text(
              widget.data['reason'] ?? 'No reason',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Reported: ${widget.data['reportedUserId'] ?? 'Unknown'}',
            ),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow('Reporter ID', widget.data['reporterId'] ?? 'Unknown'),
                  _DetailRow('Reported User ID', widget.data['reportedUserId'] ?? 'Unknown'),
                  if (widget.data['roomId'] != null)
                    _DetailRow('Room ID', widget.data['roomId']),
                  _DetailRow('Reason', widget.data['reason'] ?? 'None'),
                  _DetailRow('Timestamp', _formatTimestamp(widget.data['timestamp'])),
                  const SizedBox(height: 8),
                  const Text(
                    'Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.data['details']?.isNotEmpty == true
                          ? widget.data['details']
                          : 'No additional details provided',
                      style: TextStyle(
                        color: widget.data['details']?.isNotEmpty == true
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _dismiss,
                            child: const Text('Dismiss'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _markAsReviewed,
                            child: const Text('Mark Reviewed'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _banUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ban'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
