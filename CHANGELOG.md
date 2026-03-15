# Changelog

All notable changes to Mix & Mingle will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-09

### Added

- **Voice & Video Rooms**: Real-time multi-participant video chat with up to 12 active cameras
- **Multi-Window Layout**: Adaptive grid layouts (1x1 to 4x3) with intelligent participant ordering
- **Spotlight Mode**: Featured broadcaster highlighting with visual indicators
- **Host Tools**: Complete room management panel for hosts
  - Kick/mute participants
  - Grant/revoke co-host privileges
  - Spotlight override controls
  - Room settings management
- **Moderation System**: User reporting and blocking functionality
  - Report users with categorized reasons
  - Block/unblock users
  - Admin review dashboard
- **VIP Membership**: Tiered membership system with RevenueCat integration
  - Free tier with basic features
  - VIP tier with enhanced room access
  - VIP+ tier with premium benefits
- **Coin Economy**: In-app currency system
  - Coin packages for purchase
  - Tipping/gifting between users
  - Spotlight bidding system
- **Onboarding Flow**: 5-step guided onboarding
  - Welcome screen
  - Profile creation
  - Interests selection
  - Permission requests
  - Tutorial completion
- **User Profiles**: Customizable user profiles
  - Display name and bio
  - Profile photo upload
  - Interest tags
- **Room Discovery**: Browse and search public rooms
  - Category filters
  - Room previews
  - Join/leave functionality
- **Push Notifications**: FCM-powered notifications
  - Room invitations
  - Tip received alerts
  - System announcements
- **Analytics & Monitoring**: Firebase Analytics, Crashlytics, and Performance Monitoring
  - Comprehensive event tracking
  - Error reporting with context
  - Performance traces for critical paths

### Changed

- Migrated state management to Riverpod 3.x
- Updated all Firebase dependencies to latest versions
- Improved video encoding settings for better quality

### Fixed

- Room join reliability on slow networks
- Memory leaks in video tile management
- Audio echo in multi-participant calls

### Security

- Implemented rate limiting on API calls
- Added Firebase Auth token refresh handling
- Secured Agora token generation

## [Unreleased]

### Planned

- Screen sharing for presentations
- Virtual backgrounds
- Recording and playback
- Group chat messaging
- Friend system with invitations
