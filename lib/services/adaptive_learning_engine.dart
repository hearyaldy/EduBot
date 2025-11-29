import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/student_progress.dart';
import '../services/student_progress_service.dart';
import '../services/database_service.dart';
import 'dart:math';

/// Advanced adaptive learning engine that personalizes the educational experience
/// based on individual student performance, learning patterns, and preferences.
class AdaptiveLearningEngine {
  final StudentProgressService _progressService = StudentProgressService();
  final DatabaseService _databaseService = DatabaseService();

  // Learning algorithm parameters
  static const int _recentAttemptsWindow = 20;

  /// Generates personalized question recommendations based on student's learning profile
  Future<List<Question>> getPersonalizedRecommendations({
    required String studentId,
    required String subject,
    String? topic,
    int count = 10,
    bool includeReview = true,
    bool adaptDifficulty = true,
  }) async {
    debugPrint(
        '🎯 AdaptiveLearning: Getting recommendations for student: $studentId');
    debugPrint('📚 Subject: $subject, Topic: $topic, Count: $count');
    debugPrint(
        '⚙️ includeReview: $includeReview, adaptDifficulty: $adaptDifficulty');

    try {
      debugPrint('📊 AdaptiveLearning: Building learning profile...');
      final learningProfile = await _buildLearningProfileForStudent(studentId);
      debugPrint('✅ AdaptiveLearning: Learning profile built successfully');

      debugPrint('🔍 AdaptiveLearning: Getting available questions pool...');
      final questionPool =
          _getAvailableQuestions(subject: subject, topic: topic);
      debugPrint(
          '✅ AdaptiveLearning: Found ${questionPool.length} questions in pool');

      final recommendations = <Question>[];

      // 1. Add review questions for struggling topics
      if (includeReview) {
        debugPrint(
            '📝 AdaptiveLearning: Getting review questions (${count ~/ 3} requested)...');
        final reviewQuestions =
            await _getReviewQuestions(learningProfile, count ~/ 3);
        recommendations.addAll(reviewQuestions);
        debugPrint(
            '✅ AdaptiveLearning: Added ${reviewQuestions.length} review questions');
      }

      // 2. Add questions at appropriate difficulty level
      if (adaptDifficulty) {
        final adaptiveCount = count - recommendations.length;
        debugPrint(
            '🎚️ AdaptiveLearning: Getting adaptive difficulty questions ($adaptiveCount)...');
        final adaptiveQuestions = await _getAdaptiveDifficultyQuestions(
          learningProfile,
          questionPool,
          adaptiveCount,
          subject: subject,
          topic: topic,
        );
        recommendations.addAll(adaptiveQuestions);
        debugPrint(
            '✅ AdaptiveLearning: Added ${adaptiveQuestions.length} adaptive questions');
      }

      // 3. Fill remaining slots with diverse questions
      final remainingCount = count - recommendations.length;
      if (remainingCount > 0) {
        debugPrint(
            '🎲 AdaptiveLearning: Getting diverse questions ($remainingCount)...');
        final diverseQuestions = await _getDiverseQuestions(
          learningProfile,
          questionPool,
          remainingCount,
          excludeQuestions: recommendations,
        );
        recommendations.addAll(diverseQuestions);
        debugPrint(
            '✅ AdaptiveLearning: Added ${diverseQuestions.length} diverse questions');
      }

      // 4. Apply learning science principles (spacing, interleaving)
      debugPrint('🧠 AdaptiveLearning: Applying learning principles...');
      final finalRecommendations =
          _applyLearningPrinciples(recommendations, learningProfile);
      debugPrint(
          '🎉 AdaptiveLearning: Returning ${finalRecommendations.length} total recommendations');
      return finalRecommendations;
    } catch (e, stackTrace) {
      debugPrint(
          '❌ AdaptiveLearning ERROR in getPersonalizedRecommendations: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // Fallback to basic recommendations
      debugPrint('⚠️ AdaptiveLearning: Using fallback recommendations');
      return _getFallbackRecommendations(
          studentId: studentId, subject: subject, topic: topic, count: count);
    }
  }

  /// Internal method to build comprehensive learning profile for the specific student
  Future<LearningProfile> _buildLearningProfileForStudent(
      String studentId) async {
    debugPrint('👤 AdaptiveLearning: Building profile for student: $studentId');

    try {
      debugPrint(
          '📥 AdaptiveLearning: Fetching recent progress (last $_recentAttemptsWindow attempts)...');
      final recentProgress = await _progressService.getRecentProgressByStudent(
          studentId, _recentAttemptsWindow);
      debugPrint(
          '✅ AdaptiveLearning: Found ${recentProgress.length} progress entries');

      if (recentProgress.isEmpty) {
        debugPrint('⚠️ AdaptiveLearning: No progress data found for student');
      }

      // Analyze performance patterns
      debugPrint('📊 AdaptiveLearning: Analyzing subject performance...');
      final subjectPerformance = _analyzeSubjectPerformance(recentProgress);
      debugPrint(
          '✅ AdaptiveLearning: Analyzed ${subjectPerformance.length} subjects');

      debugPrint('🎚️ AdaptiveLearning: Analyzing difficulty preference...');
      final difficultyPreference = _analyzeDifficultyPreference(recentProgress);
      debugPrint(
          '✅ AdaptiveLearning: Preferred difficulty: ${difficultyPreference.preferredLevel.name}');

      debugPrint('📈 AdaptiveLearning: Calculating learning velocity...');
      final learningVelocity = _calculateLearningVelocity(recentProgress);
      debugPrint(
          '✅ AdaptiveLearning: Improvement rate: ${learningVelocity.improvementRate.toStringAsFixed(3)}');

      debugPrint('💪 AdaptiveLearning: Identifying conceptual strengths...');
      final conceptualStrengths = _identifyConceptualStrengths(recentProgress);
      debugPrint(
          '✅ AdaptiveLearning: Found ${conceptualStrengths.length} strength areas');

      debugPrint('🎓 AdaptiveLearning: Inferring learning style...');
      final learningStyle = _inferLearningStyle(recentProgress);
      debugPrint(
          '✅ AdaptiveLearning: Learning style: ${learningStyle.primaryStyle}');

      // Identify knowledge gaps
      debugPrint('🔍 AdaptiveLearning: Identifying knowledge gaps...');
      final knowledgeGaps = _identifyKnowledgeGaps(recentProgress);
      debugPrint(
          '✅ AdaptiveLearning: Found ${knowledgeGaps.length} knowledge gaps');

      // Calculate confidence levels
      debugPrint('💯 AdaptiveLearning: Calculating confidence levels...');
      final confidenceLevels = _calculateConfidenceLevels(recentProgress);
      debugPrint(
          '✅ AdaptiveLearning: Overall confidence: ${(confidenceLevels["overall"] ?? 0) * 100}%');

      debugPrint('🎯 AdaptiveLearning: Calculating mastery levels...');
      final masteryLevels = _calculateMasteryLevels(recentProgress);

      debugPrint('🎮 AdaptiveLearning: Analyzing question type preferences...');
      final preferredQuestionTypes =
          _analyzeQuestionTypePreferences(recentProgress);

      debugPrint('⏱️ AdaptiveLearning: Calculating optimal session length...');
      final optimalSessionLength =
          _calculateOptimalSessionLength(recentProgress);

      debugPrint('🕐 AdaptiveLearning: Identifying best study times...');
      final bestStudyTimes = _identifyOptimalStudyTimes(recentProgress);

      debugPrint('❗ AdaptiveLearning: Analyzing error patterns...');
      final errorPatterns = _analyzeErrorPatterns(recentProgress);

      debugPrint('✅ AdaptiveLearning: Learning profile built successfully');

      return LearningProfile(
        subjectPerformance: subjectPerformance,
        difficultyPreference: difficultyPreference,
        learningVelocity: learningVelocity,
        conceptualStrengths: conceptualStrengths,
        learningStyle: learningStyle,
        knowledgeGaps: knowledgeGaps,
        confidenceLevels: confidenceLevels,
        masteryLevels: masteryLevels,
        preferredQuestionTypes: preferredQuestionTypes,
        optimalSessionLength: optimalSessionLength,
        bestStudyTimes: bestStudyTimes,
        errorPatterns: errorPatterns,
      );
    } catch (e, stackTrace) {
      debugPrint(
          '❌ AdaptiveLearning ERROR in _buildLearningProfileForStudent: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Public method to build comprehensive learning profile for the specific student
  Future<LearningProfile> buildLearningProfileForStudent(
      String studentId) async {
    debugPrint(
        '🔄 AdaptiveLearning: Public buildLearningProfileForStudent called for: $studentId');
    try {
      final profile = await _buildLearningProfileForStudent(studentId);
      debugPrint('✅ AdaptiveLearning: Profile successfully returned');
      return profile;
    } catch (e, stackTrace) {
      debugPrint(
          '❌ AdaptiveLearning ERROR in buildLearningProfileForStudent: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Identifies topics that need review based on performance patterns
  Future<List<Question>> _getReviewQuestions(
      LearningProfile profile, int count) async {
    final reviewTopics = profile.knowledgeGaps
        .where((gap) => gap.severity > 0.6)
        .take(3)
        .toList();

    final reviewQuestions = <Question>[];

    for (final gap in reviewTopics) {
      final questions = _databaseService.getQuestionsByTopic(
        gap.topic,
        subject: gap.subject,
      );

      // Add questions that target this specific gap
      final gapQuestions = questions
          .where((q) => _questionTargetsGap(q, gap))
          .take((count / reviewTopics.length).ceil())
          .toList();

      reviewQuestions.addAll(gapQuestions);
    }

    return reviewQuestions;
  }

  /// Gets questions adapted to student's current difficulty level
  Future<List<Question>> _getAdaptiveDifficultyQuestions(
    LearningProfile profile,
    List<Question> questionPool,
    int count, {
    String? subject,
    String? topic,
  }) async {
    final currentPerformance = _getCurrentPerformanceLevel(profile);
    final targetDifficulty =
        _calculateTargetDifficulty(currentPerformance, profile);

    // Get questions around target difficulty
    final candidateQuestions = questionPool.where((q) {
      final difficultyMatch =
          _isDifficultyAppropriate(q.difficulty, targetDifficulty);
      final subjectMatch = subject == null || q.subject == subject;
      final topicMatch = topic == null || q.topic == topic;

      return difficultyMatch && subjectMatch && topicMatch;
    }).toList();

    // Sort by relevance and learning value
    candidateQuestions.sort((a, b) => _calculateLearningValue(a, profile)
        .compareTo(_calculateLearningValue(b, profile)));

    return candidateQuestions.reversed.take(count).toList();
  }

  /// Provides diverse questions to maintain engagement and broad learning
  Future<List<Question>> _getDiverseQuestions(
    LearningProfile profile,
    List<Question> questionPool,
    int count, {
    List<Question> excludeQuestions = const [],
  }) async {
    final excludeIds = excludeQuestions.map((q) => q.id).toSet();
    final availableQuestions =
        questionPool.where((q) => !excludeIds.contains(q.id)).toList();

    // Ensure diversity across question types, topics, and difficulties
    final diverseQuestions = <Question>[];
    final usedTypes = <QuestionType>{};
    final usedTopics = <String>{};

    for (final question in availableQuestions) {
      if (diverseQuestions.length >= count) break;

      // Check for diversity
      final typeUnique = !usedTypes.contains(question.questionType);
      final topicUnique = !usedTopics.contains(question.topic);

      if (typeUnique || topicUnique || diverseQuestions.length < count ~/ 2) {
        diverseQuestions.add(question);
        usedTypes.add(question.questionType);
        usedTopics.add(question.topic);
      }
    }

    // Fill remaining slots randomly from appropriate difficulty
    while (diverseQuestions.length < count &&
        diverseQuestions.length < availableQuestions.length) {
      final remaining = availableQuestions
          .where((q) => !diverseQuestions.contains(q))
          .toList();
      if (remaining.isEmpty) break;

      diverseQuestions.add(remaining[Random().nextInt(remaining.length)]);
    }

    return diverseQuestions;
  }

  /// Applies learning science principles to optimize question sequence
  List<Question> _applyLearningPrinciples(
      List<Question> questions, LearningProfile profile) {
    final optimized = List<Question>.from(questions);

    // 1. Spaced repetition - space out similar topics
    _applySpacedRepetition(optimized);

    // 2. Interleaving - mix different topics/types
    _applyInterleaving(optimized);

    // 3. Desirable difficulty - optimal challenge level
    _applyDesirableDifficulty(optimized, profile);

    // 4. Progressive disclosure - gradual complexity increase
    _applyProgressiveDisclosure(optimized);

    return optimized;
  }

  void _applySpacedRepetition(List<Question> questions) {
    // Group questions by topic
    final topicGroups = <String, List<Question>>{};
    for (final question in questions) {
      topicGroups.putIfAbsent(question.topic, () => []).add(question);
    }

    // Redistribute questions to space out same topics
    final spaced = <Question>[];
    final indices = <String, int>{};

    for (int i = 0; i < questions.length; i++) {
      String? bestTopic;
      int maxGap = 0;

      for (final topic in topicGroups.keys) {
        final lastIndex = indices[topic] ?? -1;
        final gap = i - lastIndex;

        if (topicGroups[topic]!.isNotEmpty && gap > maxGap) {
          maxGap = gap;
          bestTopic = topic;
        }
      }

      if (bestTopic != null) {
        final question = topicGroups[bestTopic]!.removeAt(0);
        spaced.add(question);
        indices[bestTopic] = i;
      }
    }

    questions.clear();
    questions.addAll(spaced);
  }

  void _applyInterleaving(List<Question> questions) {
    // Shuffle while maintaining some spacing between similar content
    final interleaved = <Question>[];
    final remaining = List<Question>.from(questions);

    while (remaining.isNotEmpty) {
      // Try to pick a question different from the last few
      final lastTopics = interleaved.take(3).map((q) => q.topic).toSet();

      Question? nextQuestion = remaining.firstWhere(
        (q) => !lastTopics.contains(q.topic),
        orElse: () => remaining.first,
      );

      interleaved.add(nextQuestion);
      remaining.remove(nextQuestion);
    }

    questions.clear();
    questions.addAll(interleaved);
  }

  void _applyDesirableDifficulty(
      List<Question> questions, LearningProfile profile) {
    // Sort by optimal challenge level for this learner
    questions.sort((a, b) {
      final challengeA = _calculateOptimalChallenge(a, profile);
      final challengeB = _calculateOptimalChallenge(b, profile);
      return challengeA.compareTo(challengeB);
    });
  }

  void _applyProgressiveDisclosure(List<Question> questions) {
    // Gradually increase complexity throughout the session
    questions.sort((a, b) {
      final complexityA = _calculateQuestionComplexity(a);
      final complexityB = _calculateQuestionComplexity(b);
      return complexityA.compareTo(complexityB);
    });
  }

  /// Calculates learning value of a question for specific student
  double _calculateLearningValue(Question question, LearningProfile profile) {
    double value = 0.0;

    // Higher value for topics with knowledge gaps
    final gapRelevance = profile.knowledgeGaps
        .where((gap) => gap.topic == question.topic)
        .fold(0.0, (sum, gap) => sum + gap.severity);
    value += gapRelevance * 2.0;

    // Optimal difficulty bonus
    final difficultyOptimality =
        _calculateDifficultyOptimality(question.difficulty, profile);
    value += difficultyOptimality;

    // Question type preference
    final typePreference =
        profile.preferredQuestionTypes[question.questionType] ?? 0.5;
    value += typePreference * 0.5;

    // Novelty bonus (haven't seen this question recently)
    final noveltyBonus = _calculateNoveltyBonus(question);
    value += noveltyBonus;

    return value;
  }

  /// Analyzes student's performance patterns by subject
  Map<String, SubjectPerformance> _analyzeSubjectPerformance(
      List<StudentProgress> progress) {
    final subjectStats = <String, List<StudentProgress>>{};

    // Group progress by subject using real data from progress entries
    for (final p in progress) {
      subjectStats.putIfAbsent(p.subject, () => []).add(p);
    }

    final performance = <String, SubjectPerformance>{};

    for (final entry in subjectStats.entries) {
      final attempts = entry.value;
      if (attempts.isEmpty) continue;

      final accuracy =
          attempts.map((a) => a.isCorrect ? 1.0 : 0.0).reduce((a, b) => a + b) /
              attempts.length;
      final avgTime = attempts
              .map((a) => a.responseTime.inSeconds)
              .reduce((a, b) => a + b) /
          attempts.length;
      final confidence =
          attempts.map((a) => a.confidenceLevel).reduce((a, b) => a + b) /
              attempts.length;

      performance[entry.key] = SubjectPerformance(
        accuracy: accuracy,
        averageTime: Duration(seconds: avgTime.round()),
        confidence: confidence,
        totalAttempts: attempts.length,
        trend: _calculateTrend(attempts),
      );
    }

    return performance;
  }

  /// Analyzes preferred difficulty level
  DifficultyPreference _analyzeDifficultyPreference(
      List<StudentProgress> progress) {
    final difficultyStats = <DifficultyTag, List<double>>{};

    // Use real difficulty data from progress entries
    for (final p in progress) {
      difficultyStats
          .putIfAbsent(p.difficulty, () => [])
          .add(p.isCorrect ? 1.0 : 0.0);
    }

    if (difficultyStats.isEmpty) {
      return const DifficultyPreference(
        preferredLevel: DifficultyTag.medium,
        comfortRange: [
          DifficultyTag.easy,
          DifficultyTag.medium,
          DifficultyTag.hard
        ],
        confidenceByDifficulty: {},
      );
    }

    DifficultyTag? preferredLevel;
    double maxScore = 0.0;

    for (final entry in difficultyStats.entries) {
      if (entry.value.isEmpty) continue;
      final avgScore = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avgScore > maxScore) {
        maxScore = avgScore;
        preferredLevel = entry.key;
      }
    }

    return DifficultyPreference(
      preferredLevel: preferredLevel ?? DifficultyTag.medium,
      comfortRange: [
        DifficultyTag.easy,
        DifficultyTag.medium,
        DifficultyTag.hard
      ],
      confidenceByDifficulty: difficultyStats.map((k, v) {
        if (v.isEmpty) return MapEntry(k, 0.0);
        return MapEntry(k, v.reduce((a, b) => a + b) / v.length);
      }),
    );
  }

  /// Calculates learning velocity (how quickly student improves)
  LearningVelocity _calculateLearningVelocity(List<StudentProgress> progress) {
    if (progress.length < 5) {
      return const LearningVelocity(
        improvementRate: 0.0,
        accelerationRate: 0.0,
        plateauIndicator: 0.0,
      );
    }

    // Calculate improvement rate over time
    final accuracies = <double>[];
    final times = <int>[];

    for (int i = 0; i < progress.length; i++) {
      final windowStart = max(0, i - 4);
      final window = progress.sublist(windowStart, i + 1);
      final accuracy =
          window.map((p) => p.isCorrect ? 1.0 : 0.0).reduce((a, b) => a + b) /
              window.length;
      accuracies.add(accuracy);
      times.add(i);
    }

    // Calculate linear regression to find improvement rate
    final improvementRate = _calculateLinearRegression(
        times.map((t) => t.toDouble()).toList(), accuracies);

    // Calculate acceleration (change in improvement rate)
    final accelerationRate = improvementRate > 0 ? improvementRate * 1.1 : 0.0;

    // Detect plateau (low variance in recent performance)
    final recentAccuracies = accuracies.take(10).toList();
    final variance = _calculateVariance(recentAccuracies);
    final plateauIndicator = variance < 0.05 ? 1.0 : 0.0;

    return LearningVelocity(
      improvementRate: improvementRate,
      accelerationRate: accelerationRate,
      plateauIndicator: plateauIndicator,
    );
  }

  /// Identifies conceptual strengths and learning patterns
  List<ConceptualStrength> _identifyConceptualStrengths(
      List<StudentProgress> progress) {
    final strengths = <ConceptualStrength>[];

    // Group progress by topic for real conceptual analysis
    final topicGroups = <String, List<StudentProgress>>{};
    for (final p in progress) {
      topicGroups.putIfAbsent(p.topic, () => []).add(p);
    }

    for (final entry in topicGroups.entries) {
      final conceptProgress = entry.value;
      if (conceptProgress.length < 3) continue; // Need minimum attempts

      final accuracy = conceptProgress
              .map((p) => p.isCorrect ? 1.0 : 0.0)
              .reduce((a, b) => a + b) /
          conceptProgress.length;

      // Only include as strength if accuracy is above 70%
      if (accuracy > 0.7) {
        final accuracyList =
            conceptProgress.map((p) => p.isCorrect ? 1.0 : 0.0).toList();
        final consistency = 1.0 - _calculateVariance(accuracyList);

        strengths.add(ConceptualStrength(
          concept: entry.key,
          masteryLevel: accuracy,
          consistency: consistency.clamp(0.0, 1.0),
          applicability: accuracy * 0.9, // How well they apply this concept
        ));
      }
    }

    // Sort by mastery level and return top strengths
    strengths.sort((a, b) => b.masteryLevel.compareTo(a.masteryLevel));
    return strengths;
  }

  /// Infers learning style from interaction patterns
  LearningStyle _inferLearningStyle(List<StudentProgress> progress) {
    // Return default learning style if no progress data
    if (progress.isEmpty) {
      debugPrint(
          '⚠️ AdaptiveLearning: No progress data, using default learning style');
      return const LearningStyle(
        primaryStyle: 'visual',
        secondaryStyle: 'auditory',
        processingSpeed: 'medium',
        preferredFeedback: 'detailed',
      );
    }

    try {
      // Analyze patterns to infer learning preferences
      final avgResponseTime = progress
              .map((p) => p.responseTime.inSeconds)
              .reduce((a, b) => a + b) /
          progress.length;
      final hintUsage =
          progress.map((p) => p.hintsUsedCount).reduce((a, b) => a + b) /
              progress.length;

      debugPrint(
          '📊 AdaptiveLearning: Avg response time: ${avgResponseTime.toStringAsFixed(1)}s, Avg hints: ${hintUsage.toStringAsFixed(1)}');

      String primaryStyle = 'visual';
      if (avgResponseTime < 30) {
        primaryStyle = 'kinesthetic'; // Quick responders often prefer hands-on
      } else if (hintUsage > 2) {
        primaryStyle =
            'auditory'; // High hint usage suggests need for explanation
      }

      return LearningStyle(
        primaryStyle: primaryStyle,
        secondaryStyle: 'visual',
        processingSpeed: avgResponseTime < 30
            ? 'fast'
            : avgResponseTime > 60
                ? 'slow'
                : 'medium',
        preferredFeedback: hintUsage > 1 ? 'detailed' : 'brief',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ AdaptiveLearning ERROR in _inferLearningStyle: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      // Return default on error
      return const LearningStyle(
        primaryStyle: 'visual',
        secondaryStyle: 'auditory',
        processingSpeed: 'medium',
        preferredFeedback: 'detailed',
      );
    }
  }

  /// Identifies specific knowledge gaps
  List<KnowledgeGap> _identifyKnowledgeGaps(List<StudentProgress> progress) {
    final gaps = <KnowledgeGap>[];

    // Group by subject and topic to identify weak areas
    final subjectTopicPerformance =
        <String, Map<String, List<StudentProgress>>>{};

    for (final p in progress) {
      subjectTopicPerformance
          .putIfAbsent(p.subject, () => {})
          .putIfAbsent(p.topic, () => [])
          .add(p);
    }

    for (final subjectEntry in subjectTopicPerformance.entries) {
      final subject = subjectEntry.key;
      final topicProgress = subjectEntry.value;

      for (final topicEntry in topicProgress.entries) {
        final topic = topicEntry.key;
        final attempts = topicEntry.value;

        if (attempts.length < 2)
          continue; // Need minimum attempts to identify gap

        final correctAttempts = attempts.where((p) => p.isCorrect).length;
        final accuracy = correctAttempts / attempts.length;

        // Identify as knowledge gap if accuracy is below 60%
        if (accuracy < 0.6) {
          attempts.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));

          gaps.add(KnowledgeGap(
            subject: subject,
            topic: topic,
            severity: 1.0 - accuracy,
            lastAccuracy: accuracy,
            attempts: attempts.length,
            lastAttempt: attempts.first.attemptedAt,
          ));
        }
      }
    }

    // Sort by severity (worst performance first)
    gaps.sort((a, b) => b.severity.compareTo(a.severity));
    return gaps;
  }

  /// Calculates confidence levels across different dimensions
  Map<String, double> _calculateConfidenceLevels(
      List<StudentProgress> progress) {
    if (progress.isEmpty) {
      return {
        'overall': 0.5,
      };
    }

    final overallConfidence =
        progress.map((p) => p.confidenceLevel).reduce((a, b) => a + b) /
            progress.length;

    // Calculate confidence by subject
    final subjectGroups = <String, List<StudentProgress>>{};
    for (final p in progress) {
      subjectGroups.putIfAbsent(p.subject, () => []).add(p);
    }

    final confidenceLevels = <String, double>{
      'overall': overallConfidence / 5.0
    };

    for (final entry in subjectGroups.entries) {
      final subjectProgress = entry.value;
      if (subjectProgress.isEmpty) continue;

      final avgConfidence = subjectProgress
              .map((p) => p.confidenceLevel)
              .reduce((a, b) => a + b) /
          subjectProgress.length;

      confidenceLevels[entry.key.toLowerCase()] = avgConfidence / 5.0;
    }

    return confidenceLevels;
  }

  /// Calculates mastery levels for different topics/concepts
  Map<String, double> _calculateMasteryLevels(List<StudentProgress> progress) {
    final masteryLevels = <String, double>{};

    // Group by topic
    final topicGroups = <String, List<StudentProgress>>{};
    for (final p in progress) {
      topicGroups.putIfAbsent(p.topic, () => []).add(p);
    }

    for (final entry in topicGroups.entries) {
      final topicProgress = entry.value;
      if (topicProgress.isEmpty) continue;

      final correctCount = topicProgress.where((p) => p.isCorrect).length;
      final accuracy = correctCount / topicProgress.length;

      // Mastery level considers both accuracy and number of attempts
      final attemptFactor = (topicProgress.length / 10.0).clamp(0.0, 1.0);
      final masteryScore = accuracy * (0.7 + 0.3 * attemptFactor);

      masteryLevels[entry.key.toLowerCase()] = masteryScore;
    }

    return masteryLevels;
  }

  /// Analyzes preferred question types
  Map<QuestionType, double> _analyzeQuestionTypePreferences(
      List<StudentProgress> progress) {
    final typeStats = <QuestionType, List<double>>{};

    for (final p in progress) {
      // Get question type from metadata
      final questionTypeStr = p.metadata['question_type'] as String?;
      if (questionTypeStr != null) {
        try {
          final type = QuestionType.values.firstWhere(
            (t) => t.name == questionTypeStr,
            orElse: () => QuestionType.multipleChoice,
          );
          typeStats.putIfAbsent(type, () => []).add(p.isCorrect ? 1.0 : 0.0);
        } catch (e) {
          // Skip if question type not found
          continue;
        }
      }
    }

    if (typeStats.isEmpty) {
      return {};
    }

    return typeStats.map((type, scores) {
      if (scores.isEmpty) return MapEntry(type, 0.0);
      return MapEntry(type, scores.reduce((a, b) => a + b) / scores.length);
    });
  }

  /// Calculates optimal session length based on performance patterns
  Duration _calculateOptimalSessionLength(List<StudentProgress> progress) {
    // Analyze performance degradation over time in sessions
    // Mock calculation - would need session tracking in real implementation
    return const Duration(minutes: 25);
  }

  /// Identifies best study times based on performance patterns
  List<TimeOfDay> _identifyOptimalStudyTimes(List<StudentProgress> progress) {
    // Analyze accuracy vs time of day
    // Mock calculation - would need timestamp analysis
    return const [
      TimeOfDay(hour: 14, minute: 0), // 2 PM
      TimeOfDay(hour: 19, minute: 0), // 7 PM
    ];
  }

  /// Analyzes common error patterns
  List<ErrorPattern> _analyzeErrorPatterns(List<StudentProgress> progress) {
    // Mock error pattern analysis
    return [
      const ErrorPattern(
        pattern: 'Calculation errors in multi-step problems',
        frequency: 0.35,
        topics: ['algebra', 'calculus'],
        remedy: 'Practice step-by-step verification',
      ),
      const ErrorPattern(
        pattern: 'Misreading word problems',
        frequency: 0.22,
        topics: ['word_problems', 'applications'],
        remedy: 'Highlight key information before solving',
      ),
    ];
  }

  // Utility methods
  List<Question> _getAvailableQuestions({String? subject, String? topic}) {
    try {
      debugPrint(
          '🔍 AdaptiveLearning: Getting available questions (subject: $subject, topic: $topic)');
      final questions = _databaseService.getFilteredQuestions(
        subject: subject,
        topic: topic,
      );
      debugPrint(
          '✅ AdaptiveLearning: Retrieved ${questions.length} questions from database');
      return questions;
    } catch (e, stackTrace) {
      debugPrint('❌ AdaptiveLearning ERROR in _getAvailableQuestions: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  DifficultyTag _getReviewDifficulty(double lastAccuracy) {
    if (lastAccuracy < 0.3) return DifficultyTag.veryEasy;
    if (lastAccuracy < 0.5) return DifficultyTag.easy;
    if (lastAccuracy < 0.7) return DifficultyTag.medium;
    return DifficultyTag.hard;
  }

  bool _questionTargetsGap(Question question, KnowledgeGap gap) {
    return question.topic == gap.topic;
  }

  double _getCurrentPerformanceLevel(LearningProfile profile) {
    return profile.confidenceLevels['overall'] ?? 0.5;
  }

  DifficultyTag _calculateTargetDifficulty(
      double currentPerformance, LearningProfile profile) {
    final preferredLevel = profile.difficultyPreference.preferredLevel;

    if (currentPerformance > 0.8) {
      // Increase difficulty if performing well
      final currentIndex = DifficultyTag.values.indexOf(preferredLevel);
      final nextIndex =
          (currentIndex + 1).clamp(0, DifficultyTag.values.length - 1);
      return DifficultyTag.values[nextIndex];
    } else if (currentPerformance < 0.5) {
      // Decrease difficulty if struggling
      final currentIndex = DifficultyTag.values.indexOf(preferredLevel);
      final prevIndex =
          (currentIndex - 1).clamp(0, DifficultyTag.values.length - 1);
      return DifficultyTag.values[prevIndex];
    }

    return preferredLevel;
  }

  bool _isDifficultyAppropriate(
      DifficultyTag questionDifficulty, DifficultyTag targetDifficulty) {
    final questionIndex = DifficultyTag.values.indexOf(questionDifficulty);
    final targetIndex = DifficultyTag.values.indexOf(targetDifficulty);
    return (questionIndex - targetIndex).abs() <= 1;
  }

  double _calculateDifficultyOptimality(
      DifficultyTag difficulty, LearningProfile profile) {
    final preferred = profile.difficultyPreference.preferredLevel;
    final distance = (DifficultyTag.values.indexOf(difficulty) -
            DifficultyTag.values.indexOf(preferred))
        .abs();
    return 1.0 / (1.0 + distance);
  }

  double _calculateNoveltyBonus(Question question) {
    // Check when this question was last seen
    // Mock implementation
    return 0.5;
  }

  double _calculateOptimalChallenge(
      Question question, LearningProfile profile) {
    final difficultyScore = DifficultyTag.values.indexOf(question.difficulty) /
        DifficultyTag.values.length;
    final performanceLevel = profile.confidenceLevels['overall'] ?? 0.5;

    // Optimal challenge is slightly above current performance level
    final targetChallenge = performanceLevel + 0.15;
    return (difficultyScore - targetChallenge).abs();
  }

  double _calculateQuestionComplexity(Question question) {
    double complexity = 0.0;

    // Question length
    complexity += question.questionText.length / 1000.0;

    // Difficulty level
    complexity += DifficultyTag.values.indexOf(question.difficulty) /
        DifficultyTag.values.length;

    // Question type complexity
    const typeComplexity = {
      QuestionType.multipleChoice: 0.3,
      QuestionType.trueOrFalse: 0.1,
      QuestionType.shortAnswer: 0.6,
      QuestionType.essay: 0.9,
      QuestionType.fillInTheBlank: 0.4,
      QuestionType.matching: 0.5,
      QuestionType.calculation: 0.7,
      QuestionType.ordering: 0.5,
    };
    complexity += typeComplexity[question.questionType] ?? 0.5;

    return complexity;
  }

  double _calculateTrend(List<StudentProgress> attempts) {
    if (attempts.length < 2) return 0.0;

    final accuracies = attempts.map((a) => a.isCorrect ? 1.0 : 0.0).toList();
    final times = List.generate(accuracies.length, (i) => i.toDouble());

    return _calculateLinearRegression(times, accuracies);
  }

  double _calculateLinearRegression(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;

    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((val) => val * val).reduce((a, b) => a + b);

    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return 0.0;

    return (n * sumXY - sumX * sumY) / denominator;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((val) => pow(val - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  List<Question> _getFallbackRecommendations({
    required String studentId,
    String? subject,
    String? topic,
    required int count,
  }) {
    debugPrint('🆘 AdaptiveLearning: Using fallback recommendations');
    debugPrint(
        '   Student: $studentId, Subject: $subject, Topic: $topic, Count: $count');

    try {
      // Simple fallback when adaptive engine fails
      debugPrint('📚 AdaptiveLearning: Getting all questions from database...');
      final allQuestions = _databaseService.getAllQuestions();
      debugPrint(
          '✅ AdaptiveLearning: Found ${allQuestions.length} total questions');

      final questions = allQuestions
          .where((q) => subject == null || q.subject == subject)
          .where((q) => topic == null || q.topic == topic)
          .toList();

      debugPrint(
          '🔍 AdaptiveLearning: After filtering: ${questions.length} questions');

      if (questions.isEmpty) {
        debugPrint(
            '⚠️ AdaptiveLearning: No questions found matching criteria!');
        return [];
      }

      questions.shuffle();
      final result = questions.take(count).toList();
      debugPrint(
          '✅ AdaptiveLearning: Returning ${result.length} fallback recommendations');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ AdaptiveLearning ERROR in _getFallbackRecommendations: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }
}

/// Comprehensive learning profile for personalized education
class LearningProfile {
  final Map<String, SubjectPerformance> subjectPerformance;
  final DifficultyPreference difficultyPreference;
  final LearningVelocity learningVelocity;
  final List<ConceptualStrength> conceptualStrengths;
  final LearningStyle learningStyle;
  final List<KnowledgeGap> knowledgeGaps;
  final Map<String, double> confidenceLevels;
  final Map<String, double> masteryLevels;
  final Map<QuestionType, double> preferredQuestionTypes;
  final Duration optimalSessionLength;
  final List<TimeOfDay> bestStudyTimes;
  final List<ErrorPattern> errorPatterns;

  const LearningProfile({
    required this.subjectPerformance,
    required this.difficultyPreference,
    required this.learningVelocity,
    required this.conceptualStrengths,
    required this.learningStyle,
    required this.knowledgeGaps,
    required this.confidenceLevels,
    required this.masteryLevels,
    required this.preferredQuestionTypes,
    required this.optimalSessionLength,
    required this.bestStudyTimes,
    required this.errorPatterns,
  });
}

class SubjectPerformance {
  final double accuracy;
  final Duration averageTime;
  final double confidence;
  final int totalAttempts;
  final double trend;

  const SubjectPerformance({
    required this.accuracy,
    required this.averageTime,
    required this.confidence,
    required this.totalAttempts,
    required this.trend,
  });
}

class DifficultyPreference {
  final DifficultyTag preferredLevel;
  final List<DifficultyTag> comfortRange;
  final Map<DifficultyTag, double> confidenceByDifficulty;

  const DifficultyPreference({
    required this.preferredLevel,
    required this.comfortRange,
    required this.confidenceByDifficulty,
  });
}

class LearningVelocity {
  final double improvementRate;
  final double accelerationRate;
  final double plateauIndicator;

  const LearningVelocity({
    required this.improvementRate,
    required this.accelerationRate,
    required this.plateauIndicator,
  });
}

class ConceptualStrength {
  final String concept;
  final double masteryLevel;
  final double consistency;
  final double applicability;

  const ConceptualStrength({
    required this.concept,
    required this.masteryLevel,
    required this.consistency,
    required this.applicability,
  });
}

class LearningStyle {
  final String primaryStyle;
  final String secondaryStyle;
  final String processingSpeed;
  final String preferredFeedback;

  const LearningStyle({
    required this.primaryStyle,
    required this.secondaryStyle,
    required this.processingSpeed,
    required this.preferredFeedback,
  });
}

class KnowledgeGap {
  final String subject;
  final String topic;
  final double severity;
  final double lastAccuracy;
  final int attempts;
  final DateTime lastAttempt;

  const KnowledgeGap({
    required this.subject,
    required this.topic,
    required this.severity,
    required this.lastAccuracy,
    required this.attempts,
    required this.lastAttempt,
  });
}

class ErrorPattern {
  final String pattern;
  final double frequency;
  final List<String> topics;
  final String remedy;

  const ErrorPattern({
    required this.pattern,
    required this.frequency,
    required this.topics,
    required this.remedy,
  });
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
