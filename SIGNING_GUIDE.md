# 🔐 App Signing Guide for EduBot

## Before Publishing to Google Play Store

You **MUST** create a proper release keystore before publishing. The current configuration is using debug keys which are NOT suitable for production.

## Step 1: Generate Release Keystore

Run this command in your terminal:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Follow the prompts and remember:
# - Choose a STRONG password
# - Keep the alias name as 'upload'
# - Store the keystore file securely
```

## Step 2: Create Key Properties File

Create `android/key.properties` (DO NOT commit this file):

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=upload-keystore.jks
```

## Step 3: Update build.gradle.kts

Replace the current signingConfigs section with:

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing configuration ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ... rest of configuration
        }
    }
}
```

## Step 4: Secure Your Files

Add these to your `.gitignore`:
```
android/key.properties
android/upload-keystore.jks
```

## Step 5: Test Release Build

```bash
flutter build appbundle --release
```

## 🚨 IMPORTANT SECURITY NOTES

1. **NEVER** commit keystore files or key.properties to version control
2. **BACKUP** your keystore file securely - if lost, you cannot update your app
3. **USE STRONG PASSWORDS** - minimum 12 characters with mixed case, numbers, symbols
4. **STORE SEPARATELY** - keep keystore and passwords in different secure locations

## Current Status

❌ **NOT READY FOR PRODUCTION** - Still using debug keys
✅ **READY FOR DEVELOPMENT** - Can build and test locally

**Next Action**: Generate proper keystore before Play Store submission