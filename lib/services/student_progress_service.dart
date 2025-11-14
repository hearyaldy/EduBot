import '../models/student_progress.dart';
import '../models/question.dart';
import 'database_service.dart';
import 'dart:async';

class StudentProgressService {
  static final StudentProgressService _instance =
      StudentProgressService._internal();
  factory StudentProgressService() => _instance;
  StudentProgressService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Record a student's attempt at a question
  Future<StudentProgress> recordAttempt({
    required String studentId,
    required Question question,
    required String studentAnswer,
    required int responseTimeSeconds,
    double confidenceLevel = 3.0,
    List<String> hintsUsed = const [],
    Map<String, dynamic> additionalMetadata = const {},
  }) async {
    await _databaseService.initialize();

    // Check for existing attempts to set attempt number
    final existingAttempts = _databaseService
        .getStudentProgress(studentId)
        .where((p) => p.questionId == question.id)
        .length;

    final progress = StudentProgress.fromAttempt(
      studentId: studentId,
      question: question,
      studentAnswer: studentAnswer,
      responseTimeSeconds: responseTimeSeconds,
      confidenceLevel: confidenceLevel,
      hintsUsed: hintsUsed,
      additionalMetadata: {
        'attempt_number': existingAttempts + 1,
        ...additionalMetadata,
      },
    );

    await _databaseService.saveProgress(progress);

    // Trigger analytics update
    _updateStudentAnalytics(studentId);

    return progress;
  }

  /// Get student's performance on a specific question
  Future<List<StudentProgress>> getQuestionAttempts(
      String studentId, String questionId) async {
    await _databaseService.initialize();

    return _databaseService
        .getStudentProgress(studentId)
        .where((p) => p.questionId == questionId)
        .toList()
      ..sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt)); // Oldest first
  }

  /// Get student's recent activity
  Future<List<StudentProgress>> getRecentActivity(String studentId,
      {int limit = 20}) async {
    await _databaseService.initialize();

    final progress = _databaseService.getStudentProgress(studentId);
    progress
        .sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt)); // Latest first

    return progress.take(limit).toList();
  }

  /// Get student's performance by subject
  Future<Map<String, SubjectPerformance>> getSubjectPerformance(
      String studentId) async {
    await _databaseService.initialize();

    final progress = _databaseService.getStudentProgress(studentId);
    final subjectGroups = _groupBy(progress, (p) => p.subject);

    final result = <String, SubjectPerformance>{};

    for (final entry in subjectGroups.entries) {
      final subjectProgress = entry.value;
      final correctAttempts = subjectProgress.where((p) => p.isCorrect).length;
      final totalAttempts = subjectProgress.length;
      final accuracy =
          totalAttempts > 0 ? (correctAttempts / totalAttempts) * 100 : 0.0;

      // Get recent performance trend (last 10 attempts)
      final recentProgress = subjectProgress.take(10).toList();
      final recentCorrect = recentProgress.where((p) => p.isCorrect).length;
      final recentAccuracy = recentProgress.isNotEmpty
          ? (recentCorrect / recentProgress.length) * 100
          : 0.0;

      // Calculate average response time
      final avgResponseTime = subjectProgress.isNotEmpty
          ? subjectProgress
                  .map((p) => p.responseTimeSeconds)
                  .reduce((a, b) => a + b) /
              subjectProgress.length
          : 0.0;

      // Get topic breakdown
      final topicGroups = _groupBy(subjectProgress, (p) => p.topic);
      final topicPerformance = <String, double>{};

      for (final topicEntry in topicGroups.entries) {
        final topicProgress = topicEntry.value;
        final topicCorrect = topicProgress.where((p) => p.isCorrect).length;
        topicPerformance[topicEntry.key] = topicProgress.isNotEmpty
            ? (topicCorrect / topicProgress.length) * 100
            : 0.0;
      }

      result[entry.key] = SubjectPerformance(
        subject: entry.key,
        totalAttempts: totalAttempts,
        correctAttempts: correctAttempts,
        accuracy: accuracy,
        recentAccuracy: recentAccuracy,
        averageResponseTime: avgResponseTime,
        topicPerformance: topicPerformance,
        lastAttempt: subjectProgress.isNotEmpty
            ? subjectProgress.first.attemptedAt
            : DateTime.now(),
        performanceLevel: _getPerformanceLevel(accuracy),
      );
    }

    return result;
  }

  /// Get student's learning trajectory over time
  Future<List<LearningDataPoint>> getLearningTrajectory(String studentId,
      {int days = 30}) async {
    await _databaseService.initialize();

    final progress = _databaseService.getStudentProgress(studentId);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    // Filter progress to the specified time period
    final recentProgress = progress
        .where((p) => p.attemptedAt.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt)); // Oldest first

    // Group by day and calculate daily performance
    final dailyProgress = <DateTime, List<StudentProgress>>{};

    for (final p in recentProgress) {
      final day =
          DateTime(p.attemptedAt.year, p.attemptedAt.month, p.attemptedAt.day);
      dailyProgress.putIfAbsent(day, () => []).add(p);
    }

    final trajectory = <LearningDataPoint>[];

    for (final entry in dailyProgress.entries) {
      final dayProgress = entry.value;
      final correct = dayProgress.where((p) => p.isCorrect).length;
      final accuracy = (correct / dayProgress.length) * 100;
      final avgResponseTime = dayProgress
              .map((p) => p.responseTimeSeconds)
              .reduce((a, b) => a + b) /
          dayProgress.length;

      trajectory.add(LearningDataPoint(
        date: entry.key,
        accuracy: accuracy,
        attemptsCount: dayProgress.length,
        averageResponseTime: avgResponseTime,
        subjects: dayProgress.map((p) => p.subject).toSet().toList(),
        difficultiesAttempted:
            dayProgress.map((p) => p.difficulty).toSet().toList(),
      ));
    }

    return trajectory;
  }

  /// Get personalized recommendations for next questions
  Future<List<QuestionRecommendation>> getQuestionRecommendations(
      String studentId,
      {int limit = 10}) async {
    await _databaseService.initialize();

    final analytics =
        await _databaseService.calculateStudentAnalytics(studentId);
    final allQuestions = _databaseService.getAllQuestions();

    // Get questions the student hasn't attempted yet
    final attemptedQuestionIds = _databaseService
        .getStudentProgress(studentId)
        .map((p) => p.questionId)
        .toSet();

    final unattemptedQuestions = allQuestions
        .where((q) => !attemptedQuestionIds.contains(q.id))
        .toList();

    final recommendations = <QuestionRecommendation>[];

    // Recommend questions for weak topics (highest priority)
    for (final weakTopic in analytics.weakTopics.take(3)) {
      final topicQuestions = unattemptedQuestions
          .where((q) => q.topic == weakTopic)
          .where((q) =>
              q.difficulty == DifficultyTag.easy) // Start with easier questions
          .toList()
        ..shuffle(); // Randomize order

      for (final question in topicQuestions.take(3)) {
        recommendations.add(QuestionRecommendation(
          question: question,
          reason: 'Practice needed in $weakTopic',
          priority: RecommendationPriority.high,
          confidenceScore: 0.9,
        ));
      }
    }

    // Recommend questions for grade-appropriate difficulty progression
    final recommendedDifficulty = analytics.getRecommendedDifficulty();
    final difficultyQuestions = unattemptedQuestions
        .where((q) => q.difficulty == recommendedDifficulty)
        .where((q) => !analytics.weakTopics
            .contains(q.topic)) // Avoid weak topics already covered
        .toList()
      ..shuffle();

    for (final question in difficultyQuestions.take(4)) {
      recommendations.add(QuestionRecommendation(
        question: question,
        reason: 'Good difficulty match (${recommendedDifficulty.name})',
        priority: RecommendationPriority.medium,
        confidenceScore: 0.7,
      ));
    }

    // Recommend review questions from strong topics (confidence building)
    for (final strongTopic in analytics.strongTopics.take(2)) {
      final reviewQuestions = unattemptedQuestions
          .where((q) => q.topic == strongTopic)
          .where((q) => q.difficulty == DifficultyTag.medium)
          .toList()
        ..shuffle();

      for (final question in reviewQuestions.take(2)) {
        recommendations.add(QuestionRecommendation(
          question: question,
          reason: 'Confidence building in $strongTopic',
          priority: RecommendationPriority.low,
          confidenceScore: 0.6,
        ));
      }
    }

    // Sort by priority and confidence, then return limited results
    recommendations.sort((a, b) {
      final priorityComparison = a.priority.index.compareTo(b.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      return b.confidenceScore.compareTo(a.confidenceScore);
    });

    return recommendations.take(limit).toList();
  }

  /// Calculate mastery level for a specific topic
  Future<MasteryLevel> getTopicMastery(String studentId, String topic) async {
    await _databaseService.initialize();

    final progress = _databaseService
        .getStudentProgress(studentId)
        .where((p) => p.topic == topic)
        .toList();

    if (progress.isEmpty) {
      return MasteryLevel(
        topic: topic,
        level: MasteryState.notStarted,
        accuracy: 0.0,
        attemptsCount: 0,
        lastAttempt: null,
        suggestions: ['Start with basic questions in $topic'],
      );
    }

    final correct = progress.where((p) => p.isCorrect).length;
    final accuracy = (correct / progress.length) * 100;

    MasteryState level;
    List<String> suggestions;

    if (accuracy >= 90 && progress.length >= 5) {
      level = MasteryState.mastered;
      suggestions = [
        'Try advanced questions in $topic',
        'Explore related topics'
      ];
    } else if (accuracy >= 70 && progress.length >= 3) {
      level = MasteryState.developing;
      suggestions = [
        'Continue practicing $topic',
        'Try slightly harder questions'
      ];
    } else if (accuracy >= 50) {
      level = MasteryState.emerging;
      suggestions = [
        'Focus on basic concepts in $topic',
        'Review explanations carefully'
      ];
    } else {
      level = MasteryState.struggling;
      suggestions = [
        'Start with easier questions in $topic',
        'Ask for help with $topic concepts'
      ];
    }

    return MasteryLevel(
      topic: topic,
      level: level,
      accuracy: accuracy,
      attemptsCount: progress.length,
      lastAttempt: progress.isNotEmpty ? progress.first.attemptedAt : null,
      suggestions: suggestions,
    );
  }

  /// Update student analytics cache
  Future<void> _updateStudentAnalytics(String studentId) async {
    // This runs in the background to update cached analytics
    Timer(const Duration(seconds: 1), () async {
      try {
        await _databaseService.calculateStudentAnalytics(studentId);
      } catch (e) {
        print('Error updating analytics for student $studentId: $e');
      }
    });
  }

  /// Utility method to group items by a key
  Map<T, List<S>> _groupBy<S, T>(Iterable<S> values, T Function(S) key) {
    final map = <T, List<S>>{};
    for (final element in values) {
      final k = key(element);
      map.putIfAbsent(k, () => []).add(element);
    }
    return map;
  }

  /// Get performance level from accuracy percentage
  PerformanceLevel _getPerformanceLevel(double accuracy) {
    if (accuracy >= 90) return PerformanceLevel.excellent;
    if (accuracy >= 75) return PerformanceLevel.good;
    if (accuracy >= 60) return PerformanceLevel.average;
    return PerformanceLevel.needsImprovement;
  }

  /// Delete all progress for a student (GDPR compliance)
  Future<void> deleteStudentData(String studentId) async {
    await _databaseService.initialize();
    await _databaseService.deleteStudentProgress(studentId);

    // Also remove from analytics cache
    await _databaseService.analyticsBox.delete('student_$studentId');
  }

  /// Get students with recent activity (for teacher/parent dashboard)
  Future<List<String>> getActiveStudents({int days = 7}) async {
    await _databaseService.initialize();

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentProgress = _databaseService.progressBox.values
        .where((p) => p.attemptedAt.isAfter(cutoffDate))
        .toList();

    return recentProgress.map((p) => p.studentId).toSet().toList();
  }

  /// Get analytics summary for dashboard
  Future<Map<String, dynamic>> getAnalyticsSummary(String studentId) async {
    await _databaseService.initialize();
    final progress = _databaseService.getStudentProgress(studentId);

    if (progress.isEmpty) {
      return {
        'total_questions': 0,
        'correct_answers': 0,
        'accuracy': 0.0,
        'total_time': 0,
        'subject_breakdown': <String, dynamic>{},
        'difficulty_breakdown': <String, dynamic>{},
      };
    }

    final totalQuestions = progress.length;
    final correctAnswers = progress.where((p) => p.isCorrect).length;
    final accuracy = (correctAnswers / totalQuestions * 100);
    final totalTime =
        progress.fold<int>(0, (sum, p) => sum + p.responseTimeSeconds);

    return {
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'accuracy': accuracy,
      'total_time': totalTime,
    };
  }

  /// Get progress data within a date range for a specific student
  Future<List<StudentProgress>> getStudentProgressInDateRange(
      String studentId, DateTime startDate, DateTime endDate) async {
    await _databaseService.initialize();
    final studentProgress = _databaseService.getStudentProgress(studentId);

    return studentProgress.where((progress) {
      return progress.attemptedAt.isAfter(startDate) &&
          progress.attemptedAt.isBefore(endDate);
    }).toList();
  }

  /// Get progress data within a date range for all students (use carefully)
  @Deprecated("Use getStudentProgressInDateRange instead")
  Future<List<StudentProgress>> getProgressInDateRange(
      DateTime startDate, DateTime endDate) async {
    await _databaseService.initialize();
    final allProgress = _databaseService.getAllProgress();

    return allProgress.where((progress) {
      return progress.attemptedAt.isAfter(startDate) &&
          progress.attemptedAt.isBefore(endDate);
    }).toList();
  }

  /// Get recent progress data for a specific student for learning analysis
  Future<List<StudentProgress>> getRecentProgressByStudent(
      String studentId, int recentAttemptsWindow) async {
    await _databaseService.initialize();
    final studentProgress = _databaseService.getStudentProgress(studentId);

    studentProgress.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    return studentProgress.take(recentAttemptsWindow).toList();
  }

  /// Get recent progress data for learning analysis (for all students - deprecated)
  @Deprecated("Use getRecentProgressByStudent instead")
  Future<List<StudentProgress>> getRecentProgress(
      int recentAttemptsWindow) async {
    await _databaseService.initialize();
    final allProgress = _databaseService.getAllProgress();

    allProgress.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    return allProgress.take(recentAttemptsWindow).toList();
  }

  /// Get overall statistics for a specific student's performance tracking
  Future<Map<String, dynamic>> getOverallStatisticsByStudent(String studentId) async {
    await _databaseService.initialize();
    final studentProgress = _databaseService.getStudentProgress(studentId);

    if (studentProgress.isEmpty) {
      return {
        'total_attempts': 0,
        'overall_accuracy': 0.0,
        'average_response_time': 0.0,
        'active_subjects': <String>[],
        'unique_students': 1, // Just this one student
      };
    }

    final totalAttempts = studentProgress.length;
    final correctAttempts = studentProgress.where((p) => p.isCorrect).length;
    final overallAccuracy = (correctAttempts / totalAttempts * 100);
    final avgResponseTime =
        studentProgress.fold<int>(0, (sum, p) => sum + p.responseTimeSeconds) /
            totalAttempts;
    final activeSubjects = studentProgress.map((p) => p.subject).toSet().toList();

    return {
      'total_attempts': totalAttempts,
      'unique_students': 1,
      'overall_accuracy': overallAccuracy,
      'average_response_time': avgResponseTime,
      'active_subjects': activeSubjects,
    };
  }

  /// Get overall statistics for performance tracking (for all students - deprecated)
  @Deprecated("Use getOverallStatisticsByStudent instead")
  Future<Map<String, dynamic>> getOverallStatistics() async {
    await _databaseService.initialize();
    final allProgress = _databaseService.getAllProgress();

    if (allProgress.isEmpty) {
      return {
        'total_attempts': 0,
        'unique_students': 0,
        'overall_accuracy': 0.0,
        'average_response_time': 0.0,
        'active_subjects': <String>[],
      };
    }

    final totalAttempts = allProgress.length;
    final uniqueStudents = allProgress.map((p) => p.studentId).toSet().length;
    final correctAttempts = allProgress.where((p) => p.isCorrect).length;
    final overallAccuracy = (correctAttempts / totalAttempts * 100);
    final avgResponseTime =
        allProgress.fold<int>(0, (sum, p) => sum + p.responseTimeSeconds) /
            totalAttempts;
    final activeSubjects = allProgress.map((p) => p.subject).toSet().toList();

    return {
      'total_attempts': totalAttempts,
      'unique_students': uniqueStudents,
      'overall_accuracy': overallAccuracy,
      'average_response_time': avgResponseTime,
      'active_subjects': activeSubjects,
    };
  }

  /// Export student progress data
  Future<Map<String, dynamic>> exportStudentData(String studentId) async {
    await _databaseService.initialize();

    final progress = _databaseService.getStudentProgress(studentId);
    final analytics =
        await _databaseService.calculateStudentAnalytics(studentId);

    return {
      'student_id': studentId,
      'export_date': DateTime.now().toIso8601String(),
      'total_attempts': progress.length,
      'analytics': analytics.toJson(),
      'progress_history': progress.map((p) => p.toJson()).toList(),
    };
  }
}

// Supporting classes for the service

class SubjectPerformance {
  final String subject;
  final int totalAttempts;
  final int correctAttempts;
  final double accuracy;
  final double recentAccuracy;
  final double averageResponseTime;
  final Map<String, double> topicPerformance;
  final DateTime lastAttempt;
  final PerformanceLevel performanceLevel;

  const SubjectPerformance({
    required this.subject,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.accuracy,
    required this.recentAccuracy,
    required this.averageResponseTime,
    required this.topicPerformance,
    required this.lastAttempt,
    required this.performanceLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'total_attempts': totalAttempts,
      'correct_attempts': correctAttempts,
      'accuracy': accuracy,
      'recent_accuracy': recentAccuracy,
      'average_response_time': averageResponseTime,
      'topic_performance': topicPerformance,
      'last_attempt': lastAttempt.toIso8601String(),
      'performance_level': performanceLevel.name,
    };
  }
}

class LearningDataPoint {
  final DateTime date;
  final double accuracy;
  final int attemptsCount;
  final double averageResponseTime;
  final List<String> subjects;
  final List<DifficultyTag> difficultiesAttempted;

  const LearningDataPoint({
    required this.date,
    required this.accuracy,
    required this.attemptsCount,
    required this.averageResponseTime,
    required this.subjects,
    required this.difficultiesAttempted,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'accuracy': accuracy,
      'attempts_count': attemptsCount,
      'average_response_time': averageResponseTime,
      'subjects': subjects,
      'difficulties_attempted':
          difficultiesAttempted.map((d) => d.name).toList(),
    };
  }
}

class QuestionRecommendation {
  final Question question;
  final String reason;
  final RecommendationPriority priority;
  final double confidenceScore;

  const QuestionRecommendation({
    required this.question,
    required this.reason,
    required this.priority,
    required this.confidenceScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': question.id,
      'question_text': question.questionText,
      'subject': question.subject,
      'topic': question.topic,
      'difficulty': question.difficulty.name,
      'reason': reason,
      'priority': priority.name,
      'confidence_score': confidenceScore,
    };
  }
}

enum RecommendationPriority {
  high,
  medium,
  low,
}

class MasteryLevel {
  final String topic;
  final MasteryState level;
  final double accuracy;
  final int attemptsCount;
  final DateTime? lastAttempt;
  final List<String> suggestions;

  const MasteryLevel({
    required this.topic,
    required this.level,
    required this.accuracy,
    required this.attemptsCount,
    required this.lastAttempt,
    required this.suggestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'topic': topic,
      'level': level.name,
      'accuracy': accuracy,
      'attempts_count': attemptsCount,
      'last_attempt': lastAttempt?.toIso8601String(),
      'suggestions': suggestions,
    };
  }
}

enum MasteryState {
  notStarted,
  struggling,
  emerging,
  developing,
  mastered,
}
