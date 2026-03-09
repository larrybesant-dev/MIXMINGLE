import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'search_service.dart';

final searchProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<UserProfile>>>(
  (ref) => SearchNotifier(ref.read(searchServiceProvider)),
);

class SearchNotifier extends StateNotifier<AsyncValue<List<UserProfile>>> {
  final SearchService _service;
  SearchNotifier(this._service) : super(const AsyncValue.data([]));

  void search(String query) async {
    state = const AsyncValue.loading();
    try {
      final results = await _service.searchUsers(query);
      state = AsyncValue.data(results);
    } catch (e) {
      state = AsyncValue.error(e);
    }
  }
}
