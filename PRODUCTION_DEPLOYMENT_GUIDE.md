# MixMingle - Production Deployment Guide

## Overview

MixMingle is a social video chat platform built with Flutter, Firebase, and Agora RTC Engine. This guide covers deploying to production.

## System Requirements

- **Flutter**: 3.38.7 (stable)
- **Dart**: 3.10.7 (stable)
- **Node.js**: 20.x (for Firebase Functions)
- **Firebase CLI**: Latest
- **Platform Support**: Web, iOS, Android

## Architecture

```
┌─────────────┐
│   Flutter   │
│     App     │
└──────┬──────┘
       │
       ├─ Firebase Auth
       ├─ Cloud Firestore
       ├─ Cloud Functions
       ├─ Cloud Storage
       ├─ Firebase Messaging
       └─ Firebase Crashlytics
       │
       └─ Agora RTC (Video Chat)
```

## Pre-Deployment Checklist

- [ ] Code quality: `flutter analyze` → 0 issues
- [ ] Tests: `flutter test` → all passing
- [ ] Web build: `flutter build web --release` → successful
- [ ] Environment variables configured in `.env`
- [ ] Firebase project created and configured
- [ ] Agora RTC project setup complete
- [ ] SSL certificates ready for domain
- [ ] DNS records prepared

## Configuration

### Environment Setup

1. **Create `.env` file** in project root:

```env
# Firebase
FIREBASE_PROJECT_ID=mixmingle-prod
FIREBASE_API_KEY=<your-api-key>
FIREBASE_AUTH_DOMAIN=mixmingle-prod.firebaseapp.com
FIREBASE_STORAGE_BUCKET=mixmingle-prod.appspot.com
FIREBASE_MESSAGING_SENDER_ID=<your-sender-id>
FIREBASE_APP_ID=<your-app-id>

# Agora
AGORA_APP_ID=ec1b578586d24976a89d787d9ee4d5c7
AGORA_APP_CERTIFICATE=79a3e92a657042d08c3c26a26d1e70b6

# App
APP_VERSION=1.0.1+2
ENVIRONMENT=production
```

2. **Set Environment in Code**:

```dart
EnvironmentConfig.current = Environment.production;
```

## Deployment Steps

### 1. Firebase Setup

```bash
# Login to Firebase
firebase login

# Set project
firebase use --add

# Deploy security rules
firebase deploy --only firestore:rules

# Deploy functions
firebase deploy --only functions

# Deploy indexes
firebase deploy --only firestore:indexes
```

### 2. Web Build

```bash
# Clean previous build
flutter clean

# Build for web
flutter build web --release --dart-define=ENVIRONMENT=production

# Optimize assets
cd build/web
# Compress images, minimize JavaScript, etc.
cd ../..
```

### 3. Firebase Hosting

```bash
# Deploy web app
firebase deploy --only hosting
```

### 4. Verify Deployment

```bash
# Test production build
flutter build web --release

# Open in browser
open build/web/index.html

# Check Firestore rules
firebase firestore:describe

# Check deployed functions
firebase functions:list
```

## Monitoring

### Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Monitor:
   - **Firestore**: Database usage, real-time metrics
   - **Authentication**: Active users, sign-up funnels
   - **Crashlytics**: Crash rates, error trends
   - **Performance**: API latency, custom traces
   - **Cloud Functions**: Invocations, errors, duration

### Analytics Dashboard

- User acquisition and retention
- Feature usage
- Conversion funnels
- Custom events

### Real-Time Alerts

Configure in Firebase Console:
- Crash rate > 1%
- API latency > 500ms
- Authentication failures > 5%
- Firestore quota exceeded

## Security Checklist

- [ ] Firebase security rules deployed
- [ ] API keys restricted to specific domains/services
- [ ] Sensitive data encrypted
- [ ] Rate limiting configured
- [ ] User input validation on frontend
- [ ] Cloud Functions input validation
- [ ] CORS headers configured
- [ ] SSL/TLS certificates installed
- [ ] Regular security audits scheduled

## Performance Optimization

### Web

```bash
# Measure performance
flutter build web --release --profiling

# Check bundle size
du -sh build/web/

# Optimize images
flutter build web --split-per-locale
```

### Database

- Firestore composite indexes created
- Pagination implemented for large datasets
- Document subcollections used for scalability
- Cloud Firestore backups enabled

### CDN

- Assets cached with aggressive TTL
- Gzip compression enabled
- Image optimization enabled
- Lazy loading for widgets

## Maintenance

### Daily

- Monitor Crashlytics dashboard
- Check Firebase quotas
- Review error logs

### Weekly

- Analyze user metrics
- Review security logs
- Check performance trends

### Monthly

- Update dependencies
- Security patches
- Performance optimization
- Database cleanup

## Disaster Recovery

### Backup Strategy

```bash
# Enable daily backups
gcloud firestore backups create --retention=7d

# Restore from backup
gcloud firestore restore <backup-id>
```

### Rollback Procedure

```bash
# Revert to previous version
firebase deploy --only hosting --version=<previous-version>

# Or manually rollback
firebase hosting:channel:deploy <channel>
```

## Troubleshooting

### Common Issues

**Issue**: Firestore quota exceeded
- **Solution**: Increase quota in Firebase Console or optimize queries

**Issue**: High API latency
- **Solution**: Add Firestore indexes, check Network tab in browser

**Issue**: Users unable to join rooms
- **Solution**: Verify Agora token generation, check rate limits

**Issue**: Web build fails
- **Solution**: Run `flutter clean`, check Node.js version

## Support

- **Issues**: Create GitHub issue with environment details
- **Security**: Email security@mixmingle.app
- **Production Incidents**: Escalate through Firebase support

## Version History

| Version | Date | Notes |
|---------|------|-------|
| 1.0.1+2 | Jan 31, 2026 | MVP Launch |

---

**Last Updated**: January 31, 2026
