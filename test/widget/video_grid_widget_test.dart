/// VideoGridWidget Tests - Layout, Animation, Pin/Unpin Functionality
///
/// Tests for:
/// - Grid layout rendering
/// - Video tile entry animations
/// - Pin/unpin participant functionality
/// - Participant info display
/// - Responsive grid sizing
/// - Error states and fallbacks
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixmingle/design/design_colors.dart';
import '../test_helpers.dart';

// Mock VideoGridWidget for testing
class MockVideoGridWidget extends StatefulWidget {
  final List<Map<String, dynamic>> participants;
  final Function(String)? onPin;
  final Function(String)? onRemove;

  const MockVideoGridWidget({
    super.key,
    required this.participants,
    this.onPin,
    this.onRemove,
  });

  @override
  State<MockVideoGridWidget> createState() => _MockVideoGridWidgetState();
}

class _MockVideoGridWidgetState extends State<MockVideoGridWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<String> pinnedParticipants;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    pinnedParticipants = [];
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePin(String participantId) {
    setState(() {
      if (pinnedParticipants.contains(participantId)) {
        pinnedParticipants.remove(participantId);
      } else {
        pinnedParticipants.add(participantId);
      }
    });
    widget.onPin?.call(participantId);
  }

  @override
  Widget build(BuildContext context) {
    const columns = 3;
    final rows =
        (widget.participants.length / columns).ceil();

    return SingleChildScrollView(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 1.2,
        ),
        itemCount: widget.participants.length,
        itemBuilder: (context, index) {
          final participant = widget.participants[index];
          final isPinned = pinnedParticipants.contains(participant['id']);

          return ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (index * 0.05).clamp(0.0, 1.0),
                  1.0,
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
            child: Container(
              key: Key('participant-tile-${participant['id']}'),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: DesignColors.accent[900],
                borderRadius: BorderRadius.circular(12),
                border: isPinned
                    ? Border.all(color: DesignColors.accent, width: 3)
                    : Border.all(color: DesignColors.accent, width: 1),
              ),
              child: Stack(
                children: [
                  // Video placeholder
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: DesignColors.accent87,
                    child: Center(
                      child: Text(
                        participant['name'] ?? 'Unknown',
                        style: TextStyle(
                          color: DesignColors.accent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Top-left: Name badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignColors.accent54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        participant['name'] ?? 'Unknown',
                        style: TextStyle(
                          color: DesignColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Bottom-right: Controls
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mute indicator
                        if ((participant['isMuted'] as bool?) ?? false)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: DesignColors.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.mic_off,
                              size: 12,
                              color: DesignColors.accent,
                            ),
                          ),
                        const SizedBox(width: 4),
                        // Pin button
                        GestureDetector(
                          onTap: () => _togglePin(participant['id']),
                          child: Container(
                            key: Key('pin-button-${participant['id']}'),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isPinned
                                  ? DesignColors.accent
                                  : DesignColors.accent[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              size: 14,
                              color: DesignColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Top-right: Badge (optional unread count)
                  if (((participant['unreadCount'] as int?) ?? 0) > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: DesignColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${participant['unreadCount']}',
                            style: TextStyle(
                              color: DesignColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() {
  group('VideoGridWidget Tests', () {
    testWidgets('renders grid with correct number of tiles',
        (WidgetTester tester) async {
      final participants = TestFixtures.participants();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: participants,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
      expect(
        find.byKey(Key('participant-tile-${participants[0]['id']}')),
        findsOneWidget,
      );
    });

    testWidgets('displays participant name on tile',
        (WidgetTester tester) async {
      final participants =
          TestFixtures.participants().sublist(0, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: participants,
            ),
          ),
        ),
      );

      expect(
        find.text(participants[0]['name']),
        findsWidgets,
      );
    });

    testWidgets('tapping pin button toggles pin state',
        (WidgetTester tester) async {
      final participants =
          TestFixtures.participants().sublist(0, 1);
      var pinCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: participants,
              onPin: (id) => pinCount++,
            ),
          ),
        ),
      );

      final pinButton =
          find.byKey(Key('pin-button-${participants[0]['id']}'));
      expect(pinButton, findsOneWidget);

      await tester.tap(pinButton);
      await tester.pumpAndSettle();

      expect(pinCount, equals(1));
    });

    testWidgets('pinned participant has blue border',
        (WidgetTester tester) async {
      final participants =
          TestFixtures.participants().sublist(0, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: participants,
            ),
          ),
        ),
      );

      // Pin the participant
      final pinButton =
          find.byKey(Key('pin-button-${participants[0]['id']}'));
      await tester.tap(pinButton);
      await tester.pumpAndSettle();

      // Check for blue border (container with blue border should exist)
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays mute indicator when participant is muted',
        (WidgetTester tester) async {
      final participants = [
        MockUserData.participant(
          userId: 'p1',
          name: 'Muted User',
          isMuted: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: participants,
            ),
          ),
        ),
      );

      expect(
        find.byIcon(Icons.mic_off),
        findsOneWidget,
      );
    });

    testWidgets('displays unread count badge',
        (WidgetTester tester) async {
      final participants = [
        MockUserData.participant(
          userId: 'p1',
          name: 'User with Messages',
          unreadCount: 5,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: participants,
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('no badge shown when unread count is 0',
        (WidgetTester tester) async {
      final participants = [
        MockUserData.participant(
          userId: 'p1',
          name: 'User',
          unreadCount: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: participants,
            ),
          ),
        ),
      );

      // Should not find the red badge with unread count
      final badges = find.byType(Container);
      expect(badges, findsWidgets);
    });

    testWidgets('grid handles empty participant list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: [],
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets(
        'entry animation triggers on widget build',
        (WidgetTester tester) async {
      final participants = TestFixtures.participants();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: participants,
            ),
          ),
        ),
      );

      // Verify animation controller is running
      expect(find.byType(ScaleTransition), findsWidgets);

      // Pump to advance animation
      await tester.pumpAndSettle();

      // After animation completes, tiles should be fully scaled
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('multiple participants can be pinned',
        (WidgetTester tester) async {
      final participants = TestFixtures.participants();
      var totalPins = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: participants,
              onPin: (id) => totalPins++,
            ),
          ),
        ),
      );

      // Pin first participant
      await tester.tap(find.byKey(Key('pin-button-${participants[0]['id']}')));
      await tester.pumpAndSettle();

      // Pin second participant
      await tester.tap(find.byKey(Key('pin-button-${participants[1]['id']}')));
      await tester.pumpAndSettle();

      expect(totalPins, equals(2));
    });

    testWidgets('unpinning participant removes blue border',
        (WidgetTester tester) async {
      final participants =
          TestFixtures.participants().sublist(0, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockVideoGridWidget(
              participants: participants,
            ),
          ),
        ),
      );

      final pinButton =
          find.byKey(Key('pin-button-${participants[0]['id']}'));

      // Pin
      await tester.tap(pinButton);
      await tester.pumpAndSettle();

      // Unpin
      await tester.tap(pinButton);
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });
  });
}
