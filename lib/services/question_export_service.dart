import 'dart:convert';
import '../models/question.dart';
import '../models/lesson.dart';
import 'lesson_service.dart';
import 'database_service.dart';
import 'firebase_service.dart';

class QuestionExportService {
  static final QuestionExportService _instance = QuestionExportService._internal();
  factory QuestionExportService() => _instance;
  QuestionExportService._internal();

  final LessonService _lessonService = LessonService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Export all hardcoded lessons to questions format
  Future<Map<String, dynamic>> exportLessonsToQuestions() async {
    await _lessonService.initialize();

    // Get all hardcoded lessons
    final lessons = await _lessonService.getAllLessons();

    final questions = <Map<String, dynamic>>[];

    for (final lesson in lessons) {
      for (int i = 0; i < lesson.exercises.length; i++) {
        final exercise = lesson.exercises[i];
        
        // Convert exercise to question
        final question = {
          'id': '${lesson.id}_q${exercise.questionNumber}',
          'question_text': exercise.questionText,
          'question_type': _getQuestionTypeFromInputType(exercise.inputType),
          'subject': lesson.subject,
          'topic': lesson.topic,
          'subtopic': lesson.subtopic,
          'grade_level': lesson.gradeLevel,
          'difficulty': _getDifficultyFromLessonDifficulty(lesson.difficulty),
          'answer_key': exercise.answerKey,
          'explanation': exercise.explanation,
          'choices': [],
          'target_language': lesson.targetLanguage,
          'metadata': {
            'curriculum_standards': [lesson.standardPencapaian],
            'tags': [lesson.topic, lesson.subtopic, lesson.lessonTitle],
            'estimated_time_minutes': 2,
            'cognitive_level': BloomsTaxonomy.apply.index,
            'additional_data': {
              'original_lesson_id': lesson.id,
              'original_lesson_title': lesson.lessonTitle,
              'migrated_from_hardcoded': true,
            },
          },
        };

        questions.add(question);
      }
    }

    return {
      'metadata': {
        'version': '1.0',
        'exported_from': 'Hardcoded Lessons',
        'exported_at': DateTime.now().toIso8601String(),
        'total_questions': questions.length,
        'total_lessons': lessons.length,
      },
      'questions': questions,
    };
  }

  /// Convert input type to question type enum index
  int _getQuestionTypeFromInputType(String inputType) {
    switch (inputType.toLowerCase()) {
      case 'multiple_choice':
        return QuestionType.multipleChoice.index;
      case 'true_false':
        return QuestionType.trueOrFalse.index;
      case 'fill_in_the_blank':
      case 'text':
        return QuestionType.fillInTheBlank.index;
      case 'short_answer':
        return QuestionType.shortAnswer.index;
      case 'essay':
        return QuestionType.essay.index;
      case 'matching':
        return QuestionType.matching.index;
      case 'ordering':
        return QuestionType.ordering.index;
      default:
        return QuestionType.fillInTheBlank.index;
    }
  }

  /// Convert lesson difficulty to difficulty tag enum index
  int _getDifficultyFromLessonDifficulty(DifficultyLevel lessonDifficulty) {
    switch (lessonDifficulty) {
      case DifficultyLevel.beginner:
        return DifficultyTag.easy.index;
      case DifficultyLevel.intermediate:
        return DifficultyTag.medium.index;
      case DifficultyLevel.advanced:
        return DifficultyTag.hard.index;
    }
  }

  /// Export lessons to JSON string
  Future<String> exportLessonsToJson() async {
    final data = await exportLessonsToQuestions();
    return json.encode(data, toEncodable: (dynamic obj) {
      if (obj is DateTime) {
        return obj.toIso8601String();
      }
      return obj;
    });
  }

  /// Save exported questions to database
  Future<void> saveExportedQuestionsToDatabase() async {
    final data = await exportLessonsToQuestions();
    final questionsJson = data['questions'] as List<dynamic>;

    await _databaseService.initialize();

    for (final questionJson in questionsJson) {
      if (questionJson is Map<String, dynamic>) {
        final question = Question.fromJson(questionJson);
        await _databaseService.saveQuestion(question);
      }
    }
  }

  /// Save exported questions to Firestore
  Future<void> saveExportedQuestionsToFirestore() async {
    if (!FirebaseService.isInitialized) {
      throw Exception('Firebase is not initialized. Cannot save to Firestore.');
    }

    final data = await exportLessonsToQuestions();
    final questionsJson = data['questions'] as List<dynamic>;

    int successCount = 0;
    int errorCount = 0;

    for (final questionJson in questionsJson) {
      if (questionJson is Map<String, dynamic>) {
        try {
          await _firebaseService.saveQuestionToBank(questionJson);
          successCount++;
        } catch (e) {
          errorCount++;
          print('Failed to save question to Firestore: $e');
        }
      }
    }

    print('Exported $successCount questions to Firestore, $errorCount failed.');
  }

  /// Export all hardcoded lessons to both database and Firestore
  Future<Map<String, dynamic>> exportAllLessons() async {
    await _databaseService.initialize();

    print('Exporting hardcoded lessons to question bank format...');

    // Export to database
    await saveExportedQuestionsToDatabase();
    print('✅ Exported lessons to local database');

    // Export to Firestore (if initialized)
    if (FirebaseService.isInitialized) {
      await saveExportedQuestionsToFirestore();
      print('✅ Exported lessons to Firestore');
    } else {
      print('⚠️ Firebase not initialized, skipping Firestore export');
    }

    final data = await exportLessonsToQuestions();
    final questionCount = (data['questions'] as List).length;
    final lessonCount = (data['metadata'] as Map)['total_lessons'];

    return {
      'success': true,
      'questions_exported': questionCount,
      'lessons_converted': lessonCount,
      'database_saved': true,
      'firestore_saved': FirebaseService.isInitialized,
    };
  }
}