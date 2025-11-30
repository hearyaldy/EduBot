import '../models/lesson.dart';
import '../models/exercise.dart';
import '../models/question.dart';
import 'database_service.dart';
import 'firebase_service.dart';
import 'package:flutter/foundation.dart';

class LessonService {
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<Lesson> _lessons = [];
  bool _isInitialized = false;
  bool _useOnlyQuestionBank = false; // Flag to use only question bank

  /// Helper to deeply convert Map<dynamic, dynamic> to Map<String, dynamic>
  static Map<String, dynamic> _deepConvertMap(Map map) {
    return map.map((key, value) {
      final stringKey = key.toString();
      if (value is Map) {
        return MapEntry(stringKey, _deepConvertMap(value));
      } else if (value is List) {
        return MapEntry(
            stringKey,
            value.map((item) {
              if (item is Map) {
                return _deepConvertMap(item);
              }
              return item;
            }).toList());
      }
      return MapEntry(stringKey, value);
    });
  }

  /// Initialize the service with sample lessons
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (!_useOnlyQuestionBank) {
        // Create sample Math lesson based on the provided JSON
        _lessons = [
          _createMathMoneyLesson(),
          _createMathFractionsLesson(),
          _createMathMultiplicationLesson(),

          // KSSR Year 1 Mathematics - Foundational Practice
          _createYear1MathFoundationalLesson(),

          // KSSR Year 6 Mathematics - Divided by Topic and Difficulty
          // Time and Time Zones
          _createTimeZonesBeginnerLesson(),
          _createTimeZonesIntermediateLesson(),
          _createTimeZonesAdvancedLesson(),

          // Measurement and Measuring
          _createMeasurementBeginnerLesson(),
          _createMeasurementIntermediateLesson(),
          _createMeasurementAdvancedLesson(),

          // Space (Geometry)
          // Space/Geometry Lessons
          _createSpaceBeginnerLesson(),
          _createSpaceIntermediateLesson(),
          _createSpaceAdvancedLesson(), // Relations and Algebra
          _createRelationsBeginnerLesson(),
          _createRelationsIntermediateLesson(),
          _createRelationsAdvancedLesson(),

          // Statistics and Probability
          _createStatisticsBeginnerLesson(),
          _createStatisticsIntermediateLesson(),
          _createStatisticsAdvancedLesson(),
        ];
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing LessonService: $e');
    }
  }

  /// Enable using only questions from the question bank (no hardcoded lessons)
  void useOnlyQuestionBank() {
    _useOnlyQuestionBank = true;
  }

  /// Get all lessons for a specific subject
  Future<List<Lesson>> getLessonsBySubject(String subject) async {
    await initialize();
    return _lessons
        .where(
            (lesson) => lesson.subject.toLowerCase() == subject.toLowerCase())
        .toList();
  }

  /// Get all lessons (including ones from question bank and AI-generated)
  Future<List<Lesson>> getAllLessons() async {
    await initialize();

    if (_useOnlyQuestionBank) {
      // Only return lessons from the question bank
      final questionBankLessons = await getLessonsFromQuestionBank();
      final aiLessons = await getAILessonsFromFirestore();
      return [...questionBankLessons, ...aiLessons];
    } else {
      // Get hardcoded lessons
      final hardcodedLessons = List<Lesson>.from(_lessons);

      // Get lessons from question bank
      final questionBankLessons = await getLessonsFromQuestionBank();

      // Get AI-generated lessons from Firestore
      final aiLessons = await getAILessonsFromFirestore();

      // Combine them (AI lessons first for visibility, then hardcoded, then question bank)
      return [...aiLessons, ...hardcodedLessons, ...questionBankLessons];
    }
  }

  /// Get AI-generated lessons with local caching
  /// Loads from local cache first, syncs from Firestore only when needed
  Future<List<Lesson>> getAILessonsFromFirestore({bool forceRefresh = false}) async {
    try {
      // Initialize database for caching
      await _databaseService.initialize();

      // Try to load from local cache first (unless force refresh)
      if (!forceRefresh) {
        final cachedLessons = await _loadAILessonsFromCache();
        if (cachedLessons.isNotEmpty) {
          debugPrint('Loaded ${cachedLessons.length} AI lessons from local cache (no Firestore read)');
          return cachedLessons;
        }
      }

      // No cache or force refresh - load from Firestore
      if (!FirebaseService.isInitialized) {
        debugPrint('Firebase not initialized, returning empty AI lessons');
        return [];
      }

      debugPrint('Fetching AI lessons from Firestore...');
      final lessonData = await _firebaseService.getAILessonsFromFirestore();
      final lessons = lessonData
          .map((data) {
            try {
              // Deep convert Map<dynamic, dynamic> to Map<String, dynamic>
              final Map<String, dynamic> stringData = _deepConvertMap(data);
              return Lesson.fromJson(stringData);
            } catch (e) {
              debugPrint('Error parsing AI lesson from Firestore: $e');
              return null;
            }
          })
          .whereType<Lesson>()
          .toList();

      debugPrint('Loaded ${lessons.length} AI lessons from Firestore');

      // Save to local cache for next time
      if (lessons.isNotEmpty) {
        await _saveAILessonsToCache(lessons);
        debugPrint('Cached ${lessons.length} AI lessons locally');
      }

      return lessons;
    } catch (e) {
      debugPrint('Error loading AI lessons: $e');

      // Fallback to cache on error
      try {
        final cachedLessons = await _loadAILessonsFromCache();
        if (cachedLessons.isNotEmpty) {
          debugPrint('Using cached AI lessons due to Firestore error');
          return cachedLessons;
        }
      } catch (cacheError) {
        debugPrint('Cache fallback also failed: $cacheError');
      }

      return [];
    }
  }

  /// Load AI lessons from local cache
  Future<List<Lesson>> _loadAILessonsFromCache() async {
    try {
      await _databaseService.initialize();

      // Get all lessons stored locally with 'ai_' prefix
      final allLessonsJson = await _databaseService.getAILessonsFromCache();

      final lessons = allLessonsJson
          .map((json) {
            try {
              return Lesson.fromJson(json);
            } catch (e) {
              debugPrint('Error parsing cached lesson: $e');
              return null;
            }
          })
          .whereType<Lesson>()
          .toList();

      return lessons;
    } catch (e) {
      debugPrint('Error loading from cache: $e');
      return [];
    }
  }

  /// Save AI lessons to local cache
  Future<void> _saveAILessonsToCache(List<Lesson> lessons) async {
    try {
      await _databaseService.initialize();

      // Clear old cached AI lessons first
      await _databaseService.clearAILessonsCache();

      // Save each lesson to cache
      for (final lesson in lessons) {
        await _databaseService.cacheAILesson(lesson.toJson());
      }
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  /// Delete a lesson by ID
  /// Returns true if deletion was successful, false otherwise
  Future<bool> deleteLesson(String lessonId) async {
    await initialize();

    try {
      // First, check if it's a hardcoded lesson
      final hardcodedIndex =
          _lessons.indexWhere((lesson) => lesson.id == lessonId);
      if (hardcodedIndex != -1) {
        _lessons.removeAt(hardcodedIndex);
        debugPrint('Deleted hardcoded lesson: $lessonId');
        return true;
      }

      // Check if it's an AI-generated lesson (matches pattern: ai_<subject>_g<grade>_<timestamp>)
      if (lessonId.startsWith('ai_')) {
        // Delete from Firestore
        if (FirebaseService.isInitialized) {
          try {
            await _firebaseService.deleteAILesson(lessonId);
            debugPrint('Deleted AI lesson from Firestore: $lessonId');
          } catch (e) {
            debugPrint('Error deleting AI lesson from Firestore: $e');
            return false;
          }
        }

        // Delete from local cache
        await _databaseService.initialize();
        await _databaseService.deleteCachedAILesson(lessonId);

        // Delete associated questions from local database
        final allQuestions = _databaseService.getAllQuestions();
        for (final question in allQuestions) {
          if (question.id.startsWith(lessonId)) {
            await _databaseService.deleteQuestion(question.id);
          }
        }

        debugPrint('Deleted AI lesson: $lessonId');
        return true;
      }

      // Check if it's from question bank (matches pattern: qb_<subject>_<grade>_<topic>)
      if (lessonId.startsWith('qb_')) {
        // For question bank lessons, we need to delete the underlying questions
        // Parse the lesson ID to get subject, grade, and topic
        // Format: qb_<subject>_<grade>_<topic>
        final parts = lessonId.replaceFirst('qb_', '').split('_');
        if (parts.length >= 3) {
          final subject = parts[0];
          final gradeStr = parts[1].replaceAll('grade', '');
          final grade = int.tryParse(gradeStr) ?? 0;
          final topic = parts.sublist(2).join('_');

          // Delete questions from local database that match this lesson
          await _databaseService.initialize();
          final allQuestions = _databaseService.getAllQuestions();
          for (final question in allQuestions) {
            if (question.subject.toLowerCase() == subject.toLowerCase() &&
                question.gradeLevel == grade &&
                question.topic.toLowerCase() == topic.toLowerCase()) {
              await _databaseService.deleteQuestion(question.id);
            }
          }

          // Delete from Firestore if available
          if (FirebaseService.isInitialized) {
            try {
              await _firebaseService.deleteQuestionsForLesson(
                  subject, grade, topic);
            } catch (e) {
              debugPrint('Error deleting from Firestore: $e');
            }
          }

          debugPrint('Deleted question bank lesson: $lessonId');
          return true;
        }
      }

      debugPrint('Lesson not found: $lessonId');
      return false;
    } catch (e) {
      debugPrint('Error deleting lesson: $e');
      return false;
    }
  }

  /// Generate lessons from question bank (database + Firestore)
  Future<List<Lesson>> getLessonsFromQuestionBank() async {
    try {
      // Initialize database
      await _databaseService.initialize();

      List<Question> allQuestions = [];

      // Load from local database
      allQuestions.addAll(_databaseService.getAllQuestions());

      // Load from Firestore if initialized
      if (FirebaseService.isInitialized) {
        try {
          final firestoreData = await _firebaseService.getQuestionsFromBank();
          final firestoreQuestions = firestoreData
              .map((data) {
                try {
                  // Deep convert Map<dynamic, dynamic> to Map<String, dynamic>
                  final Map<String, dynamic> stringData = _deepConvertMap(data);
                  return Question.fromJson(stringData);
                } catch (e) {
                  debugPrint('Error parsing question from Firestore: $e');
                  return null;
                }
              })
              .whereType<Question>()
              .toList();

          // Deduplicate - Firestore takes priority
          final questionMap = <String, Question>{};
          for (final q in allQuestions) {
            questionMap[q.id] = q;
          }
          for (final q in firestoreQuestions) {
            questionMap[q.id] = q;
          }
          allQuestions = questionMap.values.toList();
        } catch (e) {
          debugPrint('Error loading from Firestore: $e');
        }
      }

      if (allQuestions.isEmpty) {
        return [];
      }

      // Group questions by subject and grade
      final lessonsMap = <String, List<Question>>{};
      for (final question in allQuestions) {
        final key = '${question.subject}_Grade${question.gradeLevel}';
        lessonsMap.putIfAbsent(key, () => []);
        lessonsMap[key]!.add(question);
      }

      // Convert to lessons
      final lessons = <Lesson>[];
      lessonsMap.forEach((key, questions) {
        if (questions.isEmpty) return;

        final subject = questions.first.subject;
        final gradeLevel = questions.first.gradeLevel;

        // Group by difficulty
        final easyQuestions = questions
            .where((q) =>
                q.difficulty == DifficultyTag.veryEasy ||
                q.difficulty == DifficultyTag.easy)
            .toList();
        final mediumQuestions = questions
            .where((q) => q.difficulty == DifficultyTag.medium)
            .toList();
        final hardQuestions = questions
            .where((q) =>
                q.difficulty == DifficultyTag.hard ||
                q.difficulty == DifficultyTag.veryHard)
            .toList();

        // Create lessons for each difficulty level
        if (easyQuestions.isNotEmpty) {
          lessons.add(_createLessonFromQuestions(
            questions: easyQuestions.take(10).toList(),
            subject: subject,
            gradeLevel: gradeLevel,
            difficulty: DifficultyLevel.beginner,
            suffix: 'Beginner',
          ));
        }

        if (mediumQuestions.isNotEmpty) {
          lessons.add(_createLessonFromQuestions(
            questions: mediumQuestions.take(10).toList(),
            subject: subject,
            gradeLevel: gradeLevel,
            difficulty: DifficultyLevel.intermediate,
            suffix: 'Intermediate',
          ));
        }

        if (hardQuestions.isNotEmpty) {
          lessons.add(_createLessonFromQuestions(
            questions: hardQuestions.take(10).toList(),
            subject: subject,
            gradeLevel: gradeLevel,
            difficulty: DifficultyLevel.advanced,
            suffix: 'Advanced',
          ));
        }
      });

      return lessons;
    } catch (e) {
      debugPrint('Error generating lessons from question bank: $e');
      return [];
    }
  }

  /// Create a lesson from a list of questions
  Lesson _createLessonFromQuestions({
    required List<Question> questions,
    required String subject,
    required int gradeLevel,
    required DifficultyLevel difficulty,
    required String suffix,
  }) {
    final exercises = questions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;

      return Exercise(
        questionNumber: index + 1,
        questionText: question.questionText,
        inputType: _getInputTypeFromQuestionType(question.questionType),
        answerKey: question.answerKey,
        explanation: question.explanation,
      );
    }).toList();

    return Lesson(
      id: 'qb_${subject}_g${gradeLevel}_${difficulty.name}_${DateTime.now().millisecondsSinceEpoch}',
      lessonTitle: '$subject - Grade $gradeLevel ($suffix)',
      targetLanguage: questions.first.targetLanguage,
      subject: subject,
      gradeLevel: gradeLevel,
      topic: questions.first.topic,
      subtopic: questions.first.subtopic,
      learningObjective: 'Master ${questions.first.topic} concepts',
      standardPencapaian: 'Question Bank Practice',
      difficulty: difficulty,
      exercises: exercises,
      estimatedDuration: exercises.length * 2, // 2 minutes per question
    );
  }

  String _getInputTypeFromQuestionType(QuestionType type) {
    switch (type) {
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

  /// Get lesson by ID
  Future<Lesson?> getLessonById(String id) async {
    await initialize();
    try {
      return _lessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update exercise progress
  Future<void> updateExerciseProgress(String lessonId, int exerciseNumber,
      String userAnswer, bool isCorrect) async {
    await initialize();

    final lessonIndex = _lessons.indexWhere((lesson) => lesson.id == lessonId);
    if (lessonIndex == -1) return;

    final lesson = _lessons[lessonIndex];
    final exerciseIndex = lesson.exercises
        .indexWhere((ex) => ex.questionNumber == exerciseNumber);
    if (exerciseIndex == -1) return;

    final updatedExercise = lesson.exercises[exerciseIndex].copyWith(
      userAnswer: userAnswer,
      isCompleted: true,
      isCorrect: isCorrect,
    );

    final updatedExercises = List<Exercise>.from(lesson.exercises);
    updatedExercises[exerciseIndex] = updatedExercise;

    final completedCount =
        updatedExercises.where((ex) => ex.isCompleted).length;
    final isLessonCompleted = completedCount == updatedExercises.length;

    final updatedLesson = lesson.copyWith(
      exercises: updatedExercises,
      completedExercises: completedCount,
      isCompleted: isLessonCompleted,
    );

    _lessons[lessonIndex] = updatedLesson;
  }

  /// Get lesson progress
  Future<Map<String, dynamic>> getLessonProgress(String lessonId) async {
    final lesson = await getLessonById(lessonId);
    if (lesson == null) {
      return {'progress': 0.0, 'completed': 0, 'total': 0};
    }

    return {
      'progress': lesson.progressPercentage,
      'completed': lesson.completedExercises,
      'total': lesson.exercises.length,
      'isCompleted': lesson.isCompleted,
    };
  }

  /// Create the math money lesson from the provided JSON
  Lesson _createMathMoneyLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "Encik Ali membeli sebuah basikal dengan harga RM350. Dia menjualnya dengan keuntungan 20%. Berapakah harga jual basikal itu?",
        inputType: "text",
        answerKey: "RM420",
        explanation:
            "Keuntungan = 20% × RM350 = RM70.\nHarga jual = RM350 + RM70 = RM420.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "Puan Siti membeli beras sebanyak 10 kg dengan harga RM25. Dia menjual semula dengan harga RM3.00 sekilogram. Berapakah keuntungannya?",
        inputType: "text",
        answerKey: "RM5",
        explanation:
            "Harga jual = 10 kg × RM3 = RM30.\nUntung = RM30 – RM25 = RM5.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "Sebuah beg tangan dijual dengan harga RM180 selepas diberi diskaun 10%. Berapakah harga asal beg itu?",
        inputType: "text",
        answerKey: "RM200",
        explanation:
            "Harga selepas diskaun = 90% daripada harga asal.\n90% × H = RM180 → H = RM180 ÷ 0.9 = RM200.",
      ),
      const Exercise(
        questionNumber: 4,
        questionText:
            "Faedah mudah 5% setahun dikenakan ke atas pinjaman RM2 000 selama 2 tahun. Berapakah jumlah faedah yang perlu dibayar?",
        inputType: "text",
        answerKey: "RM200",
        explanation: "Faedah = 5% × RM2 000 × 2 = 0.05 × 2 000 × 2 = RM200.",
      ),
      const Exercise(
        questionNumber: 5,
        questionText:
            "Sebuah telefon bimbit dijual dengan kerugian 15%. Jika harga kos ialah RM1 200, berapakah harga jualnya?",
        inputType: "text",
        answerKey: "RM1 020",
        explanation:
            "Kerugian = 15% × RM1 200 = RM180.\nHarga jual = RM1 200 – RM180 = RM1 020.",
      ),
    ];

    return Lesson(
      id: "math_money_grade6",
      lessonTitle: "Penyelesaian Masalah Harian: Wang dan Peratus",
      targetLanguage: "Malay",
      gradeLevel: 6,
      subject: "Matematik",
      topic: "Wang",
      subtopic:
          "Harga Jual, Untung, Rugi, Diskaun, Faedah & Cukai Perkhidmatan",
      learningObjective:
          "Murid dapat menyelesaikan masalah harian melibatkan pengurusan kewangan seperti harga kos, harga jual, untung, rugi, diskaun, faedah dan cukai perkhidmatan.",
      standardPencapaian:
          "3.3.1 Menyelesaikan masalah harian melibatkan harga kos, harga jual, untung, rugi, diskaun, rebat, baucer, bil, resit, invois, aset, liabiliti, faedah, dividen dan cukai perkhidmatan, pengurusan kewangan dan risiko dalam situasi harian.",
      exercises: exercises,
      difficulty: DifficultyLevel.intermediate,
      estimatedDuration: 45,
    );
  }

  /// Create additional math lessons
  Lesson _createMathFractionsLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText: "What is 1/2 + 1/4?",
        inputType: "text",
        answerKey: "3/4",
        explanation:
            "To add fractions, find common denominator: 2/4 + 1/4 = 3/4",
      ),
      const Exercise(
        questionNumber: 2,
        questionText: "Which is bigger: 1/3 or 2/5?",
        inputType: "text",
        answerKey: "2/5",
        explanation:
            "Convert to common denominator: 1/3 = 5/15, 2/5 = 6/15. So 2/5 is bigger.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText: "Simplify 6/9",
        inputType: "text",
        answerKey: "2/3",
        explanation:
            "Divide both numerator and denominator by 3: 6÷3 = 2, 9÷3 = 3",
      ),
    ];

    return Lesson(
      id: "math_fractions_grade3",
      lessonTitle: "Understanding Fractions",
      targetLanguage: "English",
      gradeLevel: 3,
      subject: "Math",
      topic: "Fractions",
      subtopic: "Basic Fraction Operations",
      learningObjective:
          "Students can add, compare, and simplify basic fractions",
      standardPencapaian:
          "Understand and work with fractions in everyday situations",
      exercises: exercises,
      difficulty: DifficultyLevel.beginner,
      estimatedDuration: 25,
    );
  }

  Lesson _createMathMultiplicationLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText: "What is 7 × 8?",
        inputType: "text",
        answerKey: "56",
        explanation:
            "7 × 8 = 56. You can think of it as 7 groups of 8, or 8 groups of 7.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText: "If one book costs RM5, how much do 6 books cost?",
        inputType: "text",
        answerKey: "RM30",
        explanation:
            "6 × RM5 = RM30. Multiply the number of books by the cost per book.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText: "What is 12 × 9?",
        inputType: "text",
        answerKey: "108",
        explanation:
            "12 × 9 = 108. You can break this down: 12 × 10 = 120, then subtract 12 to get 108.",
      ),
    ];

    return Lesson(
      id: "math_multiplication_grade4",
      lessonTitle: "Multiplication Mastery",
      targetLanguage: "English",
      gradeLevel: 4,
      subject: "Math",
      topic: "Multiplication",
      subtopic: "Times Tables and Word Problems",
      learningObjective:
          "Students can solve multiplication problems and apply them to real-world situations",
      standardPencapaian:
          "Master multiplication facts and solve word problems involving multiplication",
      exercises: exercises,
      difficulty: DifficultyLevel.intermediate,
      estimatedDuration: 30,
    );
  }

  /// Reset all lesson progress
  Future<void> resetProgress() async {
    await initialize();
    for (int i = 0; i < _lessons.length; i++) {
      final lesson = _lessons[i];
      final resetExercises = lesson.exercises
          .map((ex) => ex.copyWith(
                userAnswer: null,
                isCompleted: false,
                isCorrect: false,
              ))
          .toList();

      _lessons[i] = lesson.copyWith(
        exercises: resetExercises,
        completedExercises: 0,
        isCompleted: false,
      );
    }
  }

  // Time Zones Lessons
  Lesson _createTimeZonesBeginnerLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "If it is 8:00 AM in Kuala Lumpur (UTC+8), what time is it in London (UTC+0)?",
        inputType: "text",
        answerKey: "00:00",
        explanation:
            "London is 8 hours behind Kuala Lumpur. To find the time in London, subtract 8 hours from the time in Kuala Lumpur: 8:00 AM - 8 hours = 12:00 AM (midnight).",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "Sarah calls her friend in New York (UTC-5) at 7:00 PM Malaysian time (UTC+8). What time is it in New York when she calls?",
        inputType: "text",
        answerKey: "6:00 AM",
        explanation:
            "New York is 13 hours behind Malaysia (8 - (-5) = 13). Subtract 13 hours from 7:00 PM: 7:00 PM - 13 hours = 6:00 AM the next day.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "It is 11:00 AM on Friday in Paris (UTC+1). What time and day is it in Los Angeles (UTC-8)?",
        inputType: "text",
        answerKey: "2:00 AM Friday",
        explanation:
            "Los Angeles is 9 hours behind Paris (1 - (-8) = 9). Subtract 9 hours from 11:00 AM Friday: 11:00 AM - 9 hours = 2:00 AM on the same day, Friday.",
      ),
      const Exercise(
        questionNumber: 4,
        questionText:
            "A live sports broadcast starts at 7:30 PM in London (UTC+0). What time should viewers in Malaysia (UTC+8) tune in?",
        inputType: "text",
        answerKey: "3:30 AM",
        explanation:
            "Malaysia is 8 hours ahead of London. Add 8 hours to the broadcast time: 7:30 PM + 8 hours = 3:30 AM the next day.",
      ),
    ];

    return Lesson(
      id: "time_zones_beginner",
      lessonTitle: "Time Zones: Beginner Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Time and Time Zones",
      subtopic: "Basic Time Zone Calculations",
      learningObjective:
          "To understand and calculate time differences between different time zones.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Time and Time Zones (Beginner)",
      exercises: exercises,
      difficulty: DifficultyLevel.beginner,
      estimatedDuration: 25,
    );
  }

  Lesson _createTimeZonesIntermediateLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "If a train leaves Berlin (UTC+1) at 10:00 PM and travels for 8 hours to arrive in Moscow (UTC+3), what is the local arrival time in Moscow?",
        inputType: "text",
        answerKey: "8:00 AM",
        explanation:
            "Moscow is 2 hours ahead of Berlin. The arrival time in Berlin would be 10:00 PM + 8 hours = 6:00 AM. In Moscow, add the 2-hour difference: 6:00 AM + 2 hours = 8:00 AM.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "A business call is planned between Singapore (UTC+8) at 4:00 PM and Toronto (UTC-5). What time will it be in Toronto?",
        inputType: "text",
        answerKey: "3:00 AM",
        explanation:
            "Toronto is 13 hours behind Singapore (8 - (-5) = 13). Subtract 13 hours from 4:00 PM: 4:00 PM - 13 hours = 3:00 AM the next day.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "An international conference is held simultaneously at 9:00 AM in Hong Kong (UTC+8) and in a European city at 2:00 AM. What is the UTC offset of that European city?",
        inputType: "text",
        answerKey: "UTC+1",
        explanation:
            "Convert Hong Kong time to UTC: 9:00 AM - 8 hours = 1:00 AM UTC. If the European city shows 2:00 AM at the same moment, it is 1 hour ahead of UTC, making it UTC+1.",
      ),
    ];

    return Lesson(
      id: "time_zones_intermediate",
      lessonTitle: "Time Zones: Intermediate Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Time and Time Zones",
      subtopic: "Travel Times and International Coordination",
      learningObjective:
          "To solve intermediate problems involving travel times and international business coordination.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Time and Time Zones (Intermediate)",
      exercises: exercises,
      difficulty: DifficultyLevel.intermediate,
      estimatedDuration: 30,
    );
  }

  Lesson _createTimeZonesAdvancedLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "A flight departs from Tokyo (UTC+9) at 3:00 PM and arrives in Dubai (UTC+4) after a 12-hour journey. What is the local arrival time in Dubai?",
        inputType: "text",
        answerKey: "10:00 PM",
        explanation:
            "First, calculate the departure time in UTC: 3:00 PM (Tokyo) - 9 hours = 6:00 AM UTC. Add the flight duration: 6:00 AM + 12 hours = 6:00 PM UTC. Convert to Dubai's local time: 6:00 PM UTC + 4 hours = 10:00 PM.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "An online meeting is scheduled for 2:00 PM in Sydney (UTC+10) and 9:00 AM in Mexico City. What is the time difference between these two cities?",
        inputType: "text",
        answerKey: "5 hours",
        explanation:
            "The meeting occurs simultaneously in both locations. The time difference is calculated by subtracting the earlier time from the later time: 2:00 PM - 9:00 AM = 5 hours. Sydney is 5 hours ahead of Mexico City.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "If it is currently 2:00 PM Wednesday in Sydney (UTC+10), what day and time is it in Hawaii (UTC-10)?",
        inputType: "text",
        answerKey: "6:00 PM Tuesday",
        explanation:
            "Hawaii is 20 hours behind Sydney (10 - (-10) = 20). Subtract 20 hours from 2:00 PM Wednesday: 2:00 PM - 20 hours = 6:00 PM on Tuesday.",
      ),
    ];

    return Lesson(
      id: "time_zones_advanced",
      lessonTitle: "Time Zones: Advanced Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Time and Time Zones",
      subtopic: "Complex International Travel and Date Changes",
      learningObjective:
          "To solve complex problems involving flight schedules, date line crossings, and multi-city time calculations.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Time and Time Zones (Advanced)",
      exercises: exercises,
      difficulty: DifficultyLevel.advanced,
      estimatedDuration: 30,
    );
  }

  // Measurement Lessons
  Lesson _createMeasurementBeginnerLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "A book is 2.5 cm thick. If you stack 6 books on top of each other, what is the total height of the stack?",
        inputType: "text",
        answerKey: "15 cm",
        explanation:
            "To find the total height, multiply the thickness of one book by the number of books: 2.5 cm × 6 = 15 cm.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "A rectangular garden measures 4 meters by 3 meters. What is the area of the garden in square meters?",
        inputType: "text",
        answerKey: "12",
        explanation:
            "To find the area of a rectangle, multiply length by width: 4 m × 3 m = 12 square meters.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText: "Convert 2500 milliliters to liters.",
        inputType: "text",
        answerKey: "2.5",
        explanation:
            "To convert milliliters to liters, divide by 1000: 2500 mL ÷ 1000 = 2.5 L.",
      ),
      const Exercise(
        questionNumber: 4,
        questionText:
            "A roll of wire is 50 meters long. If 18.5 meters is used, how much wire remains?",
        inputType: "text",
        answerKey: "31.5 meters",
        explanation:
            "To find the remaining wire, subtract the used length from the total: 50 m - 18.5 m = 31.5 m.",
      ),
    ];

    return Lesson(
      id: "measurement_beginner",
      lessonTitle: "Measurement: Beginner Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Measurement and Measuring",
      subtopic: "Basic Length, Area, and Volume",
      learningObjective:
          "To perform basic calculations with length, area, and volume measurements.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Measurement and Measuring (Beginner)",
      exercises: exercises,
      difficulty: DifficultyLevel.beginner,
      estimatedDuration: 25,
    );
  }

  Lesson _createMeasurementIntermediateLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "A swimming pool is 25 meters long, 10 meters wide, and 2 meters deep. How much water does it hold when full?",
        inputType: "text",
        answerKey: "500 cubic meters",
        explanation:
            "To find the volume, multiply length × width × depth: 25 m × 10 m × 2 m = 500 cubic meters.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "A piece of ribbon is 3.75 meters long. If it is cut into equal pieces, each 0.25 meters long, how many pieces will there be?",
        inputType: "text",
        answerKey: "15",
        explanation:
            "To find the number of pieces, divide the total length by the length of each piece: 3.75 m ÷ 0.25 m = 15 pieces.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "A water tank can hold 1500 liters. If water flows out at a rate of 12 liters per minute, how long will it take to empty the tank?",
        inputType: "text",
        answerKey: "125 minutes",
        explanation:
            "To find the time, divide the total volume by the rate: 1500 L ÷ 12 L/min = 125 minutes.",
      ),
      const Exercise(
        questionNumber: 4,
        questionText:
            "A cube has a side length of 4 cm. What is the volume of the cube?",
        inputType: "text",
        answerKey: "64 cubic cm",
        explanation:
            "The volume of a cube is side length cubed: 4 cm × 4 cm × 4 cm = 64 cubic cm.",
      ),
    ];

    return Lesson(
      id: "measurement_intermediate",
      lessonTitle: "Measurement: Intermediate Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Measurement and Measuring",
      subtopic: "Volume, Division, and Rate Calculations",
      learningObjective:
          "To solve problems involving volume calculations, measurement divisions, and rate calculations.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Measurement and Measuring (Intermediate)",
      exercises: exercises,
      difficulty: DifficultyLevel.intermediate,
      estimatedDuration: 30,
    );
  }

  Lesson _createMeasurementAdvancedLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "A cylindrical tank has a radius of 3 meters and a height of 8 meters. Calculate the volume of the tank using the formula V = π × r² × h. (Use π = 3.14)",
        inputType: "text",
        answerKey: "226.08 cubic meters",
        explanation:
            "Using the formula V = π × r² × h: V = 3.14 × 3² × 8 = 3.14 × 9 × 8 = 226.08 cubic meters.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "A farmer wants to fence a rectangular field that is 120 meters long and 80 meters wide. If fencing costs RM 15 per meter, what is the total cost?",
        inputType: "text",
        answerKey: "RM 6000",
        explanation:
            "First, find the perimeter: 2 × (120 + 80) = 2 × 200 = 400 meters. Then calculate the cost: 400 m × RM 15 = RM 6000.",
      ),
    ];

    return Lesson(
      id: "measurement_advanced",
      lessonTitle: "Measurement: Advanced Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Measurement and Measuring",
      subtopic: "Complex Formulas and Real-World Applications",
      learningObjective:
          "To solve advanced problems involving geometric formulas and real-world measurement applications.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Measurement and Measuring (Advanced)",
      exercises: exercises,
      difficulty: DifficultyLevel.advanced,
      estimatedDuration: 30,
    );
  }

  // Space (Geometry) Lessons
  Lesson _createSpaceBeginnerLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "A triangle has angles of 60°, 80°, and x°. What is the value of x?",
        inputType: "text",
        answerKey: "40",
        explanation:
            "The sum of angles in a triangle is 180°. So x = 180° - 60° - 80° = 40°.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText: "A circle has a radius of 7 cm. What is its diameter?",
        inputType: "text",
        answerKey: "14 cm",
        explanation: "The diameter is twice the radius: 2 × 7 cm = 14 cm.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText: "How many sides does a hexagon have?",
        inputType: "text",
        answerKey: "6",
        explanation: "A hexagon is a polygon with 6 sides.",
      ),
    ];

    return Lesson(
      id: "space_beginner",
      lessonTitle: "Space (Geometry): Beginner Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Space",
      subtopic: "Basic Shapes and Angles",
      learningObjective: "To identify basic geometric properties of 2D shapes.",
      standardPencapaian: "KSSR Year 6 Mathematics - Space (Beginner)",
      exercises: exercises,
      difficulty: DifficultyLevel.beginner,
      estimatedDuration: 25,
    );
  }

  Lesson _createSpaceIntermediateLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "A rectangular prism has a length of 8 cm, width of 5 cm, and height of 3 cm. What is its volume?",
        inputType: "text",
        answerKey: "120 cubic cm",
        explanation:
            "The volume of a rectangular prism is length × width × height: 8 cm × 5 cm × 3 cm = 120 cubic cm.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "Find the area of a circle with radius 5 cm. (Use π = 3.14)",
        inputType: "text",
        answerKey: "78.5",
        explanation:
            "The area of a circle is π × r²: 3.14 × 5² = 3.14 × 25 = 78.5 square cm.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "What is the perimeter of a square with side length 6 cm?",
        inputType: "text",
        answerKey: "24 cm",
        explanation:
            "The perimeter of a square is 4 × side length: 4 × 6 cm = 24 cm.",
      ),
      const Exercise(
        questionNumber: 4,
        questionText:
            "A cube has a side length of 3 cm. What is its surface area?",
        inputType: "text",
        answerKey: "54 square cm",
        explanation:
            "A cube has 6 faces, each with area 3² = 9 square cm. Total surface area = 6 × 9 = 54 square cm.",
      ),
    ];

    return Lesson(
      id: "space_intermediate",
      lessonTitle: "Space (Geometry): Intermediate Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Space",
      subtopic: "Area, Perimeter, and Volume Calculations",
      learningObjective:
          "To calculate area, perimeter, and volume of geometric shapes.",
      standardPencapaian: "KSSR Year 6 Mathematics - Space (Intermediate)",
      exercises: exercises,
      difficulty: DifficultyLevel.intermediate,
      estimatedDuration: 30,
    );
  }

  Lesson _createSpaceAdvancedLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "A cone has a base radius of 4 cm and a height of 9 cm. Calculate its volume using the formula V = (1/3) × π × r² × h. (Use π = 3.14)",
        inputType: "text",
        answerKey: "150.72 cubic cm",
        explanation:
            "Using the formula V = (1/3) × π × r² × h: V = (1/3) × 3.14 × 4² × 9 = (1/3) × 3.14 × 16 × 9 = 150.72 cubic cm.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "A parallelogram has a base of 12 cm and a height of 7 cm. What is its area?",
        inputType: "text",
        answerKey: "84 square cm",
        explanation:
            "The area of a parallelogram is base × height: 12 cm × 7 cm = 84 square cm.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "A sphere has a radius of 6 cm. Calculate its volume using the formula V = (4/3) × π × r³. (Use π = 3.14)",
        inputType: "text",
        answerKey: "904.32 cubic cm",
        explanation:
            "Using the formula V = (4/3) × π × r³: V = (4/3) × 3.14 × 6³ = (4/3) × 3.14 × 216 = 904.32 cubic cm.",
      ),
    ];

    return Lesson(
      id: "space_advanced",
      lessonTitle: "Space (Geometry): Advanced Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Space",
      subtopic: "Advanced 3D Shapes and Complex Formulas",
      learningObjective:
          "To solve complex problems involving 3D shapes and advanced geometric formulas.",
      standardPencapaian: "KSSR Year 6 Mathematics - Space (Advanced)",
      exercises: exercises,
      difficulty: DifficultyLevel.advanced,
      estimatedDuration: 30,
    );
  }

  // Relations and Algebra Lessons
  Lesson _createRelationsBeginnerLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText: "Simplify the ratio 24:36 to its simplest form.",
        inputType: "text",
        answerKey: "2:3",
        explanation:
            "To simplify a ratio, divide both numbers by their greatest common divisor (GCD). The GCD of 24 and 36 is 12. 24 ÷ 12 = 2 and 36 ÷ 12 = 3. So, the simplified ratio is 2:3.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "A recipe requires flour and sugar in the ratio 4:1. If 12 cups of flour are used, how many cups of sugar are needed?",
        inputType: "text",
        answerKey: "3",
        explanation:
            "The ratio 4:1 means for every 4 parts of flour, 1 part of sugar is needed. If 12 cups of flour are used, the multiplier is 12 / 4 = 3. Therefore, sugar needed = 1 × 3 = 3 cups.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "Point C is located at (5, 1) and point D is at (9, 1). What is the horizontal distance between them?",
        inputType: "text",
        answerKey: "4 units",
        explanation:
            "Since both points have the same y-coordinate (1), the distance is purely horizontal. Subtract the smaller x-coordinate from the larger one: 9 - 5 = 4 units.",
      ),
      const Exercise(
        questionNumber: 4,
        questionText: "If x + 7 = 12, what is the value of x?",
        inputType: "text",
        answerKey: "5",
        explanation: "To find x, subtract 7 from both sides: x = 12 - 7 = 5.",
      ),
    ];

    return Lesson(
      id: "relations_beginner",
      lessonTitle: "Relations and Algebra: Beginner Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Relations and Algebra",
      subtopic: "Basic Ratios and Simple Equations",
      learningObjective:
          "To understand basic concepts of ratios, coordinates, and simple algebraic equations.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Relations and Algebra (Beginner)",
      exercises: exercises,
      difficulty: DifficultyLevel.beginner,
      estimatedDuration: 25,
    );
  }

  Lesson _createRelationsIntermediateLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "The ratio of boys to girls in a class is 3:5. If there are 15 boys, how many girls are there?",
        inputType: "text",
        answerKey: "25",
        explanation:
            "The ratio 3:5 means for every 3 boys, there are 5 girls. If there are 15 boys, we can find the multiplier: 15 boys / 3 = 5. Multiply the number of girls in the ratio by this multiplier: 5 × 5 = 25 girls.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText: "Solve for y: 2y - 3 = 11",
        inputType: "text",
        answerKey: "7",
        explanation:
            "To solve for y: 2y - 3 = 11. Add 3 to both sides: 2y = 14. Divide by 2: y = 7.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "A car travels at a constant speed. If it covers 150 km in 3 hours, how far will it travel in 5 hours?",
        inputType: "text",
        answerKey: "250 km",
        explanation:
            "First find the speed: 150 km ÷ 3 hours = 50 km/h. In 5 hours: 50 km/h × 5 hours = 250 km.",
      ),
    ];

    return Lesson(
      id: "relations_intermediate",
      lessonTitle: "Relations and Algebra: Intermediate Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Relations and Algebra",
      subtopic: "Proportional Relationships and Linear Equations",
      learningObjective:
          "To solve intermediate problems involving ratios, proportions, and linear equations.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Relations and Algebra (Intermediate)",
      exercises: exercises,
      difficulty: DifficultyLevel.intermediate,
      estimatedDuration: 30,
    );
  }

  Lesson _createRelationsAdvancedLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "A map uses a scale of 1:100,000. If two buildings are 3 cm apart on the map, what is their actual distance apart in kilometers?",
        inputType: "text",
        answerKey: "3 km",
        explanation:
            "A scale of 1:100,000 means 1 cm on the map represents 100,000 cm in reality. 100,000 cm = 1 km. So, 1 cm on the map = 1 km in reality. For 3 cm: 3 × 1 km = 3 km.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "On a grid, point A is at (2, 3) and point B is at (2, 7). What is the vertical distance between point A and point B?",
        inputType: "text",
        answerKey: "4 units",
        explanation:
            "Since both points have the same x-coordinate (2), the distance between them is purely vertical. Subtract the smaller y-coordinate from the larger one: 7 - 3 = 4 units.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText: "In the equation 3(x + 4) = 21, what is the value of x?",
        inputType: "text",
        answerKey: "3",
        explanation:
            "First distribute: 3x + 12 = 21. Subtract 12 from both sides: 3x = 9. Divide by 3: x = 3.",
      ),
    ];

    return Lesson(
      id: "relations_advanced",
      lessonTitle: "Relations and Algebra: Advanced Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Relations and Algebra",
      subtopic: "Complex Scales and Algebraic Manipulation",
      learningObjective:
          "To solve advanced problems involving map scales, coordinate calculations, and algebraic equations.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Relations and Algebra (Advanced)",
      exercises: exercises,
      difficulty: DifficultyLevel.advanced,
      estimatedDuration: 30,
    );
  }

  // Statistics and Probability Lessons
  Lesson _createStatisticsBeginnerLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "A pie chart shows the favorite fruits of a group of students. If the sector for 'Apple' has a central angle of 90 degrees, what fraction of the students chose apples?",
        inputType: "text",
        answerKey: "1/4",
        explanation:
            "A full circle is 360 degrees. The fraction of the pie chart for apples is the central angle divided by 360°: 90° / 360° = 1/4.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "When rolling a fair six-sided die, is it possible to roll a 7? Explain your answer.",
        inputType: "text",
        answerKey: "No",
        explanation:
            "It is not possible to roll a 7. A standard die only has faces numbered from 1 to 6. Since 7 is not on any face, the event of rolling a 7 cannot occur; it is impossible.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "In a bag, there are 3 red balls, 5 blue balls, and 2 green balls. If you pick one ball at random, what is the probability of picking a green ball?",
        inputType: "text",
        answerKey: "2/10 or 1/5",
        explanation:
            "The total number of balls is 3 + 5 + 2 = 10. The probability of picking a green ball is the number of green balls divided by the total number of balls: 2/10, which simplifies to 1/5.",
      ),
    ];

    return Lesson(
      id: "statistics_beginner",
      lessonTitle: "Statistics and Probability: Beginner Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Statistics and Probability",
      subtopic: "Basic Probability and Data Interpretation",
      learningObjective:
          "To understand basic concepts of probability and data representation.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Statistics and Probability (Beginner)",
      exercises: exercises,
      difficulty: DifficultyLevel.beginner,
      estimatedDuration: 25,
    );
  }

  Lesson _createStatisticsIntermediateLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "In a class of 30 students, 12 students like football, 8 like basketball, and the rest like swimming. What percentage of the class likes swimming?",
        inputType: "text",
        answerKey: "33.33%",
        explanation:
            "Students who like swimming: 30 - 12 - 8 = 10 students. Percentage = (10/30) × 100% = 33.33%.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "A spinner has 4 equal sections: red, blue, green, and yellow. What is the probability of spinning either red or blue?",
        inputType: "text",
        answerKey: "1/2",
        explanation:
            "There are 2 favorable outcomes (red or blue) out of 4 possible outcomes. Probability = 2/4 = 1/2.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "The average height of 5 students is 150 cm. If 4 students have heights 145 cm, 148 cm, 152 cm, and 155 cm, what is the height of the fifth student?",
        inputType: "text",
        answerKey: "150 cm",
        explanation:
            "Total height of 5 students = 150 × 5 = 750 cm. Sum of 4 known heights = 145 + 148 + 152 + 155 = 600 cm. Height of fifth student = 750 - 600 = 150 cm.",
      ),
      const Exercise(
        questionNumber: 4,
        questionText:
            "A bag contains 6 red marbles and 4 blue marbles. What is the probability of drawing a red marble?",
        inputType: "text",
        answerKey: "3/5",
        explanation:
            "Total marbles = 6 + 4 = 10. Probability of drawing red = 6/10 = 3/5.",
      ),
    ];

    return Lesson(
      id: "statistics_intermediate",
      lessonTitle: "Statistics and Probability: Intermediate Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Statistics and Probability",
      subtopic: "Percentages, Averages, and Compound Events",
      learningObjective:
          "To solve intermediate problems involving percentages, averages, and compound probability events.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Statistics and Probability (Intermediate)",
      exercises: exercises,
      difficulty: DifficultyLevel.intermediate,
      estimatedDuration: 30,
    );
  }

  Lesson _createStatisticsAdvancedLesson() {
    final exercises = [
      const Exercise(
        questionNumber: 1,
        questionText:
            "A bag has 8 identical marbles, all of which are white. What is the probability of drawing a white marble?",
        inputType: "text",
        answerKey: "1",
        explanation:
            "Since all 8 marbles in the bag are white, every single draw will result in a white marble. An event that is guaranteed to happen has a probability of 1.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText:
            "A survey result is displayed in a pie chart. The sector for 'Reading' has a central angle of 180 degrees. What fraction of the respondents chose reading?",
        inputType: "text",
        answerKey: "1/2",
        explanation:
            "A central angle of 180 degrees represents half of a full circle (360 degrees). Therefore, the fraction of respondents who chose reading is 180° / 360° = 1/2.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText:
            "In a survey of 200 people about their favorite season, 80 chose summer, 60 chose winter, 40 chose spring, and 20 chose autumn. Create a frequency table showing the data.",
        inputType: "text",
        answerKey: "Summer: 80, Winter: 60, Spring: 40, Autumn: 20",
        explanation:
            "A frequency table lists each category and its corresponding frequency: Summer (80), Winter (60), Spring (40), Autumn (20). Total = 200 people.",
      ),
    ];

    return Lesson(
      id: "statistics_advanced",
      lessonTitle: "Statistics and Probability: Advanced Level",
      targetLanguage: "English",
      gradeLevel: 6,
      subject: "Mathematics",
      topic: "Statistics and Probability",
      subtopic: "Certainty, Data Tables, and Complex Analysis",
      learningObjective:
          "To analyze probability events, create data tables, and interpret complex statistical information.",
      standardPencapaian:
          "KSSR Year 6 Mathematics - Statistics and Probability (Advanced)",
      exercises: exercises,
      difficulty: DifficultyLevel.advanced,
      estimatedDuration: 30,
    );
  }

  // KSSR Year 1 Mathematics - Foundational Practice
  Lesson _createYear1MathFoundationalLesson() {
    final exercises = [
      // 1.0 Whole Numbers Up to 100
      const Exercise(
        questionNumber: 1,
        questionText: "How many apples are there?",
        inputType: "text",
        answerKey: "7",
        explanation:
            "The image shows a group of seven apples. Counting them one by one gives the total number.",
      ),
      const Exercise(
        questionNumber: 2,
        questionText: "Which number is bigger, 15 or 23?",
        inputType: "text",
        answerKey: "23",
        explanation:
            "When comparing two numbers, the number with the higher value is bigger. 23 is greater than 15.",
      ),
      const Exercise(
        questionNumber: 3,
        questionText: "Write the number 'forty-two' in digits.",
        inputType: "text",
        answerKey: "42",
        explanation:
            "'Forty-two' means 4 tens and 2 ones. In digits, this is written as 42.",
      ),
      const Exercise(
        questionNumber: 4,
        questionText:
            "Arrange these numbers in order from smallest to biggest: 8, 12, 5, 9.",
        inputType: "text",
        answerKey: "5, 8, 9, 12",
        explanation:
            "We compare the values of each number. The smallest is 5, then 8, then 9, and finally 12. So, the order is 5, 8, 9, 12.",
      ),
      const Exercise(
        questionNumber: 5,
        questionText:
            "There is a missing number in this sequence: 10, 12, 14, ___, 18. What is it?",
        inputType: "text",
        answerKey: "16",
        explanation:
            "The pattern shows that the numbers are increasing by 2 each time (counting by twos). After 14, adding 2 gives us 16, which comes before 18.",
      ),

      // 2.0 Basic Operations
      const Exercise(
        questionNumber: 6,
        questionText: "What is 5 + 3?",
        inputType: "text",
        answerKey: "8",
        explanation:
            "Adding 5 and 3 together means combining five objects with three more objects. The total is eight objects.",
      ),
      const Exercise(
        questionNumber: 7,
        questionText: "What is 9 - 4?",
        inputType: "text",
        answerKey: "5",
        explanation:
            "Subtracting 4 from 9 means taking away four objects from a group of nine. You are left with five objects.",
      ),
      const Exercise(
        questionNumber: 8,
        questionText:
            "There are 6 birds on a tree. 2 more birds fly onto the tree. How many birds are there now?",
        inputType: "text",
        answerKey: "8",
        explanation:
            "This is an addition problem. We start with 6 birds and add 2 more. 6 + 2 = 8. There are now 8 birds on the tree.",
      ),
      const Exercise(
        questionNumber: 9,
        questionText:
            "A child has 10 candies. She eats 3 of them. How many candies does she have left?",
        inputType: "text",
        answerKey: "7",
        explanation:
            "This is a subtraction problem. We start with 10 candies and take away 3. 10 - 3 = 7. She has 7 candies left.",
      ),
      const Exercise(
        questionNumber: 10,
        questionText:
            "Tom has some marbles. He gets 4 more marbles from his friend. Now he has 9 marbles. How many did he have at first?",
        inputType: "text",
        answerKey: "5",
        explanation:
            "We know Tom ended up with 9 marbles after receiving 4. To find out how many he had at first, we subtract the 4 he received from the total. 9 - 4 = 5. He had 5 marbles at first.",
      ),

      // 3.0 Fractions
      const Exercise(
        questionNumber: 11,
        questionText:
            "Look at the picture of a circle. If half of it is shaded, what fraction is shaded?",
        inputType: "text",
        answerKey: "one half",
        explanation:
            "When a shape is divided into two equal parts, each part is called a half. If one part is shaded, then one half of the shape is shaded.",
      ),
      const Exercise(
        questionNumber: 12,
        questionText:
            "A pizza is cut into 4 equal pieces. One piece is eaten. What fraction of the pizza is eaten?",
        inputType: "text",
        answerKey: "one quarter",
        explanation:
            "When a whole is divided into 4 equal parts, each part is called a quarter. Since one piece out of four is eaten, the fraction eaten is one quarter.",
      ),
      const Exercise(
        questionNumber: 13,
        questionText: "Draw a rectangle and shade 1/2 of it.",
        inputType: "short_answer",
        answerKey:
            "Correctly divides a rectangle into two equal parts and shades one part.",
        explanation:
            "The student must divide the rectangle into two equal halves, either vertically or horizontally, and shade exactly one of those halves.",
      ),
      const Exercise(
        questionNumber: 14,
        questionText: "Is 2/4 the same amount as 1/2? Explain why.",
        inputType: "short_answer",
        answerKey: "Yes, because two quarters make one half.",
        explanation:
            "Two quarters (2/4) cover the same area as one half (1/2). They represent the same portion of a whole when it is divided correctly.",
      ),
      const Exercise(
        questionNumber: 15,
        questionText:
            "A cake is cut into 4 equal pieces. Ali eats 1 piece and Siti eats 2 pieces. What fraction of the cake did they eat altogether?",
        inputType: "text",
        answerKey: "three quarters",
        explanation:
            "Ali ate 1 piece (1/4) and Siti ate 2 pieces (2/4). Together, they ate 1/4 + 2/4 = 3/4 of the cake.",
      ),

      // 4.0 Money
      const Exercise(
        questionNumber: 16,
        questionText:
            "What is the name of this Malaysian coin? [Image of a 50 sen coin]",
        inputType: "text",
        answerKey: "fifty sen",
        explanation:
            "The coin shown has the value of fifty cents, which is written as 50 sen in Malaysia.",
      ),
      const Exercise(
        questionNumber: 17,
        questionText: "How much money is this? [Image of a RM5 note]",
        inputType: "text",
        answerKey: "five ringgit",
        explanation:
            "The banknote shown is worth five Malaysian Ringgit, abbreviated as RM5.",
      ),
      const Exercise(
        questionNumber: 18,
        questionText:
            "You want to buy a pencil that costs 70 sen. You have a RM1 coin. How much change will you get?",
        inputType: "text",
        answerKey: "30 sen",
        explanation:
            "RM1 is equal to 100 sen. The pencil costs 70 sen. To find the change, subtract the cost from the amount paid: 100 sen - 70 sen = 30 sen.",
      ),
      const Exercise(
        questionNumber: 19,
        questionText:
            "Can you pay for a book that costs RM8 using only RM1 coins? How many do you need?",
        inputType: "text",
        answerKey: "Yes, 8 coins",
        explanation:
            "Since each RM1 coin is worth one ringgit, you would need eight RM1 coins to make a total of RM8.",
      ),
      const Exercise(
        questionNumber: 20,
        questionText:
            "Ahmad saves 10 sen every day. How much money will he have saved after one week (7 days)?",
        inputType: "text",
        answerKey: "70 sen",
        explanation:
            "Ahmad saves 10 sen per day. Over 7 days, he saves 10 sen + 10 sen + 10 sen + 10 sen + 10 sen + 10 sen + 10 sen. This can be calculated as 10 sen x 7 = 70 sen.",
      ),

      // 5.0 Time and Duration
      const Exercise(
        questionNumber: 21,
        questionText:
            "What time is it when the long hand points to 12 and the short hand points to 3?",
        inputType: "text",
        answerKey: "3 o'clock",
        explanation:
            "On an analog clock, when the minute hand (long hand) points to 12, it means zero minutes past the hour. When the hour hand (short hand) points to 3, it means it is 3 o'clock.",
      ),
      const Exercise(
        questionNumber: 22,
        questionText: "Name the day that comes after Tuesday.",
        inputType: "text",
        answerKey: "Wednesday",
        explanation:
            "The days of the week in order are Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday. The day after Tuesday is Wednesday.",
      ),
      const Exercise(
        questionNumber: 23,
        questionText:
            "Look at the clock. The long hand is on 6 and the short hand is between 4 and 5. What time is it?",
        inputType: "text",
        answerKey: "half past four",
        explanation:
            "When the minute hand points to 6, it means 30 minutes have passed (half an hour). The hour hand between 4 and 5 indicates it is 4 o'clock. So, the time is half past four, or 4:30.",
      ),
      const Exercise(
        questionNumber: 24,
        questionText:
            "Put these events in the correct order: Going to school, Eating breakfast, Waking up.",
        inputType: "text",
        answerKey: "Waking up, Eating breakfast, Going to school",
        explanation:
            "The logical sequence of daily events is to wake up first, then eat breakfast, and finally go to school.",
      ),
      const Exercise(
        questionNumber: 25,
        questionText: "If today is Friday, what day will it be in 3 days?",
        inputType: "text",
        answerKey: "Monday",
        explanation:
            "Starting from Friday: Day 1 is Saturday, Day 2 is Sunday, and Day 3 is Monday. So, in 3 days, it will be Monday.",
      ),

      // 6.0 Measurement and Size
      const Exercise(
        questionNumber: 26,
        questionText: "Which object is longer: a pencil or a ruler?",
        inputType: "text",
        answerKey: "ruler",
        explanation:
            "A standard ruler is typically 30 centimeters long, while a pencil is usually about 15-20 centimeters long. Therefore, a ruler is longer than a pencil.",
      ),
      const Exercise(
        questionNumber: 27,
        questionText: "Which container holds more water: a cup or a bucket?",
        inputType: "text",
        answerKey: "bucket",
        explanation:
            "A bucket is much larger in size than a cup. It can hold a significantly greater volume of liquid, so it holds more water.",
      ),
      const Exercise(
        questionNumber: 28,
        questionText:
            "Use paper clips to measure the length of your pencil. About how many paper clips long is it?",
        inputType: "text",
        answerKey: "Answers will vary based on the actual measurement.",
        explanation:
            "This is a practical activity. The student should place paper clips end-to-end along the length of the pencil and count how many are needed to cover its entire length.",
      ),
      const Exercise(
        questionNumber: 29,
        questionText:
            "Compare the weight of a book and a feather. Which one is heavier?",
        inputType: "text",
        answerKey: "book",
        explanation:
            "A book is made of many pages and a cover, giving it significant mass. A feather is very light and airy. Therefore, a book is much heavier than a feather.",
      ),
      const Exercise(
        questionNumber: 30,
        questionText:
            "You have two glasses of the same size. Glass A is full of water. Glass B is half full of water. Which glass has less water?",
        inputType: "text",
        answerKey: "Glass B",
        explanation:
            "Glass A contains the maximum amount of water it can hold. Glass B contains only half of that amount. Therefore, Glass B has less water than Glass A.",
      ),

      // 7.0 Space
      const Exercise(
        questionNumber: 31,
        questionText: "What is the name of this 3D shape? [Image of a cube]",
        inputType: "text",
        answerKey: "cube",
        explanation:
            "A cube is a 3D shape that has six square faces, all of which are the same size.",
      ),
      const Exercise(
        questionNumber: 32,
        questionText:
            "What is the name of this 2D shape? [Image of a triangle]",
        inputType: "text",
        answerKey: "triangle",
        explanation:
            "A triangle is a 2D shape that has three straight sides and three corners (vertices).",
      ),
      const Exercise(
        questionNumber: 33,
        questionText: "How many flat faces does a cylinder have?",
        inputType: "text",
        answerKey: "2",
        explanation:
            "A cylinder has two flat circular faces, one at the top and one at the bottom. The side is curved.",
      ),
      const Exercise(
        questionNumber: 34,
        questionText: "How many corners (vertices) does a square have?",
        inputType: "text",
        answerKey: "4",
        explanation:
            "A square is a type of quadrilateral. It has four straight sides and four corners where the sides meet.",
      ),
      const Exercise(
        questionNumber: 35,
        questionText:
            "Imagine building a robot using 3D shapes. Name two different 3D shapes you could use for its body and head.",
        inputType: "short_answer",
        answerKey: "e.g., Cube for body, sphere for head",
        explanation:
            "Students can be creative. Common answers include using a cuboid or cube for the body and a sphere for the head. Any two appropriate 3D shapes are acceptable.",
      ),

      // 8.0 Data Management
      const Exercise(
        questionNumber: 36,
        questionText: "Look at the pictograph. How many children like apples?",
        inputType: "text",
        answerKey: "6",
        explanation:
            "In the pictograph, each apple picture represents one child. By counting the number of apple pictures, we see there are 6, meaning 6 children like apples.",
      ),
      const Exercise(
        questionNumber: 37,
        questionText:
            "In the pictograph, which fruit is liked by the most children?",
        inputType: "text",
        answerKey: "banana",
        explanation:
            "By counting the symbols for each fruit, bananas have the highest number of pictures, indicating it is the most popular fruit.",
      ),
      const Exercise(
        questionNumber: 38,
        questionText:
            "You ask your classmates what their favorite color is. How can you collect this information?",
        inputType: "short_answer",
        answerKey: "Ask each classmate and write down their answer.",
        explanation:
            "Data collection involves gathering information. For this question, the method is to survey the classmates by asking them directly and recording their responses.",
      ),
      const Exercise(
        questionNumber: 39,
        questionText:
            "In the pictograph, 8 children like oranges and 4 children like grapes. How many more children like oranges than grapes?",
        inputType: "text",
        answerKey: "4",
        explanation:
            "To find the difference, subtract the smaller number from the larger number: 8 (oranges) - 4 (grapes) = 4. So, 4 more children like oranges.",
      ),
      const Exercise(
        questionNumber: 40,
        questionText:
            "Create a simple pictograph to show that 3 students like cats, 5 like dogs, and 2 like birds. Use a simple symbol like a star (*) for each student.",
        inputType: "short_answer",
        answerKey: "Cats: ***\nDogs: *****\nBirds: **",
        explanation:
            "The student should list the animals and draw a symbol (like a star) for each student who likes that animal. Cats get 3 stars, Dogs get 5 stars, and Birds get 2 stars.",
      ),
    ];

    return Lesson(
      id: "year1_math_foundational",
      lessonTitle:
          "Year 1 Mathematics: Foundational Practice (Based on KSSR Curriculum)",
      targetLanguage: "English",
      gradeLevel: 1,
      subject: "Mathematics",
      topic: "Foundational Mathematics",
      subtopic: "Comprehensive Year 1 Skills",
      learningObjective:
          "To reinforce understanding of core Year 1 Mathematics topics through leveled questions ranging from basic recall to critical thinking.",
      standardPencapaian:
          "KSSR Year 1 Mathematics - Comprehensive Foundation Skills",
      exercises: exercises,
      difficulty: DifficultyLevel.beginner,
      estimatedDuration: 120, // 2 hours for 40 questions
    );
  }
}
