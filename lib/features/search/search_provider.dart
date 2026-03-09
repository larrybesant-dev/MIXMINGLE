import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'search_service.dart';
import 'search_service.dart' show UserProfile;
final searchProvider = NotifierProvider<SearchNotifier, AsyncValue<List<UserProfile>>>(SearchNotifier.new);

class SearchNotifier extends Notifier<AsyncValue<List<UserProfile>>> {
  @override
  AsyncValue<List<UserProfile>> build() {
    return const AsyncValue.data([]);
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    final searchService = ref.read(searchServiceProvider);
    try {
      final results = await searchService.searchUsers(query);
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
