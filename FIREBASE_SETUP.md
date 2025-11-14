# Firebase Setup Guide for EduBot

## Prerequisites

1. You need a Google account
2. Your app is already set up with package name: `com.edubot.app`

## Step 1: Install FlutterFire CLI (One-time setup)

```bash
# Install the FlutterFire CLI
dart pub global activate flutterfire_cli
```

## Step 2: Login to Firebase

```bash
# Login to your Google account
firebase login
```

If you don't have Firebase CLI installed, install it first:
```bash
# For macOS
curl -sL https://firebase.tools | bash

# Or using npm
npm install -g firebase-tools
```

## Step 3: Create/Select Firebase Project

Go to [Firebase Console](https://console.firebase.google.com/) and:
1. Create a new project (or select existing "edubot" project if you have one)
2. Name it "EduBot" or keep existing name
3. Enable Google Analytics (optional)
4. Wait for project creation

## Step 4: Auto-Configure Firebase

Run this command in your project directory:

```bash
cd /Users/hearyhealdysairin/Documents/Flutter/edubot
flutterfire configure
```

This will:
- ✅ Detect your Flutter app
- ✅ Show your Firebase projects
- ✅ Let you select or create a project
- ✅ Automatically configure Android, iOS, Web, etc.
- ✅ Generate the correct `firebase_options.dart` file
- ✅ Update Android and iOS files

## Step 5: Enable Authentication in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your EduBot project
3. Click "Authentication" in left sidebar
4. Click "Get Started"
5. Enable "Email/Password" authentication:
   - Click "Email/Password"
   - Toggle "Enable" switch
   - Click "Save"

## Step 6: Enable Firestore Database (for user data sync)

1. In Firebase Console, click "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location (choose closest to your users)
5. Click "Enable"

## Step 7: Add Security Rules (Important!)

In Firestore Rules tab, replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Allow reading user profiles for premium check
      allow read: if request.auth != null;
    }

    // Questions and explanations subcollections
    match /users/{userId}/questions/{questionId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /users/{userId}/explanations/{explanationId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 8: Test the Setup

```bash
# Rebuild the app
flutter clean
flutter build apk --debug

# Install and run
flutter install
```

You should see:
```
✓ Firebase initialized successfully
```

Instead of:
```
⚠️ Firebase not initialized
```

## What Firebase Enables

Once configured, your app will have:

✅ **Cloud User Authentication**
- Secure email/password login
- Password reset emails
- Email verification

✅ **Cloud Data Sync**
- Questions and answers sync across devices
- User profile stored in cloud
- Premium status synced

✅ **User Management**
- Track user stats
- Admin dashboard functionality
- Premium subscription tracking

✅ **Analytics** (if enabled)
- User behavior tracking
- Feature usage stats

## Current Status (Without Firebase)

Your app currently works with:
- ✅ Local storage only
- ✅ All features functional
- ✅ Data saved on device
- ❌ No cloud sync
- ❌ No cross-device sync
- ❌ No admin dashboard

## Troubleshooting

### "Command not found: flutterfire"

Make sure Flutter's bin directory is in your PATH:
```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### "No Firebase project found"

Create a project first at https://console.firebase.google.com/

### "Permission denied"

Run with sudo or check Firebase login:
```bash
firebase login --reauth
```

## Need Help?

Firebase Documentation: https://firebase.google.com/docs/flutter/setup
FlutterFire Documentation: https://firebase.flutter.dev/
