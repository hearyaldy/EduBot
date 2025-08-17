import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../providers/app_provider.dart';
import '../services/ai_service.dart';
import '../services/audio_service.dart';
import '../utils/app_theme.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final TextEditingController _questionController = TextEditingController();
  final FocusNode _questionFocusNode = FocusNode();
  final AIService _aiService = AIService();
  
  bool _isLoading = false;
  String? _selectedSubject;
  Explanation? _currentExplanation;

  final List<String> _subjects = [
    'Math',
    'Science',
    'English',
    'History',
    'Geography',
    'Art',
    'Other'
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _questionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      _showSnackBar('Please enter a question', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _currentExplanation = null;
    });

    try {
      final question = HomeworkQuestion(
        question: _questionController.text.trim(),
        type: QuestionType.text,
        subject: _selectedSubject,
      );

      final explanation = await _aiService.explainProblem(
        question.question,
        question.id,
      );

      // Add to provider
      if (mounted) {
        Provider.of<AppProvider>(context, listen: false)
            .saveQuestion(question);
      }

      setState(() {
        _currentExplanation = explanation;
        _isLoading = false;
      });

      _showSnackBar('Question answered successfully!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Failed to get answer: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _playAudio(String text) async {
    try {
      await AudioService.speakExplanation(text);
    } catch (e) {
      _showSnackBar('Failed to play audio: ${e.toString()}', isError: true);
    }
  }

  void _clearQuestion() {
    setState(() {
      _questionController.clear();
      _selectedSubject = null;
      _currentExplanation = null;
    });
    _questionFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Question'),
        centerTitle: true,
        actions: [
          if (_currentExplanation != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clearQuestion,
              tooltip: 'Ask new question',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionInput(),
                    const SizedBox(height: 24),
                    if (_isLoading) _buildLoadingWidget(),
                    if (_currentExplanation != null) _buildExplanationWidget(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What would you like help with?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subject Selection
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              hint: const Text('Select subject (optional)'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.school),
              ),
              items: _subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Question Input
            TextField(
              controller: _questionController,
              focusNode: _questionFocusNode,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your question here...\n\nFor example:\n• How do I solve 2x + 5 = 15?\n• What is photosynthesis?\n• How do I find the main idea in a paragraph?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.help_outline),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitQuestion(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Getting your answer...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This might take a few seconds',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationWidget() {
    final explanation = _currentExplanation!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Answer Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: AppTheme.success,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Answer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => _playAudio(explanation.answer),
                      tooltip: 'Play audio',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  explanation.answer,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Steps
        if (explanation.steps.isNotEmpty) ...[
          Text(
            'Step-by-Step Explanation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...explanation.steps.map((step) => _buildStepCard(step)),
        ],
        
        const SizedBox(height: 16),
        
        // Parent Tip
        if (explanation.parentFriendlyTip?.isNotEmpty == true)
          _buildTipCard(
            'Parent Tip',
            explanation.parentFriendlyTip!,
            Icons.favorite,
            AppTheme.accent,
          ),
        
        const SizedBox(height: 12),
        
        // Real World Example
        if (explanation.realWorldExample?.isNotEmpty == true)
          _buildTipCard(
            'Real World Connection',
            explanation.realWorldExample!,
            Icons.public,
            AppTheme.info,
          ),
      ],
    );
  }

  Widget _buildStepCard(ExplanationStep step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: step.isKeyStep ? AppTheme.primaryBlue : AppTheme.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepNumber}',
                      style: TextStyle(
                        color: step.isKeyStep ? Colors.white : AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              step.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (step.tip?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.tip!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryDark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(String title, String content, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [AppTheme.subtleShadow],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitQuestion,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
                label: Text(_isLoading ? 'Getting Answer...' : 'Get Answer'),
              ),
            ),
            if (_currentExplanation != null) ...[
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => _playAudio(_currentExplanation!.answer),
                icon: const Icon(Icons.volume_up),
                tooltip: 'Play answer',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
