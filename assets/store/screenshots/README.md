# Screenshot Templates for App Store Listings

This directory contains screenshot templates for App Store (iOS) and Play Store (Android) listings.

## Required Screenshots

### iOS App Store

#### iPhone 6.5" (Required)

- Resolution: 1284 x 2778 pixels
- Device: iPhone 14 Pro Max / 15 Pro Max

#### iPhone 5.5" (Required for older support)

- Resolution: 1242 x 2208 pixels
- Device: iPhone 8 Plus

#### iPad 12.9" (If supporting iPad)

- Resolution: 2048 x 2732 pixels
- Device: iPad Pro 12.9"

### Google Play Store

#### Phone

- Minimum: 320px
- Maximum: 3840px
- Recommended: 1080 x 1920 pixels

#### 7-inch Tablet

- Resolution: 1024 x 600 to 1080 x 1920 pixels

#### 10-inch Tablet

- Resolution: 1200 x 1920 pixels

#### Feature Graphic (Required)

- Resolution: 1024 x 500 pixels

---

## Screenshot Content

### 1. Onboarding / Welcome

- **File**: `01_onboarding.png`
- **Content**: Welcome screen showing app branding and value proposition
- **Text Overlay**: "Connect with people worldwide"

### 2. Room Discovery

- **File**: `02_discovery.png`
- **Content**: Room list with live participant previews
- **Text Overlay**: "Discover live video rooms"

### 3. Multi-Cam Video

- **File**: `03_multicam.png`
- **Content**: Active video room with 4-6 participants
- **Text Overlay**: "Chat with multiple people"

### 4. Spotlight Mode

- **File**: `04_spotlight.png`
- **Content**: Featured broadcaster in spotlight view
- **Text Overlay**: "Take the spotlight"

### 5. Host Tools

- **File**: `05_host_tools.png`
- **Content**: Host control panel with moderation options
- **Text Overlay**: "Host your own rooms"

### 6. VIP Features

- **File**: `06_vip.png`
- **Content**: VIP membership benefits and badges
- **Text Overlay**: "Go VIP for exclusive access"

### 7. Coin Store

- **File**: `07_coins.png`
- **Content**: Coin packages and gift options
- **Text Overlay**: "Send gifts to your favorites"

### 8. Profile

- **File**: `08_profile.png`
- **Content**: User profile with membership badge
- **Text Overlay**: "Express yourself"

---

## Design Guidelines

### Branding Colors

- Primary: Neon Purple (#A855F7)
- Secondary: Neon Pink (#EC4899)
- Background: Dark (#0D0D0D)
- Text: White (#FFFFFF)

### Typography

- Headlines: Bold, 48-64px
- Subtext: Regular, 24-32px
- Font: System default or Poppins

### Do's

- ✅ Show actual app UI
- ✅ Use high-quality mock device frames
- ✅ Include benefit-focused text overlays
- ✅ Show diverse, happy users (stock photos)
- ✅ Use consistent branding across all screenshots

### Don'ts

- ❌ Don't show placeholder content
- ❌ Don't use copyrighted music/video content
- ❌ Don't include sensitive user information
- ❌ Don't show debug UI elements
- ❌ Don't use inconsistent styling

---

## App Preview Video (Optional)

### iOS App Preview

- Duration: 15-30 seconds
- Resolution: 1080 x 1920 (portrait) or 1920 x 1080 (landscape)
- Format: H.264 + AAC, .mov or .mp4

### Google Play Promo Video

- Duration: 30 seconds to 2 minutes
- Upload to YouTube and link
- Include audio/music

### Video Content Suggestions

1. **Opening** (3s): Logo animation
2. **Onboarding** (5s): Quick profile setup
3. **Discovery** (5s): Browsing rooms
4. **Video Chat** (10s): Multi-participant room
5. **Features** (5s): Spotlight, gifts, host tools
6. **Closing** (2s): Call to action

---

## Tools for Screenshot Creation

### Recommended

- **Figma**: Design and mockup
- **Shots.so**: Device frames
- **Rotato**: 3D device mockups
- **Canva**: Quick text overlays

### Automation

- `flutter screenshot` for capturing app screens
- ImageMagick for batch processing
- GitHub Actions for CI screenshot generation

---

## Localization

If supporting multiple languages, create screenshot sets for:

- English (US) - en-US
- Spanish - es
- French - fr
- German - de
- Japanese - ja
- Portuguese (Brazil) - pt-BR
- Chinese (Simplified) - zh-Hans

File naming convention:
`{locale}/{number}_{name}.png`

Example:

- `en-US/01_onboarding.png`
- `es/01_onboarding.png`
