import 'package:hive/hive.dart';
import 'question.dart';

part 'student_progress.g.dart';

@HiveType(typeId: 2)
class StudentProgress extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String questionId;

  @HiveField(3)
  final String subject;

  @HiveField(4)
  final String topic;

  @HiveField(5)
  final int gradeLevel;

  @HiveField(6)
  final DifficultyTag difficulty;

  @HiveField(7)
  final DateTime attemptedAt;

  @HiveField(8)
  final String studentAnswer;

  @HiveField(9)
  final String correctAnswer;

  @HiveField(10)
  final bool isCorrect;

  @HiveField(11)
  final int responseTimeSeconds;

  @HiveField(12)
  final int attemptNumber; // For tracking multiple attempts

  @HiveField(13)
  final double confidenceLevel; // Student's confidence (1-5 scale)

  @HiveField(14)
  final List<String> hintsUsed;

  @HiveField(15)
  final Map<String, dynamic> metadata;

  StudentProgress({
    required this.id,
    required this.studentId,
    required this.questionId,
    required this.subject,
    required this.topic,
    required this.gradeLevel,
    required this.difficulty,
    required this.attemptedAt,
    required this.studentAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.responseTimeSeconds,
    this.attemptNumber = 1,
    this.confidenceLevel = 3.0,
    this.hintsUsed = const [],
    this.metadata = const {},
  });

  /// Create progress entry from question attempt
  factory StudentProgress.fromAttempt({
    required String studentId,
    required Question question,
    required String studentAnswer,
    required int responseTimeSeconds,
    double confidenceLevel = 3.0,
    List<String> hintsUsed = const [],
    Map<String, dynamic> additionalMetadata = const {},
  }) {
    final now = DateTime.now();
    final isCorrect =
        _checkAnswer(studentAnswer, question.answerKey, question.questionType);

    return StudentProgress(
      id: '${studentId}_${question.id}_${now.millisecondsSinceEpoch}',
      studentId: studentId,
      questionId: question.id,
      subject: question.subject,
      topic: question.topic,
      gradeLevel: question.gradeLevel,
      difficulty: question.difficulty,
      attemptedAt: now,
      studentAnswer: studentAnswer,
      correctAnswer: question.answerKey,
      isCorrect: isCorrect,
      responseTimeSeconds: responseTimeSeconds,
      confidenceLevel: confidenceLevel,
      hintsUsed: hintsUsed,
      metadata: {
        'question_type': question.questionType.name,
        'cognitive_level': question.metadata.cognitiveLevel.name,
        'curriculum_standards': question.metadata.curriculumStandards,
        'tags': question.metadata.tags,
        ...additionalMetadata,
      },
    );
  }

  /// Check if student answer is correct
  static bool _checkAnswer(
      String studentAnswer, String correctAnswer, QuestionType questionType) {
    final normalizedStudent = studentAnswer.trim().toLowerCase();
    final normalizedCorrect = correctAnswer.trim().toLowerCase();

    switch (questionType) {
      case QuestionType.multipleChoice:
        return normalizedStudent == normalizedCorrect;

      case QuestionType.trueOrFalse:
        // Handle various true/false representations
        final trueValues = ['true', 't', 'yes', 'y', '1', 'correct', 'benar'];
        final falseValues = [
          'false',
          'f',
          'no',
          'n',
          '0',
          'incorrect',
          'salah'
        ];

        final studentIsTrue = trueValues.contains(normalizedStudent);
        final studentIsFalse = falseValues.contains(normalizedStudent);
        final correctIsTrue = trueValues.contains(normalizedCorrect);

        if (studentIsTrue && correctIsTrue) return true;
        if (studentIsFalse && !correctIsTrue) return true;
        return false;

      case QuestionType.fillInTheBlank:
      case QuestionType.shortAnswer:
        // Allow for multiple correct answers separated by semicolon
        final correctAnswers = correctAnswer
            .split(';')
            .map((a) => a.trim().toLowerCase())
            .toList();
        return correctAnswers.contains(normalizedStudent);

      case QuestionType.calculation:
        // Handle numerical answers with tolerance
        try {
          final studentNum = double.tryParse(normalizedStudent);
          final correctNum = double.tryParse(normalizedCorrect);
          if (studentNum != null && correctNum != null) {
            return (studentNum - correctNum).abs() <
                0.001; // Small tolerance for floating point
          }
          return normalizedStudent == normalizedCorrect;
        } catch (e) {
          return normalizedStudent == normalizedCorrect;
        }

      default:
        return normalizedStudent == normalizedCorrect;
    }
  }

  /// Calculate accuracy percentage for this attempt
  double get accuracyPercentage => isCorrect ? 100.0 : 0.0;

  /// Alias for attemptedAt to match expected API in analytics
  DateTime get attemptTime => attemptedAt;

  /// Duration representation of response time
  Duration get responseTime => Duration(seconds: responseTimeSeconds);

  /// Number of hints used during this attempt
  int get hintsUsedCount => hintsUsed.length;

  /// Get performance level based on response time and correctness
  PerformanceLevel get performanceLevel {
    if (!isCorrect) return PerformanceLevel.needsImprovement;

    // Base response time expectations on difficulty and grade level
    final expectedTimeSeconds = _getExpectedTimeSeconds();

    if (responseTimeSeconds <= expectedTimeSeconds * 0.7) {
      return PerformanceLevel.excellent;
    } else if (responseTimeSeconds <= expectedTimeSeconds * 1.2) {
      return PerformanceLevel.good;
    } else {
      return PerformanceLevel.average;
    }
  }

  /// Get expected response time based on question characteristics
  int _getExpectedTimeSeconds() {
    // Base time by grade level
    int baseTime = 30 + (gradeLevel * 10); // 40s for Grade 1, 90s for Grade 6

    // Adjust by difficulty
    switch (difficulty) {
      case DifficultyTag.veryEasy:
        baseTime = (baseTime * 0.6).round();
        break;
      case DifficultyTag.easy:
        baseTime = (baseTime * 0.8).round();
        break;
      case DifficultyTag.medium:
        baseTime = baseTime; // No change
        break;
      case DifficultyTag.hard:
        baseTime = (baseTime * 1.5).round();
        break;
      case DifficultyTag.veryHard:
        baseTime = (baseTime * 2.0).round();
        break;
    }

    return baseTime;
  }

  /// Convert to JSON for export/analysis
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'question_id': questionId,
      'subject': subject,
      'topic': topic,
      'grade_level': gradeLevel,
      'difficulty': difficulty.name,
      'attempted_at': attemptedAt.toIso8601String(),
      'student_answer': studentAnswer,
      'correct_answer': correctAnswer,
      'is_correct': isCorrect,
      'response_time_seconds': responseTimeSeconds,
      'attempt_number': attemptNumber,
      'confidence_level': confidenceLevel,
      'hints_used': hintsUsed,
      'performance_level': performanceLevel.name,
      'accuracy_percentage': accuracyPercentage,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    return StudentProgress(
      id: json['id'],
      studentId: json['student_id'],
      questionId: json['question_id'],
      subject: json['subject'],
      topic: json['topic'],
      gradeLevel: json['grade_level'],
      difficulty:
          DifficultyTag.values.firstWhere((d) => d.name == json['difficulty']),
      attemptedAt: DateTime.parse(json['attempted_at']),
      studentAnswer: json['student_answer'],
      correctAnswer: json['correct_answer'],
      isCorrect: json['is_correct'],
      responseTimeSeconds: json['response_time_seconds'],
      attemptNumber: json['attempt_number'] ?? 1,
      confidenceLevel: (json['confidence_level'] ?? 3.0).toDouble(),
      hintsUsed: List<String>.from(json['hints_used'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'StudentProgress(id: $id, student: $studentId, question: $questionId, correct: $isCorrect, time: ${responseTimeSeconds}s)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentProgress && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 3)
enum PerformanceLevel {
  @HiveField(0)
  excellent,

  @HiveField(1)
  good,

  @HiveField(2)
  average,

  @HiveField(3)
  needsImprovement,
}

/// Student performance analytics
class StudentAnalytics {
  final String studentId;
  final int totalAttempts;
  final int correctAttempts;
  final double overallAccuracy;
  final double averageResponseTime;
  final Map<String, double> subjectAccuracy;
  final Map<String, double> topicAccuracy;
  final Map<DifficultyTag, double> difficultyAccuracy;
  final Map<int, double> gradeAccuracy;
  final List<String> strongTopics;
  final List<String> weakTopics;
  final PerformanceLevel overallPerformanceLevel;
  final DateTime lastAttempt;
  final int streakDays;

  const StudentAnalytics({
    required this.studentId,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.overallAccuracy,
    required this.averageResponseTime,
    required this.subjectAccuracy,
    required this.topicAccuracy,
    required this.difficultyAccuracy,
    required this.gradeAccuracy,
    required this.strongTopics,
    required this.weakTopics,
    required this.overallPerformanceLevel,
    required this.lastAttempt,
    required this.streakDays,
  });

  /// Get recommended next topics based on performance
  List<String> getRecommendedTopics() {
    final recommendations = <String>[];

    // Prioritize weak topics for improvement
    recommendations.addAll(weakTopics.take(3));

    // Add strong topics for confidence building (1-2 max)
    if (strongTopics.isNotEmpty) {
      recommendations.add(strongTopics.first);
    }

    return recommendations;
  }

  /// Get recommended difficulty level for next questions
  DifficultyTag getRecommendedDifficulty() {
    if (overallAccuracy >= 90) {
      return DifficultyTag.hard;
    } else if (overallAccuracy >= 70) {
      return DifficultyTag.medium;
    } else {
      return DifficultyTag.easy;
    }
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'total_attempts': totalAttempts,
      'correct_attempts': correctAttempts,
      'overall_accuracy': overallAccuracy,
      'average_response_time': averageResponseTime,
      'subject_accuracy': subjectAccuracy,
      'topic_accuracy': topicAccuracy,
      'difficulty_accuracy':
          difficultyAccuracy.map((k, v) => MapEntry(k.name, v)),
      'grade_accuracy': gradeAccuracy.map((k, v) => MapEntry(k.toString(), v)),
      'strong_topics': strongTopics,
      'weak_topics': weakTopics,
      'overall_performance_level': overallPerformanceLevel.name,
      'last_attempt': lastAttempt.toIso8601String(),
      'streak_days': streakDays,
      'recommended_topics': getRecommendedTopics(),
      'recommended_difficulty': getRecommendedDifficulty().name,
    };
  }
}
