# OpenRouter Integration Guide

## Quick Start

The OpenRouter AI service is now ready to use in your EduBot app!

## Using the Service

### Basic Usage

```dart
import 'package:edubot/services/openrouter_ai_service.dart';
import 'package:edubot/models/explanation.dart';

// Create service instance
final aiService = OpenRouterAIService();

// Check if configured
if (OpenRouterAIService.isConfigured) {
  // Get explanation for a question
  final explanation = await aiService.getExplanation(
    question: 'What is 5 + 3?',
    language: 'English',
    gradeLevel: 'Elementary',
  );

  print('Answer: ${explanation.answer}');
  print('Steps: ${explanation.steps.length}');
  print('Subject: ${explanation.subject}');
} else {
  print('OpenRouter API key not configured');
}
```

### With Image Support

```dart
// For homework problems with images
final explanation = await aiService.getExplanation(
  question: 'Solve the math problem in the image',
  imageBase64: base64ImageString, // Optional
  language: 'English',
  gradeLevel: 'Middle School',
);
```

### Multi-Language Support

```dart
// Ask in Malay
final explanationMalay = await aiService.getExplanation(
  question: 'Apakah 5 + 3?',
  language: 'Malay',
  gradeLevel: 'Elementary',
);

// Ask in Spanish
final explanationSpanish = await aiService.getExplanation(
  question: '¿Qué es 5 + 3?',
  language: 'Spanish',
  gradeLevel: 'Elementary',
);
```

## Integrating with Existing Code

### Option 1: Replace Existing AI Service

If you have an existing AI service (e.g., Google Generative AI), you can replace it:

**Before:**
```dart
import 'package:edubot/services/ai_service.dart';

final aiService = AIService();
final explanation = await aiService.getExplanation(question: question);
```

**After:**
```dart
import 'package:edubot/services/openrouter_ai_service.dart';

final aiService = OpenRouterAIService();
final explanation = await aiService.getExplanation(
  question: question,
  language: userLanguage,
  gradeLevel: userGradeLevel,
);
```

### Option 2: Add as Alternative

Keep both services and let users choose:

```dart
import 'package:edubot/services/ai_service.dart';
import 'package:edubot/services/openrouter_ai_service.dart';

Future<Explanation> getExplanation({
  required String question,
  required String aiProvider, // 'gemini' or 'openrouter'
}) async {
  if (aiProvider == 'openrouter' && OpenRouterAIService.isConfigured) {
    final service = OpenRouterAIService();
    return await service.getExplanation(question: question);
  } else {
    final service = AIService();
    return await service.getExplanation(question: question);
  }
}
```

## Example Integration in Ask Question Screen

Here's how to integrate into your existing `AskQuestionScreen`:

```dart
// In lib/screens/ask_question_screen.dart

Future<void> _submitQuestion() async {
  setState(() => _isLoading = true);

  try {
    // Use OpenRouter service
    final aiService = OpenRouterAIService();

    final explanation = await aiService.getExplanation(
      question: _questionController.text,
      language: _selectedLanguage, // From language dropdown
      gradeLevel: _selectedGradeLevel, // From grade dropdown
    );

    // Save to history
    final question = HomeworkQuestion(
      question: _questionController.text,
      explanation: explanation,
      type: QuestionType.text,
    );

    context.read<AppProvider>().addQuestion(question);

    // Navigate to results
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExplanationScreen(explanation: explanation),
      ),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
```

## Error Handling

The service includes built-in error handling:

```dart
try {
  final explanation = await aiService.getExplanation(
    question: 'What is photosynthesis?',
  );

  // Success - use the explanation
  displayExplanation(explanation);

} catch (e) {
  // Error occurred
  // The service returns a fallback explanation with error message
  // So this catch block is for network/other errors
  print('Error: $e');

  // Show error to user
  showErrorDialog('Failed to get explanation. Please try again.');
}
```

The service returns a user-friendly fallback explanation on errors:

```dart
Explanation(
  questionId: '',
  question: 'Your question',
  answer: 'I encountered an error processing your question. Please try again.',
  steps: [],
  parentFriendlyTip: 'If this problem persists, please check your internet connection...',
  subject: 'Unknown',
  difficulty: DifficultyLevel.medium,
)
```

## Testing the Integration

### 1. Unit Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:edubot/services/openrouter_ai_service.dart';

void main() {
  group('OpenRouterAIService', () {
    test('should be configured with API key', () {
      expect(OpenRouterAIService.isConfigured, isTrue);
    });

    test('should get explanation for simple math', () async {
      final service = OpenRouterAIService();
      final explanation = await service.getExplanation(
        question: 'What is 2 + 2?',
      );

      expect(explanation.answer, isNotEmpty);
      expect(explanation.steps, isNotEmpty);
    });
  });
}
```

### 2. Manual Testing

1. **Open the app**
2. **Navigate to "Ask Question"**
3. **Enter a test question**: "What is 5 + 3?"
4. **Select language**: English
5. **Select grade**: Elementary
6. **Submit**
7. **Verify response** includes:
   - Answer: "8"
   - Step-by-step explanation
   - Parent tips
   - Real-world example

### 3. Check Logs

Monitor the logs to verify requests:

```bash
adb logcat | grep "OpenRouterAI"
```

Expected output:
```
[OpenRouterAI] === OpenRouter AI Request ===
[OpenRouterAI] Model: google/gemini-2.0-flash-exp:free
[OpenRouterAI] Question: What is 5 + 3?
[OpenRouterAI] Language: English
[OpenRouterAI] Grade: Elementary
[OpenRouterAI] Response status: 200
[OpenRouterAI] ✓ Received response from OpenRouter
```

## Explanation Object Structure

The `Explanation` object returned contains:

```dart
class Explanation {
  final String id;                    // Unique ID
  final String questionId;            // Question ID
  final String question;              // Original question
  final String answer;                // Direct answer
  final List<ExplanationStep> steps;  // Step-by-step breakdown
  final String? parentFriendlyTip;    // Parent guidance
  final String? realWorldExample;     // Real-world application
  final String subject;               // Subject (Math, Science, etc)
  final DifficultyLevel difficulty;   // elementary/medium/advanced
  final DateTime createdAt;           // Timestamp
}
```

### Accessing the Data

```dart
final explanation = await aiService.getExplanation(question: 'What is gravity?');

// Get answer
print('Answer: ${explanation.answer}');

// Get steps
for (var step in explanation.steps) {
  print('Step ${step.stepNumber}: ${step.title}');
  print('  ${step.description}');
  if (step.tip != null) {
    print('  Tip: ${step.tip}');
  }
}

// Get parent tip
if (explanation.parentFriendlyTip != null) {
  print('Parent Tip: ${explanation.parentFriendlyTip}');
}

// Get real-world example
if (explanation.realWorldExample != null) {
  print('Real-World: ${explanation.realWorldExample}');
}

// Get metadata
print('Subject: ${explanation.subject}');
print('Difficulty: ${explanation.difficulty.displayName}');
print('Created: ${explanation.createdAt}');
```

## Performance Optimization

### Caching Responses

To avoid duplicate API calls:

```dart
class AIServiceWithCache {
  final _cache = <String, Explanation>{};
  final _aiService = OpenRouterAIService();

  Future<Explanation> getExplanation({required String question}) async {
    // Check cache first
    if (_cache.containsKey(question)) {
      return _cache[question]!;
    }

    // Call API
    final explanation = await _aiService.getExplanation(question: question);

    // Cache result
    _cache[question] = explanation;

    return explanation;
  }

  void clearCache() {
    _cache.clear();
  }
}
```

### Loading States

Show loading indicator while waiting for response:

```dart
class AskQuestionScreen extends StatefulWidget {
  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  bool _isLoading = false;
  final _aiService = OpenRouterAIService();

  Future<void> _submitQuestion() async {
    setState(() => _isLoading = true);

    try {
      final explanation = await _aiService.getExplanation(
        question: _questionController.text,
      );

      // Handle success
      _showExplanation(explanation);

    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildQuestionForm(),
    );
  }
}
```

## Switching Models

To change the AI model, edit `lib/services/openrouter_ai_service.dart`:

```dart
class OpenRouterAIService {
  // Change this line to use a different model
  static const String _model = 'google/gemini-2.0-flash-exp:free';

  // Other available free models:
  // static const String _model = 'meta-llama/llama-3.2-3b-instruct:free';
  // static const String _model = 'microsoft/phi-3-mini-128k-instruct:free';
  // static const String _model = 'google/gemma-2-9b-it:free';
}
```

After changing the model:
1. Restart the app
2. Test with sample questions
3. Verify response quality

## Next Steps

1. **Integrate into Ask Question Screen** (`lib/screens/ask_question_screen.dart`)
2. **Integrate into Scan Homework Screen** (`lib/screens/scan_homework_screen.dart`)
3. **Add model selection** in Settings (optional)
4. **Add usage tracking** to monitor API calls
5. **Implement response caching** for better performance

## Support

If you encounter issues:
1. Check `OPENROUTER_SETUP.md` for troubleshooting
2. Verify API key is set in `.env`
3. Check logs: `adb logcat | grep OpenRouterAI`
4. Visit OpenRouter docs: https://openrouter.ai/docs

## Summary

✅ **Service is ready to use**
✅ **API key configured**
✅ **Error handling included**
✅ **Multi-language support**
✅ **Parent-friendly responses**
✅ **Free model (Gemini 2.0 Flash)**

Start integrating by adding `OpenRouterAIService()` to your question screens!
