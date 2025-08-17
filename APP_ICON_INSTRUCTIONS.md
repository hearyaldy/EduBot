
# EduBot App Icon Creation Instructions

## Icon Design Concept:
- **Background**: Purple to pink gradient (#4F46E5 to #EC4899)
- **Main Element**: Cute robot head with friendly eyes
- **Secondary Elements**: Book, question mark, mathematical symbols
- **Style**: Modern, friendly, parent-focused

## Colors Used:
- Primary Purple: #4F46E5
- Secondary Pink: #EC4899  
- Robot Color: #F8FAFC (light gray)
- Accent Blue: #6366F1
- Orange Book: #F59E0B

## Required Sizes:

### iOS (save as PNG):
- 20x20 (iOS notification icon)
- 29x29 (iOS settings icon)
- 40x40 (iOS spotlight icon)
- 58x58 (iOS settings icon @2x)
- 60x60 (iOS app icon)
- 80x80 (iOS spotlight icon @2x)
- 87x87 (iOS settings icon @3x)
- 120x120 (iOS app icon @2x)
- 180x180 (iOS app icon @3x)
- 1024x1024 (iOS App Store)

### Android (save as PNG):
- 36x36 (ldpi)
- 48x48 (mdpi)
- 72x72 (hdpi)
- 96x96 (xhdpi)
- 144x144 (xxhdpi)
- 192x192 (xxxhdpi)
- 512x512 (Google Play Store)

## Quick Setup:
1. Use the SVG file created at: assets/icons/app_icon.svg
2. Convert to PNG using online tools like:
   - https://convertio.co/svg-png/
   - https://cloudconvert.com/svg-to-png
   - Figma (import SVG, export as PNG in different sizes)

## Manual Alternative:
Use any graphic design tool (Figma, Canva, Photoshop) to create:
1. Rounded square background with purple-pink gradient
2. Friendly robot face in the center
3. Small book icon in corner
4. Optional: floating math symbols

Place the generated icons in:
- iOS: ios/Runner/Assets.xcassets/AppIcon.appiconset/
- Android: android/app/src/main/res/mipmap-*/ic_launcher.png
