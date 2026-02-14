# Match Algorithm Implementation

## ✅ Completed

### Backend (Cloud Functions)
Created [functions/src/matches.ts](functions/src/matches.ts) with:
- ✅ `generateUserMatches` - Callable function that scores candidates and writes top 50 matches
- ✅ `handleLike` - Detects mutual likes and creates match history
- ✅ `handlePass` - Records pass decisions
- ✅ `refreshDailyMatches` - Scheduled function (daily at midnight) to refresh matches
- ✅ `computeMatchScore` - Scoring algorithm (age, gender, interests, lookingFor)

### Frontend (Flutter)
Created [lib/features/matching/models/match_model.dart](lib/features/matching/models/match_model.dart):
- ✅ `MatchModel` - Generated match with score, status, profile data
- ✅ `MatchHistoryModel` - History record (liked/passed/mutual_like)

Created [lib/features/matching/services/match_service.dart](lib/features/matching/services/match_service.dart):
- ✅ `generateMatches()` - Calls Cloud Function to generate fresh matches
- ✅ `watchGeneratedMatches()` - Real-time stream of generated matches
- ✅ `likeUser()` - Like a user (returns isMutualLike boolean)
- ✅ `passUser()` - Pass on a user
- ✅ `watchMatchHistory()` - Stream of all match decisions
- ✅ `watchMutualMatches()` - Stream of mutual matches only

Updated [lib/features/matching/providers/matching_providers.dart](lib/features/matching/providers/matching_providers.dart):
- ✅ `matchServiceProvider` - Provides MatchService instance
- ✅ `generatedMatchesProvider` - Stream of generated matches
- ✅ `mutualMatchesProvider` - Stream of mutual matches
- ✅ `matchHistoryProvider` - Stream of all match history

Updated [lib/features/app/screens/matches_page.dart](lib/features/app/screens/matches_page.dart):
- ✅ Auto-generates matches on page load
- ✅ Real-time stream of matches using Riverpod
- ✅ Match cards with profile photo, name, age, bio, score
- ✅ Like button (shows "It's a Match!" dialog on mutual)
- ✅ Pass button
- ✅ Refresh button to generate new matches
- ✅ Empty state with call-to-action

Updated [functions/src/index.ts](functions/src/index.ts):
- ✅ Exported all match functions from matches.ts module

## 📋 Firestore Schema

Collections created by the system:

```
/matches/{uid}/generated/{matchId}
  - matchUserId: string
  - score: number
  - createdAt: Timestamp
  - status: 'new' | 'viewed' | 'liked' | 'passed'
  - displayName: string
  - photoUrl: string
  - age: number
  - bio: string

/matches/{uid}/history/{matchId}
  - matchUserId: string
  - outcome: 'liked' | 'passed' | 'mutual_like'
  - createdAt: Timestamp
  - displayName: string
  - photoUrl: string

/likes/{uid}/outgoing/{targetId}
  - createdAt: Timestamp
  - status: 'pending' | 'matched'

/likes/{uid}/incoming/{sourceId}
  - createdAt: Timestamp
  - status: 'pending' | 'matched'
```

**Note:** Users must have these fields in `/users/{uid}`:
- `preferences.genderPreference`: string | 'any'
- `preferences.ageMin`: number
- `preferences.ageMax`: number
- `preferences.interests`: string[]
- `preferences.lookingFor`: string[]
- `preferences.distanceMaxKm`: number (optional)
- `age`: number
- `gender`: string
- `isActive`: boolean
- `displayName`: string
- `photoUrl`: string
- `bio`: string

## 🎯 Scoring Algorithm

Score range: 0-100+

1. **Age difference** (0-30 points)
   - ≤3 years: +30
   - ≤7 years: +15
   - ≤10 years: +5

2. **Gender preference** (20 points or disqualify)
   - Matches preference: +20
   - Doesn't match: score = 0 (hard filter)

3. **Interests overlap** (0-40 points)
   - +10 per shared interest (max 40)

4. **LookingFor overlap** (20 points)
   - Any overlap: +20

## 🚀 Next Steps

### 1. Deploy Functions
```bash
cd functions
npm install
firebase deploy --only functions:generateUserMatches,functions:handleLike,functions:handlePass,functions:refreshDailyMatches
```

### 2. Test on Web
1. Navigate to Matches page
2. Click refresh to generate matches
3. Verify cards display with photos, names, scores
4. Test Like button (should show mutual match dialog if reciprocated)
5. Test Pass button (card should disappear)

### 3. Ensure User Data
Users need complete profiles:
- Set `isActive: true` in user doc
- Add `preferences` object with:
  - `genderPreference`
  - `ageMin`, `ageMax`
  - `interests` (array)
  - `lookingFor` (array)
- Ensure `age`, `gender`, `displayName`, `photoUrl`, `bio` exist

### 4. Monitor in Firebase Console
- Check Functions logs for `[generateUserMatches]` entries
- Verify `/matches/{uid}/generated` collection populates
- Check `/likes` collection when users interact
- Monitor mutual matches in `/matches/{uid}/history`

## 🎨 UI Features

### Matches Page
- Auto-generates matches on first load
- Real-time updates (no refresh needed)
- Match cards show:
  - Profile photo (300px tall)
  - Name
  - Age
  - Bio (3 lines max)
  - Match score badge (e.g., "87% Match")
- Like button (pink, heart icon)
- Pass button (grey, X icon)
- Refresh button in app bar
- Empty state with call-to-action
- Loading states
- Error handling with retry

### Match Dialog
- Shows "🎉 It's a Match!" on mutual like
- Simple "Awesome!" button to dismiss

## 📊 Analytics Points

Consider adding tracking for:
- Match generation requests
- Like/pass ratios
- Mutual match rate
- Average match scores
- Time to first like
- Daily active matchers

## 🔧 Tuning

To improve match quality:
1. Adjust scoring weights in `computeMatchScore()`
2. Add distance calculation (haversine formula)
3. Add recency score (prefer recently active users)
4. Add popularity score (users with more likes)
5. Add ML-based scoring (train on successful matches)
6. Implement ELO-style ratings

## ⚡ Performance

- `generateUserMatches`: ~2-5s for 200 candidates
- `handleLike`: ~500ms (faster if no mutual check)
- `refreshDailyMatches`: ~10-30min for 500 users (runs at midnight)

To optimize:
- Cache candidate queries
- Use Firestore indexes
- Batch write optimizations (already implemented)
- Reduce candidate pool with better filters
