import 'dart:convert';
import 'dart:math';
import '../models/question.dart';
import '../models/lesson.dart';

class QuestionFilter {
  final List<int>? gradeLevels;
  final List<String>? subjects;
  final List<String>? topics;
  final List<String>? subtopics;
  final List<DifficultyTag>? difficulties;
  final List<QuestionType>? questionTypes;
  final List<BloomsTaxonomy>? cognitiveLevels;
  final List<String>? tags;
  final String? targetLanguage;

  const QuestionFilter({
    this.gradeLevels,
    this.subjects,
    this.topics,
    this.subtopics,
    this.difficulties,
    this.questionTypes,
    this.cognitiveLevels,
    this.tags,
    this.targetLanguage,
  });
}

class LessonTemplate {
  final String id;
  final String title;
  final String subject;
  final String topic;
  final int gradeLevel;
  final DifficultyLevel difficulty;
  final int targetQuestionCount;
  final Duration estimatedDuration;
  final QuestionFilter questionFilter;
  final Map<DifficultyTag, int> difficultyDistribution;

  const LessonTemplate({
    required this.id,
    required this.title,
    required this.subject,
    required this.topic,
    required this.gradeLevel,
    required this.difficulty,
    this.targetQuestionCount = 10,
    this.estimatedDuration = const Duration(minutes: 30),
    required this.questionFilter,
    this.difficultyDistribution = const {
      DifficultyTag.easy: 40, // 40% easy
      DifficultyTag.medium: 40, // 40% medium
      DifficultyTag.hard: 20, // 20% hard
    },
  });
}

class QuestionBankService {
  static final QuestionBankService _instance = QuestionBankService._internal();
  factory QuestionBankService() => _instance;
  QuestionBankService._internal();

  final Map<String, Question> _questionBank = {};
  final Map<String, List<String>> _gradeQuestionIndex = {};
  final Map<String, List<String>> _topicQuestionIndex = {};
  final Map<String, List<String>> _difficultyQuestionIndex = {};
  bool _isInitialized = false;

  /// Initialize the question bank with sample data
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load question data (could be from JSON, database, etc.)
    await _loadQuestionBank();
    _buildIndexes();
    _isInitialized = true;
  }

  /// Load questions from various sources
  Future<void> _loadQuestionBank() async {
    // Add Year 1 Mathematics questions
    _addYear1MathQuestions();

    // Add Year 6 Mathematics questions
    _addYear6MathQuestions();

    // Future: Load from JSON files, database, API, etc.
    // await _loadFromJson('assets/questions/grade1_math.json');
    // await _loadFromDatabase();
  }

  /// Build indexes for efficient filtering
  void _buildIndexes() {
    for (final question in _questionBank.values) {
      // Grade level index
      final gradeKey = 'grade_${question.gradeLevel}';
      _gradeQuestionIndex.putIfAbsent(gradeKey, () => []);
      _gradeQuestionIndex[gradeKey]!.add(question.id);

      // Topic index
      final topicKey = '${question.subject}_${question.topic}';
      _topicQuestionIndex.putIfAbsent(topicKey, () => []);
      _topicQuestionIndex[topicKey]!.add(question.id);

      // Difficulty index
      final difficultyKey = question.difficulty.name;
      _difficultyQuestionIndex.putIfAbsent(difficultyKey, () => []);
      _difficultyQuestionIndex[difficultyKey]!.add(question.id);
    }
  }

  /// Add a question to the bank
  void addQuestion(Question question) {
    _questionBank[question.id] = question;
    _updateIndexes(question);
  }

  /// Update indexes when adding a question
  void _updateIndexes(Question question) {
    final gradeKey = 'grade_${question.gradeLevel}';
    _gradeQuestionIndex.putIfAbsent(gradeKey, () => []);
    if (!_gradeQuestionIndex[gradeKey]!.contains(question.id)) {
      _gradeQuestionIndex[gradeKey]!.add(question.id);
    }

    final topicKey = '${question.subject}_${question.topic}';
    _topicQuestionIndex.putIfAbsent(topicKey, () => []);
    if (!_topicQuestionIndex[topicKey]!.contains(question.id)) {
      _topicQuestionIndex[topicKey]!.add(question.id);
    }

    final difficultyKey = question.difficulty.name;
    _difficultyQuestionIndex.putIfAbsent(difficultyKey, () => []);
    if (!_difficultyQuestionIndex[difficultyKey]!.contains(question.id)) {
      _difficultyQuestionIndex[difficultyKey]!.add(question.id);
    }
  }

  /// Get questions by filter
  Future<List<Question>> getQuestions(QuestionFilter filter) async {
    await initialize();

    return _questionBank.values.where((question) {
      return _matchesFilter(question, filter);
    }).toList();
  }

  /// Check if question matches filter criteria
  bool _matchesFilter(Question question, QuestionFilter filter) {
    if (filter.gradeLevels != null &&
        !filter.gradeLevels!.contains(question.gradeLevel)) {
      return false;
    }

    if (filter.subjects != null &&
        !filter.subjects!.contains(question.subject)) {
      return false;
    }

    if (filter.topics != null && !filter.topics!.contains(question.topic)) {
      return false;
    }

    if (filter.subtopics != null &&
        !filter.subtopics!.contains(question.subtopic)) {
      return false;
    }

    if (filter.difficulties != null &&
        !filter.difficulties!.contains(question.difficulty)) {
      return false;
    }

    if (filter.questionTypes != null &&
        !filter.questionTypes!.contains(question.questionType)) {
      return false;
    }

    if (filter.cognitiveLevels != null &&
        !filter.cognitiveLevels!.contains(question.metadata.cognitiveLevel)) {
      return false;
    }

    if (filter.targetLanguage != null &&
        question.targetLanguage != filter.targetLanguage) {
      return false;
    }

    if (filter.tags != null) {
      final hasMatchingTag =
          filter.tags!.any((tag) => question.metadata.tags.contains(tag));
      if (!hasMatchingTag) return false;
    }

    return true;
  }

  /// Generate a lesson from a template
  Future<Lesson> generateLesson(LessonTemplate template) async {
    await initialize();

    final questions = await getQuestions(template.questionFilter);

    if (questions.isEmpty) {
      throw Exception('No questions found matching the criteria');
    }

    // Select questions based on difficulty distribution
    final selectedQuestions = _selectQuestionsByDistribution(
      questions,
      template.targetQuestionCount,
      template.difficultyDistribution,
    );

    // Convert questions to exercises
    final exercises = selectedQuestions.asMap().entries.map((entry) {
      return entry.value.toExercise(questionNumber: entry.key + 1);
    }).toList();

    return Lesson(
      id: template.id,
      lessonTitle: template.title,
      targetLanguage: questions.first.targetLanguage,
      gradeLevel: template.gradeLevel,
      subject: template.subject,
      topic: template.topic,
      subtopic: questions.first.subtopic,
      learningObjective: 'Practice ${template.topic} skills',
      standardPencapaian: 'Generated lesson for ${template.subject}',
      exercises: exercises,
      difficulty: template.difficulty,
      estimatedDuration: template.estimatedDuration.inMinutes,
    );
  }

  /// Select questions based on difficulty distribution
  List<Question> _selectQuestionsByDistribution(
    List<Question> questions,
    int targetCount,
    Map<DifficultyTag, int> distribution,
  ) {
    final selected = <Question>[];
    final random = Random();

    // Group questions by difficulty
    final byDifficulty = <DifficultyTag, List<Question>>{};
    for (final question in questions) {
      byDifficulty.putIfAbsent(question.difficulty, () => []);
      byDifficulty[question.difficulty]!.add(question);
    }

    // Select questions based on distribution percentages
    for (final entry in distribution.entries) {
      final difficulty = entry.key;
      final percentage = entry.value;
      final count = (targetCount * percentage / 100).round();

      if (byDifficulty[difficulty] != null) {
        final availableQuestions = byDifficulty[difficulty]!;
        availableQuestions.shuffle(random);

        final takeCount = min(count, availableQuestions.length);
        selected.addAll(availableQuestions.take(takeCount));
      }
    }

    // If we don't have enough questions, fill with random ones
    if (selected.length < targetCount) {
      final remaining = questions.where((q) => !selected.contains(q)).toList();
      remaining.shuffle(random);
      final needed = targetCount - selected.length;
      selected.addAll(remaining.take(needed));
    }

    selected.shuffle(random);
    return selected.take(targetCount).toList();
  }

  /// Get available topics for a grade level
  Future<List<String>> getTopicsForGrade(int gradeLevel, String subject) async {
    await initialize();

    final questions = await getQuestions(QuestionFilter(
      gradeLevels: [gradeLevel],
      subjects: [subject],
    ));

    return questions.map((q) => q.topic).toSet().toList()..sort();
  }

  /// Get question statistics
  Future<Map<String, dynamic>> getQuestionStats() async {
    await initialize();

    final totalQuestions = _questionBank.length;
    final byGrade = <int, int>{};
    final bySubject = <String, int>{};
    final byDifficulty = <DifficultyTag, int>{};

    for (final question in _questionBank.values) {
      byGrade[question.gradeLevel] = (byGrade[question.gradeLevel] ?? 0) + 1;
      bySubject[question.subject] = (bySubject[question.subject] ?? 0) + 1;
      byDifficulty[question.difficulty] =
          (byDifficulty[question.difficulty] ?? 0) + 1;
    }

    return {
      'total_questions': totalQuestions,
      'by_grade': byGrade,
      'by_subject': bySubject,
      'by_difficulty': byDifficulty.map((k, v) => MapEntry(k.name, v)),
    };
  }

  // Sample question creation methods
  void _addYear1MathQuestions() {
    // Add the Year 1 questions from the previous implementation
    final year1Questions = [
      Question(
        id: 'y1_math_numbers_001',
        questionText: 'How many apples are there?',
        questionType: QuestionType.fillInTheBlank,
        subject: 'Mathematics',
        topic: 'Whole Numbers',
        subtopic: 'Counting',
        gradeLevel: 1,
        difficulty: DifficultyTag.easy,
        answerKey: '7',
        explanation:
            'The image shows a group of seven apples. Counting them one by one gives the total number.',
        metadata: QuestionMetadata(
          curriculumStandards: ['KSSR Year 1 Mathematics 1.0'],
          tags: ['counting', 'visual', 'basic'],
          estimatedTime: Duration(minutes: 1),
          cognitiveLevel: BloomsTaxonomy.remember,
        ),
      ),
      Question(
        id: 'y1_math_numbers_002',
        questionText: 'Which number is bigger, 15 or 23?',
        questionType: QuestionType.multipleChoice,
        subject: 'Mathematics',
        topic: 'Whole Numbers',
        subtopic: 'Number Comparison',
        gradeLevel: 1,
        difficulty: DifficultyTag.easy,
        answerKey: '23',
        explanation:
            'When comparing two numbers, the number with the higher value is bigger. 23 is greater than 15.',
        choices: ['15', '23'],
        metadata: QuestionMetadata(
          curriculumStandards: ['KSSR Year 1 Mathematics 1.0'],
          tags: ['comparison', 'number_sense'],
          estimatedTime: Duration(minutes: 1),
          cognitiveLevel: BloomsTaxonomy.understand,
        ),
      ),
      // Add more Year 1 questions...
    ];

    for (final question in year1Questions) {
      addQuestion(question);
    }
  }

  void _addYear6MathQuestions() {
    // Add Year 6 questions
    final year6Questions = [
      Question(
        id: 'y6_math_time_001',
        questionText:
            'What is the time difference between 2:30 PM in Kuala Lumpur and the same moment in Tokyo?',
        questionType: QuestionType.calculation,
        subject: 'Mathematics',
        topic: 'Time Zones',
        subtopic: 'International Time Calculation',
        gradeLevel: 6,
        difficulty: DifficultyTag.medium,
        answerKey: '1 hour ahead',
        explanation:
            'Tokyo is UTC+9 and Kuala Lumpur is UTC+8. Tokyo is 1 hour ahead of Kuala Lumpur.',
        metadata: QuestionMetadata(
          curriculumStandards: [
            'KSSR Year 6 Mathematics - Time and Time Zones'
          ],
          tags: ['time_zones', 'calculation', 'international'],
          estimatedTime: Duration(minutes: 3),
          cognitiveLevel: BloomsTaxonomy.apply,
        ),
      ),
      // Add more Year 6 questions...
    ];

    for (final question in year6Questions) {
      addQuestion(question);
    }
  }

  /// Load questions from JSON (implementation for Phase 2)
  Future<void> loadFromJson(String jsonString) async {
    try {
      final data = json.decode(jsonString);

      if (data is Map<String, dynamic> && data.containsKey('questions')) {
        final questions = data['questions'] as List<dynamic>;

        for (final questionData in questions) {
          if (questionData is Map<String, dynamic>) {
            final question = Question.fromJson(questionData);
            addQuestion(question);
          }
        }

        print('Loaded ${questions.length} questions from JSON');
      } else {
        throw FormatException('Invalid JSON format. Expected questions array.');
      }
    } catch (e) {
      throw Exception('Failed to load questions from JSON: $e');
    }
  }

  /// Load questions from JSON file path
  Future<void> loadFromJsonFile(String filePath) async {
    try {
      // In a real implementation, you would read from the file system
      // For now, this is a placeholder for the structure
      throw UnimplementedError(
          'File loading not implemented yet. Use loadFromJson() with JSON string instead.');
    } catch (e) {
      throw Exception('Failed to load questions from file: $e');
    }
  }

  /// Batch import questions with validation
  Future<Map<String, dynamic>> batchImportQuestions(
      List<Map<String, dynamic>> questionsData) async {
    final results = {
      'imported': 0,
      'failed': 0,
      'errors': <String>[],
    };

    for (int i = 0; i < questionsData.length; i++) {
      try {
        final questionData = questionsData[i];

        // Validate required fields
        if (!_validateQuestionData(questionData)) {
          results['failed'] = (results['failed'] as int) + 1;
          (results['errors'] as List<String>)
              .add('Question ${i + 1}: Missing required fields');
          continue;
        }

        final question = Question.fromJson(questionData);
        addQuestion(question);
        results['imported'] = (results['imported'] as int) + 1;
      } catch (e) {
        results['failed'] = (results['failed'] as int) + 1;
        (results['errors'] as List<String>).add('Question ${i + 1}: $e');
      }
    }

    return results;
  }

  /// Validate question data before import
  bool _validateQuestionData(Map<String, dynamic> data) {
    final requiredFields = [
      'id',
      'question_text',
      'question_type',
      'subject',
      'topic',
      'grade_level',
      'answer_key'
    ];

    for (final field in requiredFields) {
      if (!data.containsKey(field) ||
          data[field] == null ||
          data[field].toString().isEmpty) {
        return false;
      }
    }

    // Validate question type
    try {
      final questionTypeIndex = data['question_type'];
      if (questionTypeIndex is int &&
          (questionTypeIndex < 0 ||
              questionTypeIndex >= QuestionType.values.length)) {
        return false;
      }
    } catch (e) {
      return false;
    }

    // Validate difficulty
    try {
      final difficultyIndex = data['difficulty'];
      if (difficultyIndex != null &&
          difficultyIndex is int &&
          (difficultyIndex < 0 ||
              difficultyIndex >= DifficultyTag.values.length)) {
        return false;
      }
    } catch (e) {
      return false;
    }

    return true;
  }

  /// Export questions to JSON format
  String exportQuestionsToJson({QuestionFilter? filter}) {
    List<Question> questionsToExport;

    if (filter != null) {
      questionsToExport = _questionBank.values
          .where((question) => _matchesFilter(question, filter))
          .toList();
    } else {
      questionsToExport = _questionBank.values.toList();
    }

    final exportData = {
      'metadata': {
        'exported_at': DateTime.now().toIso8601String(),
        'total_questions': questionsToExport.length,
      },
      'questions': questionsToExport.map((q) => q.toJson()).toList(),
    };

    return json.encode(exportData);
  }

  /// Remove duplicate questions based on content similarity
  /// Returns the number of duplicates removed
  Future<Map<String, dynamic>> removeDuplicates() async {
    await initialize();

    final Map<String, String> contentHashToId = {};
    final List<String> duplicateIds = [];
    final List<String> keptIds = [];

    for (final question in _questionBank.values) {
      // Create a content hash based on question text, subject, topic, and answer
      final contentHash = _generateContentHash(question);

      if (contentHashToId.containsKey(contentHash)) {
        // This is a duplicate
        duplicateIds.add(question.id);
      } else {
        // First occurrence, keep it
        contentHashToId[contentHash] = question.id;
        keptIds.add(question.id);
      }
    }

    // Remove duplicates
    for (final id in duplicateIds) {
      _removeQuestionFromIndexes(id);
      _questionBank.remove(id);
    }

    return {
      'duplicates_removed': duplicateIds.length,
      'questions_remaining': _questionBank.length,
      'duplicate_ids': duplicateIds,
    };
  }

  /// Generate a content hash for duplicate detection
  String _generateContentHash(Question question) {
    // Normalize the question text and answer for comparison
    final normalizedText = question.questionText.toLowerCase().trim();
    final normalizedAnswer = question.answerKey.toLowerCase().trim();
    final subject = question.subject.toLowerCase().trim();
    final topic = question.topic.toLowerCase().trim();

    return '$normalizedText|$subject|$topic|$normalizedAnswer';
  }

  /// Remove a question from all indexes
  void _removeQuestionFromIndexes(String questionId) {
    // Remove from grade index
    for (final list in _gradeQuestionIndex.values) {
      list.remove(questionId);
    }

    // Remove from topic index
    for (final list in _topicQuestionIndex.values) {
      list.remove(questionId);
    }

    // Remove from difficulty index
    for (final list in _difficultyQuestionIndex.values) {
      list.remove(questionId);
    }
  }

  /// Find potential duplicates without removing them
  Future<List<Map<String, dynamic>>> findDuplicates() async {
    await initialize();

    final Map<String, List<Question>> contentHashToQuestions = {};

    for (final question in _questionBank.values) {
      final contentHash = _generateContentHash(question);
      contentHashToQuestions.putIfAbsent(contentHash, () => []);
      contentHashToQuestions[contentHash]!.add(question);
    }

    final duplicateGroups = <Map<String, dynamic>>[];

    for (final entry in contentHashToQuestions.entries) {
      if (entry.value.length > 1) {
        duplicateGroups.add({
          'content_hash': entry.key,
          'count': entry.value.length,
          'questions': entry.value
              .map((q) => {
                    'id': q.id,
                    'question_text': q.questionText.length > 50
                        ? '${q.questionText.substring(0, 50)}...'
                        : q.questionText,
                    'subject': q.subject,
                    'topic': q.topic,
                  })
              .toList(),
        });
      }
    }

    return duplicateGroups;
  }

  /// Remove a specific question by ID
  void removeQuestion(String questionId) {
    _removeQuestionFromIndexes(questionId);
    _questionBank.remove(questionId);
  }

  /// Clear all questions from the bank
  void clearAllQuestions() {
    _questionBank.clear();
    _gradeQuestionIndex.clear();
    _topicQuestionIndex.clear();
    _difficultyQuestionIndex.clear();
  }

  /// Reset and reinitialize (useful after clearing duplicates)
  Future<void> reset() async {
    _isInitialized = false;
    clearAllQuestions();
  }
}
