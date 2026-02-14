# Performance Utilities - Quick Reference Guide

## 📚 Table of Contents
1. [Pagination](#pagination)
2. [Caching](#caching)
3. [Debouncing & Throttling](#debouncing--throttling)
4. [Performance Logging](#performance-logging)
5. [Image Optimization](#image-optimization)

---

## 1. Pagination

### Import:
```dart
import '../core/utils/pagination_controller.dart';
```

### Basic Setup:
```dart
class MyListPage extends StatefulWidget {
  @override
  _MyListPageState createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {
  late PaginationController<Event> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaginationController<Event>(
      queryBuilder: () => FirebaseFirestore.instance
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .orderBy('startTime'),
      itemBuilder: (doc) => Event.fromMap(doc.data()),
      pageSize: 20,
    );
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _controller.loadInitial();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading && _controller.items.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null) {
      return Center(child: Text('Error: ${_controller.error}'));
    }

    if (_controller.isEmpty) {
      return Center(child: Text('No items found'));
    }

    return ListView.builder(
      itemCount: _controller.items.length + (_controller.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Load more when reaching near end
        if (index == _controller.items.length - 2 && _controller.hasMore) {
          _controller.loadMore().then((_) => setState(() {}));
        }

        // Show loading indicator at end
        if (index == _controller.items.length) {
          return Center(child: CircularProgressIndicator());
        }

        final item = _controller.items[index];
        return ListTile(title: Text(item.name));
      },
    );
  }
}
```

### Pull to Refresh:
```dart
RefreshIndicator(
  onRefresh: () async {
    await _controller.refresh();
    setState(() {});
  },
  child: ListView.builder(...),
)
```

---

## 2. Caching

### Import:
```dart
import '../core/utils/cache_service.dart';
```

### Using Pre-configured Caches:
```dart
// In your service class
class ProfileService {
  Future<UserProfile?> getUserProfile(String userId) async {
    // Check cache first
    final cached = AppCaches.userProfiles.get(userId);
    if (cached != null) {
      return cached;
    }

    // Fetch from Firestore
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final profile = UserProfile.fromMap(doc.data()!);

      // Store in cache
      AppCaches.userProfiles.put(userId, profile);

      return profile;
    }
    return null;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.id).set(profile.toMap());

    // Invalidate cache after update
    AppCaches.userProfiles.remove(profile.id);
  }
}
```

### Using getOrCompute():
```dart
final profile = await AppCaches.userProfiles.getOrCompute(
  userId,
  () => _fetchProfileFromFirestore(userId),
);
```

### Creating Custom Cache:
```dart
final customCache = CacheService<String, MyData>(
  ttl: Duration(minutes: 15),
  maxSize: 50,
);

customCache.put('key', myData);
final data = customCache.get('key');
```

### Cache Management:
```dart
// Clear specific cache
AppCaches.userProfiles.clear();

// Clear all caches
AppCaches.clearAll();

// Clean up expired entries
AppCaches.cleanupAll();
```

---

## 3. Debouncing & Throttling

### Import:
```dart
import '../core/utils/debouncer.dart';
```

### Debouncing Search Input:
```dart
class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchDebouncer = Debouncer(delay: Duration(milliseconds: 300));

  @override
  void dispose() {
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (query) {
        _searchDebouncer.call(() {
          // This only runs 300ms after user stops typing
          performSearch(query);
        });
      },
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  void performSearch(String query) {
    print('Searching for: $query');
    // Actual search logic here
  }
}
```

### Throttling Scroll Events:
```dart
class ScrollablePage extends StatefulWidget {
  @override
  _ScrollablePageState createState() => _ScrollablePageState();
}

class _ScrollablePageState extends State<ScrollablePage> {
  final _scrollThrottler = Throttler(duration: Duration(milliseconds: 100));

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 100,
      itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
      onScrollNotification: (notification) {
        _scrollThrottler.call(() {
          // This runs at most once every 100ms
          print('Scroll position: ${notification.metrics.pixels}');
        });
        return true;
      },
    );
  }
}
```

### Cancel Debouncer:
```dart
// Cancel pending execution
_searchDebouncer.cancel();

// Always dispose in widget lifecycle
@override
void dispose() {
  _searchDebouncer.dispose();
  super.dispose();
}
```

---

## 4. Performance Logging

### Import:
```dart
import '../core/utils/performance_logger.dart';
```

### Basic Timing:
```dart
void myFunction() {
  PerformanceLogger.start('myFunction');

  // ... expensive operation ...

  PerformanceLogger.stop('myFunction');
  // Logs: "myFunction took 123ms"
}
```

### Measure Synchronous Operations:
```dart
final result = PerformanceLogger.measure('computation', () {
  return expensiveComputation();
});
```

### Measure Async Operations:
```dart
final data = await PerformanceLogger.measureAsync('fetchData', () async {
  return await fetchFromAPI();
});
```

### Get Statistics:
```dart
// Get stats for specific operation
final stats = PerformanceLogger.getStats('fetchData');
print('Count: ${stats['count']}');
print('Average: ${stats['avg']}ms');
print('Min: ${stats['min']}ms');
print('Max: ${stats['max']}ms');
print('Total: ${stats['total']}ms');

// Print all collected stats
PerformanceLogger.printAllStats();
```

### Track Widget Build Time:
```dart
@override
Widget build(BuildContext context) {
  return WidgetPerformanceTracker(
    widgetName: 'MyExpensiveWidget',
    child: ComplexWidget(),
  );
}
// Warns if build takes > 16ms (60fps threshold)
```

### Additional Logging:
```dart
// Log custom metric
PerformanceLogger.logMetric('cacheHitRate', 0.85);

// Log memory usage
PerformanceLogger.logMemoryUsage();

// Log frame time
PerformanceLogger.logFrameTime();
```

**Note**: All logging is automatically disabled in release builds (guarded by `kDebugMode`).

---

## 5. Image Optimization

### Import:
```dart
import '../services/image_optimization_service.dart';
```

### Upload with Thumbnails:
```dart
class MyUploadService {
  final _imageOptimization = ImageOptimizationService();

  Future<Map<String, String>> uploadProfilePhoto(File imageFile, String userId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'profile_photos/$userId/$timestamp.jpg';

    // Optimize and generate thumbnails
    final optimizedFile = await _imageOptimization.optimizeImage(imageFile);

    final urls = await _imageOptimization.uploadImageWithThumbnails(
      imageFile: optimizedFile,
      path: path,
    );

    // Clean up temporary file
    if (optimizedFile.path != imageFile.path) {
      await optimizedFile.delete();
    }

    return urls;
    // Returns: {
    //   'original': 'https://...',
    //   'thumbnail': 'https://...',  // 150x150
    //   'medium': 'https://...',     // 400x400
    //   'large': 'https://...'       // 800x800
    // }
  }
}
```

### Custom Thumbnail Sizes:
```dart
final urls = await _imageOptimization.uploadImageWithThumbnails(
  imageFile: file,
  path: path,
  sizes: [
    ThumbnailSize.thumbnail,  // 150x150 @ 80%
    ThumbnailSize.medium,     // 400x400 @ 85%
    // Omit 'large' if not needed
  ],
);
```

### Delete with Thumbnails:
```dart
await _imageOptimization.deleteImageWithThumbnails(
  'profile_photos/user123/1234567890.jpg'
);
// Deletes original and all thumbnails
```

### Optimize Only (no upload):
```dart
final optimizedFile = await _imageOptimization.optimizeImage(
  originalFile,
  maxWidth: 1920,
  quality: 85,
);
// Returns compressed File
```

### Display Thumbnails in UI:
```dart
// Use thumbnail for list items
CircleAvatar(
  backgroundImage: NetworkImage(urls['thumbnail']!),
  radius: 30,
)

// Use medium for detail views
Image.network(
  urls['medium']!,
  fit: BoxFit.cover,
)

// Use original for full screen
PhotoView(
  imageProvider: NetworkImage(urls['original']!),
)
```

---

## 🎯 Best Practices

### Pagination:
- ✅ Always include `orderBy()` for consistent results
- ✅ Use reasonable page sizes (10-50 items)
- ✅ Show loading indicators during loadMore()
- ✅ Handle empty states gracefully
- ✅ Dispose controller in widget dispose()

### Caching:
- ✅ Cache frequently accessed data (profiles, settings)
- ✅ Use short TTLs for frequently changing data
- ✅ Invalidate cache after mutations
- ✅ Don't cache real-time data (use streams instead)
- ✅ Monitor cache hit rates

### Debouncing:
- ✅ Use for search inputs (300-500ms)
- ✅ Use for auto-save (1000-2000ms)
- ✅ Always dispose in widget lifecycle
- ✅ Consider throttling for scroll events
- ✅ Cancel when unmounting

### Performance Logging:
- ✅ Only runs in debug mode (kDebugMode)
- ✅ Use for identifying bottlenecks
- ✅ Review stats periodically
- ✅ Set performance budgets (e.g., <100ms)
- ✅ Track before/after optimization

### Image Optimization:
- ✅ Always optimize before upload
- ✅ Use appropriate thumbnail size for context
- ✅ Delete all sizes when removing image
- ✅ Consider progressive loading (thumbnail → full)
- ✅ Test on slow networks

---

## 🚫 Common Pitfalls

### Pagination:
- ❌ Don't use offset-based pagination (slow at scale)
- ❌ Don't paginate without orderBy() (inconsistent results)
- ❌ Don't forget to handle errors
- ❌ Don't load too many items per page (>100)

### Caching:
- ❌ Don't cache everything (waste memory)
- ❌ Don't use stale cache for critical data
- ❌ Don't forget to invalidate on updates
- ❌ Don't cache streams (defeats real-time purpose)

### Debouncing:
- ❌ Don't use delay too short (<100ms, ineffective)
- ❌ Don't use delay too long (>1000ms, feels laggy)
- ❌ Don't forget to dispose
- ❌ Don't debounce critical operations (e.g., save button)

### Performance Logging:
- ❌ Don't use in production (already disabled by kDebugMode)
- ❌ Don't log excessively (adds overhead in debug)
- ❌ Don't forget to remove debug logs before release

### Image Optimization:
- ❌ Don't optimize twice (already done in service)
- ❌ Don't skip thumbnail generation (saves bandwidth)
- ❌ Don't forget to delete temporary files
- ❌ Don't use original for all contexts (waste bandwidth)

---

## 📊 Performance Impact

| Utility | Primary Benefit | Reduction |
|---------|----------------|-----------|
| Pagination | Load time, memory | 80-90% |
| Caching | Firestore reads | 60-80% |
| Debouncing | API calls | 90-95% |
| Performance Logging | Identify bottlenecks | N/A |
| Image Optimization | Bandwidth, storage | 70-96% |

---

## 🔗 Related Files

- **Pagination**: `lib/core/utils/pagination_controller.dart`
- **Caching**: `lib/core/utils/cache_service.dart`
- **Debouncing**: `lib/core/utils/debouncer.dart`
- **Performance Logging**: `lib/core/utils/performance_logger.dart`
- **Image Optimization**: `lib/services/image_optimization_service.dart`
- **Photo Upload**: `lib/services/photo_upload_service.dart` (integrated)
- **Profile Service**: `lib/services/profile_service.dart` (integrated)
- **Events Service**: `lib/services/events_service.dart` (integrated)

---

## 💡 Examples by Use Case

### Use Case 1: Infinite Scroll List
```dart
// Use: PaginationController + Debouncing (if search)
final _controller = PaginationController<Event>(...);
final _searchDebouncer = Debouncer();

ListView.builder(
  itemCount: _controller.items.length + 1,
  itemBuilder: (context, index) {
    if (index == _controller.items.length - 2) {
      _controller.loadMore();
    }
    // ...
  },
)
```

### Use Case 2: Profile Details Page
```dart
// Use: Caching + Image Thumbnails
final profile = await AppCaches.userProfiles.getOrCompute(
  userId,
  () => profileService.getUserProfile(userId),
);

CircleAvatar(
  backgroundImage: NetworkImage(profile.photoUrls['medium']!),
)
```

### Use Case 3: Search Bar
```dart
// Use: Debouncing + Performance Logging
final _debouncer = Debouncer(delay: Duration(milliseconds: 300));

TextField(
  onChanged: (query) {
    _debouncer.call(() async {
      final results = await PerformanceLogger.measureAsync('search', () {
        return searchService.search(query);
      });
      setState(() => _results = results);
    });
  },
)
```

### Use Case 4: Photo Upload
```dart
// Use: Image Optimization + Performance Logging
final urls = await PerformanceLogger.measureAsync('photoUpload', () {
  return photoUploadService.uploadProfilePhoto(imageFile);
});

// Display thumbnail immediately
setState(() => _photoUrl = urls['thumbnail']);
```

---

**Happy Optimizing! 🚀**
