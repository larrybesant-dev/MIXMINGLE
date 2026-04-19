import 'package:flutter_test/flutter_test.dart';
import 'package:mixvy/dev/app_state_reasoning.dart';

void main() {
  group('explainCollectionVisibility', () {
    test('reports loading state clearly', () {
      final reason = explainCollectionVisibility(
        sourceName: 'rooms',
        isLoading: true,
        hasError: false,
        totalCount: 0,
        visibleCount: 0,
        filterLabel: 'all',
      );

      expect(reason.stateLabel, 'loading');
      expect(reason.primaryReason, contains('loading'));
    });

    test('reports filter-driven emptiness', () {
      final reason = explainCollectionVisibility(
        sourceName: 'rooms',
        isLoading: false,
        hasError: false,
        totalCount: 4,
        visibleCount: 0,
        filterLabel: 'music',
      );

      expect(reason.stateLabel, 'filtered');
      expect(reason.primaryReason, contains('filter'));
    });

    test('reports backend emptiness when nothing exists', () {
      final reason = explainCollectionVisibility(
        sourceName: 'rooms',
        isLoading: false,
        hasError: false,
        totalCount: 0,
        visibleCount: 0,
        filterLabel: 'all',
      );

      expect(reason.stateLabel, 'empty');
      expect(reason.primaryReason, contains('No live rooms'));
    });

    test('reports ready state when items are visible', () {
      final reason = explainCollectionVisibility(
        sourceName: 'rooms',
        isLoading: false,
        hasError: false,
        totalCount: 5,
        visibleCount: 3,
        filterLabel: 'all',
      );

      expect(reason.stateLabel, 'ready');
      expect(reason.primaryReason, contains('visible'));
    });
  });
}
