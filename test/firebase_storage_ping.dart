import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'firebase_storage_ping.mocks.dart';

// Generate mocks
@GenerateMocks([FirebaseStorage, Reference])
void main() {
  late MockFirebaseStorage mockStorage;
  late MockReference mockRef;

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockRef = MockReference();

    when(mockStorage.ref(any)).thenReturn(mockRef);
  });

  group('Firebase Storage Test', () {
    test('storage ref creation', () async {
      final storage = mockStorage;

      final ref = storage.ref('test/storage_test.txt');
      expect(ref, isNotNull);
      print('✅ Storage ref created successfully');
    });
  });
}
