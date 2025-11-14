import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/question.dart';
import '../services/database_service.dart';
import 'question_export_service.dart';

/// Service to initialize the question bank from sample JSON files
class QuestionBankInitializer {
  static final QuestionBankInitializer _instance =
      QuestionBankInitializer._internal();
  factory QuestionBankInitializer() => _instance;
  QuestionBankInitializer._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// List of all sample question files
  final List<String> _questionFiles = [
    'assets/sample_questions/year6_science.json',
    'assets/sample_questions/year2_mathematics_basic.json',
    'assets/sample_questions/year3_english_reading.json',
  ];

  /// Import all sample questions from assets
  Future<Map<String, dynamic>> importAllSampleQuestions() async {
    debugPrint('📚 QuestionBankInitializer: Starting import of all sample questions');

    try {
      await _databaseService.initialize();
      debugPrint('✅ QuestionBankInitializer: Database initialized');

      int totalProcessed = 0;
      int totalSuccess = 0;
      int totalFailed = 0;
      final List<String> allErrors = [];
      final Map<String, Map<String, dynamic>> fileResults = {};

      for (final filePath in _questionFiles) {
        debugPrint('📂 QuestionBankInitializer: Importing $filePath');

        final result = await _importQuestionFile(filePath);
        fileResults[filePath] = result;

        totalProcessed += result['total_processed'] as int;
        totalSuccess += result['successfully_imported'] as int;
        totalFailed += result['failed_imports'] as int;
        allErrors.addAll(result['errors'] as List<String>);

        debugPrint(
            '   ✅ Imported ${result['successfully_imported']}/${result['total_processed']} questions');
      }

      debugPrint(
          '🎉 QuestionBankInitializer: Import complete! Total: $totalSuccess/$totalProcessed questions imported');

      return {
        'total_processed': totalProcessed,
        'successfully_imported': totalSuccess,
        'failed_imports': totalFailed,
        'errors': allErrors,
        'file_results': fileResults,
        'files_imported': _questionFiles.length,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ QuestionBankInitializer ERROR: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      return {
        'total_processed': 0,
        'successfully_imported': 0,
        'failed_imports': 0,
        'errors': ['Error during import: $e'],
        'file_results': {},
        'files_imported': 0,
      };
    }
  }

  /// Import questions from a specific file
  Future<Map<String, dynamic>> _importQuestionFile(String filePath) async {
    try {
      // Load the JSON file from assets
      final jsonString = await rootBundle.loadString(filePath);

      // Parse the JSON
      final jsonData = json.decode(jsonString);

      // Handle different JSON formats
      List<dynamic> questionsJson;
      if (jsonData is List) {
        questionsJson = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('questions')) {
        questionsJson = jsonData['questions'] as List;
      } else {
        throw const FormatException(
            'Invalid JSON format. Expected array of questions or object with "questions" key.');
      }

      int successCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      // Parse and save each question
      for (var i = 0; i < questionsJson.length; i++) {
        try {
          final questionData = questionsJson[i] as Map<String, dynamic>;
          final question = Question.fromJson(questionData);

          // Save to database
          await _databaseService.saveQuestion(question);
          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('$filePath [index $i]: $e');
          debugPrint('   ⚠️ Failed to import question at index $i: $e');
        }
      }

      return {
        'total_processed': questionsJson.length,
        'successfully_imported': successCount,
        'failed_imports': errorCount,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('   ❌ Failed to load file $filePath: $e');
      return {
        'total_processed': 0,
        'successfully_imported': 0,
        'failed_imports': 0,
        'errors': ['Error loading file $filePath: $e'],
      };
    }
  }

  /// Import a specific subject's questions
  Future<Map<String, dynamic>> importYear6Science() async {
    debugPrint('📚 QuestionBankInitializer: Importing Year 6 Science');
    return await _importQuestionFile(
        'assets/sample_questions/year6_science.json');
  }

  Future<Map<String, dynamic>> importYear2Mathematics() async {
    debugPrint('📚 QuestionBankInitializer: Importing Year 2 Mathematics');
    return await _importQuestionFile(
        'assets/sample_questions/year2_mathematics_basic.json');
  }

  Future<Map<String, dynamic>> importYear3English() async {
    debugPrint('📚 QuestionBankInitializer: Importing Year 3 English');
    return await _importQuestionFile(
        'assets/sample_questions/year3_english_reading.json');
  }

  /// Check if question bank has been initialized
  Future<bool> isQuestionBankInitialized() async {
    try {
      await _databaseService.initialize();
      final questionCount = _databaseService.getAllQuestions().length;
      debugPrint('💾 QuestionBankInitializer: Found $questionCount questions in database');
      return questionCount > 0;
    } catch (e) {
      debugPrint('❌ QuestionBankInitializer: Error checking database: $e');
      return false;
    }
  }

  /// Get question bank statistics
  Future<Map<String, dynamic>> getQuestionBankStats() async {
    try {
      await _databaseService.initialize();
      return _databaseService.getQuestionBankStats();
    } catch (e) {
      debugPrint('❌ QuestionBankInitializer: Error getting stats: $e');
      return {
        'total_questions': 0,
        'subjects': {},
        'grade_levels': {},
      };
    }
  }

  /// Clear all questions from database (use with caution!)
  Future<void> clearAllQuestions() async {
    debugPrint('⚠️ QuestionBankInitializer: Clearing all questions');
    try {
      await _databaseService.initialize();
      final box = _databaseService.questionsBox;
      await box.clear();
      debugPrint('✅ QuestionBankInitializer: All questions cleared');
    } catch (e) {
      debugPrint('❌ QuestionBankInitializer: Error clearing questions: $e');
      rethrow;
    }
  }

  /// Import hardcoded lessons to question bank
  Future<Map<String, dynamic>> importHardcodedLessons() async {
    debugPrint('📚 QuestionBankInitializer: Importing hardcoded lessons to question bank');

    try {
      final exportService = QuestionExportService();
      final result = await exportService.exportAllLessons();
      
      debugPrint('✅ QuestionBankInitializer: Hardcoded lessons exported to question bank');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ QuestionBankInitializer: Error importing hardcoded lessons: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Error during export: $e',
      };
    }
  }

  /// Re-import all questions (clear and reimport)
  Future<Map<String, dynamic>> reimportAllQuestions() async {
    debugPrint('🔄 QuestionBankInitializer: Re-importing all questions');

    try {
      // Clear existing questions
      await clearAllQuestions();

      // Import fresh
      return await importAllSampleQuestions();
    } catch (e, stackTrace) {
      debugPrint('❌ QuestionBankInitializer: Error during reimport: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return {
        'total_processed': 0,
        'successfully_imported': 0,
        'failed_imports': 0,
        'errors': ['Error during reimport: $e'],
      };
    }
  }
}
