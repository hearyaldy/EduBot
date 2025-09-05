import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../providers/app_provider.dart';
import '../services/ai_service.dart';
import '../services/ocr_service.dart';
import '../services/audio_service.dart';
import '../utils/app_theme.dart';
import '../widgets/gradient_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/modern_button.dart';
import '../core/theme/app_colors.dart';

class ScanHomeworkScreen extends StatefulWidget {
  const ScanHomeworkScreen({super.key});

  @override
  State<ScanHomeworkScreen> createState() => _ScanHomeworkScreenState();
}

class _ScanHomeworkScreenState extends State<ScanHomeworkScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final ImagePicker _imagePicker = ImagePicker();
  final AIService _aiService = AIService();

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _extractedText;
  Explanation? _currentExplanation;
  bool _isFullViewMode = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }


  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _showSnackBar(
          'Camera permission is required to scan homework',
          isError: true,
        );
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showSnackBar('No cameras available on this device', isError: true);
        return;
      }

      // Initialize camera controller
      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showSnackBar(
        'Failed to initialize camera: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showSnackBar('Camera not ready', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _extractedText = null;
      _currentExplanation = null;
    });

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();

      // Extract text using OCR
      final extractedText = await OCRService.extractTextFromXFile(imageFile);

      if (extractedText.trim().isEmpty) {
        _showSnackBar(
          'No text found in the image. Please try again with better lighting.',
          isError: true,
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Clean the extracted text
      final cleanText = OCRService.cleanExtractedText(extractedText);

      setState(() {
        _extractedText = cleanText;
      });

      // Get AI explanation
      final question = HomeworkQuestion(
        question: cleanText,
        type: QuestionType.image,
        imagePath: imageFile.path,
      );

      final explanation = await _aiService.explainProblem(
        cleanText,
        question.id,
      );

      // Save to provider
      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        await provider.saveQuestionWithExplanation(question, explanation);
        await provider.incrementDailyQuestions();

        // Estimate token usage (rough approximation: 4 characters per token)
        final questionTokens = (cleanText.length / 4).ceil();
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
        _currentExplanation = explanation;
        _isProcessing = false;
      });

      _showSnackBar('Homework scanned and analyzed successfully!');
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Failed to process image: ${e.toString()}', isError: true);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (imageFile == null) return;

      setState(() {
        _isProcessing = true;
        _extractedText = null;
        _currentExplanation = null;
      });

      // Extract text using OCR
      final extractedText = await OCRService.extractTextFromXFile(imageFile);

      if (extractedText.trim().isEmpty) {
        _showSnackBar(
          'No text found in the image. Please try a different image.',
          isError: true,
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Clean the extracted text
      final cleanText = OCRService.cleanExtractedText(extractedText);

      setState(() {
        _extractedText = cleanText;
      });

      // Get AI explanation
      final question = HomeworkQuestion(
        question: cleanText,
        type: QuestionType.image,
        imagePath: imageFile.path,
      );

      final explanation = await _aiService.explainProblem(
        cleanText,
        question.id,
      );

      // Save to provider
      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        await provider.saveQuestionWithExplanation(question, explanation);
        await provider.incrementDailyQuestions();

        // Estimate token usage (rough approximation: 4 characters per token)
        final questionTokens = (cleanText.length / 4).ceil();
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
        _currentExplanation = explanation;
        _isProcessing = false;
      });

      _showSnackBar('Image processed successfully!');
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Failed to process image: ${e.toString()}', isError: true);
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

  void _resetScan() {
    setState(() {
      _extractedText = null;
      _currentExplanation = null;
    });
  }

  void _toggleFullViewMode() {
    setState(() {
      _isFullViewMode = !_isFullViewMode;
    });
  }

  Widget _buildFullViewCamera() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen camera preview
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          
          // Top controls bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _toggleFullViewMode,
                    icon: const Icon(
                      Icons.fullscreen_exit,
                      color: Colors.white,
                      size: 28,
                    ),
                    tooltip: 'Exit full view',
                  ),
                  const Spacer(),
                  Text(
                    'Full View Camera',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 28,
                    ),
                    tooltip: 'Gallery',
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Instructions
                    Text(
                      'Position homework clearly in the frame',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // Capture button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isProcessing ? Colors.grey : Colors.white,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (_isProcessing || !_isCameraInitialized)
                                  ? null
                                  : _captureAndProcess,
                              borderRadius: BorderRadius.circular(40),
                              child: _isProcessing
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.black,
                                        size: 36,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Processing status
                    if (_isProcessing)
                      Text(
                        'Processing your homework...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Center focus frame
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  ...[
                    Alignment.topLeft,
                    Alignment.topRight,
                    Alignment.bottomLeft,
                    Alignment.bottomRight,
                  ].map((alignment) => 
                    Align(
                      alignment: alignment,
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullViewMode && _isCameraInitialized) {
      return _buildFullViewCamera();
    }

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          GradientHeader(
            title: 'Scan Homework',
            subtitle: 'Point your camera at the problem',
            gradientColors: const [
              AppColors.scanGradient1,
              AppColors.scanGradient2,
              AppColors.scanGradient3,
            ],
            child: _currentExplanation != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ModernButton(
                      text: 'Scan New Problem',
                      onPressed: _resetScan,
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
                  if (_currentExplanation == null) _buildCameraSection(),
                  if (_currentExplanation == null) const SizedBox(height: 16),
                  if (_currentExplanation == null) _buildTokenUsageCard(),
                  if (_isProcessing) _buildProcessingWidget(),
                  if (_extractedText != null && _currentExplanation == null)
                    _buildExtractedTextWidget(),
                  if (_currentExplanation != null) _buildExplanationWidget(),
                ],
              ),
            ),
          ),
          if (_currentExplanation == null) _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildCameraSection() {
    if (!_isCameraInitialized) {
      return GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Position your homework',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Make sure the text is clear and well-lit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleFullViewMode,
                      icon: Icon(
                        _isFullViewMode ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: AppColors.primary,
                      ),
                      tooltip: _isFullViewMode ? 'Exit full view' : 'Full view',
                    ),
                  ],
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingWidget() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Processing your homework...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Extracting text and analyzing content',
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
                        'Gemini API Usage (Free Tier)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getUsageLevelColor(provider.usageLevel).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getUsageLevelColor(provider.usageLevel).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        provider.apiUsageStatus.split(' - ')[0], // First part only
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

  Widget _buildExtractedTextWidget() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, color: AppTheme.info, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Extracted Text',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Text(
                _extractedText!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Getting AI explanation...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
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
        // Show extracted text first
        if (_extractedText != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.camera_alt,
                          color: AppTheme.info, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Scanned Text',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _extractedText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

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
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
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

        const SizedBox(height: 16),

        // Action buttons for scanned result
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetScan,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Another'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _playAudio(explanation.answer),
                icon: const Icon(Icons.volume_up),
                label: const Text('Play Audio'),
              ),
            ),
          ],
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
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_isProcessing || !_isCameraInitialized)
                    ? null
                    : _captureAndProcess,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_isProcessing ? 'Processing...' : 'Scan Now'),
              ),
            ),
          ],
        ),
      ),
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
