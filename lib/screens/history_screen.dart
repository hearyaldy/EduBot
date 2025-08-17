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
  
  Widget _buildQuestionsList(BuildContext context, List<HomeworkQuestion> questions, AppProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionCard(context, question, provider);
      },
    );
  }
  
  Widget _buildQuestionCard(BuildContext context, HomeworkQuestion question, AppProvider provider) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
  
  Widget _buildQuestionDetails(BuildContext context, HomeworkQuestion question, AppProvider provider) {
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
            child: Text(
              question.question,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewExplanation(context, question, provider),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Answer'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _playQuestionAudio(question.question),
                icon: const Icon(Icons.volume_up, size: 18),
                label: const Text('Play'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _deleteQuestion(context, question, provider),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
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
  
  Future<void> _viewExplanation(BuildContext context, HomeworkQuestion question, AppProvider provider) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final explanation = await provider.getExplanationForQuestion(question.id);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading
      
      if (explanation != null) {
        _showExplanationDialog(context, question, explanation);
      } else {
        _showSnackBar('No explanation found for this question', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading
      _showSnackBar('Failed to load explanation: $e', isError: true);
    }
  }
  
  void _showExplanationDialog(BuildContext context, HomeworkQuestion question, Explanation explanation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Answer: ${question.subject ?? 'General'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Question:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(question.question),
              const SizedBox(height: 16),
              Text(
                'Answer:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(explanation.answer),
              if (explanation.parentFriendlyTip?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Parent Tip',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(explanation.parentFriendlyTip!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => _playQuestionAudio(explanation.answer),
            icon: const Icon(Icons.volume_up, size: 18),
            label: const Text('Play Answer'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _playQuestionAudio(String text) async {
    try {
      await AudioService.speakExplanation(text);
    } catch (e) {
      _showSnackBar('Failed to play audio: $e', isError: true);
    }
  }
  
  Future<void> _deleteQuestion(BuildContext context, HomeworkQuestion question, AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: const Text('Are you sure you want to delete this question? This action cannot be undone.'),
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
