import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixmingle/core/responsive/responsive_utils.dart';
import 'package:mixmingle/core/animations/app_animations.dart';
import 'package:mixmingle/shared/providers/all_providers.dart';
import 'package:mixmingle/core/routing/app_routes.dart';
import 'package:mixmingle/shared/widgets/club_background.dart';
import 'package:mixmingle/shared/widgets/async_value_view_enhanced.dart';
import 'package:mixmingle/shared/widgets/skeleton_loaders.dart';
import 'package:mixmingle/shared/models/match.dart';
import 'package:mixmingle/shared/models/user_profile.dart';

class MatchesPage extends ConsumerStatefulWidget {
  const MatchesPage({super.key});

  @override
  ConsumerState<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends ConsumerState<MatchesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Matches'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Matches'),
              Tab(text: 'Incoming'),
              Tab(text: 'Outgoing'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMatchesTab(),
            _buildIncomingTab(),
            _buildOutgoingTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'discover_fab',
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.matchDiscovery);
          },
          icon: const Icon(Icons.explore),
          label: const Text('Discover'),
        ),
      ),
    );
  }

  // ── Tab 1: Active Matches ────────────────────────────────────────────────

  Widget _buildMatchesTab() {
    final matchesAsync = ref.watch(matchInboxProvider);

    return AsyncValueViewEnhanced(
      value: matchesAsync,
      maxRetries: 3,
      skeleton: const SkeletonGrid(itemCount: 6, crossAxisCount: 2),
      screenName: 'MatchesPage',
      providerName: 'matchInboxProvider',
      onRetry: () => ref.invalidate(matchInboxProvider),
      data: (matches) {
        if (matches.isEmpty) {
          return _buildEmptyState(
            context,
            'No matches yet',
            'Start discovering to find your perfect match!',
            Icons.favorite_border,
          );
        }

        return AppAnimations.fadeIn(
          child: GridView.builder(
            padding: Responsive.responsivePadding(context),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.responsiveValue(
                context: context,
                mobile: 2,
                tablet: 3,
                desktop: 4,
              ),
              crossAxisSpacing: Responsive.responsiveSpacing(context, 16),
              mainAxisSpacing: Responsive.responsiveSpacing(context, 16),
              childAspectRatio: 0.75,
            ),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return AppAnimations.scaleIn(
                beginScale: 0.8,
                child: _buildMatchCard(context, match),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(BuildContext context, Match match) {
    final currentUid = ref.read(currentUserProvider).value?.id;
    final otherUserId =
        match.user1Id == currentUid ? match.user2Id : match.user1Id;
    final userProfileAsync = ref.watch(userProfileProvider(otherUserId));

    return userProfileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final displayName =
            profile.displayName ?? profile.nickname ?? 'Anonymous';
        final photoUrl = profile.photoUrl;
        final isOnline = profile.presenceStatus == 'online';

        // Example fields: match.isUnread, match.isRead, match.lastMessage, match.lastMessageTimestamp
        final isUnread = (match as dynamic).isUnread == true;
        final isRead = (match as dynamic).isRead == true;
        final lastMessage = (match as dynamic).lastMessage;
        final lastMessageTimestamp = (match as dynamic).lastMessageTimestamp;
        final now = DateTime.now();
        String formattedTimestamp = '';
        if (lastMessageTimestamp is DateTime) {
          final diff = now.difference(lastMessageTimestamp);
          if (diff.inMinutes < 60) {
            formattedTimestamp = '${diff.inMinutes}m ago';
          } else if (diff.inHours < 24) {
            formattedTimestamp = '${diff.inHours}h ago';
          } else if (diff.inDays == 1) {
            formattedTimestamp = 'Yesterday';
          } else if (diff.inDays < 7) {
            formattedTimestamp = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"][lastMessageTimestamp.weekday-1];
          } else {
            formattedTimestamp = '${lastMessageTimestamp.month}/${lastMessageTimestamp.day}';
          }
        }
        return Card(
          clipBehavior: Clip.antiAlias,
          color: isRead ? Theme.of(context).colorScheme.surface.withOpacity(0.7) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // "It's a Match!" badge
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: Theme.of(context).colorScheme.secondary, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      "It's a Match!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'New',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photoUrl != null
                        ? Image.network(photoUrl, fit: BoxFit.cover)
                        : Container(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person,
                              size: Responsive.responsiveIconSize(context, 60),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                    // Subtle neon 'Matched' badge (always available in this context)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Matched',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Theme.of(context).colorScheme.secondary,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: Responsive.responsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Last message or hint
                    Row(
                      children: [
                        Expanded(
                          child: lastMessage != null && lastMessage.toString().isNotEmpty
                              ? Text(
                                  lastMessage.toString(),
                                  style: TextStyle(
                                    color: isUnread
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : Text(
                                  'Say hi 👋',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                        if (formattedTimestamp.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              formattedTimestamp,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Match prompt with actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Start Chat'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(90, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.chat,
                              arguments: {
                                'userId': otherUserId,
                                'username': displayName,
                              },
                            );
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: const Text('View Profile'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(90, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.profile,
                              arguments: {
                                'userId': otherUserId,
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Card(child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── Tab 2: Incoming Likes ─────────────────────────────────────────────────

  Widget _buildIncomingTab() {
    final likesAsync = ref.watch(incomingLikesProvider);

    return AsyncValueViewEnhanced(
      value: likesAsync,
      maxRetries: 3,
      skeleton: const SkeletonList(itemCount: 5, showAvatar: true),
      screenName: 'MatchesPage',
      providerName: 'incomingLikesProvider',
      onRetry: () => ref.invalidate(incomingLikesProvider),
      data: (profiles) {
        if (profiles.isEmpty) {
          return _buildEmptyState(
            context,
            'No incoming likes',
            'People who like you will appear here',
            Icons.thumb_up_outlined,
          );
        }

        return ListView.builder(
          padding: Responsive.responsivePadding(context),
          itemCount: profiles.length,
          itemBuilder: (context, index) =>
              _buildIncomingLikeTile(context, profiles[index]),
        );
      },
    );
  }

<<<<<<< HEAD
  Widget _buildIncomingLikeTile(BuildContext context, UserProfile profile) {
    final displayName = profile.displayName ?? profile.nickname ?? 'Anonymous';
    final photoUrl = profile.photoUrl;
    final service = ref.read(matchServiceProvider);
    final currentUid = ref.read(currentUserProvider).value?.id ?? '';

    return Card(
      margin: EdgeInsets.only(
          bottom: Responsive.responsiveSpacing(context, 12)),
      child: Padding(
        padding: Responsive.responsivePadding(context),
        child: Row(
          children: [
            CircleAvatar(
              radius: Responsive.responsiveValue(
                  context: context,
                  mobile: 28.0,
                  tablet: 32.0,
                  desktop: 36.0),
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Icons.person,
                      size: Responsive.responsiveIconSize(context, 28))
                  : null,
            ),
            SizedBox(width: Responsive.responsiveSpacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize:
                          Responsive.responsiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
=======
  Widget _buildMatchCard(BuildContext context, Match match) {
    final otherUserId = match.user1Id == ref.read(currentUserProvider).value?.id
        ? match.user2Id
        : match.user1Id;
    final userProfileAsync = ref.watch(userProfileProvider(otherUserId));

    return userProfileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.chat,
                arguments: {
                  'userId': otherUserId,
                  'username': profile.username,
                },
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      profile.profileImageUrl != null
                          ? Image.network(
                              profile.profileImageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                Icons.person,
                                size:
                                    Responsive.responsiveIconSize(context, 60),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                      if (profile.isOnline)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
>>>>>>> origin/develop
                  ),
                  if (profile.bio != null)
                    Text(
                      profile.bio!,
                      style: TextStyle(
                        fontSize:
                            Responsive.responsiveFontSize(context, 13),
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
<<<<<<< HEAD
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(width: Responsive.responsiveSpacing(context, 8)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decline
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  tooltip: 'Decline',
                  onPressed: () async {
                    try {
                      await service.declineMatch(currentUid, profile.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Could not decline: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
                // Accept
                IconButton(
                  icon: Icon(Icons.favorite,
                      color:
                          Theme.of(context).colorScheme.primary),
                  tooltip: 'Accept',
                  onPressed: () async {
                    try {
                      await service.acceptMatch(currentUid, profile.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "🎉 Matched with $displayName!")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Could not accept: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
=======
                      if (profile.age != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${profile.age} years old',
                          style: TextStyle(
                            fontSize:
                                Responsive.responsiveFontSize(context, 12),
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLikeCard(BuildContext context, Match like) {
    final otherUserId = like.user1Id == ref.read(currentUserProvider).value?.id
        ? like.user2Id
        : like.user1Id;
    final userProfileAsync = ref.watch(userProfileProvider(otherUserId));

    return userProfileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        return Card(
          margin: EdgeInsets.only(
            bottom: Responsive.responsiveSpacing(context, 12),
          ),
          child: Padding(
            padding: Responsive.responsivePadding(context),
            child: Row(
              children: [
                CircleAvatar(
                  radius: Responsive.responsiveValue(
                    context: context,
                    mobile: 30.0,
                    tablet: 35.0,
                    desktop: 40.0,
                  ),
                  backgroundImage: profile.profileImageUrl != null
                      ? NetworkImage(profile.profileImageUrl!)
                      : null,
                  child: profile.profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: Responsive.responsiveIconSize(context, 30),
                        )
                      : null,
                ),
                SizedBox(width: Responsive.responsiveSpacing(context, 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.username ?? 'User',
                        style: TextStyle(
                          fontSize: Responsive.responsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (profile.bio != null)
                        Text(
                          profile.bio!,
                          style: TextStyle(
                            fontSize:
                                Responsive.responsiveFontSize(context, 14),
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                SizedBox(width: Responsive.responsiveSpacing(context, 16)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () async {
                        await ref
                            .read(matchControllerProvider.notifier)
                            .reject(otherUserId);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () async {
                        await ref
                            .read(matchControllerProvider.notifier)
                            .accept(otherUserId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text('Loading...'),
>>>>>>> origin/develop
        ),
      ),
    );
  }

  // ── Tab 3: Outgoing Likes ─────────────────────────────────────────────────

  Widget _buildOutgoingTab() {
    final outgoingAsync = ref.watch(outgoingLikesProvider);

    return AsyncValueViewEnhanced(
      value: outgoingAsync,
      maxRetries: 3,
      skeleton: const SkeletonList(itemCount: 5, showAvatar: true),
      screenName: 'MatchesPage',
      providerName: 'outgoingLikesProvider',
      onRetry: () => ref.invalidate(outgoingLikesProvider),
      data: (profiles) {
        if (profiles.isEmpty) {
          return _buildEmptyState(
            context,
            'No outgoing likes',
            'Profiles you\'ve liked will appear here',
            Icons.send_outlined,
          );
        }

        return ListView.builder(
          padding: Responsive.responsivePadding(context),
          itemCount: profiles.length,
          itemBuilder: (context, index) =>
              _buildOutgoingLikeTile(context, profiles[index]),
        );
      },
    );
  }

  Widget _buildOutgoingLikeTile(BuildContext context, UserProfile profile) {
    final displayName = profile.displayName ?? profile.nickname ?? 'Anonymous';
    final photoUrl = profile.photoUrl;
    final service = ref.read(matchServiceProvider);
    final currentUid = ref.read(currentUserProvider).value?.id ?? '';
    final isOnline = profile.presenceStatus == 'online';

    return Card(
      margin: EdgeInsets.only(
          bottom: Responsive.responsiveSpacing(context, 12)),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: Responsive.responsiveValue(
                  context: context,
                  mobile: 24.0,
                  tablet: 28.0,
                  desktop: 32.0),
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Icons.person,
                      size: Responsive.responsiveIconSize(context, 24))
                  : null,
            ),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        title: Text(displayName),
        subtitle: profile.bio != null
            ? Text(profile.bio!,
                maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: TextButton.icon(
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Withdraw'),
          style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent),
          onPressed: () async {
            try {
              await service.unlikeUser(currentUid, profile.id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Could not withdraw: ${e.toString()}')),
                );
              }
            }
          },
        ),
        onTap: () => Navigator.of(context)
            .pushNamed(AppRoutes.userProfile, arguments: profile.id),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding: Responsive.responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: Responsive.responsiveIconSize(context, 80),
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 24)),
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 16),
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, 32)),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(AppRoutes.matchDiscovery);
              },
              icon: const Icon(Icons.explore),
              label: const Text('Start Discovering'),
            ),
          ],
        ),
      ),
    );
  }
}
