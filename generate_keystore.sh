#!/bin/bash

# EduBot Production Keystore Generation Script
# Run this script to generate your production keystore for Play Store submission

echo "🔑 EduBot Production Keystore Generator"
echo "======================================="
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "1. Use a STRONG password (minimum 12 characters)"
echo "2. Mix uppercase, lowercase, numbers, and symbols"
echo "3. NEVER share your keystore or passwords"
echo "4. BACKUP your keystore securely - losing it means you cannot update your app"
echo ""
echo "📋 You will be prompted for the following information:"
echo "   - Keystore password (REMEMBER THIS!)"
echo "   - Key password (can be same as keystore password)"
echo "   - Your name"
echo "   - Your organizational unit (can be 'Developer' or 'EduBot Team')"
echo "   - Your organization name (your company/personal name)"
echo "   - Your city"
echo "   - Your state/province"
echo "   - Your country code (e.g., US, UK, MY, etc.)"
echo ""
echo "🚀 Starting keystore generation..."
echo ""

# Navigate to android directory
cd "$(dirname "$0")/android"

# Generate the keystore
keytool -genkey -v \
    -keystore upload-keystore.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias upload

echo ""
echo "✅ Keystore generation completed!"
echo ""
echo "📁 Your keystore has been saved as: android/upload-keystore.jks"
echo ""
echo "🔒 NEXT STEPS:"
echo "1. Create android/key.properties file with your passwords"
echo "2. Update build.gradle.kts to use the keystore"
echo "3. Test your release build"
echo "4. BACKUP your keystore file securely"
echo ""
echo "⚠️  CRITICAL: Never commit upload-keystore.jks or key.properties to git!"