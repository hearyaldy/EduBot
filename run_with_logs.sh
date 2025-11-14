#!/bin/bash

# Script to run the app and capture detailed logs
# Usage: ./run_with_logs.sh

echo "=== EduBot Debug Log Capture ==="
echo "This will install and run the app with detailed logging"
echo ""

# Check if device is connected
echo "Checking for connected devices..."
flutter devices

echo ""
echo "Installing app on device..."
flutter install

echo ""
echo "=== Starting log capture (Press Ctrl+C to stop) ==="
echo "Filtering for EduBot-specific messages..."
echo ""

# Capture logs with color and filtering
adb logcat -c  # Clear old logs first
adb logcat | grep -E "(flutter|EDUBOT|AppProvider|Error|Exception|Fatal|✓|❌|⚠️)"
