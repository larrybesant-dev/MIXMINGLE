import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContentModerationPage extends ConsumerWidget {
  const ContentModerationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Content Moderation')),
      body: ListView(
        children: const [
          ModerationSection(collection: 'stories', sectionTitle: 'Stories'),
          ModerationSection(collection: 'short_videos', sectionTitle: 'Short Videos'),
          ModerationSection(collection: 'posts', sectionTitle: 'Posts'),
        ],
      ),
    );
  }
}

/// Moderation section for a Firestore collection
class ModerationSection extends StatelessWidget {
  final String collection;
  final String sectionTitle;
  const ModerationSection({required this.collection, required this.sectionTitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sectionTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(collection)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No pending items');
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final content = data['content'] ?? '[No content]';
                    return ListTile(
                      title: Text(content),
                      subtitle: Text('ID: ${doc.id}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _moderate(doc.reference, 'approved', context),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _moderate(doc.reference, 'rejected', context),
                            tooltip: 'Reject',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _moderate(DocumentReference ref, String status, BuildContext context) async {
    try {
      await ref.update({'status': status});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item ${status == 'approved' ? 'approved' : 'rejected'}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
