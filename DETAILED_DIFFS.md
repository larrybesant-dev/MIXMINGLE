# Detailed Diffs - Mix & Mingle Repair

## 1. lib/login_simple.dart - Email TextField

### Before:
```dart
TextField(
  controller: _emailController,
  enabled: !_isLoading,
  style: DesignTypography.body,
  decoration: InputDecoration(
    labelText: 'Email address',
    hintText: 'you@example.com',
    hintStyle: DesignTypography.body,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: DesignColors.accent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: DesignColors.gold),
    ),
  ),
),
```

### After:
```dart
TextField(
  controller: _emailController,
  enabled: !_isLoading,
  style: const TextStyle(
    color: DesignColors.accent,
    fontSize: 14,
  ),
  cursorColor: DesignColors.gold,
  decoration: InputDecoration(
    labelText: 'Email address',
    labelStyle: const TextStyle(
      color: DesignColors.accent,
      fontSize: 14,
    ),
    hintText: 'you@example.com',
    hintStyle: const TextStyle(
      color: DesignColors.accent,
      fontSize: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: DesignColors.accent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: DesignColors.gold, width: 2),
    ),
  ),
),
```

**Changes:**
- Added `cursorColor: DesignColors.gold` ✅
- Added `labelStyle` with explicit color ✅
- Changed `style` from reference to inline TextStyle ✅
- Made hint text color explicit ✅
- Increased focused border width to 2px ✅

---

## 2. lib/login_simple.dart - Password TextField

### Before:
```dart
TextField(
  controller: _passwordController,
  enabled: !_isLoading,
  obscureText: true,
  style: DesignTypography.body,
  decoration: InputDecoration(
    labelText: 'Password',
    hintText: 'Your password',
    hintStyle: DesignTypography.body,
    border: OutlineInputBorder(...),
    enabledBorder: OutlineInputBorder(...),
    focusedBorder: OutlineInputBorder(...),
  ),
),
```

### After:
```dart
TextField(
  controller: _passwordController,
  enabled: !_isLoading,
  obscureText: true,
  style: const TextStyle(
    color: DesignColors.accent,
    fontSize: 14,
  ),
  cursorColor: DesignColors.gold,
  decoration: InputDecoration(
    labelText: 'Password',
    labelStyle: const TextStyle(
      color: DesignColors.accent,
      fontSize: 14,
    ),
    hintText: 'Your password',
    hintStyle: const TextStyle(
      color: DesignColors.accent,
      fontSize: 14,
    ),
    border: OutlineInputBorder(...),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: DesignColors.accent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: DesignColors.gold, width: 2),
    ),
  ),
),
```

**Changes:**
- Added `cursorColor: DesignColors.gold` ✅
- Added `labelStyle` with explicit color ✅
- Made all text styles explicit and visible ✅

---

## 3. lib/login_simple.dart - Error Message

### Before:
```dart
if (_errorMessage != null)
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: DesignColors.accent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      _errorMessage!,
      style: DesignTypography.body,
    ),
  ),
```

### After:
```dart
if (_errorMessage != null)
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: DesignColors.error,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      _errorMessage!,
      style: const TextStyle(
        color: DesignColors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
```

**Changes:**
- Changed background from `accent` (blue) to `error` (red) ✅
- Changed text to white for contrast ✅
- Added fontWeight for emphasis ✅

---

## 4. lib/core/design_system/design_constants.dart - DesignTypography

### Before:
```dart
class DesignTypography {
  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: DesignColors.accent,  // ❌ Blue text only
    height: 1.2,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: DesignColors.accent,  // ❌ Blue text only
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DesignColors.accent,  // ❌ Blue text only
    height: 1.4,
  );

  // ... caption, label, button all the same ❌
}
```

### After:
```dart
class DesignTypography {
  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: DesignColors.white,  // ✅ White for readability
    height: 1.2,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: DesignColors.white,  // ✅ White for readability
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DesignColors.white,  // ✅ White for readability
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: DesignColors.white,  // ✅ White for readability
    height: 1.3,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: DesignColors.white,  // ✅ White for readability
    height: 1.2,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: DesignColors.white,  // ✅ White for readability
    height: 1.2,
  );
}
```

**Changes:**
- Changed ALL colors from `accent` (blue) to `white` ✅
- Ensures universal readability across all backgrounds ✅

---

## 5. lib/features/room/widgets/voice_room_chat_overlay.dart - _ChatMessageBubble

### Before:
```dart
return Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
    children: [
      if (!isCurrentUser)
        CircleAvatar(
          radius: 16,
          backgroundColor: DesignColors.accent,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: DesignColors.accent,  // ❌ Blue on blue - invisible!
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentUser ? DesignColors.accent : DesignColors.accent,  // ❌ Same color!
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  color: isCurrentUser ? DesignColors.accent.withValues(alpha: 0.9) : DesignColors.accent,  // ❌ Blue text
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message.content,
                style: const TextStyle(
                  color: DesignColors.accent,  // ❌ Blue text
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: DesignColors.accent,  // ❌ Blue text
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
```

### After:
```dart
return Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
    children: [
      if (!isCurrentUser)
        Tooltip(
          message: displayName,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: DesignColors.accent,
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: DesignColors.white,  // ✅ White on blue - visible!
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      if (!isCurrentUser) const SizedBox(width: 8),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentUser ? DesignColors.secondary : DesignColors.accent,  // ✅ Different colors!
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  color: isCurrentUser ? DesignColors.accent : DesignColors.white,  // ✅ Proper contrast
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message.content,
                style: TextStyle(
                  color: isCurrentUser ? DesignColors.white : DesignColors.white,  // ✅ White text
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: isCurrentUser ? Colors.white70 : Colors.white60,  // ✅ Subtle but visible
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
      if (isCurrentUser) const SizedBox(width: 8),
    ],
  ),
);
```

**Changes:**
- Avatar text: Blue → White ✅
- Message bubbles: Same color → Different (secondary for current, accent for other) ✅
- Sender name: Blue → White/Accent with proper contrast ✅
- Message content: Blue → White ✅
- Timestamp: Blue → White70/White60 opacity ✅
- Added proper spacing ✅

---

## 6. lib/features/video_room/video_room_view.dart - Video Grid

### Before:
```dart
Widget _buildJoinedUI() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('📹 Camera: ${state.cameraEnabled ? 'ON' : 'OFF'}'),
      SizedBox(height: 8),
      Text('🎤 Microphone: ${state.micEnabled ? 'ON' : 'OFF'}'),
      SizedBox(height: 8),
      Text('Remote users: ${state.remoteUserCount}'),
      SizedBox(height: 16),
      if (state.error != null)
        Text('Error: ${state.error}', style: DesignTypography.body),
    ],
  );
}
```

### After:
```dart
Widget _buildJoinedUI() {
  return Container(
    color: DesignColors.background,
    child: Stack(
      children: [
        Column(
          children: [
            // Remote videos (grid layout)
            Expanded(
              child: state.remoteUserCount > 0
                  ? GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        childAspectRatio: 1,
                      ),
                      itemCount: state.remoteUserCount,
                      itemBuilder: (context, index) {
                        return Container(
                          color: Colors.grey[900],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam, size: 48, color: DesignColors.accent),
                                const SizedBox(height: 8),
                                Text('User ${index + 1}', style: const TextStyle(color: DesignColors.white)),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off, size: 64, color: DesignColors.accent),
                            SizedBox(height: 16),
                            Text(
                              'Waiting for participants...',
                              style: TextStyle(color: DesignColors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            // Local video (small preview at bottom)
            Container(
              height: 120,
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: DesignColors.accent, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        state.cameraEnabled ? Icons.videocam : Icons.videocam_off,
                        size: 32,
                        color: state.cameraEnabled ? DesignColors.accent : DesignColors.gold,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You',
                        style: TextStyle(color: DesignColors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Status overlay
        if (state.error != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.error!,
                style: const TextStyle(
                  color: DesignColors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
```

**Changes:**
- Added complete video grid layout ✅
- Added remote user video placeholders ✅
- Added local video preview ✅
- Proper color scheme and styling ✅
- Ready for actual Agora video renderer integration ✅

---

**All Diffs Complete!** ✅
