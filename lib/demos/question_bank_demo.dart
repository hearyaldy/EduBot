import 'package:flutter/material.dart';
import '../services/enhanced_lesson_service.dart';
import '../services/exercise_service.dart';
import '../models/lesson.dart';
import '../models/exercise.dart';

class QuestionBankDemo extends StatefulWidget {
  const QuestionBankDemo({Key? key}) : super(key: key);

  @override
  State<QuestionBankDemo> createState() => _QuestionBankDemoState();
}

class _QuestionBankDemoState extends State<QuestionBankDemo> {
  final EnhancedLessonService _enhancedService = EnhancedLessonService();
  final ExerciseService _exerciseService = ExerciseService();

  List<Lesson> _lessons = [];
  List<Exercise> _exercises = [];
  Map<String, dynamic>? _insights;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);

    try {
      await _enhancedService.initialize();
      await _loadData();
    } catch (e) {
      print('Error initializing services: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    // Get all lessons (static + dynamic)
    final lessons = await _enhancedService.getAllLessons();

    // Get insights
    final insights = await _enhancedService.getLessonInsights();

    setState(() {
      _lessons = lessons;
      _insights = insights;
    });
  }

  Future<void> _generateAdaptiveExercises() async {
    try {
      final exercises = await _exerciseService.generateAdaptiveExercises(
        gradeLevel: 1,
        subject: 'Mathematics',
        topic: 'Whole Numbers',
        studentAccuracy: 0.6, // 60% accuracy
        count: 5,
      );

      setState(() {
        _exercises = exercises;
      });

      _showSnackBar('Generated ${exercises.length} adaptive exercises!');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _generateCustomLesson() async {
    try {
      final lesson = await _enhancedService.generateCustomLesson(
        gradeLevel: 1,
        subject: 'Mathematics',
        topics: ['Whole Numbers', 'Basic Operations'],
        difficulty: DifficultyLevel.beginner,
        questionCount: 8,
        title: 'Custom Math Practice',
      );

      _showSnackBar('Generated custom lesson: ${lesson.lessonTitle}');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Bank Demo'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Card
            _buildStatsCard(),
            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 16),

            // Generated Exercises
            if (_exercises.isNotEmpty) ...[
              _buildExercisesSection(),
              const SizedBox(height: 16),
            ],

            // Available Lessons
            _buildLessonsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_insights == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question Bank Statistics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Total Lessons: ${_insights!['total_lessons']}'),
            Text('Dynamic Lessons: ${_insights!['dynamic_lessons']}'),
            Text('Static Lessons: ${_insights!['static_lessons']}'),
            Text(
                'Total Questions: ${_insights!['question_bank_stats']['total_questions']}'),
            const SizedBox(height: 8),
            Text(
              'Questions by Grade:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...(_insights!['question_bank_stats']['by_grade']
                    as Map<String, dynamic>)
                .entries
                .map((e) => Text('  Grade ${e.key}: ${e.value} questions')),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Text(
          'Demo Actions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: _generateAdaptiveExercises,
              child: const Text('Generate Adaptive Exercises'),
            ),
            ElevatedButton(
              onPressed: _generateCustomLesson,
              child: const Text('Create Custom Lesson'),
            ),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExercisesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generated Exercises (${_exercises.length})',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        ...(_exercises.map((exercise) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${exercise.questionNumber}'),
                ),
                title: Text(exercise.questionText),
                subtitle: Text('Answer: ${exercise.answerKey}'),
                trailing: const Icon(Icons.quiz),
              ),
            ))),
      ],
    );
  }

  Widget _buildLessonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Lessons (${_lessons.length})',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        ...(_lessons.take(10).map((lesson) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getDifficultyColor(lesson.difficulty),
                  child: Text('${lesson.gradeLevel}'),
                ),
                title: Text(lesson.lessonTitle),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${lesson.subject} - ${lesson.topic}'),
                    Text(
                        '${lesson.exercises.length} questions • ${lesson.durationText}'),
                  ],
                ),
                trailing: Chip(
                  label: Text(lesson.difficultyLabel),
                  backgroundColor:
                      _getDifficultyColor(lesson.difficulty).withOpacity(0.2),
                ),
              ),
            ))),
        if (_lessons.length > 10)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('... and ${_lessons.length - 10} more lessons'),
          ),
      ],
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.red;
    }
  }
}
