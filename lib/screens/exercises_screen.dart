import 'package:flutter/material.dart';
import '../widgets/gradient_header.dart';
import '../widgets/glass_card.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';
import 'exercise_practice_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final LessonService _lessonService = LessonService();
  List<Lesson> _lessons = [];
  bool _isLoading = true;
  String _selectedSubject = 'All';
  int _selectedGrade = 0; // 0 means all grades

  final List<String> _subjects = [
    'All',
    'Math',
    'Matematik',
    'Science',
    'English'
  ];
  final List<int> _grades = [0, 1, 2, 3, 4, 5, 6];

  @override
  void initState() {
    super.initState();
    _loadLessons();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          GradientHeader(
            title: 'Practice Exercises',
            subtitle: 'Learn through structured practice',
            gradientColors: const [
              AppColors.primary,
              AppColors.secondary,
              Colors.deepPurple,
            ],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadLessons,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilters(),
                    const SizedBox(height: 20),
                    _buildStatsCard(),
                    const SizedBox(height: 20),
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
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Lessons',
            style: AppTextStyles.headline3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSubjectFilter(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGradeFilter(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubject,
              isExpanded: true,
              items: _subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grade',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedGrade,
              isExpanded: true,
              items: _grades.map((grade) {
                return DropdownMenuItem(
                  value: grade,
                  child: Text(grade == 0 ? 'All Grades' : 'Grade $grade'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGrade = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final totalLessons = _lessons.length;
    final completedLessons =
        _lessons.where((lesson) => lesson.isCompleted).length;
    final totalExercises =
        _lessons.fold<int>(0, (sum, lesson) => sum + lesson.exercises.length);
    final completedExercises =
        _lessons.fold<int>(0, (sum, lesson) => sum + lesson.completedExercises);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: AppTextStyles.headline3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Lessons',
                  '$completedLessons/$totalLessons',
                  Icons.book,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Exercises',
                  '$completedExercises/$totalExercises',
                  Icons.assignment,
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Accuracy',
                  totalExercises > 0
                      ? '${((completedExercises / totalExercises) * 100).toInt()}%'
                      : '0%',
                  Icons.trending_up,
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headline3.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gray600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading lessons...'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      child: Column(
        children: [
          const Icon(
            Icons.school_outlined,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            'No lessons found',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later for new content.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedSubject = 'All';
                _selectedGrade = 0;
              });
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Lessons (${_filteredLessons.length})',
          style: AppTextStyles.headline3.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...(_filteredLessons.map((lesson) => _buildLessonCard(lesson))),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _startLesson(lesson),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with subject and difficulty
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lesson.subject,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lesson.difficultyLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Grade ${lesson.gradeLevel}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lesson title
              Text(
                lesson.lessonTitle,
                style: AppTextStyles.headline3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Topic and subtopic
              Text(
                '${lesson.topic} • ${lesson.subtopic}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Progress bar
              if (lesson.completedExercises > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: lesson.progressPercentage,
                        backgroundColor: AppColors.gray200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          lesson.isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${lesson.completedExercises}/${lesson.exercises.length}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Bottom info row
              Row(
                children: [
                  const Icon(
                    Icons.assignment,
                    size: 16,
                    color: AppColors.gray500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${lesson.exercises.length} exercises',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.gray500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lesson.durationText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                  const Spacer(),
                  if (lesson.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Icon(
                      Icons.play_circle_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                ],
              ),
            ],
          ),
        ),
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
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
