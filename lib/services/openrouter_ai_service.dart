import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/explanation.dart';
import '../utils/environment_config.dart';

class OpenRouterAIService {
  static final _config = EnvironmentConfig.instance;

  // OpenRouter API configuration
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  
  // Primary and fallback models (in order of preference)
  static const List<String> _models = [
    'meta-llama/llama-3.2-3b-instruct:free',      // Primary: Most reliable
    'microsoft/phi-3-mini-128k-instruct:free',    // Fallback 1: Microsoft model
    'google/gemini-flash-1.5:free',               // Fallback 2: Stable Gemini
    'qwen/qwen-2-7b-instruct:free',               // Fallback 3: Qwen model
  ];
  
  static int _currentModelIndex = 0;
  static String get _model => _models[_currentModelIndex];

  // Get OpenRouter API key from environment
  static String get _apiKey => _config.openRouterApiKey;

  // System prompt for educational assistance
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

  /// Get explanation for a homework question with retry mechanism
  Future<Explanation> getExplanation({
    required String question,
    String? imageBase64,
    String language = 'English',
    String gradeLevel = 'Elementary',
  }) async {
    // Try each model in order until one works
    for (int attempt = 0; attempt < _models.length; attempt++) {
      try {
        _debugPrint('=== OpenRouter AI Request (Attempt ${attempt + 1}) ===');
        _debugPrint('Model: $_model');
        _debugPrint('Question: $question');
        _debugPrint('Language: $language');
        _debugPrint('Grade: $gradeLevel');

        final result = await _makeRequest(question, imageBase64, language, gradeLevel);
        
        // If successful, reset to primary model for next time
        if (_currentModelIndex != 0) {
          _debugPrint('✓ Success with fallback model, resetting to primary');
          _currentModelIndex = 0;
        }
        
        return result;
      } catch (e) {
        _debugPrint('✗ Failed with model: $_model, Error: $e');
        
        // If this was a rate limit error and we have more models to try
        if ((e.toString().contains('429') || e.toString().contains('rate')) && 
            _currentModelIndex < _models.length - 1) {
          _currentModelIndex++;
          _debugPrint('→ Switching to fallback model: $_model');
          continue; // Try next model
        }
        
        // If it's the last model or not a rate limit error, throw
        if (_currentModelIndex >= _models.length - 1) {
          // Reset to primary model for next time
          _currentModelIndex = 0;
          _debugPrint('✗ All models failed, providing fallback response');
          return _createRateLimitFallbackExplanation(question);
        }
        
        rethrow;
      }
    }
    
    // This shouldn't be reached, but just in case
    return _createRateLimitFallbackExplanation(question);
  }

  /// Make the actual API request
  Future<Explanation> _makeRequest(
    String question,
    String? imageBase64,
    String language,
    String gradeLevel,
  ) async {
    // Build messages with system prompt and user question
    final messages = [
      {
        'role': 'system',
        'content': _systemPrompt + _getLanguageInstruction(language),
      },
      {
        'role': 'user',
        'content': _buildUserContent(question, imageBase64, gradeLevel),
      },
    ];

    // Make API request to OpenRouter
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://edubot.app', // Optional: your app URL
        'X-Title': 'EduBot', // Optional: your app name
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 2000,
        'response_format': {'type': 'json_object'},
      }),
    );

    _debugPrint('Response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      _debugPrint('Error response: ${response.body}');
      
      // Try to parse error response for details
      try {
        final errorResponse = jsonDecode(response.body);
        final errorMessage = errorResponse['error']['message']?.toString() ?? '';
        
        if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded for model: $_model');
        } else if (response.statusCode == 401) {
          throw Exception('Invalid API key. Please check your OpenRouter configuration.');
        } else if (response.statusCode == 402) {
          throw Exception('Rate limit exceeded for model: $_model');
        } else {
          throw Exception('AI service error (${response.statusCode}): $errorMessage');
        }
      } catch (e) {
        // If JSON parsing fails, use status code only
        if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded for model: $_model');
        } else {
          throw Exception('OpenRouter API error: ${response.statusCode}');
        }
      }
    }

    // Parse response
    final responseData = jsonDecode(response.body);
    final content = responseData['choices'][0]['message']['content'];

    _debugPrint('✓ Received response from OpenRouter');

    return _parseAIResponse(content, question);
  }

  /// Parse the AI response content
  Explanation _parseAIResponse(String content, String question) {
    try {
      // Parse the JSON response from the AI
      final aiResponse = jsonDecode(content);
      return _parseExplanation(aiResponse, question);
    } catch (e) {
      _debugPrint('Failed to parse AI response, using fallback: $e');
      return _createRateLimitFallbackExplanation(question);
    }
  }

  /// Parse explanation from AI response
  }

  String _buildUserContent(String question, String? imageBase64, String gradeLevel) {
    String prompt = '''
Please help with this homework question for a $gradeLevel student:

Question: $question

Please provide a detailed, step-by-step explanation that helps the parent understand the concept so they can guide their child.
''';

    // Note: Gemini 2.0 Flash supports vision, but OpenRouter's API format may vary
    // If you need image support, you might need to adjust the format
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      prompt += '\n\n[Note: An image of the problem was provided]';
    }

    return prompt;
  }

  String _getLanguageInstruction(String language) {
    switch (language.toLowerCase()) {
      case 'malay':
        return '''

IMPORTANT: Please respond in Bahasa Malaysia (Malay). Use simple, clear Malay language that parents can easily understand.
Provide explanations, tips, and examples in Malay while maintaining the same helpful and encouraging tone.
All JSON fields should contain Malay text.
''';
      case 'spanish':
        return '''

IMPORTANT: Please respond in Spanish. Use simple, clear Spanish that parents can easily understand.
All JSON fields should contain Spanish text.
''';
      case 'french':
        return '''

IMPORTANT: Please respond in French. Use simple, clear French that parents can easily understand.
All JSON fields should contain French text.
''';
      case 'chinese':
        return '''

IMPORTANT: Please respond in Simplified Chinese. Use simple, clear Chinese that parents can easily understand.
All JSON fields should contain Chinese text.
''';
      default:
        return '\n\nPlease respond in English.';
    }
  }

  Explanation _parseExplanation(Map<String, dynamic> data, String question) {
    try {
      // Parse steps
      final List<ExplanationStep> steps = [];
      if (data['steps'] != null) {
        final stepsData = data['steps'] as List;
        for (var step in stepsData) {
          steps.add(ExplanationStep(
            stepNumber: step['stepNumber'] ?? steps.length + 1,
            title: step['title'] ?? 'Step ${steps.length + 1}',
            description: step['description'] ?? '',
            tip: step['tip'],
            isKeyStep: step['isKeyStep'] ?? false,
          ));
        }
      }

      return Explanation(
        questionId: '', // Will be set by the caller
        question: question,
        answer: data['answer'] ?? 'No answer provided',
        steps: steps,
        parentFriendlyTip: data['parentFriendlyTip'],
        realWorldExample: data['realWorldExample'],
        subject: data['subject'] ?? 'General',
        difficulty: _parseDifficultyLevel(data['difficulty']),
      );
    } catch (e) {
      _debugPrint('Error parsing explanation: $e');
      // Return basic explanation if parsing fails
      return Explanation(
        questionId: '',
        question: question,
        answer: data['answer']?.toString() ?? 'Unable to parse response',
        steps: [],
        parentFriendlyTip: null,
        realWorldExample: null,
        subject: 'Unknown',
        difficulty: DifficultyLevel.medium,
      );
    }
  }

  /// Parse difficulty string to DifficultyLevel enum
  DifficultyLevel _parseDifficultyLevel(dynamic difficulty) {
    if (difficulty == null) return DifficultyLevel.medium;

    final difficultyStr = difficulty.toString().toLowerCase();
    switch (difficultyStr) {
      case 'elementary':
        return DifficultyLevel.elementary;
      case 'advanced':
        return DifficultyLevel.advanced;
      case 'medium':
      default:
        return DifficultyLevel.medium;
    }
  }

  /// Create a fallback explanation when AI service is rate-limited
  Explanation _createRateLimitFallbackExplanation(String question) {
    return Explanation(
      questionId: '',
      question: question,
      answer: 'AI service is temporarily at capacity. This is common with the free model during peak times.',
      steps: [
        ExplanationStep(
          stepNumber: 1,
          title: 'Try Again Later',
          description: 'The AI service is experiencing high demand. Please try your question again in a few minutes.',
          tip: 'Peak hours are typically in the evening when more students are doing homework.',
          isKeyStep: true,
        ),
        ExplanationStep(
          stepNumber: 2,
          title: 'Add Your Own API Key',
          description: 'Visit openrouter.ai to create your own API key for unlimited access.',
          tip: 'Adding your own API key will give you higher rate limits and priority access.',
          isKeyStep: false,
        ),
        ExplanationStep(
          stepNumber: 3,
          title: 'Alternative Help',
          description: 'In the meantime, try breaking down the problem into smaller parts or searching for similar examples online.',
          tip: 'Sometimes explaining the concept with different words or analogies can help too.',
          isKeyStep: true,
        ),
      ],
      parentFriendlyTip: 'This is a temporary limitation of the free AI model. Your questions will work normally once demand decreases.',
      realWorldExample: 'This is similar to how free online services sometimes get busy during peak hours.',
      subject: 'AI Limitation',
      difficulty: DifficultyLevel.medium,
    );
  }

  /// Check if OpenRouter is configured
  bool get isConfigured {
    return OpenRouterAIService._apiKey.isNotEmpty && OpenRouterAIService._apiKey != 'your-openrouter-api-key';
  }

  /// Debug print with prefix
  void _debugPrint(String message) {
    if (OpenRouterAIService._config.isDebugMode) {
      print('[OpenRouterAI] $message');
    }
  }
