#!/bin/bash

# ============================================================
# iOS Build Script for Mix & Mingle
# ============================================================
# Usage:
#   ./tool/build_ios.sh [flavor] [build_type]
#
# Examples:
#   ./tool/build_ios.sh production internal    # TestFlight internal
#   ./tool/build_ios.sh production release     # App Store release
# ============================================================

set -e

FLAVOR=${1:-production}
BUILD_TYPE=${2:-internal}
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
BUILD_NUMBER=$(grep 'version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f2)

echo "============================================================"
echo "🍎 Mix & Mingle iOS Build"
echo "============================================================"
echo "Flavor:       $FLAVOR"
echo "Build Type:   $BUILD_TYPE"
echo "Version:      $VERSION"
echo "Build Number: $BUILD_NUMBER"
echo "============================================================"

# Navigate to project root
cd "$(dirname "$0")/.."

# ============================================================
# 1. CLEAN BUILD
# ============================================================
echo ""
echo "🧹 Cleaning previous builds..."
flutter clean
rm -rf build/ios

# ============================================================
# 2. GET DEPENDENCIES
# ============================================================
echo ""
echo "📦 Getting dependencies..."
flutter pub get

# ============================================================
# 3. IOS POD INSTALL
# ============================================================
echo ""
echo "🍫 Installing CocoaPods..."
cd ios
pod install --repo-update
cd ..

# ============================================================
# 4. FLUTTER BUILD IOS
# ============================================================
echo ""
echo "🔨 Building iOS archive..."

if [ "$BUILD_TYPE" = "release" ]; then
    flutter build ios --flavor $FLAVOR --release \
        --build-name=$VERSION \
        --build-number=$BUILD_NUMBER
else
    flutter build ios --flavor $FLAVOR --release
fi

# ============================================================
# 5. CREATE ARCHIVE
# ============================================================
echo ""
echo "📦 Creating Xcode archive..."
cd ios

SCHEME="${FLAVOR^}"  # Capitalize first letter
if [ "$FLAVOR" = "production" ]; then
    SCHEME="Runner"  # Default scheme for production
fi

xcodebuild -workspace Runner.xcworkspace \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath build/Runner.xcarchive \
    archive

# ============================================================
# 6. EXPORT IPA
# ============================================================
echo ""
echo "📤 Exporting IPA..."

# Create ExportOptions.plist if not exists
if [ ! -f "ExportOptions.plist" ]; then
    cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF
fi

xcodebuild -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportPath build/ipa \
    -exportOptionsPlist ExportOptions.plist

cd ..

# ============================================================
# 7. UPLOAD TO TESTFLIGHT (Optional)
# ============================================================
if [ "$BUILD_TYPE" = "internal" ]; then
    echo ""
    echo "✈️ Ready for TestFlight upload!"
    echo "IPA Location: ios/build/ipa/"
    echo ""
    echo "To upload manually:"
    echo "  1. Open Xcode -> Organizer"
    echo "  2. Or use: xcrun altool --upload-app -f ios/build/ipa/*.ipa -t ios"
fi

# ============================================================
# 8. SUCCESS
# ============================================================
echo ""
echo "============================================================"
echo "✅ iOS Build Complete!"
echo "============================================================"
echo "IPA: ios/build/ipa/Runner.ipa"
echo "Archive: ios/build/Runner.xcarchive"
echo ""
echo "Next Steps:"
if [ "$BUILD_TYPE" = "internal" ]; then
    echo "  1. Upload to TestFlight via Xcode Organizer or Transporter"
    echo "  2. After processing, invite internal testers"
else
    echo "  1. Upload to App Store Connect"
    echo "  2. Submit for App Review"
fi
echo "============================================================"
