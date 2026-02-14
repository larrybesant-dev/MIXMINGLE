#!/bin/bash

# ==============================
# MIX & MINGLE – ONE-COMMAND DEPLOY
# ==============================

echo "🚀 Starting Mix & Mingle Production Deployment"

# 1️⃣ Clean & Get Packages
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Getting packages..."
flutter pub get

# 2️⃣ Analyze for Errors
echo "🔍 Analyzing code..."
flutter analyze
if [ $? -ne 0 ]; then
  echo "❌ Analyze found issues. Fix them before deployment."
  exit 1
fi

# 3️⃣ Build Web Release
echo "🌐 Building Web Release..."
flutter build web --release
if [ $? -ne 0 ]; then
  echo "❌ Web build failed."
  exit 1
fi

# 4️⃣ Deploy Firebase Hosting + Functions
echo "☁️ Deploying Firebase Hosting + Functions..."
firebase deploy --only hosting,functions
if [ $? -ne 0 ]; then
  echo "❌ Firebase deployment failed."
  exit 1
fi

echo "✅ Web + Functions deployed successfully!"

# 5️⃣ Optional Mobile Builds
read -p "Do you want to build Android & iOS releases? (y/N): " BUILD_MOBILE
if [[ "$BUILD_MOBILE" == "y" || "$BUILD_MOBILE" == "Y" ]]; then
    echo "🤖 Building Android App Bundle..."
    flutter build appbundle --release
    if [ $? -ne 0 ]; then
      echo "❌ Android build failed."
    else
      echo "✅ Android build ready (AAB in build/app/outputs/bundle/release/)"
    fi

    echo "🍎 Building iOS App..."
    flutter build ios --release
    if [ $? -ne 0 ]; then
      echo "❌ iOS build failed."
    else
      echo "✅ iOS build ready (archive in Xcode required)"
    fi
fi

echo "🎉 Deployment process complete!"
