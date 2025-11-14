# Question Import Setup Guide

## Overview
Complete setup for importing sample questions into the EduBot question bank to enable adaptive learning, practice exercises, and personalized recommendations.

## Files Created

### 1. **`lib/services/question_bank_initializer.dart`**
Comprehensive service to import questions from sample JSON files.

**Features:**
- ✅ Import all sample questions at once
- ✅ Import specific subjects individually
- ✅ Check if question bank is initialized
- ✅ Get question bank statistics
- ✅ Clear and reimport questions
- ✅ Comprehensive debug logging

**Methods:**
```dart
// Import all sample questions
await QuestionBankInitializer().importAllSampleQuestions();

// Import specific subjects
await QuestionBankInitializer().importYear6Science();
await QuestionBankInitializer().importYear2Mathematics();
await QuestionBankInitializer().importYear3English();

// Check status
bool isInit = await QuestionBankInitializer().isQuestionBankInitialized();

// Get stats
Map stats = await QuestionBankInitializer().getQuestionBankStats();

// Reimport (clear and reimport)
await QuestionBankInitializer().reimportAllQuestions();
```

### 2. **`lib/screens/question_import_screen.dart`**
Beautiful UI screen for importing questions.

**Features:**
- ✅ Status indicator (initialized or empty)
- ✅ Question bank statistics display
- ✅ One-click import button
- ✅ Re-import functionality with confirmation
- ✅ Import result display
- ✅ Error handling and reporting
- ✅ Loading states
- ✅ Informative help text

### 3. **Updated `lib/screens/settings_screen.dart`**
Added "Question Bank" section with navigation to import screen.

## How to Use

### Option 1: Via Settings Screen (Recommended)

1. **Open the app**
2. **Navigate to Settings**
3. **Scroll to "Question Bank" section**
4. **Tap "Import Sample Questions"**
5. **Tap the blue "Import Sample Questions" button**
6. **Wait for import to complete**

You'll see:
```
📚 QuestionBankInitializer: Starting import of all sample questions
✅ QuestionBankInitializer: Database initialized
📂 QuestionBankInitializer: Importing assets/sample_questions/year6_science.json
   ✅ Imported 100/100 questions
📂 QuestionBankInitializer: Importing assets/sample_questions/year2_mathematics_basic.json
   ✅ Imported 25/25 questions
📂 QuestionBankInitializer: Importing assets/sample_questions/year3_english_reading.json
   ✅ Imported 15/15 questions
🎉 QuestionBankInitializer: Import complete! Total: 140/140 questions imported
```

### Option 2: Programmatic Import

Add to `main.dart` for first-time setup:

```dart
import 'package:edubot/services/question_bank_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize question bank on first launch
  final initializer = QuestionBankInitializer();
  final isInit = await initializer.isQuestionBankInitialized();

  if (!isInit) {
    debugPrint('Importing sample questions...');
    await initializer.importAllSampleQuestions();
  }

  runApp(const MyApp());
}
```

### Option 3: Via Admin Dashboard

Add to admin dashboard:

```dart
ElevatedButton(
  onPressed: () async {
    final result = await QuestionBankInitializer().importAllSampleQuestions();
    print('Imported ${result['successfully_imported']} questions');
  },
  child: const Text('Import Questions'),
)
```

## Sample Question Files

The following JSON files are included in `assets/sample_questions/`:

### 1. **year6_science.json** (100+ questions)
- **Subject**: Science
- **Topics**: Human Reproduction, Fertilization, Embryo Development
- **Grade Level**: Year 6
- **Difficulty Levels**: Very Easy to Very Hard
- **Question Types**: Short Answer, Fill in the Blank, Multiple Choice

### 2. **year2_mathematics_basic.json** (25+ questions)
- **Subject**: Mathematics
- **Topics**: Basic arithmetic, counting, shapes
- **Grade Level**: Year 2
- **Difficulty**: Very Easy to Easy

### 3. **year3_english_reading.json** (15+ questions)
- **Subject**: English
- **Topics**: Reading comprehension, vocabulary
- **Grade Level**: Year 3
- **Difficulty**: Easy to Medium

## What Happens After Import

### ✅ Adaptive Learning Works
```
🎯 AdaptiveLearning: Getting recommendations for student: child_123
📚 Subject: Science, Topic: null, Count: 10
🔍 AdaptiveLearning: Getting available questions pool...
✅ AdaptiveLearning: Retrieved 100 questions from database  ← NOW HAS QUESTIONS!
📝 AdaptiveLearning: Getting review questions (3 requested)...
✅ AdaptiveLearning: Added 3 review questions
🎚️ AdaptiveLearning: Getting adaptive difficulty questions (7)...
✅ AdaptiveLearning: Added 7 adaptive questions
🎉 AdaptiveLearning: Returning 10 total recommendations  ← SUCCESS!
```

### ✅ Features Enabled

1. **Adaptive Learning**
   - Personalized question recommendations
   - Difficulty-matched questions
   - Review questions for weak topics

2. **Practice Exercises**
   - Questions available for practice
   - Topic-specific exercises
   - Grade-appropriate content

3. **Student Progress Tracking**
   - Track which questions answered
   - Calculate subject/topic mastery
   - Build learning profiles

4. **Question Bank Features**
   - Search by subject/topic/grade
   - Filter by difficulty
   - Diverse question types

## Verification

### Check Import Success

Run the app and check terminal:
```bash
flutter run | grep "QuestionBankInitializer"
```

Expected output:
```
📚 QuestionBankInitializer: Starting import of all sample questions
✅ QuestionBankInitializer: Database initialized
🎉 QuestionBankInitializer: Import complete! Total: 140/140 questions imported
```

### Check Database

```dart
final dbService = DatabaseService();
await dbService.initialize();
final questions = dbService.getAllQuestions();
print('Total questions: ${questions.length}');

final stats = dbService.getQuestionBankStats();
print('Subjects: ${stats['subjects']}');
```

### Test Adaptive Learning

After import, navigate to Adaptive Learning Interface:
```
🔍 AdaptiveLearning: Retrieved 100 questions from database  ← Should see questions!
```

## Troubleshooting

### Issue: Import Button Does Nothing

**Check:**
```bash
flutter run | grep "❌.*QuestionBankInitializer"
```

**Common causes:**
- Database not initialized
- Asset files not declared in pubspec.yaml (already fixed)
- File path incorrect

### Issue: Some Questions Fail to Import

**Check import result:**
```dart
final result = await initializer.importAllSampleQuestions();
print('Failed: ${result['failed_imports']}');
print('Errors: ${result['errors']}');
```

**Common causes:**
- Invalid JSON format
- Missing required fields
- Type mismatch in question data

### Issue: Questions Not Showing in App

**Check:**
1. Database initialized: `await DatabaseService().initialize()`
2. Questions exist: `dbService.getAllQuestions().length`
3. Filtering correct: Check subject/topic parameters

## Adding Your Own Questions

### 1. Create JSON File

Create `assets/sample_questions/your_subject.json`:

```json
{
  "questions": [
    {
      "id": "unique_id_001",
      "questionText": "What is 2 + 2?",
      "questionType": 0,
      "subject": "Mathematics",
      "topic": "Addition",
      "subtopic": "Basic Addition",
      "gradeLevel": 1,
      "difficulty": 0,
      "answerKey": "4",
      "explanation": "2 plus 2 equals 4.",
      "choices": ["2", "3", "4", "5"],
      "metadata": {
        "curriculumStandards": ["Grade 1 Math"],
        "tags": ["addition", "basic"],
        "estimatedTime": 1,
        "cognitiveLevel": 0,
        "additionalData": {}
      },
      "targetLanguage": "English"
    }
  ]
}
```

### 2. Add to Importer

Edit `lib/services/question_bank_initializer.dart`:

```dart
final List<String> _questionFiles = [
  'assets/sample_questions/year6_science.json',
  'assets/sample_questions/year2_mathematics_basic.json',
  'assets/sample_questions/year3_english_reading.json',
  'assets/sample_questions/your_subject.json',  // ADD THIS
];
```

### 3. Declare in pubspec.yaml

Already done:
```yaml
assets:
  - assets/sample_questions/
```

### 4. Reimport

Tap "Re-import Questions" in the app to refresh.

## Question Type Reference

```dart
enum QuestionType {
  multipleChoice,   // 0
  trueOrFalse,     // 1
  fillInTheBlank,  // 2
  shortAnswer,     // 3
  essay,           // 4
  matching,        // 5
  ordering,        // 6
  calculation      // 7
}
```

## Difficulty Tag Reference

```dart
enum DifficultyTag {
  veryEasy,  // 0 - Level 1
  easy,      // 1 - Level 2
  medium,    // 2 - Level 3
  hard,      // 3 - Level 4
  veryHard   // 4 - Level 5
}
```

## Debug Logging

All operations are logged with emoji prefixes:

- 📚 Import started
- ✅ Success
- ❌ Error
- 📂 File processing
- 🎉 Complete
- ⚠️ Warning

View logs:
```bash
flutter run | grep "📚\|✅\|❌"
```

---

## Status: ✅ **READY TO USE**

**Next Steps:**
1. ✅ Files created
2. ✅ UI integrated into Settings
3. ✅ Debug logging added
4. ✅ Sample questions ready
5. 🔜 **Run app and tap "Import Sample Questions" in Settings!**

After import, your adaptive learning system will have **100+ questions** ready for personalized recommendations!
