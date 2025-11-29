import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../models/student_progress.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../services/student_progress_service.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final StudentProgressService _progressService = StudentProgressService();

  late TabController _tabController;

  // Analytics data
  Map<String, dynamic> _analyticsData = {};
  List<StudentProgress> _recentProgress = [];
  bool _isLoading = true;
  String _selectedTimeFrame = '7days'; // 7days, 30days, 90days, all

  // Chart data
  List<FlSpot> _performanceData = [];
  List<PieChartSectionData> _subjectDistribution = [];
  List<BarChartGroupData> _difficultyStats = [];
  List<FlSpot> _learningTrendData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.initialize();

      // Get active child profile ID or use 'main_user' as fallback
      final appProvider = context.read<AppProvider>();
      final childProfile = appProvider.activeProfile;
      final studentId = childProfile?.id ?? 'main_user';

      // Get analytics data based on selected timeframe
      final endDate = DateTime.now();
      late DateTime startDate;

      switch (_selectedTimeFrame) {
        case '7days':
          startDate = endDate.subtract(const Duration(days: 7));
          break;
        case '30days':
          startDate = endDate.subtract(const Duration(days: 30));
          break;
        case '90days':
          startDate = endDate.subtract(const Duration(days: 90));
          break;
        case 'all':
        default:
          startDate = DateTime(2020); // Far back date
          break;
      }

      // Load analytics data for specific student
      _analyticsData = await _progressService.getAnalyticsSummary(studentId);

      // Load recent progress for specific student within date range
      _recentProgress = await _progressService.getStudentProgressInDateRange(
          studentId, startDate, endDate);

      // Generate chart data
      _generateChartData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load analytics: $e');
    }
  }

  void _generateChartData() {
    // Performance trend data
    _performanceData = _generatePerformanceTrend();

    // Subject distribution pie chart
    _subjectDistribution = _generateSubjectDistribution();

    // Difficulty statistics bar chart
    _difficultyStats = _generateDifficultyStats();

    // Learning trend data
    _learningTrendData = _generateLearningTrend();
  }

  List<FlSpot> _generatePerformanceTrend() {
    final spots = <FlSpot>[];
    final groupedProgress = <String, List<StudentProgress>>{};

    // Group progress by date
    for (final progress in _recentProgress) {
      final dateKey =
          '${progress.attemptTime.year}-${progress.attemptTime.month}-${progress.attemptTime.day}';
      groupedProgress.putIfAbsent(dateKey, () => []).add(progress);
    }

    // Calculate daily averages
    int index = 0;
    for (final entry in groupedProgress.entries) {
      final dailyAccuracy = entry.value
              .map((p) => p.isCorrect ? 1.0 : 0.0)
              .reduce((a, b) => a + b) /
          entry.value.length;
      spots.add(FlSpot(index.toDouble(), dailyAccuracy * 100));
      index++;
    }

    return spots;
  }

  List<PieChartSectionData> _generateSubjectDistribution() {
    final subjectCounts = <String, int>{};
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    // Use actual subject data from progress records
    for (final progress in _recentProgress) {
      final subject = progress.subject.isNotEmpty ? progress.subject : 'Other';
      subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
    }

    // If no data, show empty state
    if (subjectCounts.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 1,
          title: 'No Data',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ];
    }

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;

    for (final entry in subjectCounts.entries) {
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: entry.value.toDouble(),
          title: '${entry.key}\n${entry.value}',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    }

    return sections;
  }

  List<BarChartGroupData> _generateDifficultyStats() {
    final difficultyStats = <DifficultyTag, Map<String, int>>{};

    // Initialize difficulty stats
    for (final difficulty in DifficultyTag.values) {
      difficultyStats[difficulty] = {'correct': 0, 'incorrect': 0};
    }

    // Use actual difficulty data from progress records
    for (final progress in _recentProgress) {
      final difficulty = progress.difficulty;
      if (progress.isCorrect) {
        difficultyStats[difficulty]!['correct'] =
            difficultyStats[difficulty]!['correct']! + 1;
      } else {
        difficultyStats[difficulty]!['incorrect'] =
            difficultyStats[difficulty]!['incorrect']! + 1;
      }
    }

    final groups = <BarChartGroupData>[];
    int index = 0;

    for (final entry in difficultyStats.entries) {
      groups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: entry.value['correct']!.toDouble(),
              color: Colors.green,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: entry.value['incorrect']!.toDouble(),
              color: Colors.red,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
      index++;
    }

    return groups;
  }

  List<FlSpot> _generateLearningTrend() {
    final spots = <FlSpot>[];
    final streaks = <int>[];

    // Calculate learning streaks over time
    int currentStreak = 0;
    for (int i = 0; i < _recentProgress.length; i++) {
      if (_recentProgress[i].isCorrect) {
        currentStreak++;
      } else {
        streaks.add(currentStreak);
        currentStreak = 0;
      }

      if (i % 5 == 0) {
        // Sample every 5 attempts
        spots.add(FlSpot(i.toDouble(), currentStreak.toDouble()));
      }
    }

    return spots;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time frame selector
          _buildTimeFrameSelector(),

          const SizedBox(height: 16),

          // Key metrics cards
          _buildKeyMetricsCards(),

          const SizedBox(height: 24),

          // Performance trend chart
          _buildPerformanceTrendCard(),

          const SizedBox(height: 24),

          // Quick insights
          _buildQuickInsights(),
        ],
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Time Frame',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '7days', label: Text('7 Days')),
                ButtonSegment(value: '30days', label: Text('30 Days')),
                ButtonSegment(value: '90days', label: Text('90 Days')),
                ButtonSegment(value: 'all', label: Text('All Time')),
              ],
              selected: {_selectedTimeFrame},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedTimeFrame = newSelection.first;
                });
                _loadAnalyticsData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCards() {
    final totalQuestions = _analyticsData['total_attempts'] ?? 0;
    final correctAnswers = _analyticsData['correct_answers'] ?? 0;
    final averageScore =
        totalQuestions > 0 ? (correctAnswers / totalQuestions * 100) : 0.0;
    final learningStreak = _analyticsData['current_streak'] ?? 0;
    final timeSpent = _analyticsData['total_time_minutes'] ?? 0;

    return Row(
      children: [
        Expanded(
            child: _buildMetricCard(
                'Total Questions', '$totalQuestions', Icons.quiz, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildMetricCard(
                'Average Score',
                '${averageScore.toStringAsFixed(1)}%',
                Icons.analytics,
                Colors.green)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildMetricCard('Learning Streak', '$learningStreak days',
                Icons.local_fire_department, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildMetricCard('Time Spent', '${timeSpent}m',
                Icons.access_time, Colors.purple)),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTrendCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _performanceData.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('Day ${value.toInt() + 1}');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}%');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _performanceData,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text('No data available')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              Icons.trending_up,
              'Improvement Area',
              'Focus on medium difficulty questions to boost your overall performance',
              Colors.blue,
            ),
            _buildInsightItem(
              Icons.star,
              'Strong Subject',
              'Mathematics shows excellent progress with 95% accuracy',
              Colors.green,
            ),
            _buildInsightItem(
              Icons.schedule,
              'Study Pattern',
              'You perform best during morning study sessions',
              Colors.orange,
            ),
            _buildInsightItem(
              Icons.psychology,
              'Learning Style',
              'Visual questions have higher success rates for you',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
      IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Subject distribution pie chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _subjectDistribution.isNotEmpty
                        ? PieChart(
                            PieChartData(
                              sections: _subjectDistribution,
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          )
                        : const Center(child: Text('No data available')),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Subject performance details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSubjectPerformanceList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformanceList() {
    final subjects = [
      {'name': 'Mathematics', 'score': 95, 'questions': 120, 'trend': 'up'},
      {'name': 'Science', 'score': 88, 'questions': 98, 'trend': 'up'},
      {'name': 'English', 'score': 82, 'questions': 76, 'trend': 'down'},
      {'name': 'History', 'score': 79, 'questions': 54, 'trend': 'stable'},
    ];

    return Column(
      children: subjects.map((subject) {
        final score = subject['score'] as int;
        final questions = subject['questions'] as int;
        final trend = subject['trend'] as String;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getScoreColor(score).withValues(alpha: 0.2),
            child: Text(
              subject['name'].toString().substring(0, 1),
              style: TextStyle(
                color: _getScoreColor(score),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(subject['name'].toString()),
          subtitle: Text('$questions questions answered'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
              const SizedBox(width: 8),
              _getTrendIcon(trend),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  Widget _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return const Icon(Icons.trending_up, color: Colors.green);
      case 'down':
        return const Icon(Icons.trending_down, color: Colors.red);
      case 'stable':
      default:
        return const Icon(Icons.trending_flat, color: Colors.grey);
    }
  }

  Widget _buildDifficultyAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Difficulty distribution bar chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance by Difficulty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _difficultyStats.isNotEmpty
                        ? BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _getMaxBarValue(),
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final difficulties = [
                                        'Very Easy',
                                        'Easy',
                                        'Medium',
                                        'Hard',
                                        'Very Hard'
                                      ];
                                      if (value.toInt() < difficulties.length) {
                                        return Text(
                                          difficulties[value.toInt()],
                                          style: const TextStyle(fontSize: 12),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(value.toInt().toString());
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                              barGroups: _difficultyStats,
                            ),
                          )
                        : const Center(child: Text('No data available')),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Difficulty recommendations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended Focus Areas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDifficultyRecommendations(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxBarValue() {
    double max = 0;
    for (final group in _difficultyStats) {
      for (final rod in group.barRods) {
        if (rod.toY > max) max = rod.toY;
      }
    }
    return max + 5; // Add some padding
  }

  Widget _buildDifficultyRecommendations() {
    return Column(
      children: [
        _buildRecommendationCard(
          'Master the Basics',
          'Focus on Very Easy and Easy questions to build confidence',
          Colors.green,
          Icons.school,
        ),
        _buildRecommendationCard(
          'Challenge Yourself',
          'Try more Medium difficulty questions to improve problem-solving',
          Colors.blue,
          Icons.fitness_center,
        ),
        _buildRecommendationCard(
          'Advanced Practice',
          'Gradually incorporate Hard questions when ready',
          Colors.orange,
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
      String title, String description, Color color, IconData icon) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildLearningTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Learning streak chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learning Streak Trend',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _learningTrendData.isNotEmpty
                        ? LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${value.toInt()}');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${value.toInt()}');
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _learningTrendData,
                                  isCurved: true,
                                  color: Colors.purple,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.purple.withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Center(child: Text('No data available')),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Learning habits analysis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learning Habits Analysis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildLearningHabitsAnalysis(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Study recommendations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personalized Study Recommendations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStudyRecommendations(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningHabitsAnalysis() {
    return Column(
      children: [
        _buildHabitCard('Best Study Time', '2:00 PM - 4:00 PM',
            Icons.access_time, Colors.blue),
        _buildHabitCard(
            'Average Session Length', '25 minutes', Icons.timer, Colors.green),
        _buildHabitCard('Most Active Day', 'Wednesday', Icons.calendar_today,
            Colors.orange),
        _buildHabitCard('Preferred Question Type', 'Multiple Choice',
            Icons.quiz, Colors.purple),
      ],
    );
  }

  Widget _buildHabitCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStudyRecommendations() {
    return Column(
      children: [
        _buildRecommendationCard(
          'Consistent Practice',
          'Study for 20-30 minutes daily for optimal retention',
          Colors.blue,
          Icons.schedule,
        ),
        _buildRecommendationCard(
          'Spaced Repetition',
          'Review previously incorrect questions after 3 days',
          Colors.green,
          Icons.repeat,
        ),
        _buildRecommendationCard(
          'Focus Areas',
          'Spend extra time on Science and History topics',
          Colors.orange,
          Icons.dashboard,
        ),
        _buildRecommendationCard(
          'Break Time',
          'Take 5-minute breaks between study sessions',
          Colors.purple,
          Icons.coffee,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Learning Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadAnalyticsData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh data',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download_rounded, color: Colors.blue),
                  title: Text('Export Report'),
                  subtitle: Text('Download analytics as PDF',
                      style: TextStyle(fontSize: 11)),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_rounded, color: Colors.green),
                  title: Text('Share Progress'),
                  subtitle: Text('Share with parents/teachers',
                      style: TextStyle(fontSize: 11)),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading:
                      Icon(Icons.restart_alt_rounded, color: Colors.orange),
                  title: Text('Reset Filters'),
                  dense: true,
                ),
              ),
            ],
            onSelected: (value) {
              // Handle menu actions
              if (value == 'export') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon!')),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.teal.shade700,
              unselectedLabelColor: Colors.white.withOpacity(0.9),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.dashboard_rounded, size: 20),
                  text: 'Overview',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.subject_rounded, size: 20),
                  text: 'Subjects',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.bar_chart_rounded, size: 20),
                  text: 'Difficulty',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.trending_up_rounded, size: 20),
                  text: 'Trends',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildSubjectAnalysisTab(),
          _buildDifficultyAnalysisTab(),
          _buildLearningTrendsTab(),
        ],
      ),
    );
  }
}
