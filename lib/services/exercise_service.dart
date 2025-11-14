import '../models/question.dart';
import '../models/exercise.dart';
import '../models/lesson.dart';
import 'question_bank_service.dart';

class ExerciseService {
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();

  final QuestionBankService _questionBankService = QuestionBankService();

  /// Initialize the service
  Future<void> initialize() async {
    await _questionBankService.initialize();
  }

  /// Generate exercises for a specific grade and topic
  Future<List<Exercise>> generateExercises({
    required int gradeLevel,
    required String subject,
    required String topic,
    int count = 10,
    DifficultyTag? difficulty,
    List<QuestionType>? questionTypes,
  }) async {
    final filter = QuestionFilter(
      gradeLevels: [gradeLevel],
      subjects: [subject],
      topics: [topic],
      difficulties: difficulty != null ? [difficulty] : null,
      questionTypes: questionTypes,
    );

    final questions = await _questionBankService.getQuestions(filter);

    if (questions.isEmpty) {
      throw Exception(
          'No questions found for Grade $gradeLevel $subject - $topic');
    }

    // Shuffle and take the requested count
    questions.shuffle();
    final selectedQuestions = questions.take(count).toList();

    // Convert to exercises
    return selectedQuestions.asMap().entries.map((entry) {
      return entry.value.toExercise(questionNumber: entry.key + 1);
    }).toList();
  }

  /// Generate a balanced set of exercises with mixed difficulties
  Future<List<Exercise>> generateBalancedExercises({
    required int gradeLevel,
    required String subject,
    required String topic,
    int count = 10,
    Map<DifficultyTag, int>? difficultyDistribution,
  }) async {
    // Default distribution: 40% easy, 40% medium, 20% hard
    final distribution = difficultyDistribution ??
        {
          DifficultyTag.easy: 40,
          DifficultyTag.medium: 40,
          DifficultyTag.hard: 20,
        };

    final template = LessonTemplate(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Generated Exercises',
      subject: subject,
      topic: topic,
      gradeLevel: gradeLevel,
      difficulty: DifficultyLevel.intermediate,
      targetQuestionCount: count,
      questionFilter: QuestionFilter(
        gradeLevels: [gradeLevel],
        subjects: [subject],
        topics: [topic],
      ),
      difficultyDistribution: distribution,
    );

    final lesson = await _questionBankService.generateLesson(template);
    return lesson.exercises;
  }

  /// Generate exercises based on student performance (adaptive)
  Future<List<Exercise>> generateAdaptiveExercises({
    required int gradeLevel,
    required String subject,
    required String topic,
    required double studentAccuracy, // 0.0 to 1.0
    int count = 10,
  }) async {
    // Adjust difficulty based on performance
    Map<DifficultyTag, int> distribution;

    if (studentAccuracy >= 0.8) {
      // High performer - more challenging questions
      distribution = {
        DifficultyTag.medium: 30,
        DifficultyTag.hard: 50,
        DifficultyTag.veryHard: 20,
      };
    } else if (studentAccuracy >= 0.6) {
      // Average performer - balanced mix
      distribution = {
        DifficultyTag.easy: 20,
        DifficultyTag.medium: 50,
        DifficultyTag.hard: 30,
      };
    } else {
      // Struggling student - more basic questions
      distribution = {
        DifficultyTag.veryEasy: 30,
        DifficultyTag.easy: 50,
        DifficultyTag.medium: 20,
      };
    }

    return generateBalancedExercises(
      gradeLevel: gradeLevel,
      subject: subject,
      topic: topic,
      count: count,
      difficultyDistribution: distribution,
    );
  }

  /// Generate exercises for specific learning objectives
  Future<List<Exercise>> generateObjectiveBasedExercises({
    required int gradeLevel,
    required String subject,
    required String topic,
    required BloomsTaxonomy cognitiveLevel,
    int count = 10,
  }) async {
    final filter = QuestionFilter(
      gradeLevels: [gradeLevel],
      subjects: [subject],
      topics: [topic],
      cognitiveLevels: [cognitiveLevel],
    );

    final questions = await _questionBankService.getQuestions(filter);

    if (questions.isEmpty) {
      // Fallback to any questions for that topic
      return generateExercises(
        gradeLevel: gradeLevel,
        subject: subject,
        topic: topic,
        count: count,
      );
    }

    questions.shuffle();
    final selectedQuestions = questions.take(count).toList();

    return selectedQuestions.asMap().entries.map((entry) {
      return entry.value.toExercise(questionNumber: entry.key + 1);
    }).toList();
  }

  /// Get exercise recommendations based on curriculum standards
  Future<List<Exercise>> generateCurriculumBasedExercises({
    required int gradeLevel,
    required String subject,
    required List<String> curriculumStandards,
    int count = 10,
  }) async {
    final filter = QuestionFilter(
      gradeLevels: [gradeLevel],
      subjects: [subject],
    );

    final allQuestions = await _questionBankService.getQuestions(filter);

    // Filter by curriculum standards
    final matchingQuestions = allQuestions.where((question) {
      return curriculumStandards.any((standard) =>
          question.metadata.curriculumStandards.contains(standard));
    }).toList();

    if (matchingQuestions.isEmpty) {
      throw Exception(
          'No questions found for the specified curriculum standards');
    }

    matchingQuestions.shuffle();
    final selectedQuestions = matchingQuestions.take(count).toList();

    return selectedQuestions.asMap().entries.map((entry) {
      return entry.value.toExercise(questionNumber: entry.key + 1);
    }).toList();
  }

  /// Generate quick practice exercises (short, focused)
  Future<List<Exercise>> generateQuickPractice({
    required int gradeLevel,
    required String subject,
    required String topic,
    int count = 5,
  }) async {
    final filter = QuestionFilter(
      gradeLevels: [gradeLevel],
      subjects: [subject],
      topics: [topic],
      difficulties: [DifficultyTag.easy, DifficultyTag.medium],
    );

    final questions = await _questionBankService.getQuestions(filter);

    // Prefer questions with shorter estimated time
    questions.sort(
        (a, b) => a.metadata.estimatedTime.compareTo(b.metadata.estimatedTime));

    final selectedQuestions = questions.take(count).toList();
    selectedQuestions.shuffle();

    return selectedQuestions.asMap().entries.map((entry) {
      return entry.value.toExercise(questionNumber: entry.key + 1);
    }).toList();
  }

  /// Generate exercises for assessment/testing
  Future<List<Exercise>> generateAssessmentExercises({
    required int gradeLevel,
    required String subject,
    required String topic,
    int count = 20,
    bool includeAllDifficulties = true,
  }) async {
    final difficulties = includeAllDifficulties
        ? [
            DifficultyTag.easy,
            DifficultyTag.medium,
            DifficultyTag.hard,
            DifficultyTag.veryHard
          ]
        : [DifficultyTag.medium, DifficultyTag.hard];

    final filter = QuestionFilter(
      gradeLevels: [gradeLevel],
      subjects: [subject],
      topics: [topic],
      difficulties: difficulties,
    );

    final questions = await _questionBankService.getQuestions(filter);

    if (questions.length < count) {
      throw Exception(
          'Not enough questions available for assessment. Found ${questions.length}, need $count');
    }

    // Ensure balanced representation of difficulties
    final distribution = includeAllDifficulties
        ? {
            DifficultyTag.easy: 25,
            DifficultyTag.medium: 35,
            DifficultyTag.hard: 25,
            DifficultyTag.veryHard: 15,
          }
        : {
            DifficultyTag.medium: 60,
            DifficultyTag.hard: 40,
          };

    return generateBalancedExercises(
      gradeLevel: gradeLevel,
      subject: subject,
      topic: topic,
      count: count,
      difficultyDistribution: distribution,
    );
  }

  /// Get exercise analytics
  Future<Map<String, dynamic>> getExerciseAnalytics({
    required int gradeLevel,
    required String subject,
  }) async {
    final stats = await _questionBankService.getQuestionStats();
    final topics =
        await _questionBankService.getTopicsForGrade(gradeLevel, subject);

    return {
      'available_topics': topics,
      'total_questions': stats['by_grade'][gradeLevel] ?? 0,
      'question_stats': stats,
    };
  }

  /// Search exercises by keywords
  Future<List<Exercise>> searchExercises({
    required String query,
    int? gradeLevel,
    String? subject,
    int limit = 20,
  }) async {
    final filter = QuestionFilter(
      gradeLevels: gradeLevel != null ? [gradeLevel] : null,
      subjects: subject != null ? [subject] : null,
    );

    final questions = await _questionBankService.getQuestions(filter);

    // Simple text search in question text and topics
    final matchingQuestions = questions.where((question) {
      final queryLower = query.toLowerCase();
      return question.questionText.toLowerCase().contains(queryLower) ||
          question.topic.toLowerCase().contains(queryLower) ||
          question.subtopic.toLowerCase().contains(queryLower) ||
          question.metadata.tags
              .any((tag) => tag.toLowerCase().contains(queryLower));
    }).toList();

    matchingQuestions.shuffle();
    final selectedQuestions = matchingQuestions.take(limit).toList();

    return selectedQuestions.asMap().entries.map((entry) {
      return entry.value.toExercise(questionNumber: entry.key + 1);
    }).toList();
  }
}
