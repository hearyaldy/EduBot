import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../providers/app_provider.dart';
import '../services/ai_service.dart';
import '../services/audio_service.dart';
import '../services/voice_input_service.dart';
import '../utils/app_theme.dart';
import '../widgets/gradient_header.dart';
import '../widgets/modern_button.dart';
import '../core/theme/app_colors.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final TextEditingController _questionController = TextEditingController();
  final FocusNode _questionFocusNode = FocusNode();
  final AIService _aiService = AIService();
  final VoiceInputService _voiceService = VoiceInputService();

  bool _isLoading = false;
  bool _isListening = false;
  String _partialSpeech = '';
  String? _selectedSubject;

  final List<String> _subjects = [
    'Math',
    'Science',
    'English',
    'History',
    'Geography',
    'Art',
    'Other',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _questionFocusNode.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _startVoiceInput() async {
    try {
      final hasPermission = await _voiceService.hasPermission();
      if (!hasPermission) {
        final granted = await _voiceService.requestPermission();
        if (!granted) {
          _showSnackBar('Microphone permission is required for voice input',
              isError: true);
          return;
        }
      }

      setState(() {
        _isListening = true;
        _partialSpeech = '';
      });

      await _voiceService.startListening(
        onResult: (finalText) {
          setState(() {
            _questionController.text = finalText;
            _isListening = false;
            _partialSpeech = '';
          });
          _showSnackBar('Voice input completed!');
        },
        onPartialResult: (partialText) {
          setState(() {
            _partialSpeech = partialText;
          });
        },
        onListeningComplete: () {
          setState(() {
            _isListening = false;
            _partialSpeech = '';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isListening = false;
        _partialSpeech = '';
      });
      _showSnackBar('Voice input failed: ${e.toString()}', isError: true);
    }
  }

  Future<void> _stopVoiceInput() async {
    await _voiceService.stopListening();
    setState(() {
      _isListening = false;
      _partialSpeech = '';
    });
  }

  Future<void> _submitQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      _showSnackBar('Please enter a question', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Clear current explanation from provider
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.clearCurrentExplanation();

    try {
      final question = HomeworkQuestion(
        question: _questionController.text.trim(),
        type: QuestionType.text,
        subject: _selectedSubject,
      );

      final explanation = await _aiService.explainProblem(
        question.question,
        question.id,
        language:
            Provider.of<AppProvider>(context, listen: false).selectedLanguage,
      );

      // Add to provider with persistent storage
      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        await provider.saveQuestionWithExplanation(question, explanation);
        await provider.incrementDailyQuestions();

        // Set current explanation in provider for viewing
        provider.setCurrentExplanation(explanation);

        // Estimate token usage (rough approximation: 4 characters per token)
        final questionTokens = (question.question.length / 4).ceil();
        final answerTokens = (explanation.answer.length / 4).ceil();
        final stepsTokens = explanation.steps.fold<int>(
            0,
            (sum, step) =>
                sum +
                (step.description.length / 4).ceil() +
                (step.title.length / 4).ceil());
        final totalTokens = questionTokens + answerTokens + stepsTokens;

        // Track token usage
        await provider.addTokenUsage(totalTokens);
      }

      setState(() {
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
      _showSnackBar('Failed to play audio: ${e.toString()}', isError: true);
    }
  }

  void _clearQuestion() {
    setState(() {
      _questionController.clear();
      _selectedSubject = null;
    });

    // Clear current explanation from provider
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.clearCurrentExplanation();

    _questionFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              GradientHeader(
                title: 'Ask a Question',
                subtitle: 'Get help with any homework problem',
                gradientColors: [
                  AppColors.askGradient1,
                  AppColors.askGradient2,
                  AppColors.askGradient3,
                ],
                child: provider.currentExplanation != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ModernButton(
                          text: 'Ask New Question',
                          onPressed: _clearQuestion,
                          icon: Icons.refresh,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          textColor: Colors.white,
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuestionInput(),
                      const SizedBox(height: 16),
                      _buildTokenUsageCard(),
                      const SizedBox(height: 24),
                      if (_isLoading) _buildLoadingWidget(),
                      if (provider.currentExplanation != null)
                        _buildExplanationWidget(),
                    ],
                  ),
                ),
              ),
              _buildBottomActions(),
            ],
          );
        },
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                return DropdownMenuItem(value: subject, child: Text(subject));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Question Input with Voice
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _questionController,
                  focusNode: _questionFocusNode,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: _isListening
                        ? 'Listening... Speak your question now'
                        : 'Type your question here or tap the microphone...\n\nFor example:\n• How do I solve 2x + 5 = 15?\n• What is photosynthesis?\n• How do I find the main idea in a paragraph?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isListening ? AppColors.primary : Colors.grey,
                        width: _isListening ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.help_outline),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 60, right: 8),
                      child: IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isListening
                              ? Icon(
                                  Icons.mic,
                                  key: const ValueKey('listening'),
                                  color: AppColors.primary,
                                  size: 28,
                                )
                              : Icon(
                                  Icons.mic_none,
                                  key: const ValueKey('not_listening'),
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                        ),
                        onPressed:
                            _isListening ? _stopVoiceInput : _startVoiceInput,
                        tooltip: _isListening
                            ? 'Stop voice input'
                            : 'Start voice input',
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitQuestion(),
                ),

                // Show partial speech recognition results
                if (_isListening && _partialSpeech.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mic,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _partialSpeech,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Voice input instructions
                if (!_isListening) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.mic_none,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap the microphone to ask your question with voice',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenUsageCard() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final questionsUsed = provider.dailyQuestionsUsed;
        final questionsRemaining = provider.remainingQuestions;
        final tokensUsed = provider.dailyTokensUsed;
        final tokenUsagePercentage = provider.tokenUsagePercentage;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Usage',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Questions usage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Questions',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        Text(
                          '$questionsUsed / 10',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Remaining',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        Text(
                          '$questionsRemaining',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: questionsRemaining > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // AI Tokens usage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI Tokens',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        Text(
                          '${(tokenUsagePercentage * 100).toStringAsFixed(1)}%',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: tokenUsagePercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tokenUsagePercentage < 0.8
                            ? AppColors.success
                            : tokenUsagePercentage < 0.9
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(tokensUsed / 1000).toStringAsFixed(1)}k / ${(provider.estimatedDailyTokenLimit / 1000).toStringAsFixed(0)}k tokens',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Global API usage (for all users)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.public,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Global API Usage',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppProvider.globalDailyRequests} / 240 requests',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        Text(
                          '${(AppProvider.globalRequestUsagePercentage * 100).toStringAsFixed(1)}%',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppProvider.isNearGlobalLimit
                                        ? AppColors.warning
                                        : Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: AppProvider.globalRequestUsagePercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppProvider.globalRequestUsagePercentage < 0.8
                            ? AppColors.success
                            : AppProvider.globalRequestUsagePercentage < 0.9
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                    ),
                  ],
                ),

                if (questionsRemaining == 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Daily question limit reached. Resets at midnight.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (AppProvider.isNearGlobalLimit) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_outlined,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'High global usage detected. Service may be limited.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.warning,
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
      },
    );
  }

  Widget _buildExplanationWidget() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final explanation = provider.currentExplanation!;

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
                        Icon(Icons.lightbulb,
                            color: AppTheme.success, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Answer',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
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
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
      },
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
                    color: step.isKeyStep
                        ? AppTheme.primaryBlue
                        : AppTheme.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepNumber}',
                      style: TextStyle(
                        color: step.isKeyStep
                            ? Colors.white
                            : AppTheme.primaryBlue,
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

  Widget _buildTipCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
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
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
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
                    label:
                        Text(_isLoading ? 'Getting Answer...' : 'Get Answer'),
                  ),
                ),
                if (provider.currentExplanation != null) ...[
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () =>
                        _playAudio(provider.currentExplanation!.answer),
                    icon: const Icon(Icons.volume_up),
                    tooltip: 'Play answer',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
