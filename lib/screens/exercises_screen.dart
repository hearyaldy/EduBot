import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/lesson.dart';
import '../providers/app_provider.dart';
import '../services/lesson_service.dart';
import '../services/database_service.dart';
import 'exercise_practice_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final LessonService _lessonService = LessonService();
  final DatabaseService _databaseService = DatabaseService();
  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String _selectedSubject = 'All';
  int _selectedGrade = 0; // 0 means all grades

  final List<String> _subjects = [
    'All',
    'Math',
    'Mathematics',
    'Matematik',
    'Science',
    'English'
  ];
  final List<int> _grades = [0, 1, 2, 3, 4, 5, 6];

  // Subject colors and icons for kids
  final Map<String, Color> _subjectColors = {
    'Math': Colors.blue,
    'Mathematics': Colors.blue,
    'Matematik': Colors.indigo,
    'Science': Colors.green,
    'English': Colors.orange,
    'All': Colors.purple,
  };

  final Map<String, IconData> _subjectIcons = {
    'Math': Icons.calculate_rounded,
    'Mathematics': Icons.calculate_rounded,
    'Matematik': Icons.functions_rounded,
    'Science': Icons.science_rounded,
    'English': Icons.menu_book_rounded,
    'All': Icons.auto_awesome_rounded,
  };

  final Map<String, String> _subjectEmojis = {
    'Math': '🔢',
    'Mathematics': '🔢',
    'Matematik': '➕',
    'Science': '🔬',
    'English': '📚',
    'All': '✨',
  };

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lessons = await _lessonService.getAllLessons();
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to load lessons: ${e.toString()}', isError: true);
    }
  }

  List<Lesson> get _filteredLessons {
    return _lessons.where((lesson) {
      final matchesSubject = _selectedSubject == 'All' ||
          lesson.subject.toLowerCase() == _selectedSubject.toLowerCase();
      final matchesGrade =
          _selectedGrade == 0 || lesson.gradeLevel == _selectedGrade;

      return matchesSubject && matchesGrade;
    }).toList();
  }

  Color _getSubjectColor(String subject) {
    return _subjectColors[subject] ?? Colors.purple;
  }

  IconData _getSubjectIcon(String subject) {
    return _subjectIcons[subject] ?? Icons.school_rounded;
  }

  String _getSubjectEmoji(String subject) {
    return _subjectEmojis[subject] ?? '📖';
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

  IconData _getDifficultyIcon(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Icons.sentiment_satisfied_alt_rounded;
      case DifficultyLevel.intermediate:
        return Icons.sentiment_neutral_rounded;
      case DifficultyLevel.advanced:
        return Icons.local_fire_department_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade400,
              Colors.purple.shade600,
              Colors.indigo.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
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
                    child: RefreshIndicator(
                      onRefresh: _loadLessons,
                      color: Colors.purple,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilterChips(),
                            const SizedBox(height: 20),
                            _buildProgressCard(),
                            const SizedBox(height: 24),
                            if (_isLoading)
                              _buildLoadingState()
                            else if (_filteredLessons.isEmpty)
                              _buildEmptyState()
                            else
                              _buildLessonsList(),
                          ],
                        ),
                      ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
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
                    const Text(
                      'Practice Time! ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text('🎯', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Text(
                  'Let\'s learn something fun today!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Settings button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              onPressed: _showSettingsSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subject filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _subjects.map((subject) {
              final isSelected = _selectedSubject == subject;
              final color = _getSubjectColor(subject);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSubject = subject;
                    });
                  },
                  avatar: isSelected
                      ? null
                      : Text(_getSubjectEmoji(subject),
                          style: const TextStyle(fontSize: 16)),
                  label: Text(subject),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: color.withOpacity(0.1),
                  selectedColor: color,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? color : color.withOpacity(0.3),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Grade filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _grades.map((grade) {
              final isSelected = _selectedGrade == grade;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedGrade = grade;
                    });
                  },
                  avatar: isSelected
                      ? null
                      : Icon(
                          grade == 0
                              ? Icons.all_inclusive_rounded
                              : Icons.school_rounded,
                          size: 16,
                          color: Colors.indigo,
                        ),
                  label: Text(grade == 0 ? 'All Grades' : 'Grade $grade'),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.indigo,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  selectedColor: Colors.indigo,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.indigo
                          : Colors.indigo.withOpacity(0.3),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    final totalLessons = _lessons.length;
    final completedLessons =
        _lessons.where((lesson) => lesson.isCompleted).length;
    final totalExercises =
        _lessons.fold<int>(0, (sum, lesson) => sum + lesson.exercises.length);
    final completedExercises =
        _lessons.fold<int>(0, (sum, lesson) => sum + lesson.completedExercises);
    final progress =
        totalExercises > 0 ? completedExercises / totalExercises : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade400,
            Colors.indigo.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Animated progress indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'done',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Progress 🌟',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMiniStat(
                        '📚', '$completedLessons/$totalLessons lessons'),
                    const SizedBox(height: 4),
                    _buildMiniStat(
                        '✏️', '$completedExercises/$totalExercises exercises'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Motivational message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💪', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  _getMotivationalMessage(progress),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _getMotivationalMessage(double progress) {
    if (progress == 0) return 'Start your learning journey!';
    if (progress < 0.25) return 'Great start! Keep going!';
    if (progress < 0.5) return 'You\'re doing amazing!';
    if (progress < 0.75) return 'Halfway there! So proud of you!';
    if (progress < 1) return 'Almost done! You\'re a star!';
    return 'Champion! You completed everything! 🏆';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading fun lessons... 📚',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '🎒',
                style: TextStyle(fontSize: 64),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No lessons found!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your filters or check back later for new fun lessons!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSubject = 'All';
                  _selectedGrade = 0;
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🎮',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              'Available Lessons',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_filteredLessons.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(
          _filteredLessons.length,
          (index) => _buildLessonCard(_filteredLessons[index], index),
        ),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson, int index) {
    final color = _getSubjectColor(lesson.subject);
    final difficultyColor = _getDifficultyColor(lesson.difficulty);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _startLesson(lesson),
            onLongPress: () => _showLessonOptions(lesson),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with icon and badges
                  Row(
                    children: [
                      // Subject icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.8),
                              color,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getSubjectIcon(lesson.subject),
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title and topic
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.lessonTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lesson.topic,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // More options
                      IconButton(
                        onPressed: () => _showLessonOptions(lesson),
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.grey.shade400,
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tags row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(
                        lesson.subject,
                        color,
                        _getSubjectEmoji(lesson.subject),
                      ),
                      _buildTag(
                        lesson.difficultyLabel,
                        difficultyColor,
                        null,
                        icon: _getDifficultyIcon(lesson.difficulty),
                      ),
                      _buildTag(
                        'Grade ${lesson.gradeLevel}',
                        Colors.indigo,
                        '🎓',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress and info row
                  Row(
                    children: [
                      // Progress bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${lesson.exercises.length} exercises',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lesson.durationText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: lesson.progressPercentage,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withOpacity(0.8),
                                          color,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Play button or completed badge
                      if (lesson.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green.shade600,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Done!',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color.withOpacity(0.8), color],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color, String? emoji, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showLessonOptions(Lesson lesson) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getSubjectColor(lesson.subject).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSubjectIcon(lesson.subject),
                      color: _getSubjectColor(lesson.subject),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.lessonTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${lesson.exercises.length} exercises',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Options
            _buildOptionTile(
              icon: Icons.play_circle_rounded,
              iconColor: Colors.green,
              title: 'Start Lesson',
              subtitle: 'Begin practicing now',
              onTap: () {
                Navigator.pop(context);
                _startLesson(lesson);
              },
            ),
            _buildOptionTile(
              icon: Icons.restart_alt_rounded,
              iconColor: Colors.orange,
              title: 'Reset Progress',
              subtitle: 'Start this lesson from scratch',
              onTap: () {
                Navigator.pop(context);
                _resetLessonProgress(lesson);
              },
            ),
            // Only show delete option for superadmin users
            if (Provider.of<AppProvider>(context, listen: false).isSuperadmin)
              _buildOptionTile(
                icon: Icons.delete_rounded,
                iconColor: Colors.red,
                title: 'Delete Lesson',
                subtitle: 'Remove this lesson permanently',
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteLesson(lesson);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      onTap: onTap,
    );
  }

  void _confirmDeleteLesson(Lesson lesson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_forever_rounded,
                  color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            const Text('Delete Lesson?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this lesson?',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSubjectIcon(lesson.subject),
                    color: _getSubjectColor(lesson.subject),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lesson.lessonTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
                  Icon(Icons.warning_rounded, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteLesson(lesson);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    setState(() => _isLoading = true);

    try {
      // Delete the lesson using the LessonService
      final success = await _lessonService.deleteLesson(lesson.id);

      if (success) {
        // Also try to delete questions associated with this lesson from local database
        for (final exercise in lesson.exercises) {
          final questions = _databaseService.getQuestionsByFilter(
            searchText: exercise.questionText,
          );
          for (final q in questions) {
            await _databaseService.deleteQuestion(q.id);
          }
        }

        // Reload lessons to get fresh data
        await _loadLessons();
        _showSnackBar('Lesson deleted successfully! 🗑️');
      } else {
        setState(() => _isLoading = false);
        _showSnackBar('Could not find lesson to delete', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to delete lesson: $e', isError: true);
    }
  }

  Future<void> _resetLessonProgress(Lesson lesson) async {
    try {
      await _lessonService.updateExerciseProgress(
          lesson.id, 0, '', false); // Reset progress

      // Reload lessons
      await _loadLessons();
      _showSnackBar('Progress reset successfully! 🔄');
    } catch (e) {
      _showSnackBar('Failed to reset progress: $e', isError: true);
    }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.settings_rounded,
                        color: Colors.purple.shade600),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildOptionTile(
              icon: Icons.refresh_rounded,
              iconColor: Colors.blue,
              title: 'Refresh Lessons',
              subtitle: 'Reload all lessons from database',
              onTap: () {
                Navigator.pop(context);
                _loadLessons();
              },
            ),
            _buildOptionTile(
              icon: Icons.restart_alt_rounded,
              iconColor: Colors.orange,
              title: 'Reset All Progress',
              subtitle: 'Clear progress for all lessons',
              onTap: () {
                Navigator.pop(context);
                _confirmResetAllProgress();
              },
            ),
            _buildOptionTile(
              icon: Icons.filter_alt_off_rounded,
              iconColor: Colors.green,
              title: 'Clear Filters',
              subtitle: 'Show all lessons',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedSubject = 'All';
                  _selectedGrade = 0;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmResetAllProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reset All Progress?'),
          ],
        ),
        content: const Text(
          'This will reset progress for all lessons. You\'ll have to start from scratch!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _lessonService.resetProgress();
              await _loadLessons();
              _showSnackBar('All progress reset! 🔄');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _startLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExercisePracticeScreen(lesson: lesson),
      ),
    ).then((_) {
      // Refresh lessons when returning from practice
      _loadLessons();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
