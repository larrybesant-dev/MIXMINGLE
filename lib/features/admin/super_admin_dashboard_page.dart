// lib/features/admin/super_admin_dashboard_page.dart
//
// SuperAdmin-only dashboard for global platform governance.
// Accessible via AppRoutes.superAdminDashboard (/admin/super).
//
// Tabs:
//   1. Rooms       — view all rooms, assign/remove room admins
//   2. Users       — view/search users, assign global roles
//   3. Mod Logs    — cross-room moderation activity feed

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/role_service.dart';
import '../../core/services/room_permission_service.dart';
import '../../shared/widgets/club_background.dart';
import '../../shared/widgets/glow_text.dart';

class SuperAdminDashboardPage extends ConsumerStatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  ConsumerState<SuperAdminDashboardPage> createState() =>
      _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState
    extends ConsumerState<SuperAdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClubBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF12082A),
          elevation: 0,
          title: const GlowText(
            text: '👑 SuperAdmin',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            glowColor: Color(0xFFFFD700),
          ),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFFFFD700),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(icon: Icon(Icons.meeting_room, size: 18), text: 'Rooms'),
              Tab(icon: Icon(Icons.people, size: 18), text: 'Users'),
              Tab(icon: Icon(Icons.history, size: 18), text: 'Mod Logs'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: const [
            _RoomsAdminTab(),
            _UsersAdminTab(),
            _GlobalModLogsTab(),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// TAB 1 — Rooms
// ===========================================================================

class _RoomsAdminTab extends StatelessWidget {
  const _RoomsAdminTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('No active rooms.',
                  style: TextStyle(color: Colors.white54)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              const Divider(color: Color(0xFF2A1A3E), height: 8),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final roomId = docs[i].id;
            final title = data['title'] as String? ?? roomId;
            final admins =
                List<String>.from(data['admins'] ?? []);
            return ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 8),
              title: Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14)),
              subtitle: Text(
                'Admins: ${admins.length}  •  Owner: ${(data['ownerId'] ?? '').toString().substring(0, 8)}…',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: Colors.white38),
              children: [
                _RoomAdminManager(roomId: roomId, admins: admins),
              ],
            );
          },
        );
      },
    );
  }
}

class _RoomAdminManager extends StatefulWidget {
  const _RoomAdminManager(
      {required this.roomId, required this.admins});
  final String roomId;
  final List<String> admins;

  @override
  State<_RoomAdminManager> createState() => _RoomAdminManagerState();
}

class _RoomAdminManagerState extends State<_RoomAdminManager> {
  final _uidController = TextEditingController();

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) return;
    await RoomPermissionService().addRoomAdmin(widget.roomId, uid);
    _uidController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Admin added'),
            backgroundColor: Color(0xFF1A8A4A)),
      );
    }
  }

  Future<void> _remove(String uid) async {
    await RoomPermissionService()
        .removeRoomAdmin(widget.roomId, uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Admin removed'),
            backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.admins.isEmpty)
            const Text('No room admins assigned.',
                style: TextStyle(color: Colors.white38, fontSize: 12))
          else
            ...widget.admins.map((uid) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Expanded(
                        child: Text(uid,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12))),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Color(0xFFFF4C4C), size: 18),
                      tooltip: 'Remove admin',
                      onPressed: () => _remove(uid),
                    ),
                  ]),
                )),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _uidController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'User UID to add as admin',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2A1A3E))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFD700))),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _add,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A8A4A),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text('Add',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ]),
        ],
      ),
    );
  }
}

// ===========================================================================
// TAB 2 — Users
// ===========================================================================

class _UsersAdminTab extends StatefulWidget {
  const _UsersAdminTab();

  @override
  State<_UsersAdminTab> createState() => _UsersAdminTabState();
}

class _UsersAdminTabState extends State<_UsersAdminTab> {
  final _searchController = TextEditingController();
  String _query = '';

  final _roleService = RoleService();

  Stream<QuerySnapshot> get _usersStream {
    final q = FirebaseFirestore.instance
        .collection('users')
        .orderBy('displayName')
        .limit(50);
    return q.snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setRole(String uid, UserRole role) async {
    await _roleService.setUserRole(uid, role);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Role updated to ${role.value}'),
        backgroundColor: const Color(0xFF1A8A4A),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by name or UID…',
              hintStyle:
                  const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white38, size: 18),
              filled: true,
              fillColor: const Color(0xFF1A0A2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _usersStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFFD700)));
              }
              var docs = snap.data?.docs ?? [];
              if (_query.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['displayName'] ?? '').toString().toLowerCase();
                  return name.contains(_query) || d.id.contains(_query);
                }).toList();
              }
              if (docs.isEmpty) {
                return const Center(
                    child: Text('No users found.',
                        style: TextStyle(color: Colors.white54)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Color(0xFF2A1A3E), height: 8),
                itemBuilder: (ctx, i) {
                  final data =
                      docs[i].data() as Map<String, dynamic>;
                  final uid = docs[i].id;
                  final name =
                      data['displayName'] as String? ?? 'Unknown';
                  final role = data['role'] as String? ?? 'user';
                  return ListTile(
                    dense: true,
                    title: Text(name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                    subtitle: Text(uid,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: role,
                        dropdownColor: const Color(0xFF1A0A2E),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                        items: UserRole.values
                            .map((r) => DropdownMenuItem(
                                  value: r.value,
                                  child: Text(r.value),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null && v != role) {
                            _setRole(uid, UserRole.fromString(v));
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// TAB 3 — Global Mod Logs (collectionGroup query)
// ===========================================================================

class _GlobalModLogsTab extends StatelessWidget {
  const _GlobalModLogsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('moderation_logs')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('No moderation logs.',
                  style: TextStyle(color: Colors.white54)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              const Divider(color: Color(0xFF2A1A3E), height: 4),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final action = data['action'] as String? ?? '?';
            final by = (data['performedBy'] ?? '?').toString();
            final target = (data['targetUser'] ?? '?').toString();
            final ts = data['timestamp'] as Timestamp?;
            final when = ts != null
                ? _fmt(ts.toDate())
                : '—';
            return ListTile(
              dense: true,
              leading: _actionIcon(action),
              title: Text(
                '$action → ${target.length > 8 ? target.substring(0, 8) : target}…',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              subtitle: Text(
                'by ${by.length > 8 ? by.substring(0, 8) : by}…  •  $when',
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10),
              ),
            );
          },
        );
      },
    );
  }

  Widget _actionIcon(String action) {
    IconData icon;
    Color color;
    switch (action) {
      case 'kick':
        icon = Icons.logout;
        color = Colors.orangeAccent;
        break;
      case 'ban':
        icon = Icons.block;
        color = const Color(0xFFFF4C4C);
        break;
      case 'mute':
        icon = Icons.mic_off;
        color = Colors.amber;
        break;
      case 'admin_added':
        icon = Icons.shield;
        color = Colors.purpleAccent;
        break;
      case 'admin_removed':
        icon = Icons.shield_outlined;
        color = Colors.white38;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.white38;
    }
    return Icon(icon, color: color, size: 18);
  }

  String _fmt(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
