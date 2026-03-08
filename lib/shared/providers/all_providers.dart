
/// Comprehensive provider exports for Vybe Social
///
/// This file consolidates all Riverpod providers and controllers
/// organized by feature domain.
library;

// ============================================================================
// CORE PROVIDERS
// ============================================================================

export 'auth_providers.dart' hide currentUserProfileProvider;
export 'user_providers.dart' hide blockedUsersProvider, ProfileController;
export 'user_display_name_provider.dart';
export 'agora_participant_provider.dart';
export 'agora_video_tile_provider.dart';
export 'room_providers.dart' hide roomServiceProvider;
export 'broadcaster_providers.dart';
export 'camera_providers.dart';
export 'mic_providers.dart';
export 'chat_providers.dart';
export 'room_chat_presence_providers.dart';

// ============================================================================
// COMMUNICATION PROVIDERS
// ============================================================================

// Chat providers (ChatMessage-based - unified message model) - already exported above

// Hide chatServiceProvider and all duplicate providers from messaging_providers
export 'messaging_providers.dart'
    hide
        chatServiceProvider,
        roomMessagesProvider,
        paginatedRoomMessagesProvider,
        roomMessagesControllerProvider,
        sendRoomMessageProvider,
        messagingServiceProvider;

// Room message sending provider - keep for backward compatibility
export 'providers.dart' show sendRoomMessageProvider, messagingServiceProvider;
// export 'notification_social_providers.dart';

// ============================================================================
// SOCIAL & MATCHING PROVIDERS
// ============================================================================

export 'match_providers.dart' hide matchStatisticsProvider;

// ============================================================================
// EVENTS PROVIDERS
// ============================================================================

export 'event_dating_providers.dart' hide eventsServiceProvider, EventsController, eventProvider;
export 'events_controller.dart' hide eventsServiceProvider, attendingEventsProvider, eventsControllerProvider;

// ============================================================================
// MEDIA & MODERATION PROVIDERS
// ============================================================================

export 'video_media_providers.dart';

// ============================================================================
// GAMIFICATION, PAYMENTS & ANALYTICS PROVIDERS
// ============================================================================

export 'gamification_payment_providers.dart';

// ============================================================================
// FEATURE-SPECIFIC PROVIDERS
// ============================================================================

// Profile controller (hide providers to avoid conflicts with user_providers)
export 'profile_controller.dart'
    hide
        profileServiceProvider,
        currentUserProfileProvider,
        userProfileProvider,
        nearbyUsersProvider,
        searchUsersByInterestsProvider,
        isFollowingProvider;

// Matching feature providers removed - causes namespace collision with match_providers.dart
// Use match_providers.dart as single source of truth for matching providers

// Room feature providers (separate from general room providers)
export '../../features/room/providers/room_providers.dart';
export '../../features/room/providers/voice_room_providers.dart';
export '../../features/room/providers/room_subcollection_providers.dart';

// Group chat feature providers
export '../../features/group_chat/providers/group_chat_providers.dart';

// ============================================================================
// DISCOVERY PROVIDERS
// ============================================================================
export 'discovery_providers.dart';
export 'social_graph_providers.dart';
export 'feed_providers.dart';

// ============================================================================
// INTELLIGENCE + VIBE THEME PROVIDERS  (#7 #8 #10)
// ============================================================================
export 'vibe_theme_provider.dart';
export '../../core/intelligence/vibe_intelligence_service.dart';

// ============================================================================
// MONETIZATION — GIFTS, BOOSTS, ADMIN (Phase 12)
// ============================================================================
export 'gift_providers.dart';
export 'boost_providers.dart';
export 'admin_providers.dart';
