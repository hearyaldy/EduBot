#!/bin/bash

echo "=========================================="
echo "   EduBot Firebase Setup Script"
echo "=========================================="
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found"
    echo ""
    echo "Installing Firebase CLI..."
    echo ""
    curl -sL https://firebase.tools | bash

    if [ $? -ne 0 ]; then
        echo "❌ Failed to install Firebase CLI"
        echo "Please install manually: https://firebase.google.com/docs/cli"
        exit 1
    fi

    echo "✓ Firebase CLI installed"
fi

# Check if FlutterFire CLI is installed
if ! command -v flutterfire &> /dev/null; then
    echo "❌ FlutterFire CLI not found"
    echo ""
    echo "Installing FlutterFire CLI..."
    dart pub global activate flutterfire_cli

    if [ $? -ne 0 ]; then
        echo "❌ Failed to install FlutterFire CLI"
        exit 1
    fi

    # Add to PATH
    export PATH="$PATH:$HOME/.pub-cache/bin"

    echo "✓ FlutterFire CLI installed"
fi

echo ""
echo "=========================================="
echo "   Step 1: Firebase Login"
echo "=========================================="
echo ""
echo "This will open your browser to login to Firebase"
read -p "Press Enter to continue..."

firebase login

if [ $? -ne 0 ]; then
    echo "❌ Firebase login failed"
    exit 1
fi

echo ""
echo "✓ Firebase login successful"
echo ""

echo "=========================================="
echo "   Step 2: Configure Firebase"
echo "=========================================="
echo ""
echo "This will:"
echo "  - List your Firebase projects"
echo "  - Let you select or create a project"
echo "  - Auto-configure your app"
echo "  - Generate firebase_options.dart"
echo ""
read -p "Press Enter to continue..."

flutterfire configure

if [ $? -ne 0 ]; then
    echo "❌ Firebase configuration failed"
    exit 1
fi

echo ""
echo "✓ Firebase configured successfully"
echo ""

echo "=========================================="
echo "   Next Steps (Manual)"
echo "=========================================="
echo ""
echo "1. Enable Authentication:"
echo "   → Go to: https://console.firebase.google.com/"
echo "   → Select your project"
echo "   → Click 'Authentication' → 'Get Started'"
echo "   → Enable 'Email/Password'"
echo ""
echo "2. Enable Firestore Database:"
echo "   → Click 'Firestore Database'"
echo "   → Create database in 'test mode'"
echo ""
echo "3. Rebuild the app:"
echo "   → flutter clean && flutter build apk --debug"
echo ""
echo "For detailed instructions, see: FIREBASE_SETUP.md"
echo ""
echo "=========================================="
echo "   Setup Complete! 🎉"
echo "=========================================="
