import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/lesson.dart';
import '../models/exercise.dart';
import '../models/question.dart';
import '../models/practice_session.dart';
import '../services/lesson_service.dart';
import '../services/student_progress_service.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../providers/app_provider.dart';

class ExercisePracticeScreen extends StatefulWidget {
  final Lesson lesson;

  const ExercisePracticeScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<ExercisePracticeScreen> createState() => _ExercisePracticeScreenState();
}

class _ExercisePracticeScreenState extends State<ExercisePracticeScreen> {
  final LessonService _lessonService = LessonService();
  final StudentProgressService _progressService = StudentProgressService();
  final AIService _aiService = AIService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _answerController = TextEditingController();
  final PageController _pageController = PageController();

  late List<Exercise> _exercises;
  int _currentExerciseIndex = 0;
  bool _showExplanation = false;
  bool _showHint = false;
  bool _isAnswerSubmitted = false;
  bool _isCorrect = false;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  int _skippedQuestions = 0;
  DateTime? _questionStartTime;

  // Practice session tracking
  PracticeSession? _currentSession;
  DateTime? _sessionStartTime;

  // AI Hints state
  bool _isLoadingAIHints = false;
  Map<String, String>? _aiHints;
  bool _aiHintsError = false;

  // Subject colors for kids
  final Map<String, Color> _subjectColors = {
    'Math': Colors.blue,
    'Mathematics': Colors.blue,
    'Matematik': Colors.indigo,
    'Science': Colors.green,
    'English': Colors.orange,
  };

  final Map<String, String> _subjectEmojis = {
    'Math': '🔢',
    'Mathematics': '🔢',
    'Matematik': '➕',
    'Science': '🔬',
    'English': '📚',
  };

  Color get _themeColor =>
      _subjectColors[widget.lesson.subject] ?? Colors.purple;
  String get _subjectEmoji => _subjectEmojis[widget.lesson.subject] ?? '📖';

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.lesson.exercises);
    _questionStartTime = DateTime.now();
    _sessionStartTime = DateTime.now();
    _loadProgress();
    _initializePracticeSession();

    _answerController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _initializePracticeSession() async {
    final appProvider = context.read<AppProvider>();
    final childProfile = appProvider.activeProfile;

    _currentSession = PracticeSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      lessonId: widget.lesson.id,
      lessonTitle: widget.lesson.lessonTitle,
      subject: widget.lesson.subject,
      topic: widget.lesson.topic,
      gradeLevel: widget.lesson.gradeLevel,
      childProfileId: childProfile?.id,
      childName: childProfile?.name,
      startTime: _sessionStartTime ?? DateTime.now(),
      totalQuestions: _exercises.length,
      correctAnswers: 0,
      incorrectAnswers: 0,
      skippedQuestions: 0,
      accuracyPercentage: 0.0,
      isCompleted: false,
    );

    debugPrint('📝 Practice session initialized: ${_currentSession?.id}');
  }

  @override
  void dispose() {
    _answerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final progress = await _lessonService.getLessonProgress(widget.lesson.id);
    setState(() {
      _correctAnswers = progress['completed'] ?? 0;
    });
  }

  Future<void> _loadAIHints() async {
    if (_aiHints != null || _isLoadingAIHints) {
      return;
    }

    final questionIndex = _currentExerciseIndex;

    setState(() {
      _isLoadingAIHints = true;
      _aiHintsError = false;
    });

    try {
      final exercise = _currentExercise;
      final hints = await _aiService.generateQuestionHints(
        questionText: exercise.questionText,
        subject: widget.lesson.subject,
        topic: widget.lesson.topic,
        answerKey: exercise.answerKey,
      );

      if (mounted && _currentExerciseIndex == questionIndex) {
        setState(() {
          _aiHints = hints;
          _isLoadingAIHints = false;
        });
      } else if (mounted) {
        // User moved to different question, just clear loading state
        setState(() {
          _isLoadingAIHints = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI hints: $e');
      if (mounted && _currentExerciseIndex == questionIndex) {
        setState(() {
          _isLoadingAIHints = false;
          _aiHintsError = true;
        });
      }
    }
  }

  Exercise get _currentExercise => _exercises[_currentExerciseIndex];

  @override
  Widget build(BuildContext context) {
    final progress = (_currentExerciseIndex + 1) / _exercises.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _themeColor.withValues(alpha: 0.9),
              _themeColor,
              _themeColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(progress),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _exercises.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentExerciseIndex = index;
                          _resetExercise();
                        });
                      },
                      itemBuilder: (context, index) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProgressCard(),
                              const SizedBox(height: 20),
                              _buildQuestionCard(),
                              const SizedBox(height: 16),
                              _buildAnswerInput(),
                              const SizedBox(height: 16),
                              if (_showHint && !_isAnswerSubmitted) ...[
                                _buildHintCard(),
                                const SizedBox(height: 16),
                              ],
                              if (_showExplanation) ...[
                                _buildExplanationCard(),
                                const SizedBox(height: 16),
                              ],
                              _buildActionButtons(),
                              if (index == _exercises.length - 1 &&
                                  _isAnswerSubmitted)
                                _buildCompletionSummary(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => _showExitDialog(),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.lesson.lessonTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_subjectEmoji,
                            style: const TextStyle(fontSize: 20)),
                      ],
                    ),
                    Text(
                      '${widget.lesson.topic} • Question ${_currentExerciseIndex + 1} of ${_exercises.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Hint button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
                    color: Colors.white,
                  ),
                  onPressed: _toggleHint,
                  tooltip: 'Show Hints',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final accuracy = _exercises.isNotEmpty && _currentExerciseIndex > 0
        ? (_correctAnswers / _currentExerciseIndex * 100).round()
        : 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _themeColor.withValues(alpha: 0.8),
            _themeColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _themeColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_subjectEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    const Text(
                      'Keep Going! 💪',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniStat('✅', '$_correctAnswers correct'),
                    const SizedBox(width: 16),
                    _buildMiniStat('📊', '$accuracy% accuracy'),
                  ],
                ),
              ],
            ),
          ),
          // Question number badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentExerciseIndex + 1}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'of ${_exercises.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _themeColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_themeColor.withValues(alpha: 0.8), _themeColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Question ${_currentExercise.questionNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_currentExercise.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentExercise.isCorrect
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _currentExercise.isCorrect
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentExercise.isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 16,
                        color: _currentExercise.isCorrect
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentExercise.isCorrect ? 'Correct!' : 'Try Again',
                        style: TextStyle(
                          color: _currentExercise.isCorrect
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _currentExercise.questionText,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to check if a choice matches the answer key
  /// Handles various formats like "A) Answer", "Answer", "A", etc.
  bool _isChoiceCorrect(String choice, String answerKey) {
    final choiceLower = choice.trim().toLowerCase();
    final answerLower = answerKey.trim().toLowerCase();

    // Direct match
    if (choiceLower == answerLower) return true;

    // Remove common prefixes like "A) ", "B. ", "1) ", etc. and compare
    final choiceWithoutPrefix = choice.replaceFirst(RegExp(r'^[A-Da-d0-9][).]\s*'), '').trim().toLowerCase();
    final answerWithoutPrefix = answerKey.replaceFirst(RegExp(r'^[A-Da-d0-9][).]\s*'), '').trim().toLowerCase();

    if (choiceWithoutPrefix == answerWithoutPrefix) return true;
    if (choiceWithoutPrefix == answerLower) return true;
    if (choiceLower == answerWithoutPrefix) return true;

    // Check if answer key is just a letter (A, B, C, D) and choice starts with it
    if (answerKey.trim().length <= 2 && choice.toLowerCase().startsWith(answerKey.toLowerCase())) {
      return true;
    }

    return false;
  }

  Widget _buildAnswerInput() {
    final hasChoices = _currentExercise.choices.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasChoices ? Icons.checklist_rounded : Icons.edit_rounded,
                  color: _themeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                hasChoices ? 'Select Your Answer ✅' : 'Your Answer ✏️',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Show multiple choice buttons if choices exist
          if (hasChoices)
            ...(_currentExercise.choices.asMap().entries.map((entry) {
              final choice = entry.value;
              final isSelected = _answerController.text == choice;
              final isCorrectChoice = _isChoiceCorrect(choice, _currentExercise.answerKey);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: _isAnswerSubmitted
                      ? null
                      : () {
                          setState(() {
                            _answerController.text = choice;
                          });
                        },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isAnswerSubmitted
                          ? (isCorrectChoice
                              ? Colors.green.shade50
                              : (isSelected ? Colors.red.shade50 : Colors.grey.shade50))
                          : (isSelected
                              ? _themeColor.withValues(alpha: 0.1)
                              : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isAnswerSubmitted
                            ? (isCorrectChoice
                                ? Colors.green
                                : (isSelected ? Colors.red : Colors.grey.shade300))
                            : (isSelected ? _themeColor : Colors.grey.shade300),
                        width: _isAnswerSubmitted && isCorrectChoice ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isAnswerSubmitted
                                ? (isCorrectChoice
                                    ? Colors.green
                                    : (isSelected ? Colors.red : Colors.grey.shade300))
                                : (isSelected ? _themeColor : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: _isAnswerSubmitted && isCorrectChoice
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : (_isAnswerSubmitted && isSelected
                                    ? const Icon(Icons.close, color: Colors.white, size: 18)
                                    : (isSelected
                                        ? const Icon(Icons.circle, color: Colors.white, size: 12)
                                        : null)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            choice,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }))
          else
            // Show text field for non-multiple choice questions
            TextField(
            controller: _answerController,
            enabled: !_isAnswerSubmitted,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Type your answer here...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _themeColor, width: 2),
              ),
              filled: true,
              fillColor: _isAnswerSubmitted
                  ? (_isCorrect ? Colors.green.shade50 : Colors.red.shade50)
                  : Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: _isAnswerSubmitted
                  ? Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isCorrect ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isCorrect ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  : null,
            ),
            onSubmitted: (_) => _submitAnswer(),
          ),
          if (_isAnswerSubmitted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Correct Answer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentExercise.answerKey,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHintCard() {
    // If AI hints are loading, show a loading indicator
    if (_isLoadingAIHints) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.purple.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI is Analyzing Your Question...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Generating personalized hints and tips...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    // Determine hint sources - prioritize AI hints, fallback to static
    String solvingSteps = '';
    String tips = '';
    String example = '';
    bool isAIPowered = false;

    if (_aiHints != null &&
        (_aiHints!['solvingSteps']?.isNotEmpty == true ||
            _aiHints!['tips']?.isNotEmpty == true ||
            _aiHints!['example']?.isNotEmpty == true)) {
      // Use AI-generated hints
      solvingSteps = _aiHints!['solvingSteps'] ?? '';
      tips = _aiHints!['tips'] ?? '';
      example = _aiHints!['example'] ?? '';
      isAIPowered = true;
    } else {
      // Fallback: Extract sections from the explanation
      final explanation = _currentExercise.explanation;

      // Define markers
      const solveMarker = '🔧 How to Solve:';
      const tipsMarker = '💡 Tips:';
      const exampleMarker = '📝 Example:';

      // Find positions of all markers
      final solvePos = explanation.indexOf(solveMarker);
      final tipsPos = explanation.indexOf(tipsMarker);
      final examplePos = explanation.indexOf(exampleMarker);
      final topicPos = explanation.indexOf('📚 Topic:');

      // Extract solving steps
      if (solvePos != -1) {
        int endPos = explanation.length;
        if (tipsPos > solvePos) endPos = tipsPos;
        solvingSteps =
            explanation.substring(solvePos + solveMarker.length, endPos).trim();
      }

      // Extract tips
      if (tipsPos != -1) {
        int endPos = explanation.length;
        if (examplePos > tipsPos) {
          endPos = examplePos;
        } else if (topicPos > tipsPos) {
          endPos = topicPos;
        }
        tips =
            explanation.substring(tipsPos + tipsMarker.length, endPos).trim();
      }

      // Extract example
      if (examplePos != -1) {
        int endPos = explanation.length;
        if (topicPos > examplePos) endPos = topicPos;
        example = explanation
            .substring(examplePos + exampleMarker.length, endPos)
            .trim();
      }
    }

    // Default content if nothing found
    if (tips.isEmpty && solvingSteps.isEmpty && example.isEmpty) {
      solvingSteps =
          '1. Read the question carefully.\n2. Identify key information.\n3. Think about what is being asked.\n4. Apply your knowledge to answer.';
      tips =
          '• Take your time to understand the question.\n• Eliminate wrong answers if multiple choice.\n• Check your answer before submitting.';
      example = 'Think step by step and apply what you have learned.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isAIPowered ? Colors.purple : Colors.amber)
                .withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAIPowered
                        ? [Colors.purple.shade400, Colors.purple.shade600]
                        : [Colors.amber.shade400, Colors.amber.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAIPowered ? Icons.auto_awesome : Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAIPowered ? 'AI-Powered Hints 🤖' : 'Hints & Tips 💡',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAIPowered
                        ? Colors.purple.shade700
                        : Colors.amber.shade700,
                  ),
                ),
              ),
              if (isAIPowered)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.purple.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_aiHintsError && !isAIPowered)
                Tooltip(
                  message: 'AI hints unavailable. Showing default hints.',
                  child: Icon(Icons.info_outline,
                      size: 16, color: Colors.grey.shade400),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Solving Steps Section
          if (solvingSteps.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'How to Solve',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    solvingSteps,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Tips Section
          if (tips.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates,
                          size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Tips',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tips,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Example Section
          if (example.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school,
                          size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Example',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    example,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Explanation 📖',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: Text(
              _currentExercise.explanation,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!_isAnswerSubmitted) {
      return Column(
        children: [
          // Navigation and submit row
          Row(
            children: [
              if (_currentExerciseIndex > 0)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _previousQuestion,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back_rounded,
                                  color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Previous',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_currentExerciseIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: _currentExerciseIndex > 0 ? 1 : 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _answerController.text.trim().isNotEmpty
                          ? [_themeColor.withValues(alpha: 0.9), _themeColor]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _answerController.text.trim().isNotEmpty
                        ? [
                            BoxShadow(
                              color: _themeColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _answerController.text.trim().isNotEmpty
                          ? _submitAnswer
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Submit Answer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _showExplanation
                    ? Colors.grey.shade300
                    : Colors.green.shade300,
              ),
            ),
            child: Material(
              color: _showExplanation ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _showExplanation ? null : _toggleExplanation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showExplanation
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: _showExplanation
                            ? Colors.grey.shade400
                            : Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showExplanation ? 'Shown' : 'Explanation',
                        style: TextStyle(
                          color: _showExplanation
                              ? Colors.grey.shade400
                              : Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_themeColor.withValues(alpha: 0.9), _themeColor],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _themeColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isLastQuestion ? _finishLesson : _nextQuestion,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isLastQuestion
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLastQuestion ? 'Finish! 🎉' : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionSummary() {
    final accuracy = _exercises.isNotEmpty
        ? (_correctAnswers / _exercises.length * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade400,
            Colors.orange.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Trophy icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '🏆',
              style: TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Awesome Job! 🎉',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lesson Complete!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('✅', '$_correctAnswers', 'Correct'),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem('📊', '$accuracy%', 'Accuracy'),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem('📚', '${_exercises.length}', 'Questions'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Home',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _restartLesson,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded,
                                color: Colors.orange.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Try Again',
                              style: TextStyle(
                                color: Colors.orange.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  bool get _isLastQuestion => _currentExerciseIndex == _exercises.length - 1;

  void _resetExercise() {
    _answerController.clear();
    _showExplanation = false;
    _showHint = false;
    _isAnswerSubmitted = false;
    _isCorrect = false;
    // Reset AI hints for new question
    _aiHints = null;
    _isLoadingAIHints = false;
    _aiHintsError = false;
  }

  void _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) return;

    final userAnswer = _answerController.text.trim();
    final correctAnswer = _currentExercise.answerKey.trim();

    // Smart answer comparison that handles different formats
    final isCorrect = _isChoiceCorrect(userAnswer, correctAnswer);

    // Calculate response time
    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inSeconds
        : 0;

    setState(() {
      _isAnswerSubmitted = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _correctAnswers++;
      } else {
        _incorrectAnswers++;
      }
    });

    // Update practice session
    _updatePracticeSession();

    // Update progress in the lesson service
    _lessonService.updateExerciseProgress(
      widget.lesson.id,
      _currentExercise.questionNumber,
      userAnswer,
      isCorrect,
    );

    // Record progress for analytics and AI learning
    try {
      // Get current child profile or use 'main_user'
      final appProvider = context.read<AppProvider>();
      final childProfile = appProvider.activeProfile;
      final studentId = childProfile?.id ?? 'main_user';

      // Convert Exercise to Question for progress tracking
      final question = Question(
        id: '${widget.lesson.id}_q${_currentExercise.questionNumber}',
        questionText: _currentExercise.questionText,
        questionType: _getQuestionType(_currentExercise.inputType),
        subject: widget.lesson.subject,
        topic: widget.lesson.topic,
        subtopic: widget.lesson.subtopic,
        gradeLevel: widget.lesson.gradeLevel,
        difficulty: _getDifficultyFromLesson(widget.lesson.difficulty),
        answerKey: _currentExercise.answerKey,
        explanation: _currentExercise.explanation,
        metadata: QuestionMetadata(
          tags: [widget.lesson.lessonTitle, 'practice'],
          estimatedTime: Duration(seconds: responseTime),
          cognitiveLevel: BloomsTaxonomy.apply,
        ),
        targetLanguage: widget.lesson.targetLanguage,
      );

      // Record the attempt for analytics
      await _progressService.recordAttempt(
        studentId: studentId,
        question: question,
        studentAnswer: userAnswer,
        responseTimeSeconds: responseTime,
        confidenceLevel: 3.0, // Default confidence
        additionalMetadata: {
          'lesson_id': widget.lesson.id,
          'lesson_title': widget.lesson.lessonTitle,
          'exercise_number': _currentExercise.questionNumber,
        },
      );

      debugPrint(
          '✅ Progress recorded for $studentId: ${isCorrect ? "Correct" : "Incorrect"}');
    } catch (e) {
      debugPrint('Failed to record progress: $e');
      // Don't block the user flow if progress recording fails
    }

    // Show feedback
    _showSnackBar(
      isCorrect
          ? 'Correct! Well done!'
          : 'Not quite right. Check the explanation.',
      isError: !isCorrect,
    );
  }

  // Helper to convert input type to QuestionType
  QuestionType _getQuestionType(String inputType) {
    switch (inputType.toLowerCase()) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueOrFalse;
      case 'short_answer':
        return QuestionType.shortAnswer;
      case 'text':
      default:
        return QuestionType.fillInTheBlank;
    }
  }

  // Helper to convert lesson difficulty to question difficulty
  DifficultyTag _getDifficultyFromLesson(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return DifficultyTag.easy;
      case DifficultyLevel.intermediate:
        return DifficultyTag.medium;
      case DifficultyLevel.advanced:
        return DifficultyTag.hard;
    }
  }

  void _toggleExplanation() {
    setState(() {
      _showExplanation = !_showExplanation;
    });
  }

  void _toggleHint() {
    setState(() {
      _showHint = !_showHint;
    });

    // Load AI hints when showing hints for the first time
    if (_showHint && _aiHints == null && !_isLoadingAIHints) {
      _loadAIHints();
    }
  }

  void _nextQuestion() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentExerciseIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishLesson() async {
    await _completePracticeSession();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _restartLesson() {
    setState(() {
      _currentExerciseIndex = 0;
      _correctAnswers = 0;
      _incorrectAnswers = 0;
      _skippedQuestions = 0;
      _resetExercise();
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    // Reinitialize practice session
    _initializePracticeSession();
  }

  void _updatePracticeSession() {
    if (_currentSession == null) return;

    final totalAnswered = _correctAnswers + _incorrectAnswers;
    final accuracy = totalAnswered > 0
        ? (_correctAnswers / totalAnswered * 100)
        : 0.0;

    _currentSession = _currentSession!.copyWith(
      correctAnswers: _correctAnswers,
      incorrectAnswers: _incorrectAnswers,
      skippedQuestions: _skippedQuestions,
      accuracyPercentage: accuracy,
    );

    debugPrint('📊 Session updated - Correct: $_correctAnswers, Incorrect: $_incorrectAnswers, Accuracy: ${accuracy.toStringAsFixed(1)}%');
  }

  Future<void> _completePracticeSession() async {
    if (_currentSession == null) return;

    try {
      final endTime = DateTime.now();
      final duration = _sessionStartTime != null
          ? endTime.difference(_sessionStartTime!)
          : Duration.zero;

      // Calculate final statistics
      final totalAnswered = _correctAnswers + _incorrectAnswers;
      _skippedQuestions = _exercises.length - totalAnswered;

      final accuracy = totalAnswered > 0
          ? (_correctAnswers / totalAnswered * 100)
          : 0.0;

      // Update session with final data
      _currentSession = _currentSession!.copyWith(
        endTime: endTime,
        correctAnswers: _correctAnswers,
        incorrectAnswers: _incorrectAnswers,
        skippedQuestions: _skippedQuestions,
        accuracyPercentage: accuracy,
        duration: duration,
        isCompleted: true,
        metadata: {
          'lesson_type': widget.lesson.id.startsWith('ai_') ? 'ai_generated' : 'standard',
          'difficulty': widget.lesson.difficulty.toString(),
          'total_time_seconds': duration.inSeconds,
        },
      );

      // Save to database
      await _databaseService.savePracticeSession(_currentSession!.toJson());

      debugPrint('✅ Practice session completed and saved:');
      debugPrint('   - Session ID: ${_currentSession!.id}');
      debugPrint('   - Lesson: ${_currentSession!.lessonTitle}');
      debugPrint('   - Score: $_correctAnswers/${_exercises.length}');
      debugPrint('   - Accuracy: ${accuracy.toStringAsFixed(1)}%');
      debugPrint('   - Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
      debugPrint('   - Performance: ${_currentSession!.performanceEmoji} ${_currentSession!.performanceLabel}');
    } catch (e) {
      debugPrint('❌ Error saving practice session: $e');
      // Don't block user from exiting even if save fails
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🚪', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              const Text('Leave Practice?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to leave?',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Your progress on this question won\'t be saved.',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Stay',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }
}
