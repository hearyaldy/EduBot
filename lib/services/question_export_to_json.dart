import 'dart:convert';
import '../models/question.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import '../services/lesson_service.dart';

/// Helper to deeply convert Map<dynamic, dynamic> to Map<String, dynamic>
Map<String, dynamic> _deepConvertMap(Map map) {
  return map.map((key, value) {
    final stringKey = key.toString();
    if (value is Map) {
      return MapEntry(stringKey, _deepConvertMap(value));
    } else if (value is List) {
      return MapEntry(
          stringKey,
          value.map((item) {
            if (item is Map) {
              return _deepConvertMap(item);
            }
            return item;
          }).toList());
    }
    return MapEntry(stringKey, value);
  });
}

class QuestionExportToJSON {
  static final QuestionExportToJSON _instance =
      QuestionExportToJSON._internal();
  factory QuestionExportToJSON() => _instance;
  QuestionExportToJSON._internal();

  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService.instance;
  final LessonService _lessonService = LessonService();

  /// Export all questions from database and Firestore to JSON format
  Future<String> exportAllQuestionsToJSON() async {
    await _databaseService.initialize();

    try {
      // Load questions from local database
      final dbQuestions = _databaseService.getAllQuestions();

      // Load questions from Firestore if initialized
      List<Question> firestoreQuestions = [];
      if (FirebaseService.isInitialized) {
        final firestoreData = await _firebaseService.getQuestionsFromBank();
        firestoreQuestions = firestoreData
            .map((data) {
              try {
                // Deep convert Map<dynamic, dynamic> to Map<String, dynamic>
                return Question.fromJson(_deepConvertMap(data));
              } catch (e) {
                print('Error parsing question from Firestore: $e');
                return null;
              }
            })
            .whereType<Question>()
            .toList();
      }

      // Combine and deduplicate (Firestore takes priority for updates)
      final allQuestions = <String, Question>{};

      // Add database questions first
      for (final question in dbQuestions) {
        allQuestions[question.id] = question;
      }

      // Firestore questions override local ones
      for (final question in firestoreQuestions) {
        allQuestions[question.id] = question;
      }

      // Convert to JSON format
      final questionsJson = allQuestions.values.map((q) => q.toJson()).toList();

      final exportData = {
        'metadata': {
          'version': '1.0',
          'exported_from': 'Complete Question Bank Export',
          'exported_at': DateTime.now().toIso8601String(),
          'description':
              'Complete export of all questions from database and Firestore',
          'total_questions': questionsJson.length,
        },
        'questions': questionsJson,
      };

      // Format with nice indentation
      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      throw Exception('Failed to export questions: $e');
    }
  }

  /// Get the template for new question import
  String getImportTemplate() {
    final template = {
      'metadata': {
        'version': '1.0',
        'exported_from': 'Manual Import',
        'exported_at': DateTime.now().toIso8601String(),
        'description': 'Sample question bank format',
        'total_questions': 1
      },
      'questions': [
        {
          'id': 'unique_question_id_001',
          'question_text': 'Your question text here',
          'question_type':
              2, // 0: MCQ, 1: True/False, 2: Fill in blank, 3: Short answer, etc.
          'subject': 'Subject Name',
          'topic': 'Main Topic',
          'subtopic': 'Sub Topic',
          'grade_level': 5, // 1-12
          'difficulty':
              2, // 0: veryEasy, 1: easy, 2: medium, 3: hard, 4: veryHard
          'answer_key': 'Correct answer',
          'explanation': 'Explanation of the answer',
          'choices': [], // Fill with options for MCQ, otherwise keep empty
          'target_language': 'English',
          'metadata': {
            'curriculum_standards': ['Curriculum Standard'],
            'tags': ['tag1', 'tag2'],
            'estimated_time_minutes': 2,
            'cognitive_level': 2, // 0: remember, 1: understand, 2: apply, etc.
            'additional_data': {}
          }
        }
      ]
    };

    return const JsonEncoder.withIndent('  ').convert(template);
  }

  /// Export all hardcoded lessons to questions JSON format
  Future<String> exportHardcodedLessonsToQuestions() async {
    await _lessonService.initialize();

    // Get all lessons using the public method
    final allLessons = await _lessonService.getAllLessons();

    final questions = <Map<String, dynamic>>[];

    for (final lesson in allLessons) {
      for (int i = 0; i < lesson.exercises.length; i++) {
        final exercise = lesson.exercises[i];

        questions.add({
          'id': '${lesson.id}_q${i + 1}',
          'question_text': exercise.questionText,
          'question_type': _getQuestionTypeFromInputType(exercise.inputType),
          'subject': lesson.subject,
          'topic': lesson.topic,
          'subtopic': lesson.subtopic,
          'grade_level': lesson.gradeLevel,
          'difficulty': _getDifficultyFromLessonDifficulty(lesson.difficulty),
          'answer_key': exercise.answerKey,
          'explanation': exercise.explanation,
          'choices': [], // Exercise model doesn't have choices
          'target_language': lesson.targetLanguage,
          'metadata': {
            'curriculum_standards': [lesson.standardPencapaian],
            'tags': [lesson.topic, lesson.subtopic, lesson.lessonTitle],
            'estimated_time_minutes': 2,
            'cognitive_level': 2, // apply level
            'additional_data': {
              'original_lesson_id': lesson.id,
              'original_lesson_title': lesson.lessonTitle,
              'migrated_from_hardcoded': true,
            },
          },
        });
      }
    }

    final exportData = {
      'metadata': {
        'version': '1.0',
        'exported_from': 'Hardcoded Lessons',
        'exported_at': DateTime.now().toIso8601String(),
        'description':
            'Export of all hardcoded lesson exercises converted to questions',
        'total_questions': questions.length,
        'total_lessons': allLessons.length,
      },
      'questions': questions,
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Helper to convert input type to question type
  int _getQuestionTypeFromInputType(String inputType) {
    switch (inputType.toLowerCase()) {
      case 'multiple_choice':
        return 0; // QuestionType.multipleChoice.index
      case 'true_false':
        return 1; // QuestionType.trueOrFalse.index
      case 'fill_in_the_blank':
      case 'text':
        return 2; // QuestionType.fillInTheBlank.index
      case 'short_answer':
        return 3; // QuestionType.shortAnswer.index
      case 'essay':
        return 4; // QuestionType.essay.index
      case 'matching':
        return 5; // QuestionType.matching.index
      case 'ordering':
        return 6; // QuestionType.ordering.index
      default:
        return 2; // fillInTheBlank as default
    }
  }

  /// Helper to convert lesson difficulty to difficulty tag enum index
  int _getDifficultyFromLessonDifficulty(dynamic lessonDifficulty) {
    // Note: This is a simplified mapping - you might need to adjust based on actual enum values
    if (lessonDifficulty.toString().contains('beginner')) return 1; // easy
    if (lessonDifficulty.toString().contains('intermediate')) {
      return 2; // medium
    }
    if (lessonDifficulty.toString().contains('advanced')) return 3; // hard
    return 2; // medium as default
  }
}
