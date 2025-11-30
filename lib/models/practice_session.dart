class PracticeSession {
  final String id;
  final String lessonId;
  final String lessonTitle;
  final String subject;
  final String topic;
  final int gradeLevel;
  final String? childProfileId;
  final String? childName;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int skippedQuestions;
  final double accuracyPercentage;
  final Duration? duration;
  final bool isCompleted;
  final Map<String, dynamic>? metadata;

  const PracticeSession({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.subject,
    required this.topic,
    required this.gradeLevel,
    this.childProfileId,
    this.childName,
    required this.startTime,
    this.endTime,
    required this.totalQuestions,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.skippedQuestions = 0,
    this.accuracyPercentage = 0.0,
    this.duration,
    this.isCompleted = false,
    this.metadata,
  });

  PracticeSession copyWith({
    String? id,
    String? lessonId,
    String? lessonTitle,
    String? subject,
    String? topic,
    int? gradeLevel,
    String? childProfileId,
    String? childName,
    DateTime? startTime,
    DateTime? endTime,
    int? totalQuestions,
    int? correctAnswers,
    int? incorrectAnswers,
    int? skippedQuestions,
    double? accuracyPercentage,
    Duration? duration,
    bool? isCompleted,
    Map<String, dynamic>? metadata,
  }) {
    return PracticeSession(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      childProfileId: childProfileId ?? this.childProfileId,
      childName: childName ?? this.childName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      skippedQuestions: skippedQuestions ?? this.skippedQuestions,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      duration: duration ?? this.duration,
      isCompleted: isCompleted ?? this.isCompleted,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'lesson_title': lessonTitle,
      'subject': subject,
      'topic': topic,
      'grade_level': gradeLevel,
      'child_profile_id': childProfileId,
      'child_name': childName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'incorrect_answers': incorrectAnswers,
      'skipped_questions': skippedQuestions,
      'accuracy_percentage': accuracyPercentage,
      'duration_seconds': duration?.inSeconds,
      'is_completed': isCompleted,
      'metadata': metadata,
    };
  }

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['id'] ?? '',
      lessonId: json['lesson_id'] ?? '',
      lessonTitle: json['lesson_title'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      gradeLevel: json['grade_level'] ?? 0,
      childProfileId: json['child_profile_id'],
      childName: json['child_name'],
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      totalQuestions: json['total_questions'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      incorrectAnswers: json['incorrect_answers'] ?? 0,
      skippedQuestions: json['skipped_questions'] ?? 0,
      accuracyPercentage: (json['accuracy_percentage'] ?? 0.0).toDouble(),
      duration: json['duration_seconds'] != null
          ? Duration(seconds: json['duration_seconds'])
          : null,
      isCompleted: json['is_completed'] ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  String get performanceEmoji {
    if (accuracyPercentage >= 90) return '⭐'; // Excellent
    if (accuracyPercentage >= 75) return '🌟'; // Great
    if (accuracyPercentage >= 60) return '👍'; // Good
    if (accuracyPercentage >= 40) return '💪'; // Keep trying
    return '🎯'; // Practice more
  }

  String get performanceLabel {
    if (accuracyPercentage >= 90) return 'Excellent!';
    if (accuracyPercentage >= 75) return 'Great Job!';
    if (accuracyPercentage >= 60) return 'Good Work!';
    if (accuracyPercentage >= 40) return 'Keep Trying!';
    return 'Practice More!';
  }

  @override
  String toString() {
    return 'PracticeSession(id: $id, lesson: $lessonTitle, accuracy: $accuracyPercentage%)';
  }
}
