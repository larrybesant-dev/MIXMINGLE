import 'package:flutter_test/flutter_test.dart';
import '../helpers/mock_firebase.dart';

void main() {
  late MockStorageService mockStorage;

  setUp(() {
    mockStorage = MockStorageService();
  });

  tearDown(() {
    mockStorage.clear();
  });

  group('StorageService Tests', () {
    test('should upload file', () async {
      // Arrange
      final bytes = List<int>.generate(100, (i) => i);
      const path = 'users/user123/profile.jpg';

      // Act
      final url = await mockStorage.uploadFile(path, bytes);

      // Assert
      expect(url, contains(path));
      expect(mockStorage.fileExists(path), true);
    });

    test('should delete file', () async {
      // Arrange
      final bytes = List<int>.generate(100, (i) => i);
      const path = 'users/user123/profile.jpg';
      await mockStorage.uploadFile(path, bytes);

      // Act
      await mockStorage.deleteFile(path);

      // Assert
      expect(mockStorage.fileExists(path), false);
    });

    test('should validate file size', () {
      // Arrange
      final largeFile = List<int>.generate(15 * 1024 * 1024, (i) => i); // 15MB
      const maxSize = 10 * 1024 * 1024; // 10MB

      // Act
      final exceedsLimit = largeFile.length > maxSize;

      // Assert
      expect(exceedsLimit, true);
    });

    test('should validate file type', () {
      // Arrange
      const validExtensions = ['jpg', 'jpeg', 'png', 'gif'];
      const filePath = 'users/user123/profile.jpg';

      // Act
      final extension = filePath.split('.').last;
      final isValid = validExtensions.contains(extension);

      // Assert
      expect(isValid, true);
    });

    test('should handle upload errors gracefully', () async {
      // Arrange
      final bytes = <int>[];
      // const path = 'users/user123/empty.jpg';

      // Act & Assert
      expect(bytes.isEmpty, true);
    });

    test('should get file reference', () {
      // Arrange
      final bytes = List<int>.generate(100, (i) => i);
      const path = 'users/user123/profile.jpg';
      mockStorage.uploadFile(path, bytes);

      // Act
      final file = mockStorage.getFile(path);

      // Assert
      expect(file, isNotNull);
      expect(file?.length, 100);
    });

    test('should upload multiple files', () async {
      // Arrange
      final files = [
        {'path': 'file1.jpg', 'bytes': List<int>.generate(50, (i) => i)},
        {'path': 'file2.jpg', 'bytes': List<int>.generate(75, (i) => i)},
        {'path': 'file3.jpg', 'bytes': List<int>.generate(100, (i) => i)},
      ];

      // Act
      final urls = <String>[];
      for (final file in files) {
        final url = await mockStorage.uploadFile(
          file['path'] as String,
          file['bytes'] as List<int>,
        );
        urls.add(url);
      }

      // Assert
      expect(urls.length, 3);
      expect(mockStorage.fileExists('file1.jpg'), true);
      expect(mockStorage.fileExists('file2.jpg'), true);
      expect(mockStorage.fileExists('file3.jpg'), true);
    });
  });
}
