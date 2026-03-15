// lib/features/profile/screens/friends_list_page.dart
//
// Full friends list page — neon-styled, searchable, with unfriend action.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/providers/friend_providers.dart';
import '../../../shared/models/friend_request.dart';
import '../../../core/design_system/design_constants.dart';
import '../../../shared/widgets/club_background.dart';
import '../../../core/analytics/analytics_service.dart';

class FriendsListPage extends ConsumerStatefulWidget {
  /// If [userId] is supplied the list shows that user's friends (read-only).
  final String? userId;

  const FriendsListPage({super.key, this.userId});

  @override
  ConsumerState<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends ConsumerState<FriendsListPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'screen_friends_list');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final targetUid = widget.userId ?? currentUid;
    final isOwnList = targetUid == currentUid;

    final friendsAsync = isOwnList
        ? ref.watch(myFriendsProvider)
        : ref.watch(friendsOfUserProvider(targetUid));

    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: DesignColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'FRIENDS',
            style: TextStyle(
              color: DesignColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 1.5,
            ),
          ),
          actions: [
            if (isOwnList)
              IconButton(
                icon: const Icon(Icons.person_add_alt,
                    color: DesignColors.accent),
                tooltip: 'Find Friends',
                onPressed: () => Navigator.pushNamed(
                    context, '/friend-requests'),
              ),
          ],
        ),
        body: Column(
          children: [
            // ── Search bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search friends…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1F2E),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── List ───────────────────────────────────────────────────────
            Expanded(
              child: friendsAsync.when(
                data: (friends) {
                  final filtered = _query.isEmpty
                      ? friends
                      : friends
                          .where((f) =>
                              (f.displayName ?? '').toLowerCase().contains(_query))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline,
                              size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          Text(
                            _query.isNotEmpty
                                ? 'No friends match "$_query"'
                                : 'No friends yet',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 16),
                          ),
                          if (_query.isEmpty && isOwnList) ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/friend-requests'),
                              icon: const Icon(Icons.person_add_alt,
                                  color: DesignColors.accent),
                              label: const Text('Find Friends',
                                  style:
                                      TextStyle(color: DesignColors.accent)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: Colors.white10,
                      indent: 72,
                    ),
                    itemBuilder: (context, i) =>
                        _FriendTile(
                      friend: filtered[i],
                      isOwnList: isOwnList,
                      onUnfriend: () async {
                        await ref
                            .read(unfriendProvider(filtered[i].uid).future);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Friend removed'),
                                behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: DesignColors.accent),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.white54)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Friend tile ───────────────────────────────────────────────────────────────

class _FriendTile extends StatelessWidget {
  final FriendEntry friend;
  final bool isOwnList;
  final VoidCallback onUnfriend;

  const _FriendTile({
    required this.friend,
    required this.isOwnList,
    required this.onUnfriend,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () =>
          Navigator.pushNamed(context, '/profile/${friend.uid}'),
      leading: _Avatar(
          url: friend.avatarUrl,
          name: friend.displayName ?? '?'),
      title: Text(
        friend.displayName ?? 'Unknown User',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Friends since ${_fmt(friend.since)}',
        style:
            const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: isOwnList
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white38),
              color: const Color(0xFF1A1F2E),
              onSelected: (value) {
                if (value == 'unfriend') onUnfriend();
                if (value == 'message') {
                  Navigator.pushNamed(context, '/chat',
                      arguments: {'userId': friend.uid});
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'message',
                    child: Row(children: [
                      Icon(Icons.chat_bubble_outline,
                          color: DesignColors.accent, size: 18),
                      SizedBox(width: 10),
                      Text('Message',
                          style: TextStyle(color: Colors.white70)),
                    ])),
                const PopupMenuItem(
                    value: 'unfriend',
                    child: Row(children: [
                      Icon(Icons.person_remove_outlined,
                          color: Colors.redAccent, size: 18),
                      SizedBox(width: 10),
                      Text('Unfriend',
                          style: TextStyle(color: Colors.redAccent)),
                    ])),
              ],
            )
          : null,
    );
  }

  String _fmt(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Avatar widget ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;

  const _Avatar({this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(url!),
        backgroundColor: DesignColors.accent20,
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: DesignColors.accent20,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: DesignColors.accent, fontWeight: FontWeight.bold),
      ),
    );
  }
}
