import 'dart:convert';
import 'dart:io';
import '../models/question.dart';
import 'question_bank_service.dart';
import 'database_service.dart';
import 'firebase_service.dart';

class QuestionImportService {
  static final QuestionImportService _instance =
      QuestionImportService._internal();
  factory QuestionImportService() => _instance;
  QuestionImportService._internal();

  final QuestionBankService _questionBankService = QuestionBankService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Import questions from JSON file
  Future<Map<String, dynamic>> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }

      final jsonString = await file.readAsString();
      return await importFromJsonString(jsonString);
    } catch (e) {
      throw Exception('Failed to import from file: $e');
    }
  }

  /// Import questions from JSON string
  Future<Map<String, dynamic>> importFromJsonString(String jsonString) async {
    try {
      await _questionBankService.initialize();

      final data = json.decode(jsonString);

      if (data is! Map<String, dynamic>) {
        throw FormatException('JSON must be an object');
      }

      return await _processImportData(data);
    } catch (e) {
      throw Exception('Failed to import questions: $e');
    }
  }

  /// Process import data with validation and statistics
  Future<Map<String, dynamic>> _processImportData(
      Map<String, dynamic> data) async {
    final results = {
      'total_processed': 0,
      'successfully_imported': 0,
      'failed_imports': 0,
      'errors': <String>[],
      'warnings': <String>[],
      'duplicates_skipped': 0,
      'metadata': <String, dynamic>{},
    };

    // Process metadata if present
    if (data.containsKey('metadata')) {
      results['metadata'] = data['metadata'];
    }

    // Process questions
    if (!data.containsKey('questions') || data['questions'] is! List) {
      throw FormatException('Missing or invalid questions array');
    }

    final questions = data['questions'] as List<dynamic>;
    results['total_processed'] = questions.length;

    for (int i = 0; i < questions.length; i++) {
      try {
        await _processQuestion(questions[i], i + 1, results);
      } catch (e) {
        results['failed_imports'] = (results['failed_imports'] as int) + 1;
        (results['errors'] as List<String>).add('Question ${i + 1}: $e');
      }
    }

    return results;
  }

  /// Process individual question
  Future<void> _processQuestion(dynamic questionData, int questionIndex,
      Map<String, dynamic> results) async {
    if (questionData is! Map<String, dynamic>) {
      throw FormatException('Question must be an object');
    }

    // Validate and normalize question data
    final normalizedData = _normalizeQuestionData(questionData);

    // Check for duplicates
    if (await _isDuplicate(normalizedData['id'])) {
      results['duplicates_skipped'] =
          (results['duplicates_skipped'] as int) + 1;
      (results['warnings'] as List<String>).add(
          'Question $questionIndex: Duplicate ID "${normalizedData['id']}" skipped');
      return;
    }

    // Validate question data
    final validationErrors = _validateQuestionData(normalizedData);
    if (validationErrors.isNotEmpty) {
      throw FormatException(
          'Validation failed: ${validationErrors.join(', ')}');
    }

    // Create and add question
    final question = Question.fromJson(normalizedData);
    _questionBankService.addQuestion(question);
    
    // Also save question to database so it can be retrieved by LessonService
    await _databaseService.initialize();
    await _databaseService.saveQuestion(question);

    // Also save to Firestore so it's available across devices
    if (FirebaseService.isInitialized) {
      await _firebaseService.saveQuestionToBank(question.toJson());
    }

    results['successfully_imported'] =
        (results['successfully_imported'] as int) + 1;
  }

  /// Check if question ID already exists
  Future<bool> _isDuplicate(String questionId) async {
    try {
      final filter = QuestionFilter();
      final allQuestions = await _questionBankService.getQuestions(filter);
      return allQuestions.any((q) => q.id == questionId);
    } catch (e) {
      return false;
    }
  }

  /// Normalize question data to ensure consistency
  Map<String, dynamic> _normalizeQuestionData(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);

    // Ensure required fields have defaults
    normalized['target_language'] ??= 'English';
    normalized['difficulty'] ??= DifficultyTag.medium.index;
    normalized['choices'] ??= <String>[];

    // Normalize metadata
    if (normalized['metadata'] == null) {
      normalized['metadata'] = <String, dynamic>{};
    }

    final metadata = normalized['metadata'] as Map<String, dynamic>;
    metadata['curriculum_standards'] ??= <String>[];
    metadata['tags'] ??= <String>[];
    metadata['estimated_time_minutes'] ??= 2;
    metadata['cognitive_level'] ??= BloomsTaxonomy.remember.index;
    metadata['additional_data'] ??= <String, dynamic>{};

    return normalized;
  }

  /// Validate question data with detailed error reporting
  List<String> _validateQuestionData(Map<String, dynamic> data) {
    final errors = <String>[];

    // Check required fields
    final requiredFields = {
      'id': 'Question ID',
      'question_text': 'Question text',
      'question_type': 'Question type',
      'subject': 'Subject',
      'topic': 'Topic',
      'subtopic': 'Subtopic',
      'grade_level': 'Grade level',
      'answer_key': 'Answer key',
      'explanation': 'Explanation',
    };

    for (final entry in requiredFields.entries) {
      final value = data[entry.key];
      if (value == null || value.toString().trim().isEmpty) {
        errors.add('${entry.value} is required');
      }
    }

    // Validate data types and ranges
    if (data['grade_level'] != null) {
      final gradeLevel = data['grade_level'];
      if (gradeLevel is! int || gradeLevel < 1 || gradeLevel > 12) {
        errors.add('Grade level must be an integer between 1 and 12');
      }
    }

    if (data['question_type'] != null) {
      final questionType = data['question_type'];
      if (questionType is! int ||
          questionType < 0 ||
          questionType >= QuestionType.values.length) {
        errors.add('Invalid question type index');
      }
    }

    if (data['difficulty'] != null) {
      final difficulty = data['difficulty'];
      if (difficulty is! int ||
          difficulty < 0 ||
          difficulty >= DifficultyTag.values.length) {
        errors.add('Invalid difficulty index');
      }
    }

    // Validate choices for multiple choice questions
    if (data['question_type'] == QuestionType.multipleChoice.index) {
      final choices = data['choices'];
      if (choices == null || choices is! List || choices.length < 2) {
        errors.add('Multiple choice questions must have at least 2 choices');
      }
    }

    return errors;
  }

  /// Generate sample JSON structure for reference
  Map<String, dynamic> generateSampleJson() {
    return {
      'metadata': {
        'version': '1.0',
        'created_by': 'Question Import Tool',
        'created_at': DateTime.now().toIso8601String(),
        'description': 'Sample question bank format',
        'total_questions': 2,
      },
      'questions': [
        {
          'id': 'sample_math_001',
          'question_text': 'What is 2 + 3?',
          'question_type': QuestionType.fillInTheBlank.index,
          'subject': 'Mathematics',
          'topic': 'Addition',
          'subtopic': 'Basic Addition',
          'grade_level': 1,
          'difficulty': DifficultyTag.easy.index,
          'answer_key': '5',
          'explanation':
              'Adding 2 and 3 gives us 5. We can count: 1, 2, then 3, 4, 5.',
          'choices': [],
          'target_language': 'English',
          'metadata': {
            'curriculum_standards': ['KSSR Grade 1 Mathematics'],
            'tags': ['addition', 'basic', 'counting'],
            'estimated_time_minutes': 1,
            'cognitive_level': BloomsTaxonomy.remember.index,
            'additional_data': {
              'image_required': false,
              'calculator_allowed': false,
            },
          },
        },
        {
          'id': 'sample_math_002',
          'question_text': 'Which number is larger?',
          'question_type': QuestionType.multipleChoice.index,
          'subject': 'Mathematics',
          'topic': 'Number Comparison',
          'subtopic': 'Greater Than',
          'grade_level': 1,
          'difficulty': DifficultyTag.easy.index,
          'answer_key': '15',
          'explanation':
              '15 is greater than 8 because it comes after 8 when counting.',
          'choices': ['8', '15'],
          'target_language': 'English',
          'metadata': {
            'curriculum_standards': ['KSSR Grade 1 Mathematics'],
            'tags': ['comparison', 'number_sense'],
            'estimated_time_minutes': 2,
            'cognitive_level': BloomsTaxonomy.understand.index,
            'additional_data': {
              'image_required': false,
              'calculator_allowed': false,
            },
          },
        },
      ],
    };
  }

  /// Verify that questions are properly saved to database
  Future<bool> verifyQuestionSaved(String questionId) async {
    await _databaseService.initialize();
    final question = _databaseService.getQuestion(questionId);
    return question != null;
  }

  /// Export current questions to JSON format
  Future<String> exportQuestionsToJson({
    QuestionFilter? filter,
    bool includeMetadata = true,
  }) async {
    await _questionBankService.initialize();

    List<Question> questions;
    if (filter != null) {
      questions = await _questionBankService.getQuestions(filter);
    } else {
      questions =
          await _questionBankService.getQuestions(const QuestionFilter());
    }

    final exportData = <String, dynamic>{};

    if (includeMetadata) {
      exportData['metadata'] = {
        'version': '1.0',
        'exported_by': 'Question Bank Service',
        'exported_at': DateTime.now().toIso8601String(),
        'total_questions': questions.length,
        'filter_applied': filter != null,
      };
    }

    exportData['questions'] = questions.map((q) => q.toJson()).toList();

    return json.encode(exportData);
  }

  /// Convert existing hardcoded lessons to JSON format
  Map<String, dynamic> convertLessonToQuestions(
    String lessonId,
    String subject,
    String topic,
    int gradeLevel,
    List<Map<String, dynamic>> exercises,
  ) {
    final questions = <Map<String, dynamic>>[];

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];

      questions.add({
        'id': '${lessonId}_q${i + 1}',
        'question_text': exercise['question_text'] ?? '',
        'question_type':
            _inferQuestionType(exercise['input_type'] ?? 'text').index,
        'subject': subject,
        'topic': topic,
        'subtopic': _inferSubtopic(exercise['question_text'] ?? ''),
        'grade_level': gradeLevel,
        'difficulty': _inferDifficulty(exercise['question_text'] ?? '').index,
        'answer_key': exercise['answer_key'] ?? '',
        'explanation': exercise['explanation'] ?? '',
        'choices': exercise['choices'] ?? [],
        'target_language': 'English',
        'metadata': {
          'curriculum_standards': ['KSSR Grade $gradeLevel $subject'],
          'tags': _generateTags(topic, exercise['question_text'] ?? ''),
          'estimated_time_minutes': 2,
          'cognitive_level': BloomsTaxonomy.apply.index,
          'additional_data': {
            'migrated_from': lessonId,
            'original_question_number': exercise['question_number'] ?? i + 1,
          },
        },
      });
    }

    return {
      'metadata': {
        'version': '1.0',
        'converted_from': 'Hardcoded Lesson',
        'lesson_id': lessonId,
        'converted_at': DateTime.now().toIso8601String(),
        'total_questions': questions.length,
      },
      'questions': questions,
    };
  }

  /// Infer question type from input type
  QuestionType _inferQuestionType(String inputType) {
    switch (inputType.toLowerCase()) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueOrFalse;
      case 'short_answer':
        return QuestionType.shortAnswer;
      case 'text':
        return QuestionType.fillInTheBlank;
      default:
        return QuestionType.fillInTheBlank;
    }
  }

  /// Infer difficulty from question text complexity
  DifficultyTag _inferDifficulty(String questionText) {
    final text = questionText.toLowerCase();

    // Simple heuristics for difficulty
    if (text.contains('analyze') ||
        text.contains('evaluate') ||
        text.contains('create')) {
      return DifficultyTag.hard;
    } else if (text.contains('apply') ||
        text.contains('calculate') ||
        text.contains('solve')) {
      return DifficultyTag.medium;
    } else {
      return DifficultyTag.easy;
    }
  }

  /// Infer subtopic from question content
  String _inferSubtopic(String questionText) {
    // Simple keyword-based subtopic inference
    final text = questionText.toLowerCase();

    if (text.contains('add') || text.contains('+')) return 'Addition';
    if (text.contains('subtract') || text.contains('-')) return 'Subtraction';
    if (text.contains('multiply') || text.contains('×') || text.contains('*'))
      return 'Multiplication';
    if (text.contains('divide') || text.contains('÷') || text.contains('/'))
      return 'Division';
    if (text.contains('fraction')) return 'Fractions';
    if (text.contains('time') || text.contains('clock')) return 'Time';
    if (text.contains('money') ||
        text.contains('ringgit') ||
        text.contains('sen')) return 'Money';

    return 'General';
  }

  /// Generate relevant tags for a question
  List<String> _generateTags(String topic, String questionText) {
    final tags = <String>[topic.toLowerCase()];
    final text = questionText.toLowerCase();

    // Add operation-based tags
    if (text.contains('add')) tags.add('addition');
    if (text.contains('subtract')) tags.add('subtraction');
    if (text.contains('multiply')) tags.add('multiplication');
    if (text.contains('divide')) tags.add('division');

    // Add context tags
    if (text.contains('word problem')) tags.add('word_problem');
    if (text.contains('calculate')) tags.add('calculation');
    if (text.contains('compare')) tags.add('comparison');

    return tags;
  }
}
