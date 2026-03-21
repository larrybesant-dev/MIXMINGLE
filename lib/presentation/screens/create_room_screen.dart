import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateRoomScreen extends StatelessWidget {
  const CreateRoomScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final rulesController = TextEditingController();
    final slowModeController = TextEditingController(text: '0');
    bool isLoading = false;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Live Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StatefulBuilder(
          builder: (context, setState) => Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Room Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: rulesController,
                  decoration: const InputDecoration(labelText: 'Rules'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: slowModeController,
                  decoration: const InputDecoration(labelText: 'Slow Mode (seconds)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final n = int.tryParse(v);
                    if (n == null || n < 0) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  child: isLoading ? const CircularProgressIndicator() : const Text('Create Room'),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => isLoading = true);
                          final userId = 'hostId'; // TODO: Replace with real user ID from auth
                          final now = DateTime.now();
                          final slowMode = int.tryParse(slowModeController.text) ?? 0;
                          await FirebaseFirestore.instance.collection('rooms').add({
                            'name': titleController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'rules': rulesController.text.trim(),
                            'hostId': userId,
                            'isLive': true,
                            'isLocked': false,
                            'coHosts': [],
                            'slowModeSeconds': slowMode,
                            'createdAt': Timestamp.fromDate(now),
                            'updatedAt': Timestamp.fromDate(now),
                            'stageUserIds': [userId],
                            'audienceUserIds': [],
                            'memberCount': 1,
                            'category': null,
                            'tags': [],
                            'thumbnailUrl': null,
                          });
                          setState(() => isLoading = false);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
