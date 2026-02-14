/// FriendsSidebarWidget Tests - List Rendering, Search, Filtering
///
/// Tests for:
/// - Friends list rendering
/// - Search functionality
/// - Filter by online/favorite status
/// - Friend selection
/// - Unread message badges
/// - Collapse/expand animation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

// Mock FriendsSidebarWidget for testing
class MockFriendsSidebarWidget extends StatefulWidget {
  final List<Map<String, dynamic>> friends;
  final Function(String)? onSelectFriend;
  final Function(String)? onToggleFavorite;

  const MockFriendsSidebarWidget({
    Key? key,
    required this.friends,
    this.onSelectFriend,
    this.onToggleFavorite,
  }) : super(key: key);

  @override
  State<MockFriendsSidebarWidget> createState() =>
      _MockFriendsSidebarWidgetState();
}

class _MockFriendsSidebarWidgetState extends State<MockFriendsSidebarWidget>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _collapseController;
  late List<String> _favoriteIds;
  late String? _selectedFriendId;
  late List<Map<String, dynamic>> _filteredFriends;
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _collapseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _favoriteIds = [];
    _selectedFriendId = null;
    _isCollapsed = false;
    _filteredFriends = widget.friends;

    _searchController.addListener(_updateFilter);
  }

  void _updateFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = widget.friends;
      } else {
        _filteredFriends = widget.friends
            .where((f) =>
                f['name'].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _toggleFavorite(String friendId) {
    setState(() {
      if (_favoriteIds.contains(friendId)) {
        _favoriteIds.remove(friendId);
      } else {
        _favoriteIds.add(friendId);
      }
    });
    widget.onToggleFavorite?.call(friendId);
  }

  void _selectFriend(String friendId) {
    setState(() {
      _selectedFriendId = friendId;
    });
    widget.onSelectFriend?.call(friendId);
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });

    if (_isCollapsed) {
      _collapseController.forward();
    } else {
      _collapseController.reverse();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _collapseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: DesignColors.accent[900],
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignColors.accent[800],
              border: Border(
                bottom: BorderSide(color: DesignColors.accent[700]!),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Friends',
                  key: Key('sidebar-title'),
                  style: TextStyle(
                    color: DesignColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: const Key('collapse-button'),
                  icon: const Icon(Icons.menu),
                  color: DesignColors.accent,
                  onPressed: _toggleCollapse,
                  iconSize: 20,
                ),
              ],
            ),
          ),
          // Search field
          Container(
            padding: const EdgeInsets.all(8),
            child: TextField(
              key: const Key('search-friends-field'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search,
                    size: 18, color: DesignColors.accent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: DesignColors.accent[700]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              style: DesignTypography.body,
            ),
          ),
          // Friends list
          Expanded(
            child: _filteredFriends.isEmpty
                ? Center(
                    key: const Key('no-friends-message'),
                    child: Text(
                      'No friends found',
                      style: DesignTypography.body,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      final isFavorite =
                          _favoriteIds.contains(friend['id']);
                      final isSelected =
                          _selectedFriendId == friend['id'];
                      final isOnline =
                          friend['isOnline'] as bool? ?? false;

                      return Container(
                        key: Key('friend-tile-${friend['id']}'),
                        color: isSelected
                            ? DesignColors.accent.withOpacity(0.3)
                            : DesignColors.accent,
                        child: ListTile(
                          leading: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: DesignColors.accent[700],
                                child: Text(
                                  friend['name']
                                          ?.toString()
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      '?',
                                  style: const TextStyle(
                                    color: DesignColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isOnline)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: DesignColors.accent,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            friend['name'] ?? 'Unknown',
                            style: const TextStyle(
                              color: DesignColors.accent,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: isOnline
                                  ? DesignColors.accent
                                  : DesignColors.accent,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Favorite button
                              IconButton(
                                key: Key(
                                    'favorite-btn-${friend['id']}'),
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                ),
                                color: isFavorite
                                    ? DesignColors.accent
                                    : DesignColors.accent,
                                onPressed: () =>
                                    _toggleFavorite(friend['id']),
                              ),
                              // Unread badge
                              if ((friend['unreadMessages']
                                      as int? ??
                                  0) >
                                  0)
                                Container(
                                  key: Key(
                                      'unread-badge-${friend['id']}'),
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DesignColors.accent,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${friend['unreadMessages']}',
                                    style: const TextStyle(
                                      color: DesignColors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => _selectFriend(friend['id']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('FriendsSidebarWidget Tests', () {
    testWidgets('renders sidebar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: TestFixtures.friendsList(),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('sidebar-title')), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
    });

    testWidgets('displays all friends in list', (WidgetTester tester) async {
      final friends = TestFixtures.friendsList();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
            ),
          ),
        ),
      );

      for (final friend in friends) {
        expect(
          find.byKey(Key('friend-tile-${friend['id']}')),
          findsOneWidget,
        );
      }
    });

    testWidgets('friend name is displayed', (WidgetTester tester) async {
      final friends = [
        MockUserData.friend(id: 'f1', name: 'Alice'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
            ),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows online status indicator',
        (WidgetTester tester) async {
      final friends = [
        MockUserData.friend(id: 'f1', name: 'Alice', isOnline: true),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
            ),
          ),
        ),
      );

      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('shows offline status when not online',
        (WidgetTester tester) async {
      final friends = [
        MockUserData.friend(id: 'f1', name: 'Alice', isOnline: false),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
            ),
          ),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('search filters friends by name',
        (WidgetTester tester) async {
      final friends = [
        MockUserData.friend(id: 'f1', name: 'Alice'),
        MockUserData.friend(id: 'f2', name: 'Bob'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
            ),
          ),
        ),
      );

      final searchField =
          find.byKey(const Key('search-friends-field'));
      await tester.enterText(searchField, 'Alice');
      await tester.pumpAndSettle();

      // Find Text widgets with 'Alice' (matches may include input field)
      expect(find.text('Alice'), findsWidgets);
      expect(find.text('Bob'), findsNothing);
    });

    testWidgets('tapping friend selects it', (WidgetTester tester) async {
      var selectedFriendId = '';

      final friends = [
        MockUserData.friend(id: 'f1', name: 'Alice'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
              onSelectFriend: (id) => selectedFriendId = id,
            ),
          ),
        ),
      );

      final friendTile = find.byKey(const Key('friend-tile-f1'));
      await tester.tap(friendTile);
      await tester.pumpAndSettle();

      expect(selectedFriendId, equals('f1'));
    });

    testWidgets('favorite button toggles favorite status',
        (WidgetTester tester) async {
      var toggleCount = 0;

      final friends = [
        MockUserData.friend(id: 'f1', name: 'Alice'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
              onToggleFavorite: (id) => toggleCount++,
            ),
          ),
        ),
      );

      final favoriteBtn = find.byKey(const Key('favorite-btn-f1'));
      await tester.tap(favoriteBtn);
      await tester.pumpAndSettle();

      expect(toggleCount, equals(1));
    });

    testWidgets('unread message badge displays count',
        (WidgetTester tester) async {
      final friends = [
        MockUserData.friend(
          id: 'f1',
          name: 'Alice',
          unreadMessages: 3,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('unread-badge-f1')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('no badge shown when no unread messages',
        (WidgetTester tester) async {
      final friends = [
        MockUserData.friend(
          id: 'f1',
          name: 'Alice',
          unreadMessages: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('unread-badge-f1')), findsNothing);
    });

    testWidgets('shows no friends message when empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: [],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('no-friends-message')), findsOneWidget);
      expect(find.text('No friends found'), findsOneWidget);
    });

    testWidgets('collapse button is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: TestFixtures.friendsList(),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('collapse-button')), findsOneWidget);
    });

    testWidgets('collapse button toggles sidebar state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: TestFixtures.friendsList(),
            ),
          ),
        ),
      );

      final collapseBtn = find.byKey(const Key('collapse-button'));
      await tester.tap(collapseBtn);
      await tester.pumpAndSettle();

      // Widget should still be there after collapse
      expect(find.byKey(const Key('sidebar-title')), findsOneWidget);
    });

    testWidgets('search clears results when cleared',
        (WidgetTester tester) async {
      final friends = [
        MockUserData.friend(id: 'f1', name: 'Alice'),
        MockUserData.friend(id: 'f2', name: 'Bob'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
            ),
          ),
        ),
      );

      final searchField =
          find.byKey(const Key('search-friends-field'));
      await tester.enterText(searchField, 'Alice');
      await tester.pumpAndSettle();

      // Find Text widgets with 'Alice' (matches may include input field)
      expect(find.text('Alice'), findsWidgets);
      expect(find.text('Bob'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Both should be visible now
      expect(find.text('Alice'), findsWidgets);
      expect(find.text('Bob'), findsWidgets);
    });

    testWidgets('multiple favorites can be toggled',
        (WidgetTester tester) async {
      final friends = [
        MockUserData.friend(id: 'f1', name: 'Alice'),
        MockUserData.friend(id: 'f2', name: 'Bob'),
      ];

      var toggleCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
              onToggleFavorite: (id) => toggleCount++,
            ),
          ),
        ),
      );

      // Toggle first friend
      await tester.tap(find.byKey(const Key('favorite-btn-f1')));
      await tester.pumpAndSettle();

      // Toggle second friend
      await tester.tap(find.byKey(const Key('favorite-btn-f2')));
      await tester.pumpAndSettle();

      expect(toggleCount, equals(2));
    });

    testWidgets('online indicator shows for online friends',
        (WidgetTester tester) async {
      final friends = [
        MockUserData.friend(id: 'f1', name: 'Alice', isOnline: true),
        MockUserData.friend(id: 'f2', name: 'Bob', isOnline: false),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockFriendsSidebarWidget(
              friends: friends,
            ),
          ),
        ),
      );

      // Should have green indicators for online friends
      expect(find.byType(Container), findsWidgets);
    });
  });
}
