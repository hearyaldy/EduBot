import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/explanation.dart';
import '../utils/environment_config.dart';

class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1';

  // Get configuration from environment
  static final _config = EnvironmentConfig.instance;
  static String get _model => _config.openAIModel;
  static String get _apiKey => _config.openAIApiKey;
  static int get _maxTokens => _config.openAIMaxTokens;
  static double get _temperature => _config.openAITemperature;

  static const String _systemPrompt = '''
You are EduBot, a friendly AI homework helper designed specifically for parents who want to help their children with homework but may not remember the concepts themselves.

Your mission is to:
1. Explain clearly and kindly using simple language
2. Never make the parent feel bad for not knowing something
3. Use real-world examples and analogies
4. Break down problems into manageable steps
5. Provide encouragement and confidence-building tips

Format your response as JSON with the following structure:
{
  "answer": "Direct answer to the problem",
  "steps": [
    {
      "stepNumber": 1,
      "title": "Step title",
      "description": "Detailed explanation",
      "tip": "Optional parent tip",
      "isKeyStep": true/false
    }
  ],
  "parentFriendlyTip": "Encouraging tip for the parent",
  "realWorldExample": "How this concept applies in real life",
  "subject": "Math/Science/English/etc",
  "difficulty": "elementary/medium/advanced"
}

Remember: You're helping a parent help their child. Be supportive, clear, and never condescending.
''';

  Future<Explanation> explainProblem(String question, String questionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': question},
          ],
          'temperature': _temperature,
          'max_tokens': _maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Parse the JSON response from GPT
        final explanationData = jsonDecode(content);

        return Explanation(
          questionId: questionId,
          question: question,
          answer: explanationData['answer'],
          steps: (explanationData['steps'] as List)
              .map((step) => ExplanationStep.fromJson(step))
              .toList(),
          parentFriendlyTip: explanationData['parentFriendlyTip'],
          realWorldExample: explanationData['realWorldExample'],
          subject: explanationData['subject'],
          difficulty: DifficultyLevel.values.firstWhere(
            (e) => e.name == explanationData['difficulty'],
            orElse: () => DifficultyLevel.medium,
          ),
        );
      } else {
        throw Exception('Failed to get explanation: ${response.statusCode}');
      }
    } catch (e) {
      // Return a fallback explanation if the API fails
      return _createFallbackExplanation(question, questionId);
    }
  }

  Explanation _createFallbackExplanation(String question, String questionId) {
    return Explanation(
      questionId: questionId,
      question: question,
      answer:
          "I'm having trouble connecting to our AI service right now. Please try again in a moment.",
      steps: [
        ExplanationStep(
          stepNumber: 1,
          title: "Service Unavailable",
          description:
              "Our AI explanation service is temporarily unavailable. This could be due to network connectivity or high demand.",
          tip:
              "Don't worry! You can try asking the question again, or break it down into smaller parts.",
          isKeyStep: true,
        ),
      ],
      parentFriendlyTip:
          "Technology hiccups happen! Take a deep breath and remember that learning together is what matters most.",
      realWorldExample:
          "Just like when the internet is slow, sometimes our AI needs a moment to catch up.",
      subject: "General",
      difficulty: DifficultyLevel.medium,
    );
  }

  // Check if API is properly configured
  static bool get isConfigured => _config.isOpenAIConfigured;

  // Get configuration status for debugging
  static Map<String, dynamic> getConfigStatus() {
    return {
      'api_key_configured': isConfigured,
      'model': _model,
      'max_tokens': _maxTokens,
      'temperature': _temperature,
    };
  }

  // Method to test if the API key is valid
  Future<bool> testConnection() async {
    if (!isConfigured) {
      return false;
    }

    try {
      final response = await explainProblem("What is 2 + 2?", "test");
      return response.answer.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
