# Dark Mode Issue Fixes

## 🔴 Issue: "Member not found: 'darkTheme'" Error

If you're seeing this error:
```
lib/main.dart:136:26: Error: Member not found: 'darkTheme'.
                AppTheme.darkTheme.textTheme,
                         ^^^^^^^^^
lib/main.dart:134:33: Error: Member not found: 'darkTheme'.
            darkTheme: AppTheme.darkTheme.copyWith(
```

## ✅ Quick Fix

This is a **caching issue** with Flutter. The code is correct, but Flutter needs to rebuild everything.

### Solution:

Run these commands in your terminal:

```bash
# Step 1: Clean the project
flutter clean

# Step 2: Get dependencies
flutter pub get

# Step 3: Run the app (or build)
flutter run
```

**Or in one command:**
```bash
flutter clean && flutter pub get && flutter run
```

That's it! The error should be gone.

---

## 🔴 Issue: Dark Mode Toggle Not Showing in Settings

If you don't see the dark mode toggle in Settings:

### Check 1: Is the toggle there but you missed it?

1. Open the app
2. Go to Settings (via FAB menu or navigation)
3. Look in the **"Preferences"** section
4. You should see **"Dark Mode"** with a switch

### Check 2: Hot Reload Issue

Sometimes hot reload doesn't apply all changes:

1. **Stop the app completely** (don't just hot reload)
2. **Run it again**: `flutter run`
3. Go to Settings → Preferences
4. Dark Mode toggle should appear

### Check 3: File Changes Not Applied

If still not showing:

```bash
# Force rebuild
flutter clean
flutter pub get
flutter run
```

---

## 🔴 Issue: Dark Mode Toggle Exists But Doesn't Work

If the toggle is there but doesn't change the theme:

### Check 1: Are you using Provider correctly?

The app uses Provider for state management. Make sure:

1. AppProvider is wrapped around MaterialApp (already done in main.dart)
2. You're not using `context` across async gaps

### Check 2: Check Debug Logs

When you toggle dark mode, you should see in console:
```
✓ Preferences loaded (darkMode: true)
```

If you don't see this, there might be an issue with storage.

### Check 3: Restart the App

After toggling:
1. Close the app completely
2. Reopen it
3. Theme should persist

---

## 🧪 Testing Dark Mode

### Manual Test:

1. **Open app** (make sure it's freshly built)
2. **Go to Settings** → Preferences section
3. **Find "Dark Mode"** toggle (should have sun/moon icon)
4. **Toggle it ON**
5. **See immediate change**: App should turn dark
6. **Toggle it OFF**: App should return to light mode
7. **Close and reopen app**: Theme should persist

### What Should Happen:

**Light Mode (Default):**
- White/light gray backgrounds
- Dark text
- Blue primary color (#2563EB)

**Dark Mode:**
- Dark gray/black backgrounds (#111827)
- Light text (#F9FAFB)
- Bright blue accents (#3B82F6)
- All screens should adapt

### Screens That Should Change:
- ✅ Home screen
- ✅ Settings screen
- ✅ Profile screen
- ✅ Scan homework screen
- ✅ Ask question screen
- ✅ History screen
- ✅ All dialogs and cards
- ✅ Bottom navigation
- ✅ FAB menu

---

## 🔍 Verify Implementation

### Check these files exist and have the right code:

1. **lib/utils/app_theme.dart**
   - Should have `static ThemeData get darkTheme { ... }`
   - Around line 216

2. **lib/main.dart**
   - Should have `darkTheme: AppTheme.darkTheme.copyWith(...)`
   - Should have `themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light`
   - Lines 134-139

3. **lib/providers/app_provider.dart**
   - Should have `bool _isDarkMode = false;`
   - Should have `bool get isDarkMode => _isDarkMode;`
   - Should have `Future<void> setThemeMode(bool isDark)` method

4. **lib/screens/settings_screen.dart**
   - Should have dark mode SwitchListTile in Preferences section
   - Lines 195-210

### Quick Verification Command:

```bash
# Check all dark mode related code exists
grep -r "darkTheme\|isDarkMode\|setThemeMode" lib/
```

You should see multiple matches in the files listed above.

---

## 🐛 Common Issues

### Issue 1: "setState called after dispose"

**Symptom**: Error when toggling theme
**Fix**: Already handled with `if (mounted)` checks

### Issue 2: Theme doesn't persist

**Symptom**: Theme resets after app restart
**Fix**:
- Make sure SharedPreferences is working
- Check storage permissions
- Run: `flutter clean && flutter pub get`

### Issue 3: Only some screens change theme

**Symptom**: Some screens stay light/dark
**Fix**: Those screens are using hardcoded colors instead of theme colors
- Need to update those screens to use `Theme.of(context)`

### Issue 4: Text is invisible

**Symptom**: Can't read text in dark mode
**Fix**: Use theme text colors:
```dart
// Good
Text(
  'Hello',
  style: Theme.of(context).textTheme.bodyLarge,
)

// Bad
Text(
  'Hello',
  style: TextStyle(color: Colors.black), // Will be invisible in dark mode
)
```

---

## 📱 Build Commands

### For Testing:

```bash
# Android
flutter run

# iOS
flutter run

# With clean build
flutter clean && flutter pub get && flutter run
```

### For Production:

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## ✅ Verification Checklist

Use this checklist to verify everything works:

- [ ] `flutter clean` completed without errors
- [ ] `flutter pub get` completed without errors
- [ ] `flutter analyze` shows no errors
- [ ] App builds successfully
- [ ] App runs without crashes
- [ ] Settings screen loads
- [ ] "Preferences" section visible
- [ ] "Dark Mode" toggle visible
- [ ] Toggle has sun/moon icon
- [ ] Clicking toggle changes theme immediately
- [ ] All screens adapt to theme
- [ ] Text is readable in both modes
- [ ] Close and reopen app - theme persists
- [ ] Console shows "darkMode: true/false" logs

---

## 🆘 Still Having Issues?

If none of the above works:

1. **Share your error logs**: Copy the full error message from terminal
2. **Check Flutter version**: Run `flutter --version`
3. **Check Dart version**: Run `dart --version`
4. **Try on different device/emulator**: Sometimes device-specific issues occur
5. **Check file encoding**: Make sure files are UTF-8 encoded
6. **Delete and re-clone**: Last resort - clone the repo again

---

## 📞 Quick Support Commands

```bash
# Check Flutter installation
flutter doctor -v

# Check for issues
flutter analyze

# Clean everything
flutter clean
rm -rf build/
rm -rf .dart_tool/

# Reinstall dependencies
flutter pub get

# Run in verbose mode
flutter run -v
```

---

**Last Updated**: 2025-01-13
**Version**: 1.0.0
