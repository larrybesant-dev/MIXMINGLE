# 🎯 SPEED DATING - QUICK START (2 MINUTES)

## ⚡ Deploy in 3 Commands

```powershell
# 1. Deploy Cloud Functions
cd functions
firebase deploy --only functions

# 2. Deploy Firestore Rules
firebase deploy --only firestore:rules

# 3. Run Flutter
flutter run -d chrome
```

---

## 📋 WHAT TO UPDATE

### 1. Update Routing (app_routes.dart)

Change import:

```dart
// OLD
import 'package:mixmingle/features/speed_dating/screens/speed_dating_lobby_page.dart';

// NEW
import 'package:mixmingle/features/speed_dating/screens/speed_dating_lobby_cloud.dart';
```

Change route:

```dart
GoRoute(
  path: '/speed-dating-lobby',
  builder: (context, state) => const SpeedDatingLobbyPageCloud(), // Add Cloud suffix
),
```

### 2. Firestore Rules

Copy content from `firestore_speed_dating.rules` to your main `firestore.rules` file.

OR deploy separately:

```powershell
firebase deploy --only firestore:rules --config firestore_speed_dating.rules
```

### 3. Test with 2 Users

1. Open Chrome (user 1)
2. Open Chrome Incognito (user 2)
3. Both login → navigate to Speed Dating
4. Both click "START MATCHING"
5. Wait ~30 seconds
6. Should auto-match and start video session!

---

## ✅ WHAT'S ALREADY DONE

✅ **Backend**: 806 lines of Cloud Functions
✅ **Providers**: 585 lines with backend integration
✅ **Lobby Screen**: Complete with queue count + preferences
✅ **Security Rules**: Production Firestore rules
✅ **Matching**: Server-side algorithm (age/gender/sexuality/verified)
✅ **Tokens**: Backend Agora token generation
✅ **Auto-expiry**: Sessions timeout after 5 minutes
✅ **Match Creation**: Creates chat if both like

---

## 🎬 Files Created

```
functions/src/
  ✅ speedDatingComplete.ts (806 lines)

lib/features/speed_dating/
  providers/
    ✅ speed_dating_queue_cloud.dart (223 lines)
    ✅ speed_dating_session_cloud.dart (362 lines)
  screens/
    ✅ speed_dating_lobby_cloud.dart (577 lines)

Security:
  ✅ firestore_speed_dating.rules

Documentation:
  ✅ SPEED_DATING_PRODUCTION_GUIDE.md (full guide)
  ✅ SPEED_DATING_QUICKSTART.md (this file)
```

---

## 🐛 If Something Breaks

**No matches?**

- Check Firebase Console > Firestore > speed_dating_queue (should see 2+ users)
- Check Functions > Logs > matchSpeedDating (runs every 30s)

**Token errors?**

- Run: `firebase functions:config:get agora`
- Should show appid + cert
- If not: `firebase functions:config:set agora.appid="ec1b578586d24976a89d787d9ee4d5c7" agora.cert="79a3e92a657042d08c3c26a26d1e70b6"`

**Video not loading?**

- Check browser camera permissions
- Check Agora App ID in Firebase config matches
- Check token expiration in Cloud Function logs

---

## 🎉 That's It!

See `SPEED_DATING_PRODUCTION_GUIDE.md` for complete documentation.

**Support**: Check Firebase Console > Functions > Logs for detailed error messages.
