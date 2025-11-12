# Android Configuration for EduBot

This document explains the Android SDK and NDK configuration for EduBot.

## 📱 Current Configuration

The project is configured with the following Android settings in `android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "com.haweeinc.edubot"
    compileSdk = 36                    // Required for camera_android plugin
    ndkVersion = "27.0.12077973"       // Required for multiple plugins
    
    defaultConfig {
        applicationId = "com.haweeinc.edubot"
        minSdk = flutter.minSdkVersion  // Minimum supported Android version
        targetSdk = 36                  // Target Android API level
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
```

## 🔧 Why These Versions?

### Android SDK 36
Required by the following plugins:
- `camera_android` - For homework photo scanning

### Android NDK 27.0.12077973
Required by multiple plugins:
- `audioplayers_android` - Audio playback functionality
- `camera_android` - Camera integration
- `flutter_plugin_android_lifecycle` - Lifecycle management
- `flutter_tts` - Text-to-speech audio
- `google_mlkit_commons` - ML Kit base functionality
- `google_mlkit_text_recognition` - OCR text recognition
- `image_picker_android` - Image selection
- `path_provider_android` - File system access
- `permission_handler_android` - Runtime permissions
- `shared_preferences_android` - Local data storage
- `sqflite_android` - SQLite database

## 🛠 Troubleshooting

### Build Errors Related to SDK/NDK Versions

If you encounter errors like:
```
Your project is configured to compile against Android SDK 35, but the following plugin(s) require to be compiled against a higher Android SDK version
```

**Solution**: The configuration has already been updated. Try:
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### Gradle Build Issues

If Gradle build fails:
1. Ensure Android Studio is updated
2. Check that Android SDK 36 is installed
3. Verify NDK 27.0.12077973 is available
4. Clear Gradle cache if needed:
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   ```

### Permission Issues

Some plugins require additional permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Camera permissions -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Audio permissions -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Storage permissions -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## 📋 Compatibility

### Minimum Requirements
- **Min SDK**: 21 (Android 5.0) - Set by Flutter
- **Target SDK**: 36 (Android 14) - Current configuration
- **Compile SDK**: 36 (Android 14) - Current configuration

### Device Support
- ✅ Android 5.0+ (API 21+)
- ✅ 32-bit and 64-bit architectures
- ✅ Phone and tablet form factors

## 🔄 Future Updates

When updating plugins, check if they require higher SDK/NDK versions:

```bash
# Check for outdated packages
flutter pub outdated

# Update packages
flutter pub upgrade

# Check for new SDK/NDK requirements in build output
flutter build apk --debug
```

## 📞 Support

If you encounter Android-specific build issues:

1. Check the [Flutter Android setup guide](https://docs.flutter.dev/get-started/install/macos#android-setup)
2. Review plugin documentation for specific requirements
3. Consult the [Android developer documentation](https://developer.android.com/studio/build/gradle-plugin-api-updates)

---

**Note**: These settings are optimized for EduBot's feature set and may need adjustment if adding new plugins with different requirements.
