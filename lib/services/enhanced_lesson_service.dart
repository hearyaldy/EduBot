import '../models/lesson.dart';
import '../models/question.dart';
import 'question_bank_service.dart';
import 'exercise_service.dart';

/// Enhanced LessonService that can work with both hard-coded and dynamic lessons
class EnhancedLessonService {
  static final EnhancedLessonService _instance =
      EnhancedLessonService._internal();
  factory EnhancedLessonService() => _instance;
  EnhancedLessonService._internal();

  final QuestionBankService _questionBankService = QuestionBankService();
  final ExerciseService _exerciseService = ExerciseService();

  List<Lesson> _staticLessons = [];
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _questionBankService.initialize();
    await _exerciseService.initialize();

    // Load static lessons (keep existing ones for backward compatibility)
    _staticLessons = await _loadStaticLessons();

    _isInitialized = true;
  }

  /// Get all lessons (static + dynamically generated)
  Future<List<Lesson>> getAllLessons() async {
    await initialize();

    final allLessons = <Lesson>[];

    // Add static lessons
    allLessons.addAll(_staticLessons);

    // Add dynamically generated lessons
    allLessons.addAll(await _generateDynamicLessons());

    return allLessons;
  }

  /// Get lessons by grade level
  Future<List<Lesson>> getLessonsByGrade(int gradeLevel) async {
    final allLessons = await getAllLessons();
    return allLessons
        .where((lesson) => lesson.gradeLevel == gradeLevel)
        .toList();
  }

  /// Get lessons by subject
  Future<List<Lesson>> getLessonsBySubject(String subject) async {
    final allLessons = await getAllLessons();
    return allLessons
        .where(
            (lesson) => lesson.subject.toLowerCase() == subject.toLowerCase())
        .toList();
  }

  /// Generate lessons dynamically based on available questions
  Future<List<Lesson>> _generateDynamicLessons() async {
    final dynamicLessons = <Lesson>[];

    // Generate lessons for each grade level and subject combination
    final gradeLevels = [1, 2, 3, 4, 5, 6];
    final subjects = ['Mathematics', 'Science', 'English'];

    for (final grade in gradeLevels) {
      for (final subject in subjects) {
        final topics =
            await _questionBankService.getTopicsForGrade(grade, subject);

        for (final topic in topics) {
          // Generate beginner lesson
          final beginnerLesson = await _generateTopicLesson(
            gradeLevel: grade,
            subject: subject,
            topic: topic,
            difficulty: DifficultyLevel.beginner,
          );
          if (beginnerLesson != null) dynamicLessons.add(beginnerLesson);

          // Generate intermediate lesson
          final intermediateLesson = await _generateTopicLesson(
            gradeLevel: grade,
            subject: subject,
            topic: topic,
            difficulty: DifficultyLevel.intermediate,
          );
          if (intermediateLesson != null)
            dynamicLessons.add(intermediateLesson);

          // Generate advanced lesson
          final advancedLesson = await _generateTopicLesson(
            gradeLevel: grade,
            subject: subject,
            topic: topic,
            difficulty: DifficultyLevel.advanced,
          );
          if (advancedLesson != null) dynamicLessons.add(advancedLesson);
        }
      }
    }

    return dynamicLessons;
  }

  /// Generate a lesson for a specific topic and difficulty
  Future<Lesson?> _generateTopicLesson({
    required int gradeLevel,
    required String subject,
    required String topic,
    required DifficultyLevel difficulty,
  }) async {
    try {
      // Map difficulty level to difficulty tags
      final difficultyTags = _getDifficultyTagsForLevel(difficulty);

      final filter = QuestionFilter(
        gradeLevels: [gradeLevel],
        subjects: [subject],
        topics: [topic],
        difficulties: difficultyTags,
      );

      final questions = await _questionBankService.getQuestions(filter);

      if (questions.length < 5) {
        // Not enough questions to create a lesson
        return null;
      }

      // Create lesson template
      final template = LessonTemplate(
        id: 'dynamic_${subject.toLowerCase()}_${topic.toLowerCase()}_grade${gradeLevel}_${difficulty.name}',
        title: '$subject: $topic (${_getDifficultyLabel(difficulty)})',
        subject: subject,
        topic: topic,
        gradeLevel: gradeLevel,
        difficulty: difficulty,
        targetQuestionCount: 10,
        estimatedDuration: Duration(minutes: _getEstimatedDuration(difficulty)),
        questionFilter: filter,
        difficultyDistribution: _getDifficultyDistribution(difficulty),
      );

      return await _questionBankService.generateLesson(template);
    } catch (e) {
      // Failed to generate lesson, return null
      return null;
    }
  }

  /// Map DifficultyLevel to DifficultyTags
  List<DifficultyTag> _getDifficultyTagsForLevel(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return [DifficultyTag.veryEasy, DifficultyTag.easy];
      case DifficultyLevel.intermediate:
        return [DifficultyTag.easy, DifficultyTag.medium];
      case DifficultyLevel.advanced:
        return [
          DifficultyTag.medium,
          DifficultyTag.hard,
          DifficultyTag.veryHard
        ];
    }
  }

  /// Get difficulty distribution based on level
  Map<DifficultyTag, int> _getDifficultyDistribution(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return {
          DifficultyTag.veryEasy: 60,
          DifficultyTag.easy: 40,
        };
      case DifficultyLevel.intermediate:
        return {
          DifficultyTag.easy: 40,
          DifficultyTag.medium: 60,
        };
      case DifficultyLevel.advanced:
        return {
          DifficultyTag.medium: 30,
          DifficultyTag.hard: 50,
          DifficultyTag.veryHard: 20,
        };
    }
  }

  /// Get estimated duration based on difficulty
  int _getEstimatedDuration(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 20;
      case DifficultyLevel.intermediate:
        return 30;
      case DifficultyLevel.advanced:
        return 45;
    }
  }

  /// Get difficulty label
  String _getDifficultyLabel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Beginner Level';
      case DifficultyLevel.intermediate:
        return 'Intermediate Level';
      case DifficultyLevel.advanced:
        return 'Advanced Level';
    }
  }

  /// Generate custom lesson based on user preferences
  Future<Lesson> generateCustomLesson({
    required int gradeLevel,
    required String subject,
    required List<String> topics,
    required DifficultyLevel difficulty,
    int questionCount = 15,
    String? title,
  }) async {
    await initialize();

    final customTitle = title ?? '$subject Practice (Grade $gradeLevel)';

    final template = LessonTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: customTitle,
      subject: subject,
      topic: topics.join(', '),
      gradeLevel: gradeLevel,
      difficulty: difficulty,
      targetQuestionCount: questionCount,
      estimatedDuration: Duration(minutes: (questionCount * 2.5).round()),
      questionFilter: QuestionFilter(
        gradeLevels: [gradeLevel],
        subjects: [subject],
        topics: topics,
        difficulties: _getDifficultyTagsForLevel(difficulty),
      ),
      difficultyDistribution: _getDifficultyDistribution(difficulty),
    );

    return await _questionBankService.generateLesson(template);
  }

  /// Load static lessons (existing hardcoded lessons)
  Future<List<Lesson>> _loadStaticLessons() async {
    // This would load your existing hardcoded lessons
    // For backward compatibility, you can keep some key lessons as static
    return [
      // Add your critical static lessons here
      // These are lessons you want to ensure always exist exactly as designed
    ];
  }

  /// Generate practice session based on student performance
  Future<Lesson> generateAdaptivePractice({
    required int gradeLevel,
    required String subject,
    required Map<String, double>
        topicPerformance, // topic -> accuracy (0.0-1.0)
    int questionCount = 10,
  }) async {
    await initialize();

    // Focus on topics where student struggles
    final weakTopics = topicPerformance.entries
        .where((entry) => entry.value < 0.7)
        .map((entry) => entry.key)
        .toList();

    if (weakTopics.isEmpty) {
      // Student doing well, provide mixed practice
      final allTopics =
          await _questionBankService.getTopicsForGrade(gradeLevel, subject);
      return generateCustomLesson(
        gradeLevel: gradeLevel,
        subject: subject,
        topics: allTopics.take(3).toList(),
        difficulty: DifficultyLevel.intermediate,
        questionCount: questionCount,
        title: '$subject Mixed Practice (Grade $gradeLevel)',
      );
    }

    return generateCustomLesson(
      gradeLevel: gradeLevel,
      subject: subject,
      topics: weakTopics.take(2).toList(),
      difficulty: DifficultyLevel.beginner,
      questionCount: questionCount,
      title: '$subject Targeted Practice (Grade $gradeLevel)',
    );
  }

  /// Get lesson statistics and insights
  Future<Map<String, dynamic>> getLessonInsights() async {
    await initialize();

    final stats = await _questionBankService.getQuestionStats();
    final allLessons = await getAllLessons();

    final lessonsByGrade = <int, int>{};
    final lessonsBySubject = <String, int>{};
    final lessonsByDifficulty = <String, int>{};

    for (final lesson in allLessons) {
      lessonsByGrade[lesson.gradeLevel] =
          (lessonsByGrade[lesson.gradeLevel] ?? 0) + 1;
      lessonsBySubject[lesson.subject] =
          (lessonsBySubject[lesson.subject] ?? 0) + 1;
      lessonsByDifficulty[lesson.difficultyLabel] =
          (lessonsByDifficulty[lesson.difficultyLabel] ?? 0) + 1;
    }

    return {
      'total_lessons': allLessons.length,
      'static_lessons': _staticLessons.length,
      'dynamic_lessons': allLessons.length - _staticLessons.length,
      'lessons_by_grade': lessonsByGrade,
      'lessons_by_subject': lessonsBySubject,
      'lessons_by_difficulty': lessonsByDifficulty,
      'question_bank_stats': stats,
    };
  }

  /// Legacy method for backward compatibility
  Future<Lesson?> getLessonById(String id) async {
    final allLessons = await getAllLessons();
    try {
      return allLessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }
}
