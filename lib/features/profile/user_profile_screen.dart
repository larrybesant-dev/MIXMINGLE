import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final username = (data['username'] as String?)?.trim();
          final avatarUrl = (data['avatarUrl'] as String?)?.trim();
          final bio = (data['bio'] as String?)?.trim();
          final introVideoUrl = (data['introVideoUrl'] as String?)?.trim();
          final galleryUrls = List<String>.from(data['galleryUrls'] ?? const []);
          final vibePrompt = (data['vibePrompt'] as String?)?.trim();
          final firstDatePrompt = (data['firstDatePrompt'] as String?)?.trim();
          final musicTastePrompt = (data['musicTastePrompt'] as String?)?.trim();
          final interests = List<String>.from(data['interests'] ?? const []);
          final followers = List<String>.from(data['followers'] ?? const []);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                avatarUrl,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 34),
                              ),
                            )
                          : const Icon(Icons.person, size: 34),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (username == null || username.isEmpty) ? 'MixVy user' : username,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Live social creator',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _PublicStatTile(label: 'Followers', value: '${followers.length}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PublicStatTile(label: 'Interests', value: '${interests.length}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (bio != null && bio.isNotEmpty) ...[
                Text('Bio', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(bio, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
              ],
              if (introVideoUrl != null && introVideoUrl.isNotEmpty) ...[
                Text('Intro Video', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill_rounded),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Intro video available')),
                      TextButton(
                        onPressed: () async {
                          final uri = Uri.tryParse(introVideoUrl);
                          if (uri == null) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid intro video URL.')),
                            );
                            return;
                          }

                          final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open intro video.')),
                            );
                          }
                        },
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (galleryUrls.isNotEmpty) ...[
                Text('Photo Gallery', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: galleryUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final url = galleryUrls[index].trim();
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 110,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if ((vibePrompt ?? '').isNotEmpty || (firstDatePrompt ?? '').isNotEmpty || (musicTastePrompt ?? '').isNotEmpty) ...[
                Text('Prompts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if ((vibePrompt ?? '').isNotEmpty)
                  _PromptCard(title: 'Vibe', content: vibePrompt!),
                if ((firstDatePrompt ?? '').isNotEmpty)
                  _PromptCard(title: 'Ideal First Date', content: firstDatePrompt!),
                if ((musicTastePrompt ?? '').isNotEmpty)
                  _PromptCard(title: 'Music Taste', content: musicTastePrompt!),
                const SizedBox(height: 8),
              ],
              if (interests.isNotEmpty) ...[
                Text('Interests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests
                      .take(12)
                      .map((interest) => Chip(label: Text(interest), side: BorderSide.none))
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String title;
  final String content;

  const _PromptCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
}

class _PublicStatTile extends StatelessWidget {
  final String label;
  final String value;

  const _PublicStatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
