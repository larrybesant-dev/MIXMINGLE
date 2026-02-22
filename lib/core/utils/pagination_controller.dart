import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Generic pagination controller for Firestore queries
class PaginationController<T> extends ChangeNotifier {
  final Query Function() queryBuilder;
  final T Function(DocumentSnapshot) itemBuilder;
  final int pageSize;

  List<T> _items = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  PaginationController({
    required this.queryBuilder,
    required this.itemBuilder,
    this.pageSize = 20,
  });

  List<T> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty && !_isLoading;

  /// Load the first page
  Future<void> loadInitial() async {
    _items = [];
    _lastDocument = null;
    _hasMore = true;
    _error = null;
    await loadMore();
  }

  /// Load the next page
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = queryBuilder().limit(pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        final newItems = snapshot.docs.map((doc) => itemBuilder(doc)).toList();
        _items.addAll(newItems);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length >= pageSize;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Pagination error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh the list
  Future<void> refresh() async {
    await loadInitial();
  }

  /// Clear all data
  void clear() {
    _items = [];
    _lastDocument = null;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _items = [];
    super.dispose();
  }
}
