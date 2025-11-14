import 'package:uuid/uuid.dart';

class HomeworkQuestion {
  final String id;
  final String question;
  final String? imagePath;
  final QuestionType type;
  final DateTime createdAt;
  final String? subject;
  final String? childProfileId; // ID of the child profile who asked this question
  final String? answer; // Store the AI answer with the question

  HomeworkQuestion({
    String? id,
    required this.question,
    this.imagePath,
    required this.type,
    DateTime? createdAt,
    this.subject,
    this.childProfileId,
    this.answer,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'imagePath': imagePath,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'subject': subject,
      'childProfileId': childProfileId,
      'answer': answer,
    };
  }

  // Create from JSON
  factory HomeworkQuestion.fromJson(Map<String, dynamic> json) {
    return HomeworkQuestion(
      id: json['id'],
      question: json['question'],
      imagePath: json['imagePath'],
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.text,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      subject: json['subject'],
      childProfileId: json['childProfileId'],
      answer: json['answer'],
    );
  }

  @override
  String toString() {
    return 'HomeworkQuestion(id: $id, question: $question, type: $type)';
  }
}

enum QuestionType { text, image, voice }

// Extension to get display names
extension QuestionTypeExtension on QuestionType {
  String get displayName {
    switch (this) {
      case QuestionType.text:
        return 'Text Question';
      case QuestionType.image:
        return 'Scanned Problem';
      case QuestionType.voice:
        return 'Voice Question';
    }
  }

  String get icon {
    switch (this) {
      case QuestionType.text:
        return '📝';
      case QuestionType.image:
        return '📸';
      case QuestionType.voice:
        return '🎤';
    }
  }
}
