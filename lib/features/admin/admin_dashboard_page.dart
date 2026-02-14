import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mix_and_mingle/shared/models/report.dart' show ReportType;
import 'package:mix_and_mingle/shared/models/moderation.dart' show UserReport;
import 'package:mix_and_mingle/shared/widgets/club_background.dart';
import 'package:mix_and_mingle/shared/widgets/glow_text.dart';
import 'package:mix_and_mingle/providers/all_providers.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final moderationService = ref.watch(moderationServiceProvider);

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const GlowText(
            text: 'Admin Dashboard',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            glowColor: Color(0xFFFF4C4C),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Reports', '0', Icons.flag)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Pending', '0', Icons.pending)),
                ],
              ),
              const SizedBox(height: 24),

              // Pending Reports
              const GlowText(
                text: 'Pending Reports',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              const SizedBox(height: 12),

              FutureBuilder<List<UserReport>>(
                future: moderationService.getPendingReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final reports = snapshot.data ?? [];
                  if (reports.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No pending reports'),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: reports.map((report) => _buildReportCard(report)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.white.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF4C4C), size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(UserReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getReportTypeColor(report.type),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getReportTypeLabel(report.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(report.createdAt),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reporter: ${report.reporterId}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            Text(
              'Reported User: ${report.reportedUserId}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            if (report.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                report.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewReport(report, 'resolved'),
                    icon: const Icon(Icons.check),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _reviewReport(report, 'reviewed'),
                    icon: const Icon(Icons.close),
                    label: const Text('Dismiss'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getReportTypeColor(ReportType type) {
    switch (type) {
      case ReportType.spam:
        return Colors.orange;
      case ReportType.harassment:
        return Colors.red;
      case ReportType.inappropriateContent:
        return Colors.purple;
      case ReportType.hateSpeech:
        return Colors.red[900]!;
      case ReportType.violence:
        return Colors.red[700]!;
      case ReportType.scam:
        return Colors.amber;
      case ReportType.other:
        return Colors.grey;
    }
  }

  String _getReportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.spam:
        return 'SPAM';
      case ReportType.harassment:
        return 'HARASSMENT';
      case ReportType.inappropriateContent:
        return 'INAPPROPRIATE';
      case ReportType.hateSpeech:
        return 'HATE SPEECH';
      case ReportType.violence:
        return 'VIOLENCE';
      case ReportType.scam:
        return 'SCAM';
      case ReportType.other:
        return 'OTHER';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _reviewReport(UserReport report, String status) async {
    try {
      final moderationService = ref.read(moderationServiceProvider);
      final currentUser = ref.read(authServiceProvider).currentUser;
      await moderationService.reviewReport(report.id, currentUser?.uid ?? 'admin', status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report $status')),
        );
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

