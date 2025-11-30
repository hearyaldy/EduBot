import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/student_progress_service.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final StudentProgressService _progressService = StudentProgressService();
  bool _isLoading = true;

  // Analytics data
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  int _currentStreak = 0;
  Map<String, int> _subjectStats = {};
  Map<String, double> _subjectAccuracy = {};

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

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Implement actual analytics loading from StudentProgressService
      // For now, using mock data
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _totalQuestions = 42;
        _correctAnswers = 35;
        _currentStreak = 5;
        _subjectStats = {
          'Mathematics': 20,
          'Science': 15,
          'English': 7,
        };
        _subjectAccuracy = {
          'Mathematics': 85.0,
          'Science': 80.0,
          'English': 90.0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
              Color(0xFF667EEA),
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadAnalytics,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOverviewCards(),
                                const SizedBox(height: 24),
                                _buildSectionTitle('Subject Performance 📊'),
                                const SizedBox(height: 16),
                                _buildSubjectCards(),
                                const SizedBox(height: 24),
                                _buildSectionTitle('Achievements 🏆'),
                                const SizedBox(height: 16),
                                _buildAchievementsGrid(),
                                const SizedBox(height: 24),
                                _buildSectionTitle('Learning Journey 🚀'),
                                const SizedBox(height: 16),
                                _buildProgressChart(),
                              ],
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Analytics 📈',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'See how awesome you are!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final accuracy = _totalQuestions > 0
        ? ((_correctAnswers / _totalQuestions) * 100).round()
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '✅',
            '$_correctAnswers',
            'Correct',
            const [Color(0xFF4CAF50), Color(0xFF45A049)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '📊',
            '$accuracy%',
            'Accuracy',
            const [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '🔥',
            '$_currentStreak',
            'Day Streak',
            const [Color(0xFFFF9800), Color(0xFFF57C00)],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSubjectCards() {
    return Column(
      children: _subjectStats.entries.map((entry) {
        final subject = entry.key;
        final count = entry.value;
        final accuracy = _subjectAccuracy[subject] ?? 0.0;
        final color = _subjectColors[subject] ?? Colors.purple;
        final emoji = _subjectEmojis[subject] ?? '📖';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.8), color],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count questions answered',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${accuracy.toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: accuracy / 100,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementsGrid() {
    final achievements = [
      {'emoji': '🎯', 'title': 'Quick Learner', 'desc': 'Completed 10 lessons', 'unlocked': true},
      {'emoji': '⭐', 'title': 'Star Student', 'desc': '90% accuracy rate', 'unlocked': true},
      {'emoji': '🔥', 'title': 'On Fire!', 'desc': '5 day streak', 'unlocked': true},
      {'emoji': '🏆', 'title': 'Champion', 'desc': 'Complete 50 lessons', 'unlocked': false},
      {'emoji': '💎', 'title': 'Perfect Score', 'desc': 'Get 100% on a lesson', 'unlocked': false},
      {'emoji': '🚀', 'title': 'Super Learner', 'desc': '100 questions answered', 'unlocked': false},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final unlocked = achievement['unlocked'] as bool;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: unlocked
                ? const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  )
                : null,
            color: unlocked ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: unlocked ? null : Border.all(color: Colors.grey.shade200, width: 2),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                achievement['emoji'] as String,
                style: TextStyle(
                  fontSize: 40,
                  color: unlocked ? null : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement['title'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: unlocked ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                achievement['desc'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: unlocked ? Colors.white70 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressChart() {
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Progress This Week',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Simple bar chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildProgressBar('Mon', 5, 10),
              _buildProgressBar('Tue', 8, 10),
              _buildProgressBar('Wed', 6, 10),
              _buildProgressBar('Thu', 9, 10),
              _buildProgressBar('Fri', 7, 10),
              _buildProgressBar('Sat', 4, 10),
              _buildProgressBar('Sun', 3, 10),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Great work! You\'ve been very active this week! 💪',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String day, int value, int maxValue) {
    final height = (value / maxValue * 100).clamp(20.0, 100.0);
    final color = value >= 7 ? Colors.green : (value >= 4 ? Colors.orange : Colors.red);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (value > 0)
                Container(
                  width: 32,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.8),
                        color,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
