class Exercise {
  final int questionNumber;
  final String questionText;
  final String inputType;
  final String answerKey;
  final String explanation;
  final String? userAnswer;
  final bool isCompleted;
  final bool isCorrect;

  const Exercise({
    required this.questionNumber,
    required this.questionText,
    required this.inputType,
    required this.answerKey,
    required this.explanation,
    this.userAnswer,
    this.isCompleted = false,
    this.isCorrect = false,
  });

  Exercise copyWith({
    int? questionNumber,
    String? questionText,
    String? inputType,
    String? answerKey,
    String? explanation,
    String? userAnswer,
    bool? isCompleted,
    bool? isCorrect,
  }) {
    return Exercise(
      questionNumber: questionNumber ?? this.questionNumber,
      questionText: questionText ?? this.questionText,
      inputType: inputType ?? this.inputType,
      answerKey: answerKey ?? this.answerKey,
      explanation: explanation ?? this.explanation,
      userAnswer: userAnswer ?? this.userAnswer,
      isCompleted: isCompleted ?? this.isCompleted,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_number': questionNumber,
      'question_text': questionText,
      'input_type': inputType,
      'answer_key': answerKey,
      'explanation': explanation,
      'user_answer': userAnswer,
      'is_completed': isCompleted,
      'is_correct': isCorrect,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      questionNumber: json['question_number'] ?? 0,
      questionText: json['question_text'] ?? '',
      inputType: json['input_type'] ?? 'text',
      answerKey: json['answer_key'] ?? '',
      explanation: json['explanation'] ?? '',
      userAnswer: json['user_answer'],
      isCompleted: json['is_completed'] ?? false,
      isCorrect: json['is_correct'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise && other.questionNumber == questionNumber;
  }

  @override
  int get hashCode => questionNumber.hashCode;

  @override
  String toString() {
    return 'Exercise(questionNumber: $questionNumber, questionText: $questionText)';
  }
}
