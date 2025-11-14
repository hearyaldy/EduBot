# Superadmin Setup Guide

## 🚀 Quick Start

**To make yourself a superadmin, follow these 5 simple steps:**

1. **Open Firebase Console**: Go to https://console.firebase.google.com
2. **Select your project**: Click on your edubot project
3. **Open Firestore**: Click "Firestore Database" in the left menu
4. **Find your user**: Click on the `users` collection → Find your user document (search by your email)
5. **Edit the document**:
   - Click on your user document
   - Find the `accountType` field
   - Change its value from `"registered"` to `"superadmin"` (with quotes)
   - Click **Update**

**That's it!** Restart the app and you'll be a superadmin! 🎉

---

## How Superadmin Recognition Works

The system checks two fields in the Firestore user document:
1. `accountType` field set to `'superadmin'` ← **This is the easiest method**
2. `isSuperadmin` boolean field set to `true`

Either condition will grant superadmin privileges.

## Setting Up a Superadmin User

### Method 1: Using Firebase Console

1. Open Firebase Console: https://console.firebase.google.com
2. Select your project
3. Go to **Firestore Database**
4. Navigate to the `users` collection
5. Find your user document (by email or UID)
6. Click **Edit document**
7. Add or modify one of these fields:
   - **Option A**: Set `accountType` to `"superadmin"`
   - **Option B**: Add a boolean field `isSuperadmin` and set it to `true`
8. Click **Update**

### Method 2: Using Firebase CLI (Advanced)

```bash
# Make sure you're logged in
firebase login

# Update user document
firebase firestore:update users/YOUR_USER_ID --data '{"accountType":"superadmin"}'

# OR using isSuperadmin boolean
firebase firestore:update users/YOUR_USER_ID --data '{"isSuperadmin":true}'
```

### Method 3: Programmatically (For Testing)

You can add a temporary button in your app to set yourself as superadmin:

```dart
// In your settings or admin screen
ElevatedButton(
  onPressed: () async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId != null) {
      await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
          'accountType': 'superadmin',
          'isSuperadmin': true,
        });

      // Refresh admin status
      await FirebaseAdminService.instance.refreshAdminStatus();
      setState(() {});
    }
  },
  child: const Text('Make Me Superadmin'),
)
```

## User Document Structure

Here's what a superadmin user document should look like in Firestore:

```json
{
  "uid": "abc123xyz",
  "email": "admin@example.com",
  "displayName": "Admin User",
  "accountType": "superadmin",
  "isSuperadmin": true,
  "status": "active",
  "emailVerified": true,
  "totalQuestions": 0,
  "dailyQuestions": 0,
  "createdAt": "2025-01-13T10:00:00Z",
  "updatedAt": "2025-01-13T10:00:00Z",
  "metadata": {}
}
```

## How the App Recognizes Superadmins

### Location: `lib/services/firebase_admin_service.dart:35-61`

```dart
Future<void> _checkAdminStatus() async {
  // Get user profile from Firestore
  final userProfile = await _firebase.getUserProfile();

  if (userProfile != null) {
    // Check both accountType and isSuperadmin fields
    final accountType = userProfile['accountType']?.toString().toLowerCase();
    final isSuperadminBool = userProfile['isSuperadmin'] as bool?;

    _isAdmin = accountType == 'superadmin' || isSuperadminBool == true;
  }
}
```

## Superadmin Features

Once authenticated as a superadmin, you'll have access to:

1. **Unlimited Questions**: No daily limits
2. **Admin Dashboard**: Access via the floating action menu
3. **User Management**: View and manage all users
4. **Analytics**: See app usage statistics
5. **Premium Features**: All premium features unlocked

## Verifying Superadmin Status

### In the App:
1. Open the app
2. Tap the FAB (Floating Action Button) on the right side
3. If you see "Admin" option in the menu, you're a superadmin!

### Via Code:
```dart
// Check if current user is superadmin
final isAdmin = AdminService.instance.isAdmin;
print('Is Superadmin: $isAdmin');

// Or via provider
final provider = Provider.of<AppProvider>(context, listen: false);
print('Is Superadmin: ${provider.isSuperadmin}');
```

## Troubleshooting

### ⚠️ Superadmin status not recognized?

Follow these steps in order:

#### Step 1: Verify Firestore Document
1. Open Firebase Console → Firestore Database
2. Navigate to `users` collection
3. Find YOUR user document (by email)
4. Check that you see:
   ```
   accountType: "superadmin"
   ```
   OR
   ```
   isSuperadmin: true
   ```

**Important**:
- `accountType` must be a STRING value `"superadmin"` (with quotes)
- `isSuperadmin` must be a BOOLEAN value `true` (not a string)
- Make sure there are no typos: it's `superadmin` (all lowercase, no spaces)

#### Step 2: Completely Restart the App
1. **Close the app completely** (don't just minimize it)
2. **Wait 2-3 seconds**
3. **Reopen the app**
4. **Login if needed**

#### Step 3: Check Debug Logs
If you're running in debug mode, look for these messages:
```
Initializing FirebaseAdminService...
✓ FirebaseAdminService initialized (isAdmin: true)
Admin status refreshed after login: true
Checked admin status from Firestore: true (accountType: superadmin, isSuperadmin: null)
```

#### Step 4: Still Not Working?

If your profile still shows "Registered User" instead of "Superadmin":

1. **Sign out completely**:
   - Go to Settings
   - Sign out
   - Close the app

2. **Sign back in**:
   - Open the app
   - Sign in with your credentials

3. **Check immediately after login**:
   - Go to Profile screen
   - You should see "Superadmin" status

#### Step 5: Verify Your Email

Make sure you're editing the CORRECT user document:
- The email in Firestore should match your login email EXACTLY
- Check for typos or extra spaces
- Firebase auth email and Firestore email must match

### Admin Dashboard not showing?

1. Make sure you're logged in with Firebase Authentication
2. Verify the user exists in the `users` collection
3. Check that `AdminService.instance.isAdmin` returns `true`

## Security Considerations

⚠️ **Important Security Notes**:

1. **Never expose superadmin endpoints** publicly
2. **Always validate** superadmin status server-side for sensitive operations
3. **Use Firebase Security Rules** to restrict who can modify user documents:

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Only allow users to read their own document
      allow read: if request.auth != null && request.auth.uid == userId;

      // Only allow users to update non-admin fields
      allow update: if request.auth != null
        && request.auth.uid == userId
        && !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['accountType', 'isSuperadmin']);

      // Only existing superadmins can grant superadmin status
      allow update: if request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.accountType == 'superadmin';
    }
  }
}
```

## Changes Made

### 1. **FirebaseAdminService** (`lib/services/firebase_admin_service.dart`)
   - Updated `_checkAdminStatus()` to check Firestore user document
   - Now checks both `accountType` and `isSuperadmin` fields

### 2. **Settings Screen** (`lib/screens/settings_screen.dart`)
   - Removed "Developer Settings" section
   - Removed password authentication dialog
   - Cleaned up unused API configuration code

### 3. **Bottom Navigation** (`lib/widgets/main_navigator.dart`)
   - Moved FAB from center to right side (endFloat)
   - Increased scan icon size to 28px
   - Reduced bottom container padding and margins

## Next Steps

1. **Set your user as superadmin** in Firestore
2. **Restart the app** to load the new privileges
3. **Test the Admin Dashboard** via the FAB menu
4. **Configure Firestore Security Rules** for production

---

## 🔍 Visual Guide with Screenshots

### Finding Your User in Firebase Console:

1. **Firebase Console Home**:
   ```
   console.firebase.google.com → [Your Project]
   ```

2. **Firestore Database**:
   ```
   Left Menu → Firestore Database → users collection
   ```

3. **Your User Document**:
   Look for the document with YOUR email address

4. **Edit accountType Field**:
   ```
   Before: accountType: "registered"
   After:  accountType: "superadmin"
   ```
   (Keep the quotes!)

---

## 📞 Need More Help?

If you're still having issues:

1. **Check you're logged in**: The app must be logged in with Firebase Auth
2. **Verify UID matches**: User UID in auth must match document ID in Firestore
3. **Check Firebase rules**: Make sure Firestore security rules allow reading user documents
4. **Look at console logs**: Run the app in debug mode and check for error messages

---

## ✅ Changes Made in Latest Update

### Fixed Issues:
1. ✅ FirebaseAdminService now initializes on app startup
2. ✅ Admin status refreshes after every login
3. ✅ Admin status checked from Firestore user document
4. ✅ Both `accountType` and `isSuperadmin` fields supported

### Files Modified:
- `lib/providers/app_provider.dart` - Added FirebaseAdminService initialization
- `lib/screens/registration_screen.dart` - Refresh admin status after login
- `lib/services/firebase_admin_service.dart` - Check Firestore for admin status

---

**Last Updated**: 2025-01-13
**Version**: 1.1.0
