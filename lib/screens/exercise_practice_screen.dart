import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_card.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/lesson.dart';
import '../models/exercise.dart';
import '../models/question.dart';
import '../services/lesson_service.dart';
import '../services/student_progress_service.dart';
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
  final TextEditingController _answerController = TextEditingController();
  final PageController _pageController = PageController();

  late List<Exercise> _exercises;
  int _currentExerciseIndex = 0;
  bool _showExplanation = false;
  bool _isAnswerSubmitted = false;
  bool _isCorrect = false;
  int _correctAnswers = 0;
  DateTime? _questionStartTime; // Track when question was shown

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.lesson.exercises);
    _questionStartTime = DateTime.now(); // Start timer for first question
    _loadProgress();

    // Add listener to answer controller to update submit button state
    _answerController.addListener(() {
      setState(() {
        // This will trigger a rebuild and update the submit button state
      });
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    // Load existing progress if any
    final progress = await _lessonService.getLessonProgress(widget.lesson.id);
    setState(() {
      _correctAnswers = progress['completed'] ?? 0;
    });
  }

  Exercise get _currentExercise => _exercises[_currentExerciseIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => _showExitDialog(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Lessons',
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
                Colors.deepPurple,
              ],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lesson.lessonTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.lesson.topic} • Question ${_currentExerciseIndex + 1} of ${_exercises.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: (_currentExerciseIndex + 1) / _exercises.length,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionCard(),
                      const SizedBox(height: 16),
                      _buildAnswerInput(),
                      const SizedBox(height: 16),
                      if (_showExplanation) ...[
                        _buildExplanationCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildActionButtons(),
                      if (index == _exercises.length - 1 && _isAnswerSubmitted)
                        _buildCompletionSummary(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q${_currentExercise.questionNumber}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (_currentExercise.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentExercise.isCorrect
                        ? AppColors.success
                        : AppColors.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentExercise.isCorrect ? Icons.check : Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentExercise.isCorrect ? 'Correct' : 'Incorrect',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentExercise.questionText,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Answer',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _answerController,
            enabled: !_isAnswerSubmitted,
            decoration: InputDecoration(
              hintText: 'Enter your answer here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: _isAnswerSubmitted
                  ? (_isCorrect
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1))
                  : Colors.white,
              suffixIcon: _isAnswerSubmitted
                  ? Icon(
                      _isCorrect ? Icons.check_circle : Icons.cancel,
                      color: _isCorrect ? AppColors.success : AppColors.error,
                    )
                  : null,
            ),
            onSubmitted: (_) => _submitAnswer(),
          ),
          if (_isAnswerSubmitted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.info,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Correct Answer',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                        Text(
                          _currentExercise.answerKey,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
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

  Widget _buildExplanationCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Explanation',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _currentExercise.explanation,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!_isAnswerSubmitted) {
      return Row(
        children: [
          if (_currentExerciseIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
            ),
          if (_currentExerciseIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentExerciseIndex > 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _answerController.text.trim().isNotEmpty
                  ? _submitAnswer
                  : null,
              child: const Text('Submit Answer'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showExplanation ? null : _toggleExplanation,
            icon: Icon(
                _showExplanation ? Icons.visibility_off : Icons.visibility),
            label: Text(
                _showExplanation ? 'Hide Explanation' : 'Show Explanation'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLastQuestion ? _finishLesson : _nextQuestion,
            icon: Icon(_isLastQuestion ? Icons.check : Icons.arrow_forward),
            label: Text(_isLastQuestion ? 'Finish' : 'Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionSummary() {
    final accuracy = _exercises.isNotEmpty
        ? (_correctAnswers / _exercises.length * 100).round()
        : 0;

    return GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.celebration,
                  size: 48,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                Text(
                  'Lesson Complete!',
                  style: AppTextStyles.headline2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You scored $accuracy% accuracy',
                  style: AppTextStyles.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Lessons'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _restartLesson,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Practice Again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _isLastQuestion => _currentExerciseIndex == _exercises.length - 1;

  void _resetExercise() {
    _answerController.clear();
    _showExplanation = false;
    _isAnswerSubmitted = false;
    _isCorrect = false;
  }

  void _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) return;

    final userAnswer = _answerController.text.trim();
    final correctAnswer = _currentExercise.answerKey.trim();

    // Simple answer comparison (can be enhanced for more flexible matching)
    final isCorrect = userAnswer.toLowerCase() == correctAnswer.toLowerCase();

    // Calculate response time
    final responseTime = _questionStartTime != null
        ? DateTime.now().difference(_questionStartTime!).inSeconds
        : 0;

    setState(() {
      _isAnswerSubmitted = true;
      _isCorrect = isCorrect;
      if (isCorrect) _correctAnswers++;
    });

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

      debugPrint('✅ Progress recorded for $studentId: ${isCorrect ? "Correct" : "Incorrect"}');
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

  void _finishLesson() {
    Navigator.pop(context);
  }

  void _restartLesson() {
    setState(() {
      _currentExerciseIndex = 0;
      _correctAnswers = 0;
      _resetExercise();
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
          title: const Text('Exit Practice?'),
          content: const Text(
            'Are you sure you want to exit this practice session? Your progress will not be saved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit practice screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}
