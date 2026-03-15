import 'package:flutter/material.dart';

class ContributionBadgeWidget extends StatelessWidget {
  final String userId;
  const ContributionBadgeWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Stubbed badge UI
    return const Chip(
      label: Text('Top Contributor'),
      avatar: Icon(Icons.star),
    );
  }
}
