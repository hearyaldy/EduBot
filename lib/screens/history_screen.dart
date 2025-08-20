import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/gradient_header.dart';
import '../widgets/glass_card.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_provider.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../services/audio_service.dart';
import 'explanation_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const GradientHeader(
            title: 'Learning History',
            subtitle: 'Review your homework sessions',
            gradientColors: [
              AppColors.historyGradient1,
              AppColors.historyGradient2,
              AppColors.historyGradient3,
            ],
          ),
          Expanded(
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                final questions = provider.savedQuestions;

                if (questions.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildQuestionsList(context, questions, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.historyGradient1,
                    AppColors.historyGradient2,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_edu,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Questions Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start asking questions or scanning homework to build your learning history!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList(BuildContext context,
      List<HomeworkQuestion> questions, AppProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionCard(context, question, provider);
      },
    );
  }

  Widget _buildQuestionCard(
      BuildContext context, HomeworkQuestion question, AppProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(question.type),
          child: Text(
            question.type.icon,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          question.question.length > 60
              ? '${question.question.substring(0, 60)}...'
              : question.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                if (question.subject != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.subject!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  DateFormat('MMM d, y • h:mm a').format(question.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          _buildQuestionDetails(context, question, provider),
        ],
      ),
    );
  }

  Widget _buildQuestionDetails(
      BuildContext context, HomeworkQuestion question, AppProvider provider) {
    return FutureBuilder<Explanation?>(
      future: provider.getExplanationForQuestion(question.id),
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full question text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.help_outline,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Question',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.question,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Explanation content
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to load explanation',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                )
              else if (snapshot.hasData && snapshot.data != null)
                _buildExplanationContent(snapshot.data!)
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange[700], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No explanation available for this question',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Action buttons
              Column(
                children: [
                  // First row - View Details and Play Answer (when explanation exists)
                  if (snapshot.hasData && snapshot.data != null)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExplanationDetailScreen(question: question),
                              ),
                            ),
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('View Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _playQuestionAudio(snapshot.data!.answer),
                            icon: const Icon(Icons.volume_up, size: 18),
                            label: const Text('Play Answer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[50],
                              foregroundColor: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (snapshot.hasData && snapshot.data != null)
                    const SizedBox(height: 8),
                  // Second row - Play Question and Delete
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _playQuestionAudio(question.question),
                          icon: const Icon(Icons.volume_up, size: 18),
                          label: const Text('Play Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _deleteQuestion(context, question, provider),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExplanationContent(Explanation explanation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Answer section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: Colors.green[700], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Answer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                explanation.answer,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),

        // Steps section (if available)
        if (explanation.steps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_list_numbered,
                        color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Steps',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...explanation.steps.take(3).map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: step.isKeyStep
                                  ? Colors.blue[700]
                                  : Colors.grey[600],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${step.stepNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  step.description,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                if (explanation.steps.length > 3) ...[
                  const SizedBox(height: 4),
                  Text(
                    '... and ${explanation.steps.length - 3} more steps',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Parent tip (if available)
        if (explanation.parentFriendlyTip?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.family_restroom,
                        color: Colors.purple[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Parent Tip',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  explanation.parentFriendlyTip!,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],

        // Real world example (if available)
        if (explanation.realWorldExample?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.public, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Real World Example',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  explanation.realWorldExample!,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.text:
        return AppColors.primary;
      case QuestionType.image:
        return AppColors.secondary;
      case QuestionType.voice:
        return Colors.green;
    }
  }

  Future<void> _playQuestionAudio(String text) async {
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);

      if (!provider.audioEnabled) {
        _showSnackBar('Audio is disabled in settings');
        return;
      }

      await AudioService.speakExplanation(
        text,
        speechRate: provider.speechRate,
      );
    } catch (e) {
      _showSnackBar('Failed to play audio: $e', isError: true);
    }
  }

  Future<void> _deleteQuestion(BuildContext context, HomeworkQuestion question,
      AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text(
            'Are you sure you want to delete this question? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.removeQuestion(question.id);
      _showSnackBar('Question deleted successfully');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
