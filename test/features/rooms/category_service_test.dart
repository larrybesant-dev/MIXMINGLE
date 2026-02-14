import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/features/rooms/services/category_service.dart';

void main() {
  late CategoryService categoryService;

  setUp(() {
    categoryService = CategoryService();
  });

  group('CategoryService - classifyRoom', () {
    test('classifies music tags correctly', () {
      expect(categoryService.classifyRoom(['music']), 'Music');
      expect(categoryService.classifyRoom(['dj']), 'Music');
      expect(categoryService.classifyRoom(['beats']), 'Music');
      expect(categoryService.classifyRoom(['mix']), 'Music');
    });

    test('classifies gaming tags correctly', () {
      expect(categoryService.classifyRoom(['gaming']), 'Gaming');
      expect(categoryService.classifyRoom(['game']), 'Gaming');
      expect(categoryService.classifyRoom(['esports']), 'Gaming');
      expect(categoryService.classifyRoom(['play']), 'Gaming');
    });

    test('classifies chat tags correctly', () {
      expect(categoryService.classifyRoom(['chat']), 'Chat');
      expect(categoryService.classifyRoom(['talk']), 'Chat');
      expect(categoryService.classifyRoom(['hangout']), 'Chat');
    });

    test('classifies live tags correctly', () {
      expect(categoryService.classifyRoom(['live']), 'Live');
      expect(categoryService.classifyRoom(['stream']), 'Live');
      expect(categoryService.classifyRoom(['broadcast']), 'Live');
    });

    test('returns Other for unmatched tags', () {
      expect(categoryService.classifyRoom(['random']), 'Other');
      expect(categoryService.classifyRoom(['unknown']), 'Other');
      expect(categoryService.classifyRoom(['test']), 'Other');
    });

    test('returns Other for empty tags', () {
      expect(categoryService.classifyRoom([]), 'Other');
    });

    test('respects priority order: Music > Gaming > Chat > Live', () {
      expect(categoryService.classifyRoom(['music', 'gaming']), 'Music');
      expect(categoryService.classifyRoom(['gaming', 'chat']), 'Gaming');
      expect(categoryService.classifyRoom(['chat', 'live']), 'Chat');
      expect(categoryService.classifyRoom(['live', 'random']), 'Live');
    });

    test('handles case-insensitive matching', () {
      expect(categoryService.classifyRoom(['MUSIC']), 'Music');
      expect(categoryService.classifyRoom(['Gaming']), 'Gaming');
      expect(categoryService.classifyRoom(['CHAT']), 'Chat');
      expect(categoryService.classifyRoom(['LiVe']), 'Live');
    });

    test('handles tags with whitespace', () {
      expect(categoryService.classifyRoom(['  music  ']), 'Music');
      expect(categoryService.classifyRoom(['gaming   ']), 'Gaming');
      expect(categoryService.classifyRoom(['  chat']), 'Chat');
    });

    test('handles mixed matched and unmatched tags', () {
      expect(
          categoryService.classifyRoom(['music', 'random', 'test']), 'Music');
      expect(
          categoryService.classifyRoom(['random', 'gaming', 'test']), 'Gaming');
    });

    test('handles duplicate tags', () {
      expect(categoryService.classifyRoom(['music', 'music', 'dj']), 'Music');
      expect(
          categoryService.classifyRoom(['gaming', 'game', 'gaming']), 'Gaming');
    });
  });

  group('CategoryService - isValidCategory', () {
    test('validates correct categories', () {
      expect(categoryService.isValidCategory('Music'), true);
      expect(categoryService.isValidCategory('Gaming'), true);
      expect(categoryService.isValidCategory('Chat'), true);
      expect(categoryService.isValidCategory('Live'), true);
      expect(categoryService.isValidCategory('Other'), true);
    });

    test('rejects invalid categories', () {
      expect(categoryService.isValidCategory('Invalid'), false);
      expect(categoryService.isValidCategory('music'), false); // case sensitive
      expect(categoryService.isValidCategory(''), false);
    });
  });

  group('CategoryService - getAllCategories', () {
    test('returns all categories including Other', () {
      final categories = categoryService.getAllCategories();
      expect(categories, ['Music', 'Gaming', 'Chat', 'Live', 'Other']);
    });
  });

  group('CategoryService - getCategoryKeywords', () {
    test('returns keywords for Music', () {
      expect(
        categoryService.getCategoryKeywords('Music'),
        ['music', 'dj', 'beats', 'mix'],
      );
    });

    test('returns keywords for Gaming', () {
      expect(
        categoryService.getCategoryKeywords('Gaming'),
        ['gaming', 'game', 'esports', 'play'],
      );
    });

    test('returns empty list for invalid category', () {
      expect(categoryService.getCategoryKeywords('Invalid'), []);
    });
  });

  group('CategoryService - suggestCategory', () {
    test('suggests category from partial tag', () {
      expect(categoryService.suggestCategory('mus'), 'Music');
      expect(categoryService.suggestCategory('gam'), 'Gaming');
      expect(categoryService.suggestCategory('cha'), 'Chat');
      expect(categoryService.suggestCategory('liv'), 'Live');
    });

    test('returns null for no match', () {
      expect(categoryService.suggestCategory('xyz'), null);
      expect(categoryService.suggestCategory(''), null);
    });

    test('handles case-insensitive suggestions', () {
      expect(categoryService.suggestCategory('MUS'), 'Music');
      expect(categoryService.suggestCategory('GAM'), 'Gaming');
    });
  });

  group('CategoryService - normalizeTags', () {
    test('normalizes tags to lowercase and trims whitespace', () {
      expect(
        categoryService.normalizeTags(['MUSIC', '  Gaming  ', 'Chat']),
        ['music', 'gaming', 'chat'],
      );
    });

    test('removes empty tags', () {
      expect(
        categoryService.normalizeTags(['music', '', '   ', 'gaming']),
        ['music', 'gaming'],
      );
    });

    test('removes duplicate tags', () {
      expect(
        categoryService.normalizeTags(['music', 'Music', 'MUSIC', 'dj']),
        ['music', 'dj'],
      );
    });
  });

  group('CategoryService - validateTags', () {
    test('validates correct tags', () {
      expect(categoryService.validateTags(['music', 'gaming']), null);
      expect(categoryService.validateTags(['chat']), null);
    });

    test('rejects empty tag list', () {
      expect(
        categoryService.validateTags([]),
        'At least one tag is required',
      );
    });

    test('rejects tags that are all whitespace', () {
      expect(
        categoryService.validateTags(['   ', '  ']),
        'At least one valid tag is required',
      );
    });

    test('rejects too many tags', () {
      final manyTags = List.generate(11, (i) => 'tag$i');
      expect(
        categoryService.validateTags(manyTags),
        'Maximum 10 tags allowed',
      );
    });

    test('rejects tags that are too long', () {
      expect(
        categoryService.validateTags(['verylongtagnamemorethan20chars']),
        'Tags must be 20 characters or less',
      );
    });

    test('rejects tags with invalid characters', () {
      expect(
        categoryService.validateTags(['tag with spaces']),
        'Tags can only contain letters, numbers, hyphens, and underscores',
      );
      expect(
        categoryService.validateTags(['tag@special']),
        'Tags can only contain letters, numbers, hyphens, and underscores',
      );
    });

    test('accepts tags with valid characters', () {
      expect(categoryService.validateTags(['music']), null);
      expect(categoryService.validateTags(['tag-name']), null);
      expect(categoryService.validateTags(['tag_name']), null);
      expect(categoryService.validateTags(['tag123']), null);
    });
  });
}
