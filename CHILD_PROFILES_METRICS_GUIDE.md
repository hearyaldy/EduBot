# Child Profiles & Metrics Implementation Guide

## Overview

This guide explains the new per-child metrics tracking system and Firebase history synchronization that has been implemented in your EduBot app.

## Features Implemented

### 1. **Per-Child Metrics Tracking**
Each child profile now has its own independent metrics:
- **Question Count**: Total questions asked by that specific child
- **Current Streak**: Days of consecutive usage
- **Longest Streak**: Best streak record
- **Subjects Used**: Subjects the child has studied
- **Unlocked Badges**: Achievements earned by the child

### 2. **Firebase History with Child Association**
Questions and answers are now:
- Saved to Firebase with the child profile ID
- Queryable per child
- Filterable in the history screen
- Deletable with confirmation

### 3. **Enhanced History Screen**
The history screen now includes:
- **Filter Dropdown**: Select "All Children" or a specific child
- **Child Profile Badges**: Each question shows which child asked it with emoji + name
- **Delete Functionality**: Remove questions from history with confirmation
- **Child-Specific Views**: See only one child's questions

## Data Structure

### Firebase Collections

```
users/{userId}/
  ├── childProfiles/{profileId}
  │   ├── id: string
  │   ├── name: string
  │   ├── emoji: string
  │   ├── grade: number
  │   ├── questionCount: number
  │   ├── currentStreak: number
  │   ├── longestStreak: number
  │   ├── subjectsUsed: array
  │   ├── unlockedBadgeIds: array
  │   ├── createdAt: timestamp
  │   ├── lastUsedAt: timestamp
  │   └── updatedAt: timestamp
  │
  ├── questions/{questionId}
  │   ├── id: string
  │   ├── question: string
  │   ├── questionType: string
  │   ├── subject: string
  │   ├── childProfileId: string  // ← NEW: Links to child profile
  │   ├── answer: string           // ← NEW: Stores AI answer
  │   ├── imageUrl: string
  │   ├── metadata: object
  │   ├── createdAt: timestamp
  │   └── updatedAt: timestamp
  │
  └── explanations/{questionId}
      ├── questionId: string
      ├── answer: string
      ├── steps: array
      ├── parentFriendlyTip: string
      ├── realWorldExample: string
      ├── metadata: object
      ├── createdAt: timestamp
      └── updatedAt: timestamp
```

## Code Changes Made

### 1. **HomeworkQuestion Model** (`lib/models/homework_question.dart`)
Added fields:
- `childProfileId`: Links the question to a child profile
- `answer`: Stores the AI answer along with the question

### 2. **Firebase Service** (`lib/services/firebase_service.dart`)
New methods added:
- `saveChildProfile()`: Saves child profile to Firebase
- `getChildProfiles()`: Retrieves all child profiles
- `deleteChildProfile()`: Deletes a child profile
- `updateChildProfileMetrics()`: Updates metrics for a child
- `getChildProfileMetrics()`: Retrieves metrics for a child
- `getChildQuestionsStream()`: Stream of questions for a specific child
- `getChildQuestions()`: One-time fetch of child's questions

Updated methods:
- `saveQuestion()`: Now accepts `childProfileId` and `answer` parameters

### 3. **History Screen** (`lib/screens/history_screen.dart`)
Enhanced features:
- Filter dropdown to select child profile
- Visual badges showing which child asked each question
- Existing delete functionality now works with child-filtered views

## Integration Steps

To make sure questions are saved with child profile associations, update the code where you save questions:

### Example: Saving a Question with Child Profile

```dart
// When a question is asked
final provider = Provider.of<AppProvider>(context, listen: false);
final activeProfile = provider.activeProfile;

// Save to Firebase with child profile ID
await FirebaseService.instance.saveQuestion(
  questionId: question.id,
  question: question.question,
  questionType: question.type.name,
  subject: detectedSubject,
  imageUrl: imageUrl,
  childProfileId: activeProfile?.id,  // ← Link to active child
  answer: aiResponse.answer,          // ← Save the answer
  metadata: {
    'grade': activeProfile?.grade,
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```

### Example: Syncing Child Profiles to Firebase

When a child profile is created or updated locally:

```dart
// In ProfileService or AppProvider
Future<void> syncProfileToFirebase(ChildProfile profile) async {
  await FirebaseService.instance.saveChildProfile(profile.toJson());
}
```

### Example: Updating Child Metrics

After a child asks a question:

```dart
// Update local metrics first
await profileService.incrementQuestionCount();

// Sync to Firebase
final profile = profileService.activeProfile;
if (profile != null) {
  await FirebaseService.instance.updateChildProfileMetrics(
    profileId: profile.id,
    questionCount: profile.questionCount,
    currentStreak: profile.currentStreak,
    longestStreak: profile.longestStreak,
    subjectsUsed: profile.subjectsUsed,
    unlockedBadgeIds: profile.unlockedBadgeIds,
  );
}
```

## UI/UX Features

### History Screen Filter
- Dropdown at the top shows "All Children" by default
- Users can select a specific child to view only their questions
- The count updates dynamically based on the filter

### Child Profile Badges
- Each question card shows:
  - Child emoji + name in a gradient badge
  - Subject badge (if available)
  - Timestamp

### Delete Confirmation
- Tapping "Delete" shows a confirmation dialog
- Deletion removes from both local storage and Firebase
- Works correctly even when filtering by child

## Testing Checklist

- [ ] Create multiple child profiles
- [ ] Select a child profile as active
- [ ] Ask a question (scan, text, or voice)
- [ ] Go to History screen
- [ ] Verify the question shows the correct child's emoji and name
- [ ] Use the filter dropdown to filter by different children
- [ ] Verify only that child's questions appear
- [ ] Test delete functionality with confirmation
- [ ] Check Firebase console to verify data is saved correctly

## Firebase Security Rules

Make sure your Firestore security rules allow authenticated users to:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Allow users to read/write their own data
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /childProfiles/{profileId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /questions/{questionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /explanations/{explanationId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Future Enhancements

Potential improvements you could add:

1. **Analytics Dashboard**
   - Chart showing questions per child over time
   - Most active subjects per child
   - Streak comparison between children

2. **Export History**
   - Export a child's complete Q&A history as PDF
   - Email summaries to parents

3. **Bulk Operations**
   - Delete all questions for a child
   - Archive old questions

4. **Advanced Filtering**
   - Filter by date range
   - Filter by subject
   - Search within questions

5. **Offline Support**
   - Cache child-specific data for offline viewing
   - Sync when connection is restored

## Troubleshooting

### Questions Not Showing Child Profile
- Ensure `childProfileId` is passed when saving questions
- Check that an active profile is selected before asking questions
- Old questions won't have child profiles (they'll show without badges)

### Firebase Not Syncing
- Verify Firebase is initialized: `FirebaseService.isInitialized`
- Check user is authenticated: `FirebaseService.instance.isAuthenticated`
- Check console logs for error messages

### Metrics Not Updating
- Ensure `updateChildProfileMetrics()` is called after local updates
- Verify the profile ID matches between local and Firebase
- Check Firebase console for the data structure

## Support

For issues or questions about this implementation:
1. Check the error logs in the console
2. Verify Firebase configuration in `firebase_options.dart`
3. Review the code comments in the modified files

---

**Generated by Claude Code**
Implementation Date: 2025-11-13
