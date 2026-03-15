// Basic UI widget for Feedback submission
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feedback_provider.dart';

class FeedbackWidget extends ConsumerWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text('Submit Feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: 'Your feedback'),
        ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            final message = _controller.text;
            if (message.isNotEmpty) {
              final feedbackList = ref.read(feedbackProvider.notifier);
              feedbackList.state = [
                ...feedbackList.state,
                FeedbackItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: 'currentUser', // Replace with actual user ID
                  message: message,
                  timestamp: DateTime.now(),
                ),
              ];
              _controller.clear();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback submitted')));
            }
          },
          child: Text('Submit'),
        ),
      ],
    );
  }
}
