import 'exercise.dart';

enum DifficultyLevel { beginner, intermediate, advanced }

class Lesson {
  final String id;
  final String lessonTitle;
  final String targetLanguage;
  final int gradeLevel;
  final String subject;
  final String topic;
  final String subtopic;
  final String learningObjective;
  final String standardPencapaian;
  final List<Exercise> exercises;
  final DifficultyLevel difficulty;
  final int estimatedDuration; // in minutes
  final String? iconPath;
  final bool isCompleted;
  final int completedExercises;

  const Lesson({
    required this.id,
    required this.lessonTitle,
    required this.targetLanguage,
    required this.gradeLevel,
    required this.subject,
    required this.topic,
    required this.subtopic,
    required this.learningObjective,
    required this.standardPencapaian,
    required this.exercises,
    this.difficulty = DifficultyLevel.intermediate,
    this.estimatedDuration = 30,
    this.iconPath,
    this.isCompleted = false,
    this.completedExercises = 0,
  });

  double get progressPercentage {
    if (exercises.isEmpty) return 0.0;
    return completedExercises / exercises.length;
  }

  String get difficultyLabel {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
    }
  }

  String get durationText {
    if (estimatedDuration < 60) {
      return '${estimatedDuration}m';
    } else {
      final hours = estimatedDuration ~/ 60;
      final minutes = estimatedDuration % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  Lesson copyWith({
    String? id,
    String? lessonTitle,
    String? targetLanguage,
    int? gradeLevel,
    String? subject,
    String? topic,
    String? subtopic,
    String? learningObjective,
    String? standardPencapaian,
    List<Exercise>? exercises,
    DifficultyLevel? difficulty,
    int? estimatedDuration,
    String? iconPath,
    bool? isCompleted,
    int? completedExercises,
  }) {
    return Lesson(
      id: id ?? this.id,
      lessonTitle: lessonTitle ?? this.lessonTitle,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      learningObjective: learningObjective ?? this.learningObjective,
      standardPencapaian: standardPencapaian ?? this.standardPencapaian,
      exercises: exercises ?? this.exercises,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      iconPath: iconPath ?? this.iconPath,
      isCompleted: isCompleted ?? this.isCompleted,
      completedExercises: completedExercises ?? this.completedExercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_title': lessonTitle,
      'target_language': targetLanguage,
      'grade_level': gradeLevel,
      'subject': subject,
      'topic': topic,
      'subtopic': subtopic,
      'learning_objective': learningObjective,
      'standard_pencapaian': standardPencapaian,
      'exercise': exercises.map((e) => e.toJson()).toList(),
      'difficulty': difficulty.index,
      'estimated_duration': estimatedDuration,
      'icon_path': iconPath,
      'is_completed': isCompleted,
      'completed_exercises': completedExercises,
    };
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final exerciseList = json['exercise'] as List<dynamic>? ?? [];

    return Lesson(
      id: json['id'] ?? '',
      lessonTitle: json['lesson_title'] ?? '',
      targetLanguage: json['target_language'] ?? 'English',
      gradeLevel: json['grade_level'] ?? 1,
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      subtopic: json['subtopic'] ?? '',
      learningObjective: json['learning_objective'] ?? '',
      standardPencapaian: json['standard_pencapaian'] ?? '',
      exercises: exerciseList.map((e) => Exercise.fromJson(e)).toList(),
      difficulty: DifficultyLevel.values[json['difficulty'] ?? 1],
      estimatedDuration: json['estimated_duration'] ?? 30,
      iconPath: json['icon_path'],
      isCompleted: json['is_completed'] ?? false,
      completedExercises: json['completed_exercises'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lesson && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Lesson(id: $id, title: $lessonTitle, subject: $subject, topic: $topic)';
  }
}
