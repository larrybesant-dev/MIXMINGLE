#!/bin/bash

# ============================================================
# Android Build Script for Mix & Mingle
# ============================================================
# Usage:
#   ./tool/build_android.sh [flavor] [build_type]
#
# Examples:
#   ./tool/build_android.sh production internal    # Play Console Internal
#   ./tool/build_android.sh production release     # Play Store release
# ============================================================

set -e

FLAVOR=${1:-production}
BUILD_TYPE=${2:-internal}
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
BUILD_NUMBER=$(grep 'version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f2)

echo "============================================================"
echo "🤖 Mix & Mingle Android Build"
echo "============================================================"
echo "Flavor:       $FLAVOR"
echo "Build Type:   $BUILD_TYPE"
echo "Version:      $VERSION"
echo "Build Number: $BUILD_NUMBER"
echo "============================================================"

# Navigate to project root
cd "$(dirname "$0")/.."

# ============================================================
# 1. VERIFY SIGNING CONFIG
# ============================================================
echo ""
echo "🔐 Verifying signing configuration..."

if [ ! -f "android/key.properties" ]; then
    echo "⚠️  Warning: android/key.properties not found"
    echo "Creating template..."

    cat > android/key.properties << EOF
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=../upload-keystore.jks
EOF

    echo "Please update android/key.properties with your signing credentials"
    echo "Then re-run this script."
    exit 1
fi

# ============================================================
# 2. CLEAN BUILD
# ============================================================
echo ""
echo "🧹 Cleaning previous builds..."
flutter clean
rm -rf build/app

# ============================================================
# 3. GET DEPENDENCIES
# ============================================================
echo ""
echo "📦 Getting dependencies..."
flutter pub get

# ============================================================
# 4. BUILD APP BUNDLE
# ============================================================
echo ""
echo "🔨 Building Android App Bundle..."

if [ "$BUILD_TYPE" = "release" ]; then
    flutter build appbundle \
        --flavor $FLAVOR \
        --release \
        --build-name=$VERSION \
        --build-number=$BUILD_NUMBER \
        --obfuscate \
        --split-debug-info=build/app/outputs/symbols
else
    flutter build appbundle \
        --flavor $FLAVOR \
        --release
fi

# ============================================================
# 5. BUILD APK (for testing)
# ============================================================
echo ""
echo "📱 Building APK for testing..."

flutter build apk \
    --flavor $FLAVOR \
    --release

# ============================================================
# 6. VERIFY OUTPUT
# ============================================================
echo ""
echo "🔍 Verifying build outputs..."

AAB_PATH="build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
APK_PATH="build/app/outputs/flutter-apk/app-${FLAVOR}-release.apk"

if [ -f "$AAB_PATH" ]; then
    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo "✅ App Bundle: $AAB_PATH ($AAB_SIZE)"
else
    echo "❌ App Bundle not found at expected path"
    # Try alternative path
    AAB_PATH=$(find build -name "*.aab" | head -1)
    if [ -n "$AAB_PATH" ]; then
        echo "   Found at: $AAB_PATH"
    fi
fi

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "✅ APK: $APK_PATH ($APK_SIZE)"
else
    echo "❌ APK not found at expected path"
fi

# ============================================================
# 7. ANALYZE BUNDLE (Optional)
# ============================================================
if command -v bundletool &> /dev/null; then
    echo ""
    echo "📊 Analyzing bundle..."
    bundletool build-apks --bundle="$AAB_PATH" \
        --output=build/app/outputs/apks.apks \
        --mode=universal
fi

# ============================================================
# 8. SUCCESS
# ============================================================
echo ""
echo "============================================================"
echo "✅ Android Build Complete!"
echo "============================================================"
echo "App Bundle: $AAB_PATH"
echo "APK:        $APK_PATH"
echo ""
echo "Next Steps:"
if [ "$BUILD_TYPE" = "internal" ]; then
    echo "  1. Go to Play Console -> Internal Testing"
    echo "  2. Upload the .aab file"
    echo "  3. Add internal testers"
    echo "  4. Publish to internal track"
else
    echo "  1. Go to Play Console -> Production"
    echo "  2. Create new release"
    echo "  3. Upload the .aab file"
    echo "  4. Submit for review"
fi
echo ""
echo "Debug Symbols (for Crashlytics):"
echo "  build/app/outputs/symbols/"
echo "============================================================"

# ============================================================
# 9. OPTIONAL: UPLOAD VIA CLI
# ============================================================
echo ""
echo "🚀 To upload via command line (requires setup):"
echo ""
echo "# Install fastlane:"
echo "  gem install fastlane"
echo ""
echo "# Upload to internal track:"
echo "  fastlane supply --track internal --aab $AAB_PATH"
echo ""
echo "# Upload to production:"
echo "  fastlane supply --track production --aab $AAB_PATH"
echo "============================================================"
