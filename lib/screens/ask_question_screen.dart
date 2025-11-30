import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../providers/app_provider.dart';
import '../services/openrouter_ai_service.dart';
import '../services/firebase_service.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isListening = false;
  String _partialSpeech = '';
  String? _selectedSubject;
  String _selectedGradeLevel = 'Elementary'; // Default grade level
  XFile? _selectedImage;
  String? _imageBase64;
  String? _lastError;
  bool _showRetryButton = false;

  final List<String> _subjects = [
    'Math',
    'Science',
    'English',
    'History',
    'Geography',
    'Art',
    'Other',
  ];

  final List<String> _gradeLevels = [
    'Elementary',
    'Middle School',
    'High School',
    'College',
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Initialize required services (voice, etc.)
  Future<void> _initializeServices() async {
    try {
      await _voiceService.initialize();
      debugPrint('✅ Voice service initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize voice service: $e');
      // Continue without voice - don't crash the app
    }
  }

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

  /// Pick an image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Convert image to base64
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);

        setState(() {
          _selectedImage = image;
          _imageBase64 = base64String;
        });

        _showSnackBar('Image selected successfully!');
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}', isError: true);
    }
  }

  /// Remove selected image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBase64 = null;
    });
    _showSnackBar('Image removed');
  }

  Future<void> _submitQuestion() async {
    // Prevent multiple simultaneous requests
    if (_isLoading) {
      debugPrint('⚠️ Request already in progress, ignoring duplicate submit');
      return;
    }

    // Comprehensive input validation
    final questionText = _questionController.text.trim();

    if (questionText.isEmpty) {
      _showSnackBar('Please enter a question', isError: true);
      _questionFocusNode.requestFocus();
      return;
    }

    if (questionText.length < 3) {
      _showSnackBar('Question is too short. Please provide more details.',
          isError: true);
      _questionFocusNode.requestFocus();
      return;
    }

    if (questionText.length > 2000) {
      _showSnackBar(
          'Question is too long. Please keep it under 2000 characters.',
          isError: true);
      _questionFocusNode.requestFocus();
      return;
    }

    // Check if question contains only special characters or numbers
    final alphaNumericRegex = RegExp(r'[a-zA-Z0-9]');
    if (!alphaNumericRegex.hasMatch(questionText)) {
      _showSnackBar('Please enter a valid question with text or numbers.',
          isError: true);
      _questionFocusNode.requestFocus();
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

      // Get explanation from OpenRouter AI with timeout (60 seconds)
      final explanation = await _aiService
          .getExplanation(
        question: question.question,
        language: provider.selectedLanguage,
        gradeLevel: _selectedGradeLevel, // Use selected grade level
        imageBase64: _imageBase64, // Pass image if available
      )
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception(
            'Request timed out. The AI service took too long to respond. Please try again.',
          );
        },
      );

      // Check if widget is still mounted after async operation
      if (!mounted) return;

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

      // Check mounted again before setState
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Question answered successfully!');

      // Clear error state on success
      if (mounted) {
        setState(() {
          _lastError = null;
          _showRetryButton = false;
        });
      }
    } catch (e) {
      // Check mounted before setState in error handler
      if (!mounted) return;

      String errorMessage = e.toString();

      setState(() {
        _isLoading = false;
        _lastError = errorMessage;
        _showRetryButton = true;
      });

      // Check if it's a rate limit error and provide specific guidance
      if (errorMessage.toLowerCase().contains('rate limit') ||
          errorMessage.toLowerCase().contains('rate') ||
          errorMessage.toLowerCase().contains('429')) {
        _showRateLimitSnackBar();
      } else if (errorMessage.toLowerCase().contains('timeout')) {
        _showSnackBar(
          'Request timed out. Please check your connection and try again.',
          isError: true,
        );
      } else if (errorMessage.toLowerCase().contains('network') ||
          errorMessage.toLowerCase().contains('connection')) {
        _showSnackBar(
          'Network error. Please check your internet connection.',
          isError: true,
        );
      } else {
        _showSnackBar('Failed to get answer: $errorMessage', isError: true);
      }
    }
  }

  /// Retry the last failed request
  Future<void> _retryLastQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      _showSnackBar('No question to retry', isError: true);
      return;
    }

    setState(() {
      _showRetryButton = false;
      _lastError = null;
    });

    await _submitQuestion();
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
    // Superadmin bypass - no limits for superadmin users
    try {
      final isSuperadmin = await FirebaseService.instance.isSuperadmin();
      if (isSuperadmin) {
        debugPrint('✅ Superadmin detected - bypassing question limits');
        return true; // No limits for superadmin
      }
    } catch (e) {
      debugPrint('⚠️ Could not check superadmin status: $e');
    }

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
              const Text(
                'Daily Question Limit Reached',
                style: TextStyle(
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
      _selectedGradeLevel = 'Elementary'; // Reset to default
      _selectedImage = null;
      _imageBase64 = null;
    });

    // Clear current explanation from provider
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.clearCurrentExplanation();

    _questionFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Kid-friendly colorful header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFA8BFF),
                      Color(0xFF2BD2FF),
                      Color(0xFF2BFF88),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '❓ Ask Anything!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'I\'m here to help you learn! 🤖💡',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        if (provider.currentExplanation != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _clearQuestion,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh_rounded,
                                          color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Ask New Question',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
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
                      // Retry button for failed requests
                      if (_showRetryButton && !_isLoading) _buildRetryWidget(),
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8F9FF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFA8BFF).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFA8BFF), Color(0xFF2BD2FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('💬', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'What can I help you with? 🤔',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
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

            const SizedBox(height: 12),

            // Grade Level Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedGradeLevel,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.grade),
                labelText: 'Grade Level',
              ),
              items: _gradeLevels.map((level) {
                return DropdownMenuItem(value: level, child: Text(level));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGradeLevel = value ?? 'Elementary';
                });
              },
            ),

            const SizedBox(height: 16),

            // Image Upload Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gray300,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Attach Image (Optional)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedImage != null) ...[
                    // Show selected image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.red.withValues(alpha: 0.8),
                              foregroundColor: Colors.white,
                            ),
                            tooltip: 'Remove image',
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Show image picker buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text('Gallery'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('Camera'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a photo of the homework problem for better answers',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.gray600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
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

  Widget _buildRetryWidget() {
    return Card(
      color: AppColors.error.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Request Failed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _lastError?.contains('timeout') == true
                  ? 'The request took too long. Please try again.'
                  : _lastError?.contains('network') == true ||
                          _lastError?.contains('connection') == true
                      ? 'Network connection issue. Check your internet.'
                      : 'Something went wrong. Please try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _retryLastQuestion,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
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
                          questionsRemaining < 0 ? '∞' : '$questionsRemaining',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: questionsRemaining < 0 ||
                                            questionsRemaining > 0
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
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? LinearGradient(
                              colors: [
                                Colors.grey.shade300,
                                Colors.grey.shade400,
                              ],
                            )
                          : const LinearGradient(
                              colors: [
                                Color(0xFFFA8BFF),
                                Color(0xFF2BD2FF),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFFFA8BFF)
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isLoading ? null : _submitQuestion,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              else
                                const Icon(Icons.send_rounded,
                                    color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                _isLoading
                                    ? 'Getting Your Answer... 🤔'
                                    : 'Get My Answer! 🚀',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (provider.currentExplanation != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2BFF88), Color(0xFF2BD2FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            _playAudio(provider.currentExplanation!.answer),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Icon(Icons.volume_up, color: Colors.white),
                        ),
                      ),
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
