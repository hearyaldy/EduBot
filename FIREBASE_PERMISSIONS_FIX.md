# Firebase Permissions Fix

## Problem

Users were getting permission denied errors when trying to submit questions to Firestore:

```
W/Firestore: Write failed at questionBank/yr6_sci_003: Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
I/flutter: Failed to save question to Firestore: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Root Cause

The Firestore security rules were set to **deny all operations**:

```javascript
// ❌ BEFORE - Denied everything
match /{document=**} {
  allow read, write: if false;
}
```

This completely blocked all read and write operations to the database.

## Solution

Updated Firestore security rules to provide proper access control while maintaining security.

### Files Modified

1. **`firestore.rules`** - Updated security rules
2. **`firebase.json`** - Created configuration file (was missing)

### New Security Rules

#### Question Bank (Global)
```javascript
match /questionBank/{questionId} {
  // Anyone can read questions
  allow read: if true;

  // Only authenticated users can write questions
  allow write: if request.auth != null;
}
```

**Purpose**: Allow all users to read questions, but only authenticated users can add/edit questions.

#### User Profiles
```javascript
match /users/{userId} {
  // Users can read their own profile
  allow read: if request.auth != null && request.auth.uid == userId;

  // Users can write their own profile
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

**Purpose**: Users can only access their own profile data.

#### Child Profiles
```javascript
match /users/{userId}/children/{childId} {
  // Users can read their own children's profiles
  allow read: if request.auth != null && request.auth.uid == userId;

  // Users can write their own children's profiles
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

**Purpose**: Parents can manage their children's profiles.

#### Student Progress
```javascript
match /users/{userId}/children/{childId}/progress/{progressId} {
  // Users can read their own children's progress
  allow read: if request.auth != null && request.auth.uid == userId;

  // Users can write their own children's progress
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

**Purpose**: Track student learning progress securely.

#### User Questions
```javascript
match /users/{userId}/questions/{questionId} {
  // Users can read their own questions
  allow read: if request.auth != null && request.auth.uid == userId;

  // Users can write their own questions
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

**Purpose**: Users can save their own questions privately.

#### History/Submissions
```javascript
match /users/{userId}/history/{historyId} {
  // Users can read their own history
  allow read: if request.auth != null && request.auth.uid == userId;

  // Users can write their own history
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

**Purpose**: Track user activity and submissions.

#### Badges
```javascript
match /users/{userId}/badges/{badgeId} {
  // Users can read their own badges
  allow read: if request.auth != null && request.auth.uid == userId;

  // Users can write their own badges
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

**Purpose**: Manage user achievements.

#### Admin Collection
```javascript
match /admin/{document=**} {
  // Only allow if user has custom claim 'admin: true'
  allow read, write: if request.auth != null &&
                        request.auth.token.admin == true;
}
```

**Purpose**: Super restricted admin-only access.

## Deployment

### Automatic Deployment (Completed)

```bash
firebase deploy --only firestore:rules
```

**Result:**
```
✔  cloud.firestore: rules file firestore.rules compiled successfully
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!
```

### Manual Deployment (Alternative)

If you need to manually update rules:

1. Go to [Firebase Console](https://console.firebase.google.com/project/edubot-3a646/overview)
2. Click **Firestore Database** in the left menu
3. Click the **Rules** tab
4. Copy the contents of `firestore.rules`
5. Paste into the editor
6. Click **Publish**

## Security Model

### Authentication Required
- ✅ Users must be signed in to write to most collections
- ✅ Users can only access their own data
- ✅ Child profiles protected by parent authentication

### Public Access
- ✅ Question bank readable by all (for learning)
- ❌ Question bank writable only by authenticated users

### Data Isolation
- Each user can only read/write their own:
  - Profile
  - Children profiles
  - Progress records
  - Questions
  - History
  - Badges

### Admin Access
- Super restricted to users with `admin: true` custom claim
- Set via Firebase Auth admin SDK

## Testing

### Before Fix
```bash
# Try submitting questions
# Result: Permission denied errors
```

### After Fix
```bash
# Try submitting questions while signed in
# Result: Success! Questions saved to Firestore
```

### Test Cases

1. **Unauthenticated User**
   - ✅ Can read question bank
   - ❌ Cannot write to question bank
   - ❌ Cannot access user data

2. **Authenticated User**
   - ✅ Can read question bank
   - ✅ Can write to question bank
   - ✅ Can read/write own profile
   - ✅ Can read/write own children's data
   - ❌ Cannot access other users' data

3. **Admin User** (with custom claim)
   - ✅ All authenticated user permissions
   - ✅ Can access admin collection
   - ✅ Can perform admin operations

## Collection Structure

```
firestore
├── questionBank/              (public read, auth write)
│   ├── {questionId}
│   └── ...
│
├── users/                     (private to user)
│   └── {userId}/
│       ├── profile data
│       ├── children/
│       │   └── {childId}/
│       │       ├── profile
│       │       └── progress/
│       │           └── {progressId}
│       ├── questions/
│       │   └── {questionId}
│       ├── history/
│       │   └── {historyId}
│       └── badges/
│           └── {badgeId}
│
└── admin/                     (admin only)
    └── ...
```

## Security Best Practices Implemented

### ✅ Principle of Least Privilege
- Users only get access to data they need
- Default deny for unknown paths

### ✅ Authentication Required
- Most write operations require authentication
- User identity verified before access

### ✅ Data Isolation
- Users cannot access other users' data
- Parent-child relationship enforced

### ✅ Role-Based Access
- Admin role for privileged operations
- Custom claims for fine-grained control

### ✅ Public Read for Learning Content
- Question bank accessible to all
- Encourages learning and exploration

## Future Enhancements

### Potential Improvements

1. **Question Moderation**
   ```javascript
   // Allow write but mark as pending review
   allow write: if request.auth != null &&
                  request.resource.data.status == 'pending';
   ```

2. **Reputation System**
   ```javascript
   // High-reputation users can edit questions
   allow update: if request.auth != null &&
                   getUserReputation() > 100;
   ```

3. **Rate Limiting**
   ```javascript
   // Limit question submissions per day
   allow create: if request.auth != null &&
                   getSubmissionsToday() < 10;
   ```

4. **Question Voting**
   ```javascript
   // Anyone can vote on questions
   match /questionBank/{questionId}/votes/{voteId} {
     allow read: if true;
     allow write: if request.auth != null;
   }
   ```

## Troubleshooting

### Issue: Still Getting Permission Denied

**Solution:**
1. Check if user is signed in: `FirebaseAuth.instance.currentUser`
2. Verify rules deployed: Check Firebase Console
3. Check rule match paths: Ensure collection names match

### Issue: Rules Not Updating

**Solution:**
```bash
# Redeploy rules
firebase deploy --only firestore:rules

# Or manually in Firebase Console
```

### Issue: Testing Rules Locally

**Solution:**
```bash
# Install Firebase emulator
firebase emulators:start --only firestore

# Test rules locally before deploying
```

## Verification

### Check Rules in Firebase Console

1. Go to Firebase Console
2. Navigate to Firestore Database > Rules
3. Verify the rules match `firestore.rules`
4. Check the "Published" timestamp

### Test Question Submission

```dart
// In your app
try {
  await _firebaseService.saveQuestionToBank(question.toJson());
  print('✅ Success! Question saved');
} catch (e) {
  print('❌ Error: $e');
}
```

**Expected Result:**
```
✅ Success! Question saved
```

## Impact

### Now Working:
- ✅ Submit questions to shared question bank
- ✅ Read questions from question bank
- ✅ Save user profile data
- ✅ Track child progress
- ✅ Record learning history
- ✅ Earn and display badges

### Security Maintained:
- ✅ Users isolated from each other
- ✅ Authentication required for writes
- ✅ Admin functions protected
- ✅ Data privacy preserved

---

**Status**: ✅ **FIXED AND DEPLOYED**
**Date**: 2025-01-14
**Impact**: Critical - Enables Firebase functionality
**Breaking Changes**: None (only fixes broken functionality)
**Deployment**: Completed successfully to production
