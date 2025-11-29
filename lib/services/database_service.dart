import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/question.dart';
import '../models/student_progress.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _questionsBoxName = 'questions';
  static const String _progressBoxName = 'student_progress';
  static const String _analyticsBoxName = 'analytics_cache';
  static const String _settingsBoxName = 'app_settings';

  Box<Map>? _questionsBox;
  Box<StudentProgress>? _progressBox;
  Box<Map>? _analyticsBox;
  Box<dynamic>? _settingsBox;

  bool _isInitialized = false;

  /// Initialize Hive database
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('💾 DatabaseService: Already initialized, skipping');
      return;
    }

    debugPrint('🔧 DatabaseService: Starting initialization...');

    try {
      debugPrint('📦 DatabaseService: Initializing Hive Flutter...');
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(2)) {
        debugPrint(
            '📝 DatabaseService: Registering StudentProgress adapter...');
        Hive.registerAdapter(StudentProgressAdapter());
        debugPrint('✅ DatabaseService: Adapter registered');
      } else {
        debugPrint('✅ DatabaseService: Adapter already registered');
      }

      // Open boxes - check if already open first
      debugPrint('📂 DatabaseService: Opening questions box...');
      if (Hive.isBoxOpen(_questionsBoxName)) {
        debugPrint('   Box already open, using existing');
        _questionsBox = Hive.box<Map>(_questionsBoxName);
      } else {
        _questionsBox = await Hive.openBox<Map>(_questionsBoxName);
        debugPrint('   ✅ Opened new questions box');
      }

      debugPrint('📂 DatabaseService: Opening progress box...');
      if (Hive.isBoxOpen(_progressBoxName)) {
        debugPrint('   Box already open, using existing');
        _progressBox = Hive.box<StudentProgress>(_progressBoxName);
      } else {
        _progressBox = await Hive.openBox<StudentProgress>(_progressBoxName);
        debugPrint('   ✅ Opened new progress box');
      }

      debugPrint('📂 DatabaseService: Opening analytics box...');
      if (Hive.isBoxOpen(_analyticsBoxName)) {
        debugPrint('   Box already open, using existing');
        _analyticsBox = Hive.box<Map>(_analyticsBoxName);
      } else {
        _analyticsBox = await Hive.openBox<Map>(_analyticsBoxName);
        debugPrint('   ✅ Opened new analytics box');
      }

      debugPrint('📂 DatabaseService: Opening settings box...');
      if (Hive.isBoxOpen(_settingsBoxName)) {
        debugPrint('   Box already open, checking type...');
        // Try to get the box with the correct type, or use dynamic and cast
        try {
          _settingsBox = Hive.box(_settingsBoxName);
          debugPrint('   ✅ Using existing settings box');
        } catch (e) {
          debugPrint('   ⚠️ Box type mismatch, reopening: $e');
          // If it's open with wrong type, close and reopen
          final box = Hive.box(_settingsBoxName);
          await box.close();
          _settingsBox = await Hive.openBox(_settingsBoxName);
          debugPrint('   ✅ Reopened settings box with correct type');
        }
      } else {
        _settingsBox = await Hive.openBox<Map>(_settingsBoxName);
        debugPrint('   ✅ Opened new settings box');
      }

      _isInitialized = true;
      debugPrint('🎉 DatabaseService: Initialization complete!');
      debugPrint('   - Questions: ${_questionsBox?.length ?? 0} entries');
      debugPrint('   - Progress: ${_progressBox?.length ?? 0} entries');
      debugPrint('   - Analytics: ${_analyticsBox?.length ?? 0} entries');
      debugPrint('   - Settings: ${_settingsBox?.length ?? 0} entries');
    } catch (e, stackTrace) {
      debugPrint('❌ DatabaseService ERROR in initialize: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      throw Exception('Failed to initialize database: $e');
    }
  }

  /// Get questions box
  /// Get questions box
  Box<Map> get questionsBox {
    if (_questionsBox == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _questionsBox!;
  }

  /// Get progress box
  Box<StudentProgress> get progressBox {
    if (_progressBox == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _progressBox!;
  }

  /// Get analytics box
  Box<Map> get analyticsBox {
    if (_analyticsBox == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _analyticsBox!;
  }

  /// Get settings box
  Box<dynamic> get settingsBox {
    if (_settingsBox == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _settingsBox!;
  }

  // ========== QUESTION OPERATIONS ==========

  /// Add or update a question
  Future<void> saveQuestion(Question question) async {
    await initialize();
    await questionsBox.put(question.id, question.toJson());
  }

  /// Get question by ID
  Question? getQuestion(String id) {
    final questionMap = questionsBox.get(id);
    if (questionMap == null) return null;
    return Question.fromJson(Map<String, dynamic>.from(questionMap));
  }

  /// Get all questions
  List<Question> getAllQuestions() {
    return questionsBox.values
        .map((map) => Question.fromJson(Map<String, dynamic>.from(map)))
        .toList();
  }

  /// Delete question by ID
  Future<void> deleteQuestion(String id) async {
    await questionsBox.delete(id);
  }

  /// Remove duplicate questions from local database
  /// Returns the number of duplicates removed
  Future<Map<String, dynamic>> removeDuplicates() async {
    await initialize();
    final allQuestions = getAllQuestions();
    final total = allQuestions.length;

    // Create content hash map to find duplicates
    final Map<String, Question> uniqueByContent = {};
    final List<String> duplicateIds = [];

    for (final question in allQuestions) {
      final contentHash = '${question.questionText.toLowerCase().trim()}|'
          '${question.subject.toLowerCase().trim()}|'
          '${question.topic.toLowerCase().trim()}|'
          '${question.answerKey.toLowerCase().trim()}';

      if (uniqueByContent.containsKey(contentHash)) {
        // This is a duplicate - mark for deletion
        duplicateIds.add(question.id);
      } else {
        uniqueByContent[contentHash] = question;
      }
    }

    // Delete duplicates
    for (final id in duplicateIds) {
      await questionsBox.delete(id);
    }

    debugPrint(
        '🗑️ Removed ${duplicateIds.length} duplicate questions from local database');
    debugPrint('📊 Unique questions remaining: ${uniqueByContent.length}');

    return {
      'total': total,
      'duplicates_removed': duplicateIds.length,
      'unique_remaining': uniqueByContent.length,
      'duplicate_ids': duplicateIds,
    };
  }

  /// Batch save questions
  Future<void> saveQuestions(List<Question> questions) async {
    await initialize();
    final Map<String, Map> questionMap = {};
    for (final question in questions) {
      questionMap[question.id] = question.toJson();
    }
    await questionsBox.putAll(questionMap);
  }

  /// Get questions by filter
  List<Question> getQuestionsByFilter({
    List<int>? gradeLevels,
    List<String>? subjects,
    List<String>? topics,
    List<DifficultyTag>? difficulties,
    List<QuestionType>? questionTypes,
    String? searchText,
  }) {
    var questions = getAllQuestions();

    if (gradeLevels != null && gradeLevels.isNotEmpty) {
      questions =
          questions.where((q) => gradeLevels.contains(q.gradeLevel)).toList();
    }

    if (subjects != null && subjects.isNotEmpty) {
      questions = questions.where((q) => subjects.contains(q.subject)).toList();
    }

    if (topics != null && topics.isNotEmpty) {
      questions = questions.where((q) => topics.contains(q.topic)).toList();
    }

    if (difficulties != null && difficulties.isNotEmpty) {
      questions =
          questions.where((q) => difficulties.contains(q.difficulty)).toList();
    }

    if (questionTypes != null && questionTypes.isNotEmpty) {
      questions = questions
          .where((q) => questionTypes.contains(q.questionType))
          .toList();
    }

    if (searchText != null && searchText.isNotEmpty) {
      final searchLower = searchText.toLowerCase();
      questions = questions.where((q) {
        return q.questionText.toLowerCase().contains(searchLower) ||
            q.answerKey.toLowerCase().contains(searchLower) ||
            q.explanation.toLowerCase().contains(searchLower) ||
            q.metadata.tags
                .any((tag) => tag.toLowerCase().contains(searchLower));
      }).toList();
    }

    return questions;
  }

  /// Get unique values for filtering
  Set<String> getUniqueSubjects() {
    return getAllQuestions().map((q) => q.subject).toSet();
  }

  Set<String> getUniqueTopics() {
    return getAllQuestions().map((q) => q.topic).toSet();
  }

  Set<int> getUniqueGradeLevels() {
    return getAllQuestions().map((q) => q.gradeLevel).toSet();
  }

  // ========== STUDENT PROGRESS OPERATIONS ==========

  /// Record student progress
  Future<void> saveProgress(StudentProgress progress) async {
    await initialize();
    await progressBox.put(progress.id, progress);
  }

  /// Get all progress for a student
  List<StudentProgress> getStudentProgress(String studentId) {
    return progressBox.values
        .where((progress) => progress.studentId == studentId)
        .toList()
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt)); // Latest first
  }

  /// Get progress for a specific question
  List<StudentProgress> getQuestionProgress(String questionId) {
    return progressBox.values
        .where((progress) => progress.questionId == questionId)
        .toList()
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
  }

  /// Get student progress for a subject
  List<StudentProgress> getStudentSubjectProgress(
      String studentId, String subject) {
    return progressBox.values
        .where((progress) =>
            progress.studentId == studentId && progress.subject == subject)
        .toList()
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
  }

  /// Delete all progress for a student
  Future<void> deleteStudentProgress(String studentId) async {
    final keys = progressBox.keys
        .where((key) => progressBox.get(key)?.studentId == studentId)
        .toList();
    await progressBox.deleteAll(keys);
  }

  // ========== ANALYTICS OPERATIONS ==========

  /// Calculate and cache student analytics
  Future<StudentAnalytics> calculateStudentAnalytics(String studentId) async {
    await initialize();

    final progress = getStudentProgress(studentId);

    if (progress.isEmpty) {
      return StudentAnalytics(
        studentId: studentId,
        totalAttempts: 0,
        correctAttempts: 0,
        overallAccuracy: 0.0,
        averageResponseTime: 0.0,
        subjectAccuracy: {},
        topicAccuracy: {},
        difficultyAccuracy: {},
        gradeAccuracy: {},
        strongTopics: [],
        weakTopics: [],
        overallPerformanceLevel: PerformanceLevel.needsImprovement,
        lastAttempt: DateTime.now(),
        streakDays: 0,
      );
    }

    final totalAttempts = progress.length;
    final correctAttempts = progress.where((p) => p.isCorrect).length;
    final overallAccuracy = (correctAttempts / totalAttempts) * 100;
    final averageResponseTime =
        progress.map((p) => p.responseTimeSeconds).reduce((a, b) => a + b) /
            totalAttempts;

    // Calculate subject accuracy
    final subjectAccuracy = <String, double>{};
    final subjectGroups = _groupBy(progress, (p) => p.subject);
    for (final entry in subjectGroups.entries) {
      final subjectProgress = entry.value;
      final correct = subjectProgress.where((p) => p.isCorrect).length;
      subjectAccuracy[entry.key] = (correct / subjectProgress.length) * 100;
    }

    // Calculate topic accuracy
    final topicAccuracy = <String, double>{};
    final topicGroups = _groupBy(progress, (p) => p.topic);
    for (final entry in topicGroups.entries) {
      final topicProgress = entry.value;
      final correct = topicProgress.where((p) => p.isCorrect).length;
      topicAccuracy[entry.key] = (correct / topicProgress.length) * 100;
    }

    // Calculate difficulty accuracy
    final difficultyAccuracy = <DifficultyTag, double>{};
    final difficultyGroups = _groupBy(progress, (p) => p.difficulty);
    for (final entry in difficultyGroups.entries) {
      final difficultyProgress = entry.value;
      final correct = difficultyProgress.where((p) => p.isCorrect).length;
      difficultyAccuracy[entry.key] =
          (correct / difficultyProgress.length) * 100;
    }

    // Calculate grade accuracy
    final gradeAccuracy = <int, double>{};
    final gradeGroups = _groupBy(progress, (p) => p.gradeLevel);
    for (final entry in gradeGroups.entries) {
      final gradeProgress = entry.value;
      final correct = gradeProgress.where((p) => p.isCorrect).length;
      gradeAccuracy[entry.key] = (correct / gradeProgress.length) * 100;
    }

    // Identify strong and weak topics
    final sortedTopics = topicAccuracy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final strongTopics = sortedTopics
        .where((entry) => entry.value >= 80)
        .map((entry) => entry.key)
        .take(5)
        .toList();

    final weakTopics = sortedTopics
        .where((entry) => entry.value < 60)
        .map((entry) => entry.key)
        .toList()
        .reversed
        .take(5)
        .toList();

    // Determine overall performance level
    PerformanceLevel overallPerformanceLevel;
    if (overallAccuracy >= 90) {
      overallPerformanceLevel = PerformanceLevel.excellent;
    } else if (overallAccuracy >= 75) {
      overallPerformanceLevel = PerformanceLevel.good;
    } else if (overallAccuracy >= 60) {
      overallPerformanceLevel = PerformanceLevel.average;
    } else {
      overallPerformanceLevel = PerformanceLevel.needsImprovement;
    }

    // Calculate learning streak
    final streakDays = _calculateLearningStreak(progress);

    final analytics = StudentAnalytics(
      studentId: studentId,
      totalAttempts: totalAttempts,
      correctAttempts: correctAttempts,
      overallAccuracy: overallAccuracy,
      averageResponseTime: averageResponseTime,
      subjectAccuracy: subjectAccuracy,
      topicAccuracy: topicAccuracy,
      difficultyAccuracy: difficultyAccuracy,
      gradeAccuracy: gradeAccuracy,
      strongTopics: strongTopics,
      weakTopics: weakTopics,
      overallPerformanceLevel: overallPerformanceLevel,
      lastAttempt: progress.first.attemptedAt,
      streakDays: streakDays,
    );

    // Cache the analytics
    await analyticsBox.put('student_$studentId', analytics.toJson());

    return analytics;
  }

  /// Get questions filtered by topic
  List<Question> getQuestionsByTopic(String topic, {String? subject}) {
    final questions = getAllQuestions();
    return questions.where((question) {
      if (subject != null && question.subject != subject) return false;
      return question.topic.toLowerCase().contains(topic.toLowerCase()) ||
          question.subtopic.toLowerCase().contains(topic.toLowerCase());
    }).toList();
  }

  /// Get filtered questions based on criteria
  List<Question> getFilteredQuestions({
    String? subject,
    String? topic,
    int? gradeLevel,
    DifficultyTag? difficulty,
    QuestionType? questionType,
    int? limit,
  }) {
    var questions = getAllQuestions();

    // Apply filters
    if (subject != null) {
      questions = questions.where((q) => q.subject == subject).toList();
    }
    if (topic != null) {
      questions = questions.where((q) => q.topic == topic).toList();
    }
    if (gradeLevel != null) {
      questions = questions.where((q) => q.gradeLevel == gradeLevel).toList();
    }
    if (difficulty != null) {
      questions = questions.where((q) => q.difficulty == difficulty).toList();
    }
    if (questionType != null) {
      questions =
          questions.where((q) => q.questionType == questionType).toList();
    }

    // Apply limit
    if (limit != null && questions.length > limit) {
      questions = questions.take(limit).toList();
    }

    return questions;
  }

  /// Get all student progress entries
  List<StudentProgress> getAllProgress() {
    return progressBox.values.toList();
  }

  /// Get question bank statistics
  Map<String, dynamic> getQuestionBankStats() {
    final questions = getAllQuestions();
    if (questions.isEmpty) {
      return {
        'total_questions': 0,
        'subjects': <String, dynamic>{},
        'grade_levels': <String, dynamic>{},
        'difficulties': <String, dynamic>{},
        'question_types': <String, dynamic>{},
        'topics': <String, dynamic>{},
      };
    }

    final bySubject = _groupBy(questions, (q) => q.subject);
    final byGrade = _groupBy(questions, (q) => q.gradeLevel);
    final byDifficulty = _groupBy(questions, (q) => q.difficulty);
    final byType = _groupBy(questions, (q) => q.questionType);
    final byTopic = _groupBy(questions, (q) => q.topic);

    return {
      'total_questions': questions.length,
      'subjects': Map<String, dynamic>.from(
          bySubject.map((k, v) => MapEntry(k, v.length))),
      'grade_levels': Map<String, dynamic>.from(
          byGrade.map((k, v) => MapEntry(k.toString(), v.length))),
      'difficulties': Map<String, dynamic>.from(
          byDifficulty.map((k, v) => MapEntry(k.name, v.length))),
      'question_types': Map<String, dynamic>.from(
          byType.map((k, v) => MapEntry(k.name, v.length))),
      'topics': Map<String, dynamic>.from(
          byTopic.map((k, v) => MapEntry(k, v.length))),
      'avg_questions_per_subject': questions.length / bySubject.length,
      'coverage_grade_levels': byGrade.keys.toList()..sort(),
    };
  }

  // ========== UTILITY METHODS ==========

  /// Group items by a key function
  Map<T, List<S>> _groupBy<S, T>(Iterable<S> values, T Function(S) key) {
    final map = <T, List<S>>{};
    for (final element in values) {
      final k = key(element);
      map.putIfAbsent(k, () => []).add(element);
    }
    return map;
  }

  /// Calculate learning streak in days
  int _calculateLearningStreak(List<StudentProgress> progress) {
    if (progress.isEmpty) return 0;

    final sortedProgress = progress.toList()
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));

    final today = DateTime.now();
    final uniqueDays = <DateTime>{};

    for (final p in sortedProgress) {
      final day =
          DateTime(p.attemptedAt.year, p.attemptedAt.month, p.attemptedAt.day);
      uniqueDays.add(day);
    }

    final sortedDays = uniqueDays.toList()..sort((a, b) => b.compareTo(a));

    int streak = 0;
    final todayDate = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < sortedDays.length; i++) {
      final expectedDate = todayDate.subtract(Duration(days: i));
      if (sortedDays[i].isAtSameMomentAs(expectedDate)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Export all data to JSON
  Future<Map<String, dynamic>> exportAllData() async {
    await initialize();

    return {
      'questions': getAllQuestions().map((q) => q.toJson()).toList(),
      'progress': progressBox.values.map((p) => p.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// Import data from JSON
  Future<Map<String, dynamic>> importData(Map<String, dynamic> data) async {
    await initialize();

    int questionsImported = 0;
    int progressImported = 0;
    final errors = <String>[];

    // Import questions
    if (data.containsKey('questions')) {
      try {
        final questionsData = data['questions'] as List<dynamic>;
        for (final questionJson in questionsData) {
          try {
            final question = Question.fromJson(questionJson);
            await saveQuestion(question);
            questionsImported++;
          } catch (e) {
            errors.add('Question import error: $e');
          }
        }
      } catch (e) {
        errors.add('Questions array error: $e');
      }
    }

    // Import progress
    if (data.containsKey('progress')) {
      try {
        final progressData = data['progress'] as List<dynamic>;
        for (final progressJson in progressData) {
          try {
            final progress = StudentProgress.fromJson(progressJson);
            await saveProgress(progress);
            progressImported++;
          } catch (e) {
            errors.add('Progress import error: $e');
          }
        }
      } catch (e) {
        errors.add('Progress array error: $e');
      }
    }

    return {
      'questions_imported': questionsImported,
      'progress_imported': progressImported,
      'errors': errors,
      'success': errors.isEmpty,
    };
  }

  /// Clear all data (use with caution!)
  Future<void> clearAllData() async {
    await initialize();
    await questionsBox.clear();
    await progressBox.clear();
    await analyticsBox.clear();
  }

  /// Get database size info
  Map<String, dynamic> getDatabaseInfo() {
    return {
      'questions_count': questionsBox.length,
      'progress_count': progressBox.length,
      'analytics_cache_count': analyticsBox.length,
      'settings_count': settingsBox.length,
      'total_entries': questionsBox.length +
          progressBox.length +
          analyticsBox.length +
          settingsBox.length,
      'is_initialized': _isInitialized,
    };
  }

  /// Close database connections
  Future<void> close() async {
    await _questionsBox?.close();
    await _progressBox?.close();
    await _analyticsBox?.close();
    await _settingsBox?.close();
    _isInitialized = false;
  }
}
