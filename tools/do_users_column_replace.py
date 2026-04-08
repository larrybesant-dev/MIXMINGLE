#!/usr/bin/env python3
"""Replace VerticalDivider + SizedBox(sidebar) in live_room_screen.dart
   with a separate order-aware users Positioned widget."""

FILE = r'C:\MixVy\lib\presentation\screens\live_room_screen.dart'

with open(FILE, encoding='utf-8') as f:
    content = f.read()

# ── Find the section to replace ───────────────────────────────────────
START = '                        const VerticalDivider(\n'
END_MARKER = '                  if (_giftToasts.isNotEmpty)'

start_idx = content.find(START)
end_idx   = content.find(END_MARKER, start_idx)

if start_idx < 0 or end_idx < 0:
    print('ERROR: markers not found', start_idx, end_idx)
    raise SystemExit(1)

old_section = content[start_idx : end_idx + len(END_MARKER)]
print(f'Replacing {len(old_section)} chars at [{start_idx}:{end_idx+len(END_MARKER)}]')

# ── Build the replacement ─────────────────────────────────────────────
# Exact same _RoomRosterSidebar params as before, but wrapped in
# a proper order-aware users Positioned instead of SizedBox(200).
new_section = '''\
                      ],
                    ),
                    ),
                  ),
                  // ── USERS COLUMN (order-aware) ────────────────────────────
                  Positioned(
                    left: colLeft('users'),
                    top: 0,
                    bottom: 0,
                    width: kUsersW,
                    child: ColoredBox(
                      color: const Color(0xFF161A21),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // AppBar + ticker spacer so content starts below bar
                        SizedBox(
                            height: roomDescription.isEmpty
                                ? kToolbarHeight
                                : kToolbarHeight + 24),
                        // 32 px header row with ◄ ► move buttons
                        Container(
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1C2028),
                            border: Border(
                              left: BorderSide(
                                  color: Color(0xFF2E2F3A), width: 1),
                            ),
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline,
                                  size: 14, color: Color(0xFFBA9EFF)),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text('Users',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                              panelMoveBtn('users', -1,
                                  tooltip: 'Move Users left',
                                  icon: Icons.chevron_left),
                              panelMoveBtn('users', 1,
                                  tooltip: 'Move Users right',
                                  icon: Icons.chevron_right),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _RoomRosterSidebar(
                            topPadding: 0,
                            participants: participantsInRoom,
                            displayNameById: Map.unmodifiable(
                                _senderDisplayNameById),
                            vipLevelById: Map.unmodifiable(
                                _senderVipLevelById),
                            genderById: Map.unmodifiable(
                                _senderGenderById),
                            currentUserId: user.id,
                            presenceList:
                                presenceAsync.valueOrNull ?? const [],
                            pendingMicCount: micRequestsAsync.valueOrNull
                                    ?.where((r) => r.status == 'pending')
                                    .length ??
                                0,
                            currentUserRole: participantsInRoom
                                    .firstWhere(
                                      (p) => p.userId == user.id,
                                      orElse: () => RoomParticipantModel(
                                        userId: user.id,
                                        role: 'member',
                                        joinedAt: DateTime.now(),
                                        lastActiveAt: DateTime.now(),
                                      ),
                                    )
                                    .role,
                            isMicFree: !participantsInRoom
                                    .any((p) => p.role == 'stage' && p.userId != user.id),
                            isLocalVideoEnabled: _isVideoEnabled,
                            localSpeaking:
                                (_agoraService?.localSpeaking ?? false) ||
                                (!_isMicMuted &&
                                  participantsInRoom.any((p) =>
                                      p.userId == user.id && p.role == 'stage')),
                            recentChatters: Set.unmodifiable(_recentChatters),
                            remoteUids:
                                _agoraService?.remoteUids ?? const [],
                            isSpeakingFn: (uid) =>
                                _agoraService?.isRemoteSpeaking(uid) ??
                                false,
                            uidToUserId: (uid) =>
                                _userIdForRtcUid(uid, participantsInRoom),
                            onReleaseMic: () async {
                              try {
                                await micAccessController.releaseMic(
                                  roomId: widget.roomId,
                                  userId: user.id,
                                );
                                final svc = _agoraService;
                                if (svc != null && _isCallReady && !_isMicMuted) {
                                  await svc.mute(true);
                                  if (mounted) setState(() => _isMicMuted = true);
                                }
                                if (mounted) _showSnackBar('Mic released.');
                              } catch (e) {
                                if (mounted) _showSnackBar('Could not release mic: $e');
                              }
                            },
                            onJoinQueue: allowMicRequests
                                ? () async {
                                    final micFree = !participantsInRoom
                                            .any((p) => p.role == 'stage' && p.userId != user.id);
                                    try {
                                      if (micFree) {
                                        await micAccessController
                                            .grabMicDirectly(
                                          roomId: widget.roomId,
                                          userId: user.id,
                                        );
                                        if (mounted) {
                                          _showSnackBar('You have the mic!');
                                        }
                                      } else {
                                        await micAccessController
                                            .requestAccess(
                                          roomId: widget.roomId,
                                          requesterId: user.id,
                                          hostId: hostId,
                                        );
                                        if (mounted) {
                                          _showSnackBar('Mic request sent!');
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        _showSnackBar(
                                            'Could not join queue: $e');
                                      }
                                    }
                                  }
                                : null,
                            onWhisper: (p) async {
                              final currentUser = ref.read(userProvider);
                              if (currentUser == null) return;
                              try {
                                final conversationId = await ref
                                    .read(messagingControllerProvider)
                                    .createDirectConversation(
                                      userId1: currentUser.id,
                                      user1Name: currentUser.username,
                                      user1AvatarUrl: currentUser.avatarUrl,
                                      userId2: p.userId,
                                      user2Name: _senderDisplayNameById[p.userId] ?? p.userId,
                                      user2AvatarUrl: _senderAvatarUrlById[p.userId],
                                    );
                                if (!context.mounted) return;
                                FloatingWhisperPanel.show(
                                  context,
                                  ref,
                                  conversationId: conversationId,
                                  peerName:
                                      _senderDisplayNameById[p.userId] ??
                                          p.userId,
                                  peerAvatarUrl:
                                      _senderAvatarUrlById[p.userId],
                                );
                              } catch (e) {
                                _showSnackBar('Could not open whisper: $e');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                  if (_giftToasts.isNotEmpty)'''

# ── Perform the replacement ───────────────────────────────────────────
new_content = content[:start_idx] + new_section + content[end_idx + len(END_MARKER):]
print(f'New file size: {len(new_content)} (was {len(content)})')

with open(FILE, 'w', encoding='utf-8', newline='\n') as f:
    f.write(new_content)

print('Done. File written successfully.')
