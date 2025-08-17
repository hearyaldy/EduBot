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
        Provider.of<AppProvider>(context, listen: false).saveQuestion(question);
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
        Provider.of<AppProvider>(context, listen: false).saveQuestion(question);
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
      await AudioService.speakExplanation(text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          GradientHeader(
            title: 'Scan Homework',
            subtitle: 'Point your camera at the problem',
            gradientColors: [
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
                Text(
                  'Make sure the text is clear and well-lit',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
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

  Widget _buildExtractedTextWidget() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, color: AppTheme.info, size: 24),
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
                      Icon(Icons.camera_alt, color: AppTheme.info, size: 20),
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
                    Icon(Icons.lightbulb, color: AppTheme.success, size: 24),
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
}
