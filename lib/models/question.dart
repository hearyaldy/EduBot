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
    // Helper to safely convert additional data
    Map<String, dynamic> convertAdditionalData(dynamic data) {
      if (data == null) return {};
      if (data is Map<String, dynamic>) return data;
      if (data is Map) {
        return Map<String, dynamic>.from(data.map(
          (key, value) => MapEntry(key.toString(), value),
        ));
      }
      return {};
    }

    return QuestionMetadata(
      curriculumStandards:
          List<String>.from(json['curriculum_standards'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      estimatedTime: Duration(minutes: json['estimated_time_minutes'] ?? 2),
      cognitiveLevel: BloomsTaxonomy.values[json['cognitive_level'] ?? 0],
      additionalData: convertAdditionalData(json['additional_data']),
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
      explanation: _buildEnhancedExplanation(),
    );
  }

  // Build a comprehensive explanation with tips and examples
  String _buildEnhancedExplanation() {
    final buffer = StringBuffer();

    // Add the main explanation
    if (explanation.isNotEmpty) {
      buffer.writeln('📖 Explanation:');
      buffer.writeln(explanation);
      buffer.writeln();
    }

    // Add the correct answer
    buffer.writeln('✅ Correct Answer: $answerKey');
    buffer.writeln();

    // Add solving steps specific to this question
    buffer.writeln('🔧 How to Solve This Question:');
    _addContextualSolvingSteps(buffer);
    buffer.writeln();

    // Add tips specific to this question
    buffer.writeln('💡 Tips for This Question:');
    _addContextualTips(buffer);
    buffer.writeln();

    // Add a similar example
    buffer.writeln('📝 Similar Example:');
    _addContextualExample(buffer);

    // Add topic context
    buffer.writeln();
    buffer.writeln('📚 Topic: $topic');
    if (subtopic.isNotEmpty) {
      buffer.writeln('📌 Subtopic: $subtopic');
    }

    return buffer.toString().trim();
  }

  void _addContextualSolvingSteps(StringBuffer buffer) {
    final questionLower = questionText.toLowerCase();
    final subjectLower = subject.toLowerCase();

    // Analyze the question to provide specific steps
    if (subjectLower.contains('math')) {
      if (questionLower.contains('percent') || questionLower.contains('%')) {
        buffer.writeln('1. Identify the percentage and the whole number.');
        buffer
            .writeln('2. Convert the percentage to a decimal (divide by 100).');
        buffer.writeln('3. Multiply the decimal by the whole number.');
        buffer.writeln(
            '4. Check: The answer should be less than the whole if percentage < 100%.');
      } else if (questionLower.contains('area') ||
          questionLower.contains('perimeter')) {
        buffer.writeln('1. Identify the shape mentioned in the problem.');
        buffer.writeln('2. Note down the given measurements.');
        buffer.writeln(
            '3. Recall the formula: Area or Perimeter for that shape.');
        buffer.writeln('4. Substitute the values and calculate.');
        buffer.writeln('5. Include the correct units in your answer.');
      } else if (questionLower.contains('fraction')) {
        buffer.writeln('1. Identify the fractions involved.');
        buffer.writeln('2. Find a common denominator if adding/subtracting.');
        buffer.writeln('3. For multiplication, multiply tops and bottoms.');
        buffer.writeln('4. Simplify your final answer.');
      } else if (questionLower.contains('equation') ||
          questionLower.contains('solve for')) {
        buffer.writeln('1. Identify what variable you need to find.');
        buffer.writeln('2. Isolate the variable on one side.');
        buffer.writeln('3. Perform the same operation on both sides.');
        buffer.writeln('4. Check by substituting your answer back.');
      } else if (questionLower.contains('+') ||
          questionLower.contains('add') ||
          questionLower.contains('sum')) {
        buffer.writeln('1. Identify all the numbers to add.');
        buffer.writeln('2. Line up place values if needed.');
        buffer.writeln('3. Add from right to left, carrying when necessary.');
        buffer.writeln('4. Double-check your addition.');
      } else if (questionLower.contains('-') ||
          questionLower.contains('subtract') ||
          questionLower.contains('difference')) {
        buffer
            .writeln('1. Identify the numbers and which is being subtracted.');
        buffer.writeln('2. Line up place values.');
        buffer.writeln('3. Subtract from right to left, borrowing if needed.');
        buffer.writeln('4. Verify: smaller number + answer = larger number.');
      } else if (questionLower.contains('×') ||
          questionLower.contains('*') ||
          questionLower.contains('multiply') ||
          questionLower.contains('product')) {
        buffer.writeln('1. Identify the numbers to multiply.');
        buffer
            .writeln('2. Break down into simpler multiplications if helpful.');
        buffer.writeln('3. Multiply step by step.');
        buffer.writeln('4. Check: Is the answer reasonable?');
      } else if (questionLower.contains('÷') ||
          questionLower.contains('/') ||
          questionLower.contains('divide') ||
          questionLower.contains('quotient')) {
        buffer.writeln('1. Identify the dividend and divisor.');
        buffer.writeln(
            '2. See how many times the divisor fits into the dividend.');
        buffer.writeln('3. Handle any remainder appropriately.');
        buffer.writeln('4. Verify: quotient × divisor + remainder = dividend.');
      } else {
        buffer.writeln('1. Read the problem and identify what is being asked.');
        buffer.writeln('2. Extract the key numbers and operations.');
        buffer.writeln('3. Set up the calculation step by step.');
        buffer.writeln('4. Solve and verify your answer makes sense.');
      }
    } else if (subjectLower.contains('science')) {
      if (questionLower.contains('why') || questionLower.contains('explain')) {
        buffer.writeln('1. Identify the phenomenon being asked about.');
        buffer.writeln('2. Think about the underlying scientific principle.');
        buffer.writeln('3. Connect cause to effect.');
        buffer.writeln('4. Use scientific vocabulary in your answer.');
      } else if (questionLower.contains('what is') ||
          questionLower.contains('define')) {
        buffer.writeln('1. Recall the definition of the term.');
        buffer.writeln('2. Think of key characteristics.');
        buffer.writeln('3. Provide a clear, concise definition.');
      } else if (questionLower.contains('compare') ||
          questionLower.contains('difference')) {
        buffer.writeln('1. List characteristics of each item.');
        buffer.writeln('2. Identify what is similar.');
        buffer.writeln('3. Identify what is different.');
        buffer.writeln('4. Organize your comparison clearly.');
      } else {
        buffer.writeln('1. Identify the scientific concept involved.');
        buffer.writeln('2. Recall relevant facts and principles.');
        buffer.writeln('3. Apply your knowledge to the specific question.');
        buffer.writeln('4. Check that your answer is scientifically accurate.');
      }
    } else if (subjectLower.contains('english') ||
        subjectLower.contains('language')) {
      if (questionLower.contains('grammar') ||
          questionLower.contains('correct')) {
        buffer.writeln('1. Read the sentence carefully.');
        buffer.writeln('2. Identify the subject and verb.');
        buffer.writeln('3. Check subject-verb agreement.');
        buffer.writeln('4. Look for tense consistency.');
      } else if (questionLower.contains('meaning') ||
          questionLower.contains('synonym') ||
          questionLower.contains('antonym')) {
        buffer.writeln('1. Read the word in context.');
        buffer.writeln('2. Think about words with similar/opposite meanings.');
        buffer.writeln('3. Substitute to check if it makes sense.');
      } else if (questionLower.contains('comprehension') ||
          questionLower.contains('passage')) {
        buffer.writeln('1. Read the passage carefully.');
        buffer.writeln('2. Identify the main idea.');
        buffer.writeln('3. Look for specific details related to the question.');
        buffer.writeln('4. Answer based on the text, not assumptions.');
      } else {
        buffer.writeln('1. Read the question carefully.');
        buffer.writeln('2. Consider grammar and context.');
        buffer.writeln('3. Apply language rules you know.');
        buffer.writeln('4. Check that your answer sounds correct.');
      }
    } else {
      buffer.writeln(
          '1. Read the question carefully to understand what is asked.');
      buffer.writeln('2. Identify the key concepts and terms.');
      buffer.writeln('3. Recall what you learned about "$topic".');
      buffer.writeln('4. Formulate your answer clearly.');
    }
  }

  void _addContextualTips(StringBuffer buffer) {
    final questionLower = questionText.toLowerCase();

    // Add question-specific tips based on keywords in the question
    if (choices.isNotEmpty) {
      buffer.writeln(
          '• This question has ${choices.length} options: look at each one.');
      if (choices.length == 4) {
        buffer.writeln(
            '• Usually 1-2 options are clearly wrong - eliminate them first.');
      }
    }

    if (questionLower.contains('not') || questionLower.contains('except')) {
      buffer.writeln(
          '⚠️ Watch out! This question asks for what is NOT true or the exception.');
      buffer.writeln('• Read each option and find the one that doesn\'t fit.');
    }

    if (questionLower.contains('best') || questionLower.contains('most')) {
      buffer.writeln(
          '• Multiple answers might seem correct, but choose the BEST one.');
      buffer.writeln('• Look for the most complete or accurate answer.');
    }

    if (questionLower.contains('all of the above') ||
        questionLower.contains('none of the above')) {
      buffer.writeln(
          '• If you see "all/none of the above", verify each option first.');
    }

    if (questionLower.contains('how many') ||
        questionLower.contains('calculate')) {
      buffer.writeln('• Make sure to show your calculation steps.');
      buffer.writeln('• Double-check your arithmetic.');
    }

    if (questionLower.contains('true') || questionLower.contains('false')) {
      buffer.writeln(
          '• Remember: if ANY part is false, the whole statement is false.');
    }

    // Add tips based on topic
    buffer.writeln('• Focus on what you know about: $topic.');

    // Generic helpful tip
    buffer.writeln('• Take your time - don\'t rush to answer.');
  }

  void _addContextualExample(StringBuffer buffer) {
    final subjectLower = subject.toLowerCase();
    final questionLower = questionText.toLowerCase();

    // Provide a similar but different example
    buffer.writeln('Here\'s a similar type of question:');
    buffer.writeln();

    if (subjectLower.contains('math')) {
      if (questionLower.contains('percent') || questionLower.contains('%')) {
        buffer.writeln('Q: What is 20% of 50?');
        buffer.writeln('Solution:');
        buffer.writeln('  20% = 20/100 = 0.20');
        buffer.writeln('  0.20 × 50 = 10');
        buffer.writeln('  Answer: 10');
      } else if (questionLower.contains('area')) {
        buffer.writeln(
            'Q: Find the area of a rectangle with length 5cm and width 3cm.');
        buffer.writeln('Solution:');
        buffer.writeln('  Area = length × width');
        buffer.writeln('  Area = 5 × 3 = 15 cm²');
      } else if (questionLower.contains('perimeter')) {
        buffer.writeln('Q: Find the perimeter of a square with side 4m.');
        buffer.writeln('Solution:');
        buffer.writeln('  Perimeter = 4 × side');
        buffer.writeln('  Perimeter = 4 × 4 = 16 m');
      } else if (questionLower.contains('fraction')) {
        buffer.writeln('Q: Add 1/4 + 1/2');
        buffer.writeln('Solution:');
        buffer.writeln('  Convert to same denominator: 1/4 + 2/4');
        buffer.writeln('  Add: 3/4');
      } else if (questionLower.contains('+') || questionLower.contains('add')) {
        buffer.writeln('Q: 24 + 38 = ?');
        buffer.writeln('Solution:');
        buffer.writeln('  24 + 38 = 62');
      } else if (questionLower.contains('-') ||
          questionLower.contains('subtract')) {
        buffer.writeln('Q: 75 - 28 = ?');
        buffer.writeln('Solution:');
        buffer.writeln('  75 - 28 = 47');
      } else if (questionLower.contains('×') ||
          questionLower.contains('multiply')) {
        buffer.writeln('Q: 12 × 5 = ?');
        buffer.writeln('Solution:');
        buffer.writeln('  12 × 5 = 60');
      } else if (questionLower.contains('÷') ||
          questionLower.contains('divide')) {
        buffer.writeln('Q: 48 ÷ 6 = ?');
        buffer.writeln('Solution:');
        buffer.writeln('  48 ÷ 6 = 8');
      } else {
        buffer.writeln(
            'Q: If you have 5 apples and get 3 more, how many do you have?');
        buffer.writeln('Solution:');
        buffer.writeln('  5 + 3 = 8 apples');
      }
    } else if (subjectLower.contains('science')) {
      if (questionLower.contains('plant') || questionLower.contains('photo')) {
        buffer.writeln('Q: What do plants need for photosynthesis?');
        buffer.writeln('Answer: Sunlight, water, and carbon dioxide.');
        buffer.writeln(
            'Explanation: Plants use these to make glucose and oxygen.');
      } else if (questionLower.contains('animal') ||
          questionLower.contains('living')) {
        buffer.writeln('Q: What are characteristics of living things?');
        buffer.writeln(
            'Answer: They breathe, grow, reproduce, respond to stimuli.');
      } else if (questionLower.contains('water') ||
          questionLower.contains('state')) {
        buffer.writeln('Q: What are the three states of matter?');
        buffer.writeln('Answer: Solid, liquid, and gas.');
        buffer.writeln('Example: Ice (solid), water (liquid), steam (gas).');
      } else {
        buffer.writeln('Q: Why is the sky blue?');
        buffer.writeln('Answer: Sunlight scatters in the atmosphere.');
        buffer.writeln('Blue light scatters more, making the sky appear blue.');
      }
    } else if (subjectLower.contains('english') ||
        subjectLower.contains('language')) {
      if (questionLower.contains('verb') || questionLower.contains('tense')) {
        buffer.writeln(
            'Q: Choose the correct verb: "She ___ (go) to school yesterday."');
        buffer.writeln('Answer: went');
        buffer.writeln('Explanation: "Yesterday" indicates past tense.');
      } else if (questionLower.contains('noun') ||
          questionLower.contains('pronoun')) {
        buffer.writeln('Q: Identify the noun: "The cat sleeps."');
        buffer.writeln('Answer: cat');
        buffer.writeln(
            'Explanation: A noun is a person, place, thing, or animal.');
      } else {
        buffer.writeln('Q: What is the synonym of "happy"?');
        buffer.writeln('Answer: joyful, glad, pleased');
        buffer.writeln('Tip: Synonyms have similar meanings.');
      }
    } else {
      buffer.writeln('Apply the same approach:');
      buffer.writeln('1. Understand what is being asked.');
      buffer.writeln('2. Use your knowledge of $topic.');
      buffer.writeln('3. Answer clearly and completely.');
    }
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
    // Helper to safely convert metadata
    Map<String, dynamic> convertMetadata(dynamic metadata) {
      if (metadata == null) return {};
      if (metadata is Map<String, dynamic>) return metadata;
      if (metadata is Map) {
        return Map<String, dynamic>.from(metadata.map(
          (key, value) => MapEntry(key.toString(), value),
        ));
      }
      return {};
    }

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
      metadata: QuestionMetadata.fromJson(convertMetadata(json['metadata'])),
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
