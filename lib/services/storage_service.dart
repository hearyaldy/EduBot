import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../utils/environment_config.dart';
import 'questions_service.dart';

class StorageService {
  static const String _questionsBoxName = 'homework_questions';
  static const String _explanationsBoxName = 'explanations';
  static const String _settingsBoxName = 'app_settings';

  static final _config = EnvironmentConfig.instance;
  final _questionsService = QuestionsService.instance;

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late Box<Map> _questionsBox;
  late Box<Map> _explanationsBox;
  late Box<dynamic> _settingsBox;

  bool _isInitialized = false;

  // Initialize Hive and open boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Open boxes
      _questionsBox = await Hive.openBox<Map>(_questionsBoxName);
      _explanationsBox = await Hive.openBox<Map>(_explanationsBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);

      _isInitialized = true;

      try {
        if (_config.isDebugMode) {
          debugPrint('Storage service initialized successfully');
          debugPrint('Questions stored: ${_questionsBox.length}');
          debugPrint('Explanations stored: ${_explanationsBox.length}');
        }
      } catch (_) {
        // Fallback if environment config is not ready yet
        debugPrint('Storage service initialized successfully');
        debugPrint('Questions stored: ${_questionsBox.length}');
        debugPrint('Explanations stored: ${_explanationsBox.length}');
      }
    } catch (e) {
      try {
        if (_config.isDebugMode) {
          debugPrint('Failed to initialize storage service: $e');
        }
      } catch (_) {
        // Fallback if environment config is not ready yet
        debugPrint('Failed to initialize storage service: $e');
      }
      throw Exception('Storage initialization failed: $e');
    }
  }

  // === HOMEWORK QUESTIONS ===

  // Save a homework question (saves to both local storage and Supabase)
  Future<void> saveQuestion(HomeworkQuestion question) async {
    if (!_isInitialized) await initialize();

    try {
      // Save to local storage first (always works)
      await _questionsBox.put(question.id, question.toJson());
      if (_config.isDebugMode) {
        print('Question saved locally: ${question.id}');
      }

      // Also save to Supabase if user is authenticated
      final supabaseSuccess = await _questionsService.saveQuestion(question);
      if (_config.isDebugMode) {
        print('Question saved to Supabase: $supabaseSuccess');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to save question: $e');
      }
      throw Exception('Failed to save question: $e');
    }
  }

  // Get all homework questions (synced with Supabase if authenticated)
  Future<List<HomeworkQuestion>> getAllQuestions() async {
    if (!_isInitialized) await initialize();

    try {
      // Get local questions first
      final localQuestions = _questionsBox.values
          .map((json) =>
              HomeworkQuestion.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      // Sort by creation date (newest first)
      localQuestions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Sync with Supabase if user is authenticated
      final syncedQuestions = await _questionsService.syncQuestions(localQuestions);
      
      if (_config.isDebugMode) {
        print('Questions loaded: ${syncedQuestions.length} (local: ${localQuestions.length})');
      }

      return syncedQuestions;
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to get questions: $e');
      }
      return [];
    }
  }

  // Get a specific question by ID
  Future<HomeworkQuestion?> getQuestion(String id) async {
    if (!_isInitialized) await initialize();

    try {
      final json = _questionsBox.get(id);
      if (json != null) {
        return HomeworkQuestion.fromJson(Map<String, dynamic>.from(json));
      }
      return null;
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to get question $id: $e');
      }
      return null;
    }
  }

  // Delete a question (deletes from both local storage and Supabase)
  Future<void> deleteQuestion(String id) async {
    if (!_isInitialized) await initialize();

    try {
      // Delete from local storage
      await _questionsBox.delete(id);
      await deleteExplanation(id);
      
      // Also delete from Supabase if user is authenticated
      final supabaseSuccess = await _questionsService.deleteQuestion(id);
      
      if (_config.isDebugMode) {
        print('Question deleted locally: $id');
        print('Question deleted from Supabase: $supabaseSuccess');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to delete question: $e');
      }
      throw Exception('Failed to delete question: $e');
    }
  }

  // Clear all questions
  Future<void> clearAllQuestions() async {
    if (!_isInitialized) await initialize();

    try {
      await _questionsBox.clear();
      await _explanationsBox.clear();
      if (_config.isDebugMode) {
        print('All questions cleared');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to clear questions: $e');
      }
      throw Exception('Failed to clear questions: $e');
    }
  }

  // === EXPLANATIONS ===

  // Save an explanation (saves to both local storage and Supabase)
  Future<void> saveExplanation(Explanation explanation) async {
    if (!_isInitialized) await initialize();

    try {
      // Save to local storage first (always works)
      await _explanationsBox.put(explanation.questionId, explanation.toJson());
      if (_config.isDebugMode) {
        print('Explanation saved locally for question: ${explanation.questionId}');
      }

      // Also save to Supabase if user is authenticated
      final supabaseSuccess = await _questionsService.saveExplanation(explanation);
      if (_config.isDebugMode) {
        print('Explanation saved to Supabase: $supabaseSuccess');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to save explanation: $e');
      }
      throw Exception('Failed to save explanation: $e');
    }
  }

  // Get explanation for a question (tries Supabase first, then local)
  Future<Explanation?> getExplanation(String questionId) async {
    if (!_isInitialized) await initialize();

    try {
      // Try Supabase first if user is authenticated
      final supabaseExplanation = await _questionsService.getExplanation(questionId);
      if (supabaseExplanation != null) {
        if (_config.isDebugMode) {
          print('Explanation loaded from Supabase for $questionId');
        }
        return supabaseExplanation;
      }

      // Fall back to local storage
      final json = _explanationsBox.get(questionId);
      if (json != null) {
        final explanation = Explanation.fromJson(json);
        if (_config.isDebugMode) {
          print('Explanation loaded locally for $questionId');
        }
        return explanation;
      }
      return null;
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to get explanation for $questionId: $e');
      }
      return null;
    }
  }

  // Delete an explanation
  Future<void> deleteExplanation(String questionId) async {
    if (!_isInitialized) await initialize();

    try {
      await _explanationsBox.delete(questionId);
      if (_config.isDebugMode) {
        print('Explanation deleted for question: $questionId');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to delete explanation: $e');
      }
    }
  }

  // === APP SETTINGS ===

  // Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    if (!_isInitialized) await initialize();

    try {
      await _settingsBox.put(key, value);
      if (_config.isDebugMode) {
        print('Setting saved: $key = $value');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to save setting $key: $e');
      }
    }
  }

  // Get a setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    if (!_isInitialized) return defaultValue;

    try {
      return _settingsBox.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to get setting $key: $e');
      }
      return defaultValue;
    }
  }

  // Delete a setting
  Future<void> deleteSetting(String key) async {
    if (!_isInitialized) await initialize();

    try {
      await _settingsBox.delete(key);
      if (_config.isDebugMode) {
        print('Setting deleted: $key');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to delete setting $key: $e');
      }
    }
  }

  // === STATISTICS ===

  // Get total number of questions asked
  int get totalQuestionsCount => _isInitialized ? _questionsBox.length : 0;

  // Get questions count by type
  Future<Map<QuestionType, int>> getQuestionCountsByType() async {
    if (!_isInitialized) await initialize();

    final questions = await getAllQuestions();
    final counts = <QuestionType, int>{};

    for (final type in QuestionType.values) {
      counts[type] = questions.where((q) => q.type == type).length;
    }

    return counts;
  }

  // Get questions count by subject
  Future<Map<String, int>> getQuestionCountsBySubject() async {
    if (!_isInitialized) await initialize();

    final questions = await getAllQuestions();
    final counts = <String, int>{};

    for (final question in questions) {
      final subject = question.subject ?? 'Unknown';
      counts[subject] = (counts[subject] ?? 0) + 1;
    }

    return counts;
  }

  // === CLEANUP ===

  // Close all boxes (call when app is closing)
  Future<void> close() async {
    if (!_isInitialized) return;

    try {
      await _questionsBox.close();
      await _explanationsBox.close();
      await _settingsBox.close();
      _isInitialized = false;

      if (_config.isDebugMode) {
        print('Storage service closed');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Error closing storage service: $e');
      }
    }
  }

  // === FUTURE UPGRADE NOTES ===

  // TODO: Cross-device sync implementation
  // When implementing user authentication and cross-device sync:
  // 1. Add user ID to all stored data
  // 2. Implement Firebase Firestore sync
  // 3. Handle offline/online state
  // 4. Merge conflicts resolution
  // 5. Add data migration utilities

  // Placeholder for future sync functionality
  Future<void> syncToCloud({required String userId}) async {
    // TODO: Implement cloud sync when Firebase auth is added
    throw UnimplementedError('Cloud sync will be implemented in Phase 2');
  }

  Future<void> syncFromCloud({required String userId}) async {
    // TODO: Implement cloud sync when Firebase auth is added
    throw UnimplementedError('Cloud sync will be implemented in Phase 2');
  }
}
