# Practice Questions Status Report

## Current Status: ❌ Using Hardcoded Questions

### What's Happening Now

The **Practice Exercises** screen is currently using **hardcoded questions** stored directly in the code.

**Files Involved:**
- `lib/services/lesson_service.dart` - Contains all hardcoded lessons and exercises
- `lib/screens/exercises_screen.dart` - Displays the lessons from LessonService

### Hardcoded Lessons Include:
1. Math Money (10 questions)
2. Math Fractions
3. Math Multiplication
4. KSSR Year 1 Math Foundational
5. Time and Time Zones (Beginner, Intermediate, Advanced)
6. Measurement (Beginner, Intermediate, Advanced)
7. Space/Geometry (Beginner, Intermediate, Advanced)
8. Relations and Algebra (Beginner, Intermediate, Advanced)
9. Statistics and Probability (Beginner, Intermediate, Advanced)

**Total**: ~18 hardcoded lesson sets

---

## ✅ Available Solution: Question Bank System

You have a **fully functional Question Bank system** ready to use!

### DatabaseService Features

**Location**: `lib/services/database_service.dart`

**Available Methods:**
```dart
// Get all questions from database
List<Question> getAllQuestions()

// Filter by subject, topic, grade, difficulty
List<Question> getFilteredQuestions({
  String? subject,
  String? topic,
  int? gradeLevel,
  DifficultyTag? difficulty,
  QuestionType? questionType,
  int? limit,
})

// Advanced filtering with multiple criteria
List<Question> getQuestionsByFilter({
  List<int>? gradeLevels,
  List<String>? subjects,
  List<String>? topics,
  List<DifficultyTag>? difficulties,
  List<QuestionType>? questionTypes,
  String? searchText,
})

// Get by specific topic
List<Question> getQuestionsByTopic(String topic, {String? subject})
```

### Question Bank Manager UI

**Location**: `lib/ui/question_bank_manager.dart`

**Features:**
- Add/Edit/Delete questions
- Bulk import from JSON
- Search and filter questions
- Statistics dashboard
- Export questions

---

## 🔄 How to Migrate to Question Bank

### Option 1: Quick Switch (Use Existing Database)

Update `exercises_screen.dart` to use DatabaseService instead of LessonService:

```dart
// OLD (Current)
import '../services/lesson_service.dart';
final LessonService _lessonService = LessonService();
final lessons = await _lessonService.getAllLessons();

// NEW (Using Question Bank)
import '../services/database_service.dart';
final DatabaseService _dbService = DatabaseService();
await _dbService.initialize();

// Get questions by subject and grade
final mathQuestions = _dbService.getFilteredQuestions(
  subject: 'Math',
  gradeLevel: 6,
  limit: 10,
);
```

### Option 2: Create Dynamic Lessons from Database

Create a new service that generates lessons from database questions:

```dart
class DynamicLessonService {
  final DatabaseService _db = DatabaseService();

  Future<List<Lesson>> generateLessons() async {
    await _db.initialize();
    final subjects = _db.getUniqueSubjects();

    List<Lesson> lessons = [];
    for (var subject in subjects) {
      // Get questions for this subject
      final questions = _db.getFilteredQuestions(
        subject: subject,
        limit: 10,
      );

      // Convert Question to Exercise format
      final exercises = questions.map((q) => Exercise(
        questionNumber: questions.indexOf(q) + 1,
        questionText: q.questionText,
        inputType: q.questionType.name,
        answerKey: q.answerKey,
        explanation: q.explanation,
      )).toList();

      // Create lesson
      lessons.add(Lesson(
        id: 'lesson_${subject}_${DateTime.now().millisecondsSinceEpoch}',
        title: '$subject Practice',
        subject: subject,
        gradeLevel: 6,
        description: 'Practice questions for $subject',
        exercises: exercises,
      ));
    }

    return lessons;
  }
}
```

### Option 3: Hybrid Approach

Keep some hardcoded lessons + add database lessons:

```dart
Future<List<Lesson>> getAllLessons() async {
  final hardcodedLessons = await _lessonService.getAllLessons();
  final databaseLessons = await _dynamicLessonService.generateLessons();

  return [...hardcodedLessons, ...databaseLessons];
}
```

---

## 📊 Current Question Bank Status

To check how many questions are in the database:

```dart
final db = DatabaseService();
await db.initialize();
final allQuestions = db.getAllQuestions();
print('Total questions in database: ${allQuestions.length}');

// Check by subject
final subjects = db.getUniqueSubjects();
for (var subject in subjects) {
  final count = db.getFilteredQuestions(subject: subject).length;
  print('$subject: $count questions');
}
```

---

## 🎯 Recommended Migration Steps

### Phase 1: Check Question Bank
1. Open Question Bank Manager (from main navigator)
2. Check if questions exist in database
3. If empty, import questions using bulk import feature

### Phase 2: Create Dynamic Lesson Service
1. Create `lib/services/dynamic_lesson_service.dart`
2. Implement methods to convert database questions to lessons
3. Test with small dataset first

### Phase 3: Update Exercises Screen
1. Add toggle or setting: "Use Question Bank" vs "Use Hardcoded"
2. Let users choose which source
3. Gradually transition all users

### Phase 4: Full Migration
1. Replace LessonService with DynamicLessonService
2. Move hardcoded questions to database (if needed)
3. Remove old hardcoded lessons

---

## 📝 Example: Converting a Question

### Database Question Format
```dart
Question(
  id: 'q123',
  questionText: 'What is 2 + 2?',
  answerKey: '4',
  explanation: '2 plus 2 equals 4',
  subject: 'Math',
  topic: 'Addition',
  gradeLevel: 1,
  difficulty: DifficultyTag.easy,
  questionType: QuestionType.multipleChoice,
)
```

### Exercise Format (Current)
```dart
Exercise(
  questionNumber: 1,
  questionText: 'What is 2 + 2?',
  inputType: 'text',
  answerKey: '4',
  explanation: '2 plus 2 equals 4',
)
```

**They're very similar!** Easy to convert.

---

## 🚀 Quick Start: Test with One Lesson

Create a test lesson using database questions:

```dart
Future<Lesson> createTestLessonFromDB() async {
  final db = DatabaseService();
  await db.initialize();

  // Get 5 random math questions
  final questions = db.getFilteredQuestions(
    subject: 'Math',
    gradeLevel: 6,
    limit: 5,
  );

  if (questions.isEmpty) {
    throw Exception('No questions found in database');
  }

  // Convert to exercises
  final exercises = questions.asMap().entries.map((entry) {
    final index = entry.key;
    final q = entry.value;

    return Exercise(
      questionNumber: index + 1,
      questionText: q.questionText,
      inputType: 'text',
      answerKey: q.answerKey,
      explanation: q.explanation,
    );
  }).toList();

  return Lesson(
    id: 'test_db_lesson',
    title: 'Test: Database Questions',
    subject: 'Math',
    gradeLevel: 6,
    description: 'This lesson uses questions from the database!',
    topic: 'Mixed Topics',
    difficulty: DifficultyLevel.intermediate,
    exercises: exercises,
  );
}
```

---

## ✅ Benefits of Using Question Bank

1. **Unlimited Questions**: Add as many as you want via UI
2. **Easy Updates**: Change questions without code changes
3. **Better Organization**: Filter by subject, topic, grade, difficulty
4. **Analytics Ready**: Track which questions are used
5. **Scalable**: Can add 1000s of questions
6. **User-Generated**: Future: Let teachers add questions
7. **Import/Export**: Bulk operations via JSON

---

## 🎓 Conclusion

**Current**: ✅ Hardcoded questions (working, but limited)
**Available**: ✅ Question Bank system (ready to use)
**Recommended**: 🔄 Migrate to Question Bank for flexibility

The infrastructure is ready - you just need to connect the exercises screen to use DatabaseService instead of hardcoded lessons!

---

**Generated by Claude Code**
**Date**: 2025-11-13
