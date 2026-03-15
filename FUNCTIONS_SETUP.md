# Firebase Functions Environment Setup Guide

## 🔧 Environment Variables for Functions

Firebase Functions need Agora credentials to generate tokens. You have two options:

### Option 1: Use .env file (Recommended for development)

1. Create `functions/.env`:

```env
AGORA_APP_ID=ec1b578586d24976a89d787d9ee4d5c7
AGORA_APP_CERTIFICATE=79a3e92a657042d08c3c26a26d1e70b6
```

2. The functions will read from this file automatically.

### Option 2: Use Firebase Functions Config (Production)

Set environment variables using Firebase CLI:

```powershell
firebase functions:config:set `
  agora.appid="ec1b578586d24976a89d787d9ee4d5c7" `
  agora.cert="79a3e92a657042d08c3c26a26d1e70b6" `
  --project mix-and-mingle-v2
```

View current config:

```powershell
firebase functions:config:get --project mix-and-mingle-v2
```

## 🚀 Deployment Commands

### Full Deployment (Hosting + Functions)

```powershell
.\deploy.ps1
```

### Hosting Only (Fast, skip functions)

```powershell
.\deploy-hosting-only.ps1
```

### Functions Only (After hosting is live)

```powershell
.\deploy-functions-only.ps1
```

## 🧪 Testing Functions Locally

### Start Firebase Emulator

```powershell
firebase emulators:start --only functions
```

This will:

- Start functions on http://localhost:5001
- Show initialization errors immediately
- Let you test token generation without deploying

### Test Agora Token Generation

From your Flutter app, the function is called at:

```
https://us-central1-mix-and-mingle-v2.cloudfunctions.net/generateAgoraToken
```

Or locally:

```
http://localhost:5001/mix-and-mingle-v2/us-central1/generateAgoraToken
```

## ⚠️ Troubleshooting Function Timeout

If you see: "User code failed to load. Cannot determine backend specification. Timeout after 10000."

### 1. Check function initialization

```powershell
cd functions
node -e "require('./index.js'); console.log('OK')"
```

### 2. View deployment logs

```powershell
firebase functions:log --project mix-and-mingle-v2
```

### 3. Common causes:

- ❌ Missing dependencies: Run `npm install` in functions/
- ❌ Syntax errors: Check logs for JavaScript errors
- ❌ Heavy initialization: Move blocking code inside function handlers
- ❌ Missing env vars: Verify AGORA_APP_ID and AGORA_APP_CERTIFICATE

## ✅ Current Configuration

**Functions Fixed:**

- ✅ Added 30s timeout (up from 10s default)
- ✅ Added 256MB memory allocation
- ✅ Lazy-loading of push notification module
- ✅ Proper error handling
- ✅ Environment variable validation

**generateAgoraToken Configuration:**

- Timeout: 30 seconds
- Memory: 256MB
- Auth: Required (Firebase Auth)
- CORS: Enabled

## 📊 Monitoring

View function logs:

```powershell
# All logs
firebase functions:log --project mix-and-mingle-v2

# Only errors
firebase functions:log --only generateAgoraToken --project mix-and-mingle-v2
```

Check function metrics:

- Firebase Console → Functions → Usage tab
- See invocations, errors, execution time

## 🔐 Security Notes

- Functions automatically verify Firebase Auth tokens
- Private room access is validated before token generation
- Tokens expire after 24 hours
- Invalid tokens are automatically logged
