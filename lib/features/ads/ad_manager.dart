import 'package:flutter/material.dart';
// AdManager handles ad display and user preferences
class AdManager {
  // Show popup ad if user is free
  static bool shouldShowAds(String membershipLevel) {
    return membershipLevel == 'Free';
  }

  // Display ad popup logic
  static void showAdPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ad'),
        content: const Text('This is a demo ad popup.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
