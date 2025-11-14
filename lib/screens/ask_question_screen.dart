import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../providers/app_provider.dart';
import '../services/openrouter_ai_service.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/voice_input_service.dart';
import '../utils/app_theme.dart';
import '../widgets/gradient_header.dart';
import '../widgets/modern_button.dart';
import '../widgets/ad_banner_widget.dart';
import '../core/theme/app_colors.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final TextEditingController _questionController = TextEditingController();
  final FocusNode _questionFocusNode = FocusNode();
  final OpenRouterAIService _aiService = OpenRouterAIService();
  final AdService _adService = AdService();
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

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Check if user is approaching or at limit (skip for premium/superadmin)
    if (!provider.isPremium && !provider.isSuperadmin) {
      final shouldContinue = await _checkQuestionLimitAndShowWarning(provider);
      if (!shouldContinue) {
        return; // User chose not to continue or hit limit
      }
    }

    // Show interstitial ad for non-premium users (every 3rd question)
    if (!provider.isPremium && !provider.isSuperadmin) {
      await _adService.showInterstitialAdConditionally(
        actionCount: provider.dailyQuestionsUsed + 1,
        showAfterActions: 3,
      );
    }

    setState(() {
      _isLoading = true;
    });

    // Clear current explanation from provider
    provider.clearCurrentExplanation();

    if (!mounted) return;

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final question = HomeworkQuestion(
        question: _questionController.text.trim(),
        type: QuestionType.text,
        subject: _selectedSubject,
        childProfileId: provider.activeProfile?.id,
      );

      // Get explanation from OpenRouter AI with Gemini 2.0 Flash
      final explanation = await _aiService.getExplanation(
        question: question.question,
        language: provider.selectedLanguage,
        gradeLevel: 'Elementary', // Default grade level
      );

      // Ensure explanation has correct question ID (fixes rate limit fallback issue)
      final correctedExplanation = Explanation(
        id: explanation.id,
        questionId: question.id, // Use the actual question ID
        question: explanation.question,
        answer: explanation.answer,
        steps: explanation.steps,
        parentFriendlyTip: explanation.parentFriendlyTip,
        realWorldExample: explanation.realWorldExample,
        createdAt: explanation.createdAt,
        subject: explanation.subject,
        difficulty: explanation.difficulty,
      );

      // Add to provider with persistent storage
      if (mounted) {
        await provider.saveQuestionWithExplanation(
            question, correctedExplanation);
        await provider.incrementDailyQuestions(subject: question.subject);

        // Set current explanation in provider for viewing
        provider.setCurrentExplanation(correctedExplanation);

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

      String errorMessage = e.toString();

      // Check if it's a rate limit error and provide specific guidance
      if (errorMessage.toLowerCase().contains('rate limit') ||
          errorMessage.toLowerCase().contains('rate') ||
          errorMessage.toLowerCase().contains('429')) {
        _showRateLimitSnackBar();
      } else {
        _showSnackBar('Failed to get answer: $errorMessage', isError: true);
      }
    }
  }

  void _showRateLimitSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'AI service is temporarily at capacity. Please try again in a few minutes.',
        ),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Learn More',
          onPressed: () {
            _showRateLimitInfoDialog();
          },
        ),
      ),
    );
  }

  /// Check if user is approaching or at their daily question limit
  /// Returns true if user should continue, false if they hit the limit or chose not to continue
  Future<bool> _checkQuestionLimitAndShowWarning(AppProvider provider) async {
    final currentQuestions = provider.dailyQuestionsUsed;
    final maxQuestions = provider.isRegistered ? 10 : 5;
    final remaining = maxQuestions - currentQuestions;

    // If at limit, show limit reached bottom sheet
    if (remaining <= 0) {
      await _showQuestionLimitReachedBottomSheet(provider, maxQuestions);
      return false;
    }

    // If approaching limit (1 question left), show warning
    if (remaining == 1) {
      return await _showApproachingLimitBottomSheet(provider, maxQuestions);
    }

    // If getting close (2-3 questions left), show gentle reminder
    if (remaining <= 3) {
      return await _showGentleReminderBottomSheet(
          provider, remaining, maxQuestions);
    }

    return true; // Continue normally
  }

  /// Show bottom sheet when user reaches their daily limit
  Future<void> _showQuestionLimitReachedBottomSheet(
      AppProvider provider, int maxQuestions) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PopScope(
        canPop: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: AppColors.warning,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Daily Question Limit Reached',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                provider.isRegistered
                    ? 'You\'ve used all 10 questions for today as a registered user. Upgrade to Premium for unlimited questions!'
                    : 'You\'ve used all 5 questions for today. Register for free to get 10 questions daily, or upgrade to Premium for unlimited access!',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.gray600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Benefits
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    if (!provider.isRegistered) ...[
                      _buildBenefitRow(Icons.person_add, 'Register for Free',
                          'Get 10 questions daily'),
                      const SizedBox(height: 12),
                    ],
                    _buildBenefitRow(
                        Icons.diamond, 'Premium Access', 'Unlimited questions'),
                    const SizedBox(height: 12),
                    _buildBenefitRow(Icons.sync, 'Cloud Sync',
                        'Access from multiple devices'),
                    const SizedBox(height: 12),
                    _buildBenefitRow(Icons.support, 'Priority Support',
                        'Get help when you need it'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Maybe Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to premium/registration screen based on user status
                        if (provider.isRegistered) {
                          // Navigate to premium screen
                          Navigator.pushNamed(context, '/premium');
                        } else {
                          // Navigate to registration screen
                          Navigator.pushNamed(context, '/register');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(provider.isRegistered
                          ? 'Upgrade to Premium'
                          : 'Register for Free'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Show bottom sheet when user has 1 question left
  Future<bool> _showApproachingLimitBottomSheet(
      AppProvider provider, int maxQuestions) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(35),
              ),
              child: const Icon(
                Icons.warning_amber,
                color: AppColors.warning,
                size: 35,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Last Question Today!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              provider.isRegistered
                  ? 'This will be your last question for today (10/$maxQuestions used). Make it count!'
                  : 'This will be your last question for today (5/$maxQuestions used). Consider registering for more questions!',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.gray600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  /// Show gentle reminder when user has 2-3 questions left
  Future<bool> _showGentleReminderBottomSheet(
      AppProvider provider, int remaining, int maxQuestions) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Question Limit Reminder',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              'You have $remaining questions remaining today (${maxQuestions - remaining}/$maxQuestions used).',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Continue'),
                  ),
                ),
                if (!provider.isRegistered)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        Navigator.pushNamed(context, '/register');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Get More'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    return result ?? true;
  }

  Widget _buildBenefitRow(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: AppColors.success, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  void _showRateLimitInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Service Limit Reached'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The free AI service has reached its usage limit. This is temporary and usually resolves within a few minutes.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'You can:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              '• Try again in a few minutes',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              '• Add your own API key at openrouter.ai for unlimited access',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              '• Continue using other features of EduBot',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              GradientHeader(
                title: 'Ask a Question',
                subtitle: 'Get help with any homework problem',
                gradientColors: const [
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
                      const SizedBox(height: 16),
                      // Ad Banner
                      const AdBannerWidget(),
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
                      borderSide: const BorderSide(
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
                              ? const Icon(
                                  Icons.mic,
                                  key: ValueKey('listening'),
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mic,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _partialSpeech,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(
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
                    const Icon(
                      Icons.analytics_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OpenRouter AI Usage (Free)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getUsageLevelColor(provider.usageLevel)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getUsageLevelColor(provider.usageLevel)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        provider.apiUsageStatus
                            .split(' - ')[0], // First part only
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getUsageLevelColor(provider.usageLevel),
                        ),
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
                          provider.questionUsageDisplay,
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

                // API Requests usage
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Requests',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        Text(
                          '${(provider.dailyRequestUsagePercentage * 100).toStringAsFixed(1)}%',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: provider.dailyRequestUsagePercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getUsageLevelColor(provider.usageLevel),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.dailyRequestsUsed} / 1,500 requests',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
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
                          'Daily Tokens',
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
                        _getUsageLevelColor(provider.usageLevel),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(tokensUsed / 1000).toStringAsFixed(1)}k / 1,000k tokens',
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
                        const Icon(
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

                // API Usage Warnings
                if (provider.isApproachingRequestLimit ||
                    provider.isApproachingTokenLimit) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.priority_high,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Approaching OpenRouter API daily limit! ${provider.remainingDailyRequests} requests remaining.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (provider.isNearDailyRequestLimit ||
                    provider.isNearDailyTokenLimit) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${provider.apiUsageStatus}. ${provider.remainingDailyRequests} requests remaining today.',
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
                        const Icon(
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
                        const Icon(Icons.lightbulb,
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
                    const Icon(
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

  Color _getUsageLevelColor(ApiUsageLevel level) {
    switch (level) {
      case ApiUsageLevel.excellent:
        return AppColors.success;
      case ApiUsageLevel.moderate:
        return AppColors.info;
      case ApiUsageLevel.warning:
        return AppColors.warning;
      case ApiUsageLevel.critical:
        return AppColors.error;
    }
  }
}
