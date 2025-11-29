import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lesson.dart';
import '../models/exercise.dart';
import '../models/question.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/admin_service.dart';
import '../utils/environment_config.dart';

class AILessonGeneratorScreen extends StatefulWidget {
  const AILessonGeneratorScreen({super.key});

  @override
  State<AILessonGeneratorScreen> createState() =>
      _AILessonGeneratorScreenState();
}

class _AILessonGeneratorScreenState extends State<AILessonGeneratorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storage = StorageService();
  final EnvironmentConfig _config = EnvironmentConfig.instance;

  // Form state
  String _selectedSubject = 'Mathematics';
  int _selectedGrade = 4;
  DifficultyLevel _selectedDifficulty = DifficultyLevel.intermediate;
  String _selectedQuestionType = 'mixed';
  String _selectedLanguage = 'English';
  String _customTopic = '';
  int _numberOfQuestions = 10;

  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String _statusMessage = '';
  List<Lesson> _generatedLessons = [];

  // Available options
  final List<String> _subjects = [
    'Mathematics',
    'Matematik',
    'Science',
    'Sains',
    'English',
    'Bahasa Melayu',
  ];

  final List<int> _grades = [1, 2, 3, 4, 5, 6];

  final Map<String, String> _questionTypes = {
    'mixed': 'Mixed (All Types)',
    'multiple_choice': 'Multiple Choice Only',
    'fill_blank': 'Fill in the Blank',
    'calculation': 'Calculation Problems',
    'true_false': 'True or False',
    'short_answer': 'Short Answer',
  };

  final Map<String, String> _languages = {
    'English': 'English',
    'Malay': 'Bahasa Malaysia',
  };

  // Subject-specific topics based on KSSR curriculum
  final Map<String, List<String>> _topicsBySubject = {
    'Mathematics': [
      'Whole Numbers',
      'Fractions',
      'Decimals',
      'Percentages',
      'Money',
      'Time',
      'Measurement',
      'Space and Geometry',
      'Statistics',
      'Algebra',
    ],
    'Matematik': [
      'Nombor Bulat',
      'Pecahan',
      'Perpuluhan',
      'Peratus',
      'Wang',
      'Masa dan Waktu',
      'Ukuran',
      'Ruang dan Geometri',
      'Statistik',
      'Algebra',
    ],
    'Science': [
      'Living Things',
      'Plants',
      'Animals',
      'Human Body',
      'Matter',
      'Energy',
      'Forces and Motion',
      'Earth and Space',
      'Technology',
      'Environment',
    ],
    'Sains': [
      'Benda Hidup',
      'Tumbuhan',
      'Haiwan',
      'Tubuh Manusia',
      'Jirim',
      'Tenaga',
      'Daya dan Gerakan',
      'Bumi dan Angkasa',
      'Teknologi',
      'Alam Sekitar',
    ],
    'English': [
      'Grammar',
      'Vocabulary',
      'Reading Comprehension',
      'Sentence Structure',
      'Tenses',
      'Parts of Speech',
      'Punctuation',
      'Synonyms and Antonyms',
    ],
    'Bahasa Melayu': [
      'Tatabahasa',
      'Perbendaharaan Kata',
      'Pemahaman',
      'Struktur Ayat',
      'Kata Nama',
      'Kata Kerja',
      'Peribahasa',
      'Simpulan Bahasa',
    ],
  };

  String _selectedTopic = 'Whole Numbers';

  // Curriculum document source reference
  static const String _curriculumSourceUrl =
      'https://drive.google.com/drive/folders/1Rj34RtvoUlS8qw60IfzwWxuwTh8Tfmds';
  static const String _curriculumSourceName = 'KSSR Curriculum Documents';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _checkAccess();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final adminService = AdminService.instance;
      if (!provider.isSuperadmin && !adminService.isAdmin) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin access required'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _isGenerating
                    ? _buildGeneratingView(isDark)
                    : _generatedLessons.isNotEmpty
                        ? _buildResultsView(isDark)
                        : _buildFormView(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade600,
            Colors.indigo.shade600,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Lesson Generator ✨',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Create 10 AI-powered lessons instantly',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Curriculum Source Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.indigo.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.library_books_rounded,
                      color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📚 $_curriculumSourceName',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Questions aligned with official Malaysian KSSR curriculum standards',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Subject Selection
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.subject_rounded,
            iconColor: Colors.blue,
            title: 'Subject',
            child: _buildDropdown(
              value: _selectedSubject,
              items: _subjects,
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value!;
                  _selectedTopic = _topicsBySubject[value]?.first ?? '';
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Topic Selection
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.topic_rounded,
            iconColor: Colors.teal,
            title: 'Topic',
            child: _buildDropdown(
              value: _selectedTopic,
              items: _topicsBySubject[_selectedSubject] ?? [],
              onChanged: (value) {
                setState(() => _selectedTopic = value!);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Custom Topic (Optional)
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.edit_note_rounded,
            iconColor: Colors.orange,
            title: 'Custom Topic (Optional)',
            subtitle: 'Add specific focus area',
            child: TextField(
              decoration: InputDecoration(
                hintText: 'e.g., "Word problems with money"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              ),
              onChanged: (value) => _customTopic = value,
            ),
          ),
          const SizedBox(height: 16),

          // Grade and Difficulty Row
          Row(
            children: [
              Expanded(
                child: _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.school_rounded,
                  iconColor: Colors.green,
                  title: 'Grade Level',
                  child: _buildDropdown(
                    value: _selectedGrade,
                    items: _grades,
                    itemBuilder: (grade) => 'Year $grade',
                    onChanged: (value) {
                      setState(() => _selectedGrade = value!);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSectionCard(
                  isDark: isDark,
                  icon: Icons.speed_rounded,
                  iconColor: Colors.red,
                  title: 'Difficulty',
                  child: _buildDropdown(
                    value: _selectedDifficulty,
                    items: DifficultyLevel.values,
                    itemBuilder: (diff) =>
                        diff.name[0].toUpperCase() + diff.name.substring(1),
                    onChanged: (value) {
                      setState(() => _selectedDifficulty = value!);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Type
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.quiz_rounded,
            iconColor: Colors.purple,
            title: 'Question Type',
            child: _buildDropdown(
              value: _selectedQuestionType,
              items: _questionTypes.keys.toList(),
              itemBuilder: (type) => _questionTypes[type] ?? type,
              onChanged: (value) {
                setState(() => _selectedQuestionType = value!);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Language Selection
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.language_rounded,
            iconColor: Colors.indigo,
            title: 'Language',
            child: _buildDropdown(
              value: _selectedLanguage,
              items: _languages.keys.toList(),
              itemBuilder: (lang) => _languages[lang] ?? lang,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Number of Questions
          _buildSectionCard(
            isDark: isDark,
            icon: Icons.format_list_numbered_rounded,
            iconColor: Colors.amber,
            title: 'Questions per Lesson',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _numberOfQuestions.toDouble(),
                    min: 5,
                    max: 20,
                    divisions: 3,
                    label: '$_numberOfQuestions questions',
                    activeColor: Colors.purple,
                    onChanged: (value) {
                      setState(() => _numberOfQuestions = value.round());
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_numberOfQuestions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade100, Colors.indigo.shade100],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.summarize_rounded,
                        color: Colors.purple.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Generation Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Subject: $_selectedSubject',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  '• Topic: $_selectedTopic${_customTopic.isNotEmpty ? " ($_customTopic)" : ""}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  '• Grade: Year $_selectedGrade',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  '• Difficulty: ${_selectedDifficulty.name}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  '• Questions: $_numberOfQuestions per lesson',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  '• Language: ${_languages[_selectedLanguage]}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Will generate 10 unique lessons',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _generateLessons,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Generate 10 AI Lessons',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(itemBuilder?.call(item) ?? item.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildGeneratingView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated AI Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 6.28,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple, Colors.indigo],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            Text(
              'Generating AI Lessons...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.purple.shade700,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _generationProgress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              '${(_generationProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(bool isDark) {
    return Column(
      children: [
        // Success Header
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.teal.shade400],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎉 Lessons Generated!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_generatedLessons.length} lessons are now available',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lessons List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _generatedLessons.length,
            itemBuilder: (context, index) {
              final lesson = _generatedLessons[index];
              return _buildLessonCard(lesson, index, isDark);
            },
          ),
        ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _generatedLessons.clear();
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Generate More'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCard(Lesson lesson, int index, bool isDark) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.red,
      Colors.amber,
      Colors.cyan,
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.shade400, color.shade600],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          lesson.lessonTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${lesson.exercises.length} questions • ${lesson.difficultyLabel}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _buildTag(lesson.subject, Colors.blue),
                _buildTag('Year ${lesson.gradeLevel}', Colors.green),
                _buildTag(lesson.topic, Colors.orange),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.check_circle_rounded,
          color: Colors.green.shade400,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _generateLessons() async {
    setState(() {
      _isGenerating = true;
      _generationProgress = 0.0;
      _statusMessage = 'Initializing AI lesson generator...';
      _generatedLessons.clear();
    });

    try {
      // Get API key
      await _storage.initialize();
      String? apiKey = _storage.getSetting<String>('user_openrouter_api_key');
      if (apiKey == null || apiKey.isEmpty) {
        apiKey = _config.openRouterApiKey;
      }

      if (apiKey.isEmpty) {
        throw Exception('OpenRouter API key not configured');
      }

      final generatedLessons = <Lesson>[];

      // Generate 10 lessons
      for (int i = 0; i < 10; i++) {
        setState(() {
          _generationProgress = (i + 0.5) / 10;
          _statusMessage =
              'Generating lesson ${i + 1} of 10...\n${_getTopicVariation(i)}';
        });

        final lesson = await _generateSingleLesson(
          apiKey: apiKey,
          lessonIndex: i + 1,
          topicVariation: _getTopicVariation(i),
        );

        if (lesson != null) {
          generatedLessons.add(lesson);

          // Save to Firebase and local database
          await _saveLessonToDatabase(lesson);
        }

        setState(() {
          _generationProgress = (i + 1) / 10;
        });
      }

      setState(() {
        _generatedLessons = generatedLessons;
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully generated ${generatedLessons.length} lessons! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTopicVariation(int index) {
    // Create variations for each lesson based on the topic
    final variations = [
      'Basic Concepts',
      'Word Problems',
      'Real-World Applications',
      'Problem Solving',
      'Practice Exercises',
      'Challenge Questions',
      'Review and Practice',
      'Advanced Applications',
      'Mixed Practice',
      'Mastery Check',
    ];
    return variations[index % variations.length];
  }

  Future<Lesson?> _generateSingleLesson({
    required String apiKey,
    required int lessonIndex,
    required String topicVariation,
  }) async {
    try {
      final prompt = _buildPrompt(lessonIndex, topicVariation);

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://edubot.app',
          'X-Title': 'EduBot - AI Lesson Generator',
        },
        body: jsonEncode({
          'model': 'google/gemma-2-9b-it',
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(),
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 4000,
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];

        if (content != null) {
          return _parseLesson(content, lessonIndex, topicVariation);
        }
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error generating lesson: $e');
    }
    return null;
  }

  String _getSystemPrompt() {
    return '''
You are an expert education content creator specializing in creating engaging lessons for primary school students (Year 1-6) following the Malaysian KSSR (Kurikulum Standard Sekolah Rendah) curriculum.

Your questions MUST be based on and aligned with the official Malaysian Ministry of Education curriculum documents and standards. Reference the KSSR curriculum framework for:
- Learning standards (Standard Pembelajaran)
- Content standards (Standard Kandungan)
- Performance standards (Standard Pencapaian)

CURRICULUM REFERENCE SOURCE:
- Official KSSR curriculum documents from Malaysian Ministry of Education
- Document source: $_curriculumSourceUrl

IMPORTANT RULES:
1. Create age-appropriate content strictly following KSSR curriculum for the specified grade level
2. Use clear, simple language appropriate for Malaysian primary school children
3. Include detailed step-by-step explanations for each answer
4. Make questions progressively challenging within the lesson
5. For multiple choice, always include 4 options (A, B, C, D)
6. Align questions with Malaysian education standards and local context
7. Use examples relevant to Malaysian culture and daily life
8. Respond ONLY with valid JSON, no markdown or extra text
''';
  }

  String _buildPrompt(int lessonIndex, String topicVariation) {
    final questionTypeInstruction = _selectedQuestionType == 'mixed'
        ? 'Mix different question types including multiple choice, fill in the blank, and calculation problems'
        : 'Use only ${_questionTypes[_selectedQuestionType]} format';

    final languageInstruction = _selectedLanguage == 'Malay'
        ? 'Generate all content in Bahasa Malaysia.'
        : 'Generate all content in English.';

    final difficultyGuide = {
      DifficultyLevel.beginner:
          'simple and straightforward, suitable for beginners',
      DifficultyLevel.intermediate:
          'moderately challenging with some problem-solving required',
      DifficultyLevel.advanced: 'challenging with complex multi-step problems',
    };

    return '''
Generate a lesson with exactly $_numberOfQuestions questions for:

Subject: $_selectedSubject
Topic: $_selectedTopic${_customTopic.isNotEmpty ? " - $_customTopic" : ""}
Subtopic Focus: $topicVariation
Grade Level: Year $_selectedGrade (Primary School - Malaysian KSSR)
Difficulty: ${difficultyGuide[_selectedDifficulty]}
$questionTypeInstruction
$languageInstruction

CURRICULUM ALIGNMENT:
- All questions MUST align with Malaysian KSSR Year $_selectedGrade curriculum standards
- Reference the official curriculum documents for $_selectedSubject
- Include content that matches the learning standards for this grade level
- Use Malaysian context (e.g., RM for money, local names, Malaysian scenarios)

Respond with this exact JSON structure (no markdown, just JSON):
{
  "lesson_title": "Engaging lesson title here",
  "learning_objective": "What students will learn",
  "questions": [
    {
      "question_number": 1,
      "question_text": "The question text here",
      "question_type": "multiple_choice|fill_blank|calculation|true_false|short_answer",
      "choices": ["A) Option 1", "B) Option 2", "C) Option 3", "D) Option 4"],
      "answer_key": "The correct answer",
      "explanation": "Detailed step-by-step explanation of how to solve this"
    }
  ]
}

For non-multiple-choice questions, leave "choices" as an empty array [].
''';
  }

  Lesson? _parseLesson(String content, int lessonIndex, String topicVariation) {
    try {
      // Clean up the response
      String cleanContent = content.trim();

      // Remove any thinking tags
      final thinkRegex = RegExp(r'<think>.*?</think>', dotAll: true);
      cleanContent = cleanContent.replaceAll(thinkRegex, '').trim();

      // Remove markdown code blocks
      if (cleanContent.startsWith('```json')) {
        cleanContent = cleanContent.substring(7);
      } else if (cleanContent.startsWith('```')) {
        cleanContent = cleanContent.substring(3);
      }
      if (cleanContent.endsWith('```')) {
        cleanContent = cleanContent.substring(0, cleanContent.length - 3);
      }
      cleanContent = cleanContent.trim();

      // Extract JSON if needed
      if (!cleanContent.startsWith('{')) {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanContent);
        if (jsonMatch != null) {
          cleanContent = jsonMatch.group(0) ?? cleanContent;
        }
      }

      final json = jsonDecode(cleanContent);

      // Parse questions
      final questionsJson = json['questions'] as List? ?? [];
      final exercises = <Exercise>[];

      for (var i = 0; i < questionsJson.length; i++) {
        final q = questionsJson[i];
        exercises.add(Exercise(
          questionNumber: i + 1,
          questionText: q['question_text'] ?? '',
          inputType: _mapQuestionType(q['question_type'] ?? 'text'),
          answerKey: q['answer_key'] ?? '',
          explanation: q['explanation'] ?? '',
        ));
      }

      final lessonId =
          'ai_${_selectedSubject.toLowerCase()}_g${_selectedGrade}_${DateTime.now().millisecondsSinceEpoch}_$lessonIndex';

      return Lesson(
        id: lessonId,
        lessonTitle:
            json['lesson_title'] ?? '$_selectedSubject - Lesson $lessonIndex',
        targetLanguage: _selectedLanguage,
        gradeLevel: _selectedGrade,
        subject: _selectedSubject,
        topic: _selectedTopic,
        subtopic: topicVariation,
        learningObjective:
            json['learning_objective'] ?? 'Master $_selectedTopic concepts',
        standardPencapaian: 'AI Generated - KSSR Year $_selectedGrade',
        exercises: exercises,
        difficulty: _selectedDifficulty,
        estimatedDuration: exercises.length * 2,
      );
    } catch (e) {
      debugPrint('Error parsing lesson: $e');
      return null;
    }
  }

  String _mapQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'multiple_choice':
        return 'multiple_choice';
      case 'true_false':
        return 'true_false';
      case 'fill_blank':
      case 'fill_in_the_blank':
        return 'text';
      case 'calculation':
        return 'text';
      case 'short_answer':
        return 'short_answer';
      default:
        return 'text';
    }
  }

  Future<void> _saveLessonToDatabase(Lesson lesson) async {
    try {
      // Save to Firestore
      if (FirebaseService.isInitialized) {
        await FirebaseService.instance.saveLessonToFirestore(lesson);
      }

      // Save questions to local database
      await _databaseService.initialize();
      for (var i = 0; i < lesson.exercises.length; i++) {
        final exercise = lesson.exercises[i];
        final question = Question(
          id: '${lesson.id}_q${i + 1}',
          questionText: exercise.questionText,
          questionType: _getQuestionTypeFromInput(exercise.inputType),
          subject: lesson.subject,
          topic: lesson.topic,
          subtopic: lesson.subtopic,
          gradeLevel: lesson.gradeLevel,
          difficulty: _getDifficultyTag(lesson.difficulty),
          answerKey: exercise.answerKey,
          explanation: exercise.explanation,
          choices: [],
          metadata: const QuestionMetadata(),
          targetLanguage: lesson.targetLanguage,
        );
        await _databaseService.saveQuestion(question);
      }

      debugPrint('Saved lesson: ${lesson.lessonTitle}');
    } catch (e) {
      debugPrint('Error saving lesson: $e');
    }
  }

  QuestionType _getQuestionTypeFromInput(String inputType) {
    switch (inputType) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueOrFalse;
      case 'short_answer':
        return QuestionType.shortAnswer;
      default:
        return QuestionType.fillInTheBlank;
    }
  }

  DifficultyTag _getDifficultyTag(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.beginner:
        return DifficultyTag.easy;
      case DifficultyLevel.intermediate:
        return DifficultyTag.medium;
      case DifficultyLevel.advanced:
        return DifficultyTag.hard;
    }
  }
}

// Extension for Color shades
extension ColorShades on Color {
  Color get shade100 => Color.lerp(this, Colors.white, 0.8)!;
  Color get shade200 => Color.lerp(this, Colors.white, 0.6)!;
  Color get shade300 => Color.lerp(this, Colors.white, 0.4)!;
  Color get shade400 => Color.lerp(this, Colors.white, 0.2)!;
  Color get shade500 => this;
  Color get shade600 => Color.lerp(this, Colors.black, 0.1)!;
  Color get shade700 => Color.lerp(this, Colors.black, 0.2)!;
  Color get shade800 => Color.lerp(this, Colors.black, 0.3)!;
  Color get shade900 => Color.lerp(this, Colors.black, 0.4)!;
}
