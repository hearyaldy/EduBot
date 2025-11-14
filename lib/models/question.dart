import 'exercise.dart';

enum QuestionType {
  multipleChoice,
  trueOrFalse,
  fillInTheBlank,
  shortAnswer,
  essay,
  matching,
  ordering,
  calculation
}

enum DifficultyTag {
  veryEasy, // Level 1
  easy, // Level 2
  medium, // Level 3
  hard, // Level 4
  veryHard // Level 5
}

enum BloomsTaxonomy {
  remember, // Recall facts and basic concepts
  understand, // Explain ideas or concepts
  apply, // Use information in new situations
  analyze, // Draw connections among ideas
  evaluate, // Justify a stand or decision
  create // Produce new or original work
}

class QuestionMetadata {
  final List<String> curriculumStandards;
  final List<String> tags;
  final Duration estimatedTime;
  final BloomsTaxonomy cognitiveLevel;
  final Map<String, dynamic> additionalData;

  const QuestionMetadata({
    this.curriculumStandards = const [],
    this.tags = const [],
    this.estimatedTime = const Duration(minutes: 2),
    this.cognitiveLevel = BloomsTaxonomy.remember,
    this.additionalData = const {},
  });

  QuestionMetadata copyWith({
    List<String>? curriculumStandards,
    List<String>? tags,
    Duration? estimatedTime,
    BloomsTaxonomy? cognitiveLevel,
    Map<String, dynamic>? additionalData,
  }) {
    return QuestionMetadata(
      curriculumStandards: curriculumStandards ?? this.curriculumStandards,
      tags: tags ?? this.tags,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      cognitiveLevel: cognitiveLevel ?? this.cognitiveLevel,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'curriculum_standards': curriculumStandards,
      'tags': tags,
      'estimated_time_minutes': estimatedTime.inMinutes,
      'cognitive_level': cognitiveLevel.index,
      'additional_data': additionalData,
    };
  }

  factory QuestionMetadata.fromJson(Map<String, dynamic> json) {
    return QuestionMetadata(
      curriculumStandards:
          List<String>.from(json['curriculum_standards'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      estimatedTime: Duration(minutes: json['estimated_time_minutes'] ?? 2),
      cognitiveLevel: BloomsTaxonomy.values[json['cognitive_level'] ?? 0],
      additionalData: Map<String, dynamic>.from(json['additional_data'] ?? {}),
    );
  }
}

class Question {
  final String id;
  final String questionText;
  final QuestionType questionType;
  final String subject;
  final String topic;
  final String subtopic;
  final int gradeLevel;
  final DifficultyTag difficulty;
  final String answerKey;
  final String explanation;
  final List<String> choices; // For multiple choice questions
  final QuestionMetadata metadata;
  final String targetLanguage;

  const Question({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.subject,
    required this.topic,
    required this.subtopic,
    required this.gradeLevel,
    required this.difficulty,
    required this.answerKey,
    required this.explanation,
    this.choices = const [],
    required this.metadata,
    this.targetLanguage = 'English',
  });

  Question copyWith({
    String? id,
    String? questionText,
    QuestionType? questionType,
    String? subject,
    String? topic,
    String? subtopic,
    int? gradeLevel,
    DifficultyTag? difficulty,
    String? answerKey,
    String? explanation,
    List<String>? choices,
    QuestionMetadata? metadata,
    String? targetLanguage,
  }) {
    return Question(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      difficulty: difficulty ?? this.difficulty,
      answerKey: answerKey ?? this.answerKey,
      explanation: explanation ?? this.explanation,
      choices: choices ?? this.choices,
      metadata: metadata ?? this.metadata,
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }

  // Convert to Exercise for backwards compatibility
  Exercise toExercise({int? questionNumber}) {
    return Exercise(
      questionNumber: questionNumber ?? 1,
      questionText: questionText,
      inputType: _getInputTypeFromQuestionType(),
      answerKey: answerKey,
      explanation: explanation,
    );
  }

  String _getInputTypeFromQuestionType() {
    switch (questionType) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.trueOrFalse:
        return 'true_false';
      case QuestionType.fillInTheBlank:
      case QuestionType.calculation:
        return 'text';
      case QuestionType.shortAnswer:
      case QuestionType.essay:
        return 'short_answer';
      case QuestionType.matching:
        return 'matching';
      case QuestionType.ordering:
        return 'ordering';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'question_type': questionType.index,
      'subject': subject,
      'topic': topic,
      'subtopic': subtopic,
      'grade_level': gradeLevel,
      'difficulty': difficulty.index,
      'answer_key': answerKey,
      'explanation': explanation,
      'choices': choices,
      'metadata': metadata.toJson(),
      'target_language': targetLanguage,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      questionText: json['question_text'] ?? '',
      questionType: QuestionType.values[json['question_type'] ?? 0],
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      subtopic: json['subtopic'] ?? '',
      gradeLevel: json['grade_level'] ?? 1,
      difficulty: DifficultyTag.values[json['difficulty'] ?? 0],
      answerKey: json['answer_key'] ?? '',
      explanation: json['explanation'] ?? '',
      choices: List<String>.from(json['choices'] ?? []),
      metadata: QuestionMetadata.fromJson(json['metadata'] ?? {}),
      targetLanguage: json['target_language'] ?? 'English',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Question(id: $id, subject: $subject, topic: $topic, grade: $gradeLevel, difficulty: $difficulty)';
  }
}
