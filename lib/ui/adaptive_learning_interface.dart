import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../providers/app_provider.dart';
import '../services/adaptive_learning_engine.dart';
import '../services/student_progress_service.dart';

class AdaptiveLearningInterface extends StatefulWidget {
  const AdaptiveLearningInterface({super.key});

  @override
  State<AdaptiveLearningInterface> createState() =>
      _AdaptiveLearningInterfaceState();
}

class _AdaptiveLearningInterfaceState extends State<AdaptiveLearningInterface> {
  final AdaptiveLearningEngine _adaptiveEngine = AdaptiveLearningEngine();
  final StudentProgressService _progressService = StudentProgressService();

  LearningProfile? _learningProfile;
  List<Question> _recommendedQuestions = [];
  bool _isLoading = true;

  // Customization options
  String _selectedSubject = 'Mathematics';
  String? _selectedTopic;
  int _questionCount = 10;
  bool _includeReview = true;
  bool _adaptDifficulty = true;

  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'English',
    'History'
  ];
  final Map<String, List<String>> _topicsBySubject = {
    'Mathematics': ['Algebra', 'Geometry', 'Statistics', 'Calculus'],
    'Science': ['Physics', 'Chemistry', 'Biology', 'Earth Science'],
    'English': ['Grammar', 'Literature', 'Writing', 'Vocabulary'],
    'History': ['Ancient History', 'Modern History', 'Geography', 'Civics'],
  };

  @override
  void initState() {
    super.initState();
    _loadLearningProfile();
  }

  Future<void> _loadLearningProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get active child profile ID
      final appProvider = context.read<AppProvider>();
      final childProfile = appProvider.activeProfile;
      final studentId = childProfile?.id ?? 'main_user';

      // Build learning profile for the specific student
      _learningProfile = await _adaptiveEngine.buildLearningProfileForStudent(studentId);
      await _generateRecommendations();
    } catch (e) {
      _showErrorSnackBar('Failed to load learning profile: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _generateRecommendations() async {
    try {
      // Get active child profile ID
      final appProvider = context.read<AppProvider>();
      final childProfile = appProvider.activeProfile;
      final studentId = childProfile?.id ?? 'main_user';

      final recommendations =
          await _adaptiveEngine.getPersonalizedRecommendations(
        studentId: studentId,
        subject: _selectedSubject,
        topic: _selectedTopic,
        count: _questionCount,
        includeReview: _includeReview,
        adaptDifficulty: _adaptDifficulty,
      );

      setState(() {
        _recommendedQuestions = recommendations;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to generate recommendations: $e');
    }
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

  Widget _buildLearningProfileSummary() {
    if (_learningProfile == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Loading learning profile...')),
        ),
      );
    }

    final profile = _learningProfile!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Learning Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Overall confidence
            _buildProfileMetric(
              'Overall Confidence',
              '${(profile.confidenceLevels['overall']! * 100).toInt()}%',
              Icons.psychology,
              Colors.blue,
            ),

            const SizedBox(height: 12),

            // Learning style
            _buildProfileMetric(
              'Learning Style',
              '${profile.learningStyle.primaryStyle} learner',
              Icons.school,
              Colors.green,
            ),

            const SizedBox(height: 12),

            // Preferred difficulty
            _buildProfileMetric(
              'Preferred Difficulty',
              profile.difficultyPreference.preferredLevel.name,
              Icons.fitness_center,
              Colors.orange,
            ),

            const SizedBox(height: 12),

            // Optimal session length
            _buildProfileMetric(
              'Optimal Session',
              '${profile.optimalSessionLength.inMinutes} minutes',
              Icons.timer,
              Colors.purple,
            ),

            const SizedBox(height: 16),

            // Knowledge gaps
            if (profile.knowledgeGaps.isNotEmpty) ...[
              const Text(
                'Areas for Improvement:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...profile.knowledgeGaps.take(3).map(
                    (gap) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_down,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${gap.topic} (${(gap.lastAccuracy * 100).toInt()}% accuracy)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],

            const SizedBox(height: 16),

            // Strengths
            if (profile.conceptualStrengths.isNotEmpty) ...[
              const Text(
                'Your Strengths:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...profile.conceptualStrengths.take(3).map(
                    (strength) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${strength.concept} (${(strength.masteryLevel * 100).toInt()}% mastery)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMetric(
      String label, String value, IconData icon, Color color) {
    return Row(
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
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomizationOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customize Your Learning Session',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Subject selection
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              items: _subjects
                  .map((subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value!;
                  _selectedTopic = null; // Reset topic when subject changes
                });
              },
            ),

            const SizedBox(height: 16),

            // Topic selection
            DropdownButtonFormField<String?>(
              value: _selectedTopic,
              decoration: const InputDecoration(
                labelText: 'Topic (Optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Topics'),
                ),
                ...(_topicsBySubject[_selectedSubject] ?? [])
                    .map((topic) => DropdownMenuItem(
                          value: topic,
                          child: Text(topic),
                        )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTopic = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Question count
            Row(
              children: [
                const Text('Number of Questions: '),
                Expanded(
                  child: Slider(
                    value: _questionCount.toDouble(),
                    min: 5,
                    max: 20,
                    divisions: 15,
                    label: _questionCount.toString(),
                    onChanged: (value) {
                      setState(() {
                        _questionCount = value.round();
                      });
                    },
                  ),
                ),
                Text(_questionCount.toString()),
              ],
            ),

            const SizedBox(height: 16),

            // Options switches
            SwitchListTile(
              title: const Text('Include Review Questions'),
              subtitle:
                  const Text('Add questions from areas you struggled with'),
              value: _includeReview,
              onChanged: (value) {
                setState(() {
                  _includeReview = value;
                });
              },
            ),

            SwitchListTile(
              title: const Text('Adaptive Difficulty'),
              subtitle: const Text(
                  'Automatically adjust difficulty based on your performance'),
              value: _adaptDifficulty,
              onChanged: (value) {
                setState(() {
                  _adaptDifficulty = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateRecommendations,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Personalized Questions'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    if (_recommendedQuestions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
                'No recommendations available. Try adjusting your preferences.'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Recommended Questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text('${_recommendedQuestions.length} questions'),
                  backgroundColor: Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI insights
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Recommendation',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _generateRecommendationInsight(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Questions list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recommendedQuestions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final question = _recommendedQuestions[index];
                return _buildQuestionCard(question, index + 1);
              },
            ),

            const SizedBox(height: 16),

            // Start practice button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startPracticeSession(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Practice Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _getDifficultyColor(question.difficulty),
                child: Text(
                  index.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(question.difficulty.name),
                backgroundColor: _getDifficultyColor(question.difficulty)
                    .withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _getDifficultyColor(question.difficulty),
                  fontSize: 12,
                ),
              ),
              Chip(
                label: Text(question.topic),
                backgroundColor: Colors.grey.shade200,
                labelStyle: const TextStyle(fontSize: 12),
              ),
              Chip(
                label: Text(question.questionType.name),
                backgroundColor: Colors.purple.shade100,
                labelStyle: TextStyle(
                  color: Colors.purple.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(DifficultyTag difficulty) {
    switch (difficulty) {
      case DifficultyTag.veryEasy:
        return Colors.green;
      case DifficultyTag.easy:
        return Colors.lightGreen;
      case DifficultyTag.medium:
        return Colors.orange;
      case DifficultyTag.hard:
        return Colors.deepOrange;
      case DifficultyTag.veryHard:
        return Colors.red;
    }
  }

  String _generateRecommendationInsight() {
    if (_learningProfile == null)
      return 'Generating personalized recommendations...';

    final profile = _learningProfile!;
    final insights = <String>[];

    // Difficulty insight
    if (_adaptDifficulty) {
      final confidence = profile.confidenceLevels['overall']!;
      if (confidence > 0.8) {
        insights.add('Questions are slightly challenging to help you grow');
      } else if (confidence < 0.5) {
        insights.add('Questions are selected to build your confidence');
      } else {
        insights.add('Questions match your current skill level');
      }
    }

    // Review insight
    if (_includeReview && profile.knowledgeGaps.isNotEmpty) {
      insights.add('Includes review of ${profile.knowledgeGaps.first.topic}');
    }

    // Learning style insight
    insights
        .add('Optimized for ${profile.learningStyle.primaryStyle} learners');

    return insights.join(' • ');
  }

  void _startPracticeSession() {
    if (_recommendedQuestions.isEmpty) return;

    // TODO: Navigate to practice session with recommended questions
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting practice session with personalized questions!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Learning'),
        backgroundColor: Colors.blue.shade50,
        actions: [
          IconButton(
            onPressed: _loadLearningProfile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLearningProfileSummary(),
                  const SizedBox(height: 16),
                  _buildCustomizationOptions(),
                  const SizedBox(height: 16),
                  _buildRecommendationsList(),
                ],
              ),
            ),
    );
  }
}
