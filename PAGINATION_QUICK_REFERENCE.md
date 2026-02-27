# Pagination Quick Reference

## Import Statements

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/pagination/pagination_controller.dart';
import '../../shared/widgets/paginated_list_view.dart';
```

## Basic Setup (3 Steps)

### Step 1: Create Controller

```dart
late PaginationController<MyModel> _controller;

@override
void initState() {
  super.initState();
  _controller = PaginationController<MyModel>(
    pageSize: 20,
    fetchPage: (cursor) async {
      Query query = FirebaseFirestore.instance.collection('items');
      if (cursor != null) query = query.startAfterDocument(cursor);
      final snap = await query.limit(20).get();
      return PaginationResult(
        items: snap.docs.map((d) => MyModel.fromDoc(d)).toList(),
        cursor: snap.docs.isNotEmpty ? snap.docs.last : null,
        hasMore: snap.docs.length == 20,
      );
    },
  );
}
```

### Step 2: Dispose Controller

```dart
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

### Step 3: Use PaginatedListView

```dart
@override
Widget build(BuildContext context) {
  return PaginatedListView<MyModel>(
    controller: _controller,
    itemBuilder: (context, item, index) => MyItemWidget(item),
  );
}
```

## Real-Time Updates (Streams)

Replace `PaginationController` with `StreamPaginationController`:

```dart
_controller = StreamPaginationController<MyModel>(
  pageSize: 20,
  fetchStream: (cursor) {  // Returns Stream instead of Future
    Query query = FirebaseFirestore.instance.collection('items');
    if (cursor != null) query = query.startAfterDocument(cursor);
    return query.limit(20).snapshots().map((snap) {
      return PaginationResult(
        items: snap.docs.map((d) => MyModel.fromDoc(d)).toList(),
        cursor: snap.docs.isNotEmpty ? snap.docs.last : null,
        hasMore: snap.docs.length == 20,
      );
    });
  },
);
```

## Customization Options

```dart
PaginatedListView<T>(
  controller: _controller,
  itemBuilder: (context, item, index) => MyWidget(item),

  // Optional customizations:
  padding: EdgeInsets.all(16),
  shrinkWrap: false,
  physics: AlwaysScrollableScrollPhysics(),
  scrollController: myScrollController,  // Use custom scroll controller

  // Custom states:
  loadingWidget: Center(child: MyLoadingSpinner()),
  emptyWidget: Center(child: Text('No items')),
  errorBuilder: (error) => Center(child: Text('Error: $error')),
);
```

## Grid Layout

Use `PaginatedGridView` instead:

```dart
PaginatedGridView<T>(
  controller: _controller,
  itemBuilder: (context, item, index) => MyCard(item),
  crossAxisCount: 2,
  childAspectRatio: 0.75,
)
```

## Common Patterns

### With Filters

```dart
fetchPage: (cursor) async {
  Query query = FirebaseFirestore.instance
      .collection('items')
      .where('status', isEqualTo: 'active')  // Filter
      .orderBy('createdAt', descending: true);
  // ... rest of pagination logic
}
```

### With Search

```dart
fetchPage: (cursor) async {
  Query query = FirebaseFirestore.instance
      .collection('items')
      .where('searchKeywords', arrayContains: searchTerm)
      .orderBy('createdAt', descending: true);
  // ... rest of pagination logic
}
```

### Manual Refresh

```dart
ElevatedButton(
  onPressed: () => _controller.refresh(),  // Reload from beginning
  child: Text('Refresh'),
)
```

## Page Size Guidelines

| Collection     | Page Size | Reason                             |
| -------------- | --------- | ---------------------------------- |
| Notifications  | 20        | Frequent updates, small items      |
| Messages       | 50        | Need more context for conversation |
| Events         | 30        | Medium-sized cards                 |
| Rooms          | 20        | Large cards with images            |
| Search Results | 20-30     | Balance between UX and performance |

## Debugging

### Enable Logging

```dart
_controller = PaginationController<T>(
  fetchPage: (cursor) async {
    print('📄 Fetching page with cursor: $cursor');
    final result = await /* ... */;
    print('✅ Loaded ${result.items.length} items, hasMore: ${result.hasMore}');
    return result;
  },
);
```

### Check State

```dart
print('Loading: ${_controller.isLoading}');
print('Items: ${_controller.items.length}');
print('Has More: ${_controller.hasMore}');
print('Error: ${_controller.error}');
```

## Firestore Rules

Ensure your rules allow pagination queries:

```javascript
match /items/{itemId} {
  allow read: if request.auth != null
              && request.query.limit <= 100;  // Prevent abuse
}
```

## Performance Tips

1. **Composite Indexes**: Create for `.where()` + `.orderBy()` combinations
2. **Limit Page Size**: Don't exceed 50-100 items per page
3. **Cache**: Firestore caches results automatically
4. **Prefetch**: Consider loading next page in background
5. **Cursor Stability**: Always use `DocumentSnapshot` as cursor, not field values
