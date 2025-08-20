import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../providers/app_provider.dart';
import '../widgets/gradient_header.dart';
import '../widgets/glass_card.dart';
import '../core/theme/app_colors.dart';
import '../services/audio_service.dart';

class ExplanationDetailScreen extends StatefulWidget {
  final HomeworkQuestion question;

  const ExplanationDetailScreen({
    super.key,
    required this.question,
  });

  @override
  State<ExplanationDetailScreen> createState() =>
      _ExplanationDetailScreenState();
}

class _ExplanationDetailScreenState extends State<ExplanationDetailScreen> {
  Explanation? _explanation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExplanation();
  }

  Future<void> _loadExplanation() async {
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final explanation =
          await provider.getExplanationForQuestion(widget.question.id);

      if (mounted) {
        setState(() {
          _explanation = explanation;
          _isLoading = false;
          if (explanation == null) {
            _error = 'No explanation found for this question';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load explanation: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          GradientHeader(
            title: 'Answer Details',
            subtitle: widget.question.subject ?? 'General',
            gradientColors: [
              AppColors.primary,
              AppColors.secondary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_explanation == null) {
      return const Center(
        child: Text('No explanation available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionCard(),
          const SizedBox(height: 16),
          _buildAnswerCard(),
          if (_explanation!.steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildStepsCard(),
          ],
          if (_explanation!.parentFriendlyTip?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildParentTipCard(),
          ],
          if (_explanation!.realWorldExample?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildRealWorldExampleCard(),
          ],
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Question',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.question.question,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Answer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _playAudio(_explanation!.answer),
                icon: const Icon(Icons.volume_up),
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _explanation!.answer,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.format_list_numbered,
                color: Colors.blue,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Step-by-Step Solution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._explanation!.steps.map((step) => _buildStepItem(step)),
        ],
      ),
    );
  }

  Widget _buildStepItem(ExplanationStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: step.isKeyStep
            ? Colors.blue.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: step.isKeyStep
              ? Colors.blue.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: step.isKeyStep ? Colors.blue : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${step.stepNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: step.isKeyStep ? Colors.blue : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: const TextStyle(height: 1.4),
          ),
          if (step.tip?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 16,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.tip!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[700],
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
    );
  }

  Widget _buildParentTipCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: Colors.purple,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Parent Tip',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _explanation!.parentFriendlyTip!,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealWorldExampleCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.public,
                color: Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Real World Example',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _explanation!.realWorldExample!,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _playAudio(_explanation!.answer),
                icon: const Icon(Icons.volume_up),
                label: const Text('Play Answer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareExplanation(),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
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
      _showSnackBar('Failed to play audio: $e', isError: true);
    }
  }

  void _shareExplanation() {
    // Implementation for sharing the explanation
    _showSnackBar('Share functionality coming soon!');
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
