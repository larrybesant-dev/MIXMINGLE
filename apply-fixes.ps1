# Auto-fix script for Mix & Mingle smoke test failures
# Generated on 2025-11-26
# This script applies common fixes for the 8 failing features

Write-Host "Starting auto-fixes for Mix & Mingle smoke test failures..." -ForegroundColor Green

# 1. Check for Chrome extension scripts in web/index.html
Write-Host "Checking web/index.html for extension scripts..." -ForegroundColor Yellow
$indexHtml = Get-Content "web/index.html" -Raw
if ($indexHtml -match "utils\.js|tabutils\.js|chrome\.") {
    Write-Host "Found potential extension scripts. Guarding them..." -ForegroundColor Red
    # Add guard around extension scripts
    $guardedScript = @"
<script>
  if (typeof chrome !== 'undefined' && chrome.runtime && chrome.runtime.id) {
    // load extension-only scripts
    var s = document.createElement('script');
    s.src = 'utils.js'; document.head.appendChild(s);
    console.info('Extension scripts loaded.');
  } else {
    console.info('Extension APIs not available; skipping extension scripts.');
  }
</script>
"@
    # Replace any <script src="utils.js"> with guarded version
    $indexHtml = $indexHtml -replace '<script[^>]*src="[^"]*utils\.js[^"]*"[^>]*></script>', $guardedScript
    $indexHtml | Set-Content "web/index.html"
    Write-Host "Guarded extension scripts in web/index.html" -ForegroundColor Green
} else {
    Write-Host "No extension scripts found in web/index.html" -ForegroundColor Green
}

# 2. Add missing Keys to Flutter widgets
Write-Host "Adding missing Keys to Flutter widgets..." -ForegroundColor Yellow

# Home page buttons
$homePagePath = "lib/features/home_page.dart"
if (Test-Path $homePagePath) {
    $content = Get-Content $homePagePath -Raw

    # Add keys to quick action buttons if missing
    if ($content -notmatch "Key\('findEventsButton'\)") {
        $content = $content -replace "(_buildQuickActionButton\(\s*context,\s*'Find Events'", "_buildQuickActionButton(context, 'Find Events', Icons.event, () { if (context.findAncestorStateOfType<_HomePageState>() != null) { context.findAncestorStateOfType<_HomePageState>()!.setState(() { context.findAncestorStateOfType<_HomePageState>()!._selectedIndex = 1; }); } }, key: const Key('findEventsButton'),"
        Write-Host "Added key to Find Events button" -ForegroundColor Green
    }

    if ($content -notmatch "Key\('startChatButton'\)") {
        $content = $content -replace "(_buildQuickActionButton\(\s*context,\s*'Start Chat'", "_buildQuickActionButton(context, 'Start Chat', Icons.chat, () { if (context.findAncestorStateOfType<_HomePageState>() != null) { context.findAncestorStateOfType<_HomePageState>()!.setState(() { context.findAncestorStateOfType<_HomePageState>()!._selectedIndex = 2; }); } }, key: const Key('startChatButton'),"
        Write-Host "Added key to Start Chat button" -ForegroundColor Green
    }

    if ($content -notmatch "Key\('editProfileButton'\)") {
        $content = $content -replace "(_buildQuickActionButton\(\s*context,\s*'Edit Profile'", "_buildQuickActionButton(context, 'Edit Profile', Icons.person, () { if (context.findAncestorStateOfType<_HomePageState>() != null) { context.findAncestorStateOfType<_HomePageState>()!.setState(() { context.findAncestorStateOfType<_HomePageState>()!._selectedIndex = 3; }); } }, key: const Key('editProfileButton'),"
        Write-Host "Added key to Edit Profile button" -ForegroundColor Green
    }

    $content | Set-Content $homePagePath
}

# Events page buttons
$eventsPagePath = "lib/features/events_page.dart"
if (Test-Path $eventsPagePath) {
    $content = Get-Content $eventsPagePath -Raw

    if ($content -notmatch "Key\('searchEventsButton'\)") {
        $content = $content -replace "(IconButton\(\s*icon:\s*const Icon\(Icons\.search\)", "IconButton(key: const Key('searchEventsButton'), icon: const Icon(Icons.search)"
        Write-Host "Added key to search events button" -ForegroundColor Green
    }

    if ($content -notmatch "Key\('filterEventsButton'\)") {
        $content = $content -replace "(IconButton\(\s*icon:\s*const Icon\(Icons\.filter_list\)", "IconButton(key: const Key('filterEventsButton'), icon: const Icon(Icons.filter_list)"
        Write-Host "Added key to filter events button" -ForegroundColor Green
    }

    if ($content -notmatch "Key\('createEventButton'\)") {
        $content = $content -replace "(FloatingActionButton\(\s*onPressed:", "FloatingActionButton(key: const Key('createEventButton'), onPressed:"
        Write-Host "Added key to create event button" -ForegroundColor Green
    }

    $content | Set-Content $eventsPagePath
}

# Chat list page
$chatPagePath = "lib/features/chat_list_page.dart"
if (Test-Path $chatPagePath) {
    $content = Get-Content $chatPagePath -Raw

    if ($content -notmatch "Key\('searchChatsButton'\)") {
        $content = $content -replace "(IconButton\(\s*icon:\s*const Icon\(Icons\.search\)", "IconButton(key: const Key('searchChatsButton'), icon: const Icon(Icons.search)"
        Write-Host "Added key to search chats button" -ForegroundColor Green
    }

    $content | Set-Content $chatPagePath
}

# 3. Check for unsafe displayName access
Write-Host "Checking for unsafe displayName access..." -ForegroundColor Yellow
$files = Get-ChildItem -Path "lib" -Recurse -Include "*.dart" | Where-Object { $_.FullName -notmatch "test" }
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match "displayName\[0\]") {
        Write-Host "Found unsafe displayName[0] in $($file.FullName)" -ForegroundColor Red
        # Replace with safe access
        $content = $content -replace "displayName\[0\]", "(displayName?.isNotEmpty == true ? displayName!.substring(0,1).toUpperCase() : '?')"
        $content | Set-Content $file.FullName
        Write-Host "Fixed unsafe access in $($file.FullName)" -ForegroundColor Green
    }
}

# 4. Add feature flags if missing
$featuresConfigPath = "lib/features/features_config.dart"
if (Test-Path $featuresConfigPath) {
    $content = Get-Content $featuresConfigPath -Raw
    $updates = @()

    if ($content -notmatch "enableChat.*=.*true") {
        $updates += "enableChat = true;"
    }
    if ($content -notmatch "enableEvents.*=.*true") {
        $updates += "enableEvents = true;"
    }
    if ($content -notmatch "enableNotifications.*=.*true") {
        $updates += "enableNotifications = true;"
    }

    if ($updates.Count -gt 0) {
        $content = $content -replace "(enableSpeedDating.*)", "`$1`n  static const $($updates -join '`n  static const ')"
        $content | Set-Content $featuresConfigPath
        Write-Host "Added missing feature flags" -ForegroundColor Green
    }
}

# 5. Create stub providers if missing
$providersDir = "lib/providers"
if (-not (Test-Path "$providersDir/events_controller.dart")) {
    $stubContent = @"
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../services/event_service.dart';

final eventsControllerProvider =
  StateNotifierProvider<EventsController, List<Event>>((ref) {
    return EventsController(ref.read);
  });

class EventsController extends StateNotifier<List<Event>> {
  final Reader read;
  EventsController(this.read) : super([]);

  Future<void> createEvent(Event e) async {
    await read(eventServiceProvider).createEvent(e);
    await loadEvents();
  }

  Future<void> loadEvents() async {
    final events = await read(eventServiceProvider).getEvents();
    state = events;
  }
}
"@
    $stubContent | Set-Content "$providersDir/events_controller.dart"
    Write-Host "Created events controller stub" -ForegroundColor Green
}

if (-not (Test-Path "$providersDir/chat_controller.dart")) {
    $stubContent = @"
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_room.dart';

final chatRoomsProvider = StateNotifierProvider<ChatController, List<ChatRoom>>((ref) {
  return ChatController();
});

class ChatController extends StateNotifier<List<ChatRoom>> {
  ChatController() : super([]);

  // TODO: Implement chat room loading and management
}
"@
    $stubContent | Set-Content "$providersDir/chat_controller.dart"
    Write-Host "Created chat controller stub" -ForegroundColor Green
}

# 6. Commit changes
Write-Host "Committing auto-fixes..." -ForegroundColor Yellow
git add .
git commit -m "Auto-fix smoke test failures: add keys, guard extension scripts, fix unsafe access, add feature flags and provider stubs"

Write-Host "Auto-fixes complete! Run 'flutter build web --release' and redeploy, then rerun smoke tests." -ForegroundColor Green