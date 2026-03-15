# Google Play Store Data Safety Documentation

# Version: 1.0.0

# Last Updated: 2026-02-09

# This document outlines the data collection and sharing practices for Mix & Mingle

# as required by Google Play's Data Safety section.

## Overview

Mix & Mingle is a live video chat platform that collects certain user data
to provide its core functionality. This document explains what data is collected,
why it is collected, and how it is used.

---

## Data Types Collected

### 1. Personal Information

#### Name

- **Collected**: Yes
- **Shared**: No
- **Purpose**: Account creation and display name in rooms
- **Required**: Yes
- **User Control**: Can edit in profile settings

#### Email Address

- **Collected**: Yes
- **Shared**: No
- **Purpose**: Account authentication and communication
- **Required**: Yes
- **User Control**: Account deletion available

---

### 2. Financial Information

#### Purchase History

- **Collected**: Yes
- **Shared**: Yes (with payment processors)
- **Shared With**: RevenueCat, Stripe, Apple/Google
- **Purpose**: Process in-app purchases and subscriptions
- **Required**: No (only if user makes purchases)
- **User Control**: Purchase history viewable in app

#### Payment Information

- **Collected**: No (handled by platform)
- **Note**: Payment card details are handled by Apple App Store / Google Play
  and are never stored directly by Mix & Mingle

---

### 3. Photos and Videos

#### Profile Photo

- **Collected**: Yes
- **Shared**: Yes (displayed to other users)
- **Purpose**: User identification in rooms
- **Required**: No
- **User Control**: Can upload, change, or remove

#### Video Streams

- **Collected**: Temporarily during calls
- **Shared**: Yes (with room participants via Agora)
- **Purpose**: Real-time video communication
- **Required**: No (can join audio-only)
- **User Control**: Can toggle camera on/off
- **Retention**: Not stored; real-time only

---

### 4. Audio

#### Voice Data

- **Collected**: Temporarily during calls
- **Shared**: Yes (with room participants via Agora)
- **Purpose**: Real-time audio communication
- **Required**: No (can mute)
- **User Control**: Can toggle microphone on/off
- **Retention**: Not stored; real-time only

---

### 5. App Activity

#### In-App Interactions

- **Collected**: Yes
- **Shared**: Yes (with Firebase Analytics)
- **Purpose**: Improve app experience and features
- **Required**: Yes (for app functionality)
- **Examples**:
  - Rooms joined/created
  - Features used
  - Session duration
  - Screen views

#### In-App Search History

- **Collected**: Yes
- **Shared**: No
- **Purpose**: Improve search recommendations
- **Required**: No
- **Retention**: Local device only

---

### 6. App Info and Performance

#### Crash Logs

- **Collected**: Yes
- **Shared**: Yes (with Firebase Crashlytics)
- **Purpose**: Identify and fix app issues
- **Required**: Yes (for stability)
- **User Control**: Opt-out available in settings

#### Diagnostics

- **Collected**: Yes
- **Shared**: Yes (with Firebase Performance)
- **Purpose**: Monitor app performance
- **Required**: Yes (for optimization)
- **Examples**:
  - App startup time
  - Room join latency
  - Frame rate metrics

---

### 7. Device and Other Identifiers

#### Device ID

- **Collected**: Yes
- **Shared**: Yes (with Firebase)
- **Purpose**: Analytics and fraud prevention
- **Required**: Yes
- **User Control**: Reset via device settings

#### Firebase Installation ID

- **Collected**: Yes
- **Shared**: No
- **Purpose**: Push notifications and analytics
- **Required**: Yes

---

## Security Practices

### Data Encryption

- **In Transit**: All data is encrypted using TLS 1.2+
- **At Rest**: User data is encrypted in Firebase/Firestore
- **Video/Audio**: End-to-end encrypted via Agora

### Data Access Controls

- Authentication required for all API calls
- Role-based access for moderation features
- Rate limiting on sensitive operations

### Data Retention

| Data Type           | Retention Period            |
| ------------------- | --------------------------- |
| Account data        | Until deletion requested    |
| Transaction history | 7 years (legal requirement) |
| Analytics data      | 14 months                   |
| Crash logs          | 90 days                     |
| Video/audio streams | Not retained                |

---

## User Rights and Controls

### Data Access

Users can view their data through:

- Profile settings
- Transaction history
- Downloaded data export (available on request)

### Data Deletion

Users can request account deletion through:

- In-app settings → Account → Delete Account
- Email: support@mixmingle.app

Upon deletion:

- Account data removed within 30 days
- Analytics data anonymized
- Transaction records retained for legal compliance

### Data Portability

Users can request a copy of their data by:

- Email: privacy@mixmingle.app
- Response time: Within 30 days

---

## Third-Party Services

### Firebase (Google)

- Services: Authentication, Firestore, Analytics, Crashlytics, Performance
- Privacy Policy: https://firebase.google.com/support/privacy

### Agora

- Services: Real-time video/audio communication
- Privacy Policy: https://www.agora.io/privacy-policy

### RevenueCat

- Services: In-app purchase management
- Privacy Policy: https://www.revenuecat.com/privacy

---

## Contact Information

For privacy-related inquiries:

- Email: privacy@mixmingle.app
- Website: https://mixmingle.app/privacy

Data Protection Officer:

- Email: dpo@mixmingle.app

---

## Updates to This Document

This document is updated whenever our data practices change.
Last update: 2026-02-09

Users will be notified of significant changes through:

- In-app notification
- Email (for registered users)
- App Store update notes
