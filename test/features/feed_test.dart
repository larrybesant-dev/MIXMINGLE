import 'package:flutter_test/flutter_test.dart';
import 'package:MIXVY/lib/features/feed/post.dart';

void main() {
  group('Post', () {
    test('copyWith returns updated post', () {
      final post = Post(
        id: '1',
        userId: '2',
        content: 'Hello',
        timestamp: DateTime.now(),
        likes: 0,
        comments: 0,
      );
      final updated = post.copyWith(likes: 5);
      expect(updated.likes, 5);
      expect(updated.content, 'Hello');
    });
  });
}
