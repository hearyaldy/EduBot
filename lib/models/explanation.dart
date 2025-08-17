import 'package:uuid/uuid.dart';

class Explanation {
  final String id;
  final String questionId;
  final String question;
  final String answer;
  final List<ExplanationStep> steps;
  final String? parentFriendlyTip;
  final String? realWorldExample;
  final DateTime createdAt;
  final String subject;
  final DifficultyLevel difficulty;

  Explanation({
    String? id,
    required this.questionId,
    required this.question,
    required this.answer,
    required this.steps,
    this.parentFriendlyTip,
    this.realWorldExample,
    DateTime? createdAt,
    required this.subject,
    this.difficulty = DifficultyLevel.medium,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'question': question,
      'answer': answer,
      'steps': steps.map((step) => step.toJson()).toList(),
      'parentFriendlyTip': parentFriendlyTip,
      'realWorldExample': realWorldExample,
      'createdAt': createdAt.toIso8601String(),
      'subject': subject,
      'difficulty': difficulty.name,
    };
  }

  // Create from JSON
  factory Explanation.fromJson(Map<String, dynamic> json) {
    return Explanation(
      id: json['id'],
      questionId: json['questionId'],
      question: json['question'],
      answer: json['answer'],
      steps: (json['steps'] as List)
          .map((step) => ExplanationStep.fromJson(step))
          .toList(),
      parentFriendlyTip: json['parentFriendlyTip'],
      realWorldExample: json['realWorldExample'],
      createdAt: DateTime.parse(json['createdAt']),
      subject: json['subject'],
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => DifficultyLevel.medium,
      ),
    );
  }

  @override
  String toString() {
    return 'Explanation(id: $id, question: $question, subject: $subject)';
  }
}

class ExplanationStep {
  final int stepNumber;
  final String title;
  final String description;
  final String? tip;
  final bool isKeyStep;

  ExplanationStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.tip,
    this.isKeyStep = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'description': description,
      'tip': tip,
      'isKeyStep': isKeyStep,
    };
  }

  factory ExplanationStep.fromJson(Map<String, dynamic> json) {
    return ExplanationStep(
      stepNumber: json['stepNumber'],
      title: json['title'],
      description: json['description'],
      tip: json['tip'],
      isKeyStep: json['isKeyStep'] ?? false,
    );
  }
}

enum DifficultyLevel { elementary, medium, advanced }

extension DifficultyLevelExtension on DifficultyLevel {
  String get displayName {
    switch (this) {
      case DifficultyLevel.elementary:
        return 'Elementary';
      case DifficultyLevel.medium:
        return 'Middle School';
      case DifficultyLevel.advanced:
        return 'High School';
    }
  }

  String get emoji {
    switch (this) {
      case DifficultyLevel.elementary:
        return '🟢';
      case DifficultyLevel.medium:
        return '🟡';
      case DifficultyLevel.advanced:
        return '🔴';
    }
  }
}
