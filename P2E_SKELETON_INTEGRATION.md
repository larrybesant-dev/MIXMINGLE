# P2E Polish: Skeleton Loaders Integration Guide

## Overview
This document outlines how to integrate skeleton loaders into high-traffic screens for improved perceived performance and modern UX.

## Available Skeleton Components

### Basic Building Blocks
- `SkeletonAvatar` — circular placeholder for profile images
- `SkeletonText` — rectangular line placeholder
- `SkeletonBubble` — chat message placeholder

### Composite Components
- `SkeletonTile` — list item (avatar + text)
- `SkeletonCard` — full card (image + text)
- `SkeletonProfileHeader` — profile header layout
- `SkeletonList` — multiple tiles
- `SkeletonGrid` — multiple cards

### Animation
- `ShimmerSkeleton` — wraps any widget with shimmer effect

## Integration Pattern

### Step 1: Import
```dart
import '../../shared/widgets/skeleton_loaders.dart';
import '../../shared/widgets/async_value_view_enhanced.dart';
```

### Step 2: Replace AsyncValueView with skeleton
```dart
// Old (plain loading)
AsyncValueView(
  value: roomsAsync,
  onRetry: () => ref.invalidate(roomsProvider),
  data: (rooms) => RoomList(rooms: rooms),
)

// New (with skeleton)
AsyncValueViewEnhanced(
  value: roomsAsync,
  onRetry: () => ref.invalidate(roomsProvider),
  skeleton: SkeletonList(itemCount: 3),  // <-- Add this
  data: (rooms) => RoomList(rooms: rooms),
)
```

## High-Impact Integration Targets

### 1. Room List Screen
**File**: `lib/features/room/screens/room_list_page.dart`
**Skeleton**: `SkeletonList(itemCount: 3, showAvatar: true)`

### 2. Event List Screen
**File**: `lib/features/events/screens/events_list_page.dart`
**Skeleton**: `SkeletonGrid(itemCount: 4, crossAxisCount: 2)`

### 3. Chat Messages
**File**: `lib/features/chat/screens/chat_page.dart`
**Skeleton**:
```dart
Column(
  children: [
    SkeletonBubble(isUserMessage: false),
    SkeletonBubble(isUserMessage: true),
    SkeletonBubble(isUserMessage: false),
  ],
)
```

### 4. Profile Header
**File**: `lib/features/profile/screens/user_profile_page.dart`
**Skeleton**: `SkeletonProfileHeader()`

### 5. Notifications/Conversations
**File**: `lib/features/chat/screens/chat_list_page.dart`
**Skeleton**: `SkeletonList(itemCount: 5, showAvatar: true)`

## Enhanced AsyncValueView Features

### Retry Counter
```dart
AsyncValueViewEnhanced(
  value: dataAsync,
  maxRetries: 3,  // Show retry count in UI
  onRetry: () => ref.invalidate(provider),
  data: (data) => DataWidget(data),
)
```

### Exponential Backoff
```dart
AsyncValueViewEnhanced(
  value: dataAsync,
  enableBackoff: true,  // Wait before allowing next retry
  backoffDuration: Duration(seconds: 2),
  onRetry: () => ref.invalidate(provider),
  data: (data) => DataWidget(data),
)
```

### Custom Skeleton
```dart
AsyncValueViewEnhanced(
  value: dataAsync,
  skeleton: CustomSkeletonWidget(),  // Your own design
  onRetry: () => ref.invalidate(provider),
  data: (data) => DataWidget(data),
)
```

## Implementation Priority

### Phase 1 (Immediate Impact)
1. Room list → SkeletonList
2. Event list → SkeletonGrid
3. Chat messages → SkeletonBubble

### Phase 2 (Secondary)
1. Profile header → SkeletonProfileHeader
2. Chat list → SkeletonList
3. Notifications → SkeletonList

### Phase 3 (Polish)
1. Add retry counters to critical screens
2. Enable exponential backoff for failing APIs
3. Custom skeletons for unique layouts

## Testing

### Verify Skeleton Display
1. Simulate slow network in Chrome DevTools
2. Navigate to room list
3. Confirm skeleton appears for ~2s before data
4. Confirm data smoothly replaces skeleton

### Verify Retry Logic
1. Simulate offline mode
2. Tap "Retry" multiple times
3. Confirm retry counter increments
4. Confirm max retry message appears

### Analytics Hooks (P2F)
```dart
// Track skeleton display duration
// Track retry attempts
// Track backoff wait time
```

## Common Mistakes to Avoid

❌ **Don't**: Use `LoadingSpinner` for everything
✅ **Do**: Use context-appropriate skeletons (list → tiles, grid → cards)

❌ **Don't**: Show skeleton for >3 seconds
✅ **Do**: Ensure data loads within 2-3s of skeleton display

❌ **Don't**: Make skeleton different from final layout
✅ **Do**: Match skeleton structure to final widget structure

❌ **Don't**: Forget to export from barrel file
✅ **Do**: Add skeleton exports to `lib/shared/widgets/index.dart` or main barrel

## Next Steps (P2F)

1. **Analytics Integration**: Track skeleton display time, retry frequency
2. **A/B Testing**: Measure if skeletons improve perceived performance
3. **Custom Theming**: Match skeletons to app theme/branding
4. **Gesture Feedback**: Add haptic feedback on successful retries
