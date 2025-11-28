import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/explanation.dart';
import '../utils/environment_config.dart';
import 'storage_service.dart';

class AIService {
  // Get configuration from environment
  static final _config = EnvironmentConfig.instance;
  static final _storage = StorageService();

  // OpenRouter configuration
  static const String _openRouterBaseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  // Use a reliable, cost-effective model as default
  static const String _defaultModel = 'google/gemma-2-9b-it';

  // Available models on OpenRouter (updated November 2025)
  // These are reliable models that work with OpenRouter API keys
  static const Map<String, String> availableModels = {
    'Gemma 2 (9B)': 'google/gemma-2-9b-it',
    'Llama 3.1 (8B)': 'meta-llama/llama-3.1-8b-instruct',
    'Mistral (7B)': 'mistralai/mistral-7b-instruct',
    'Qwen 2.5 (7B)': 'qwen/qwen-2.5-7b-instruct',
    'DeepSeek V3': 'deepseek/deepseek-chat',
  };

  // Constructor
  AIService();

  // Get user's API key from storage (OpenRouter key)
  Future<String?> _getUserApiKey() async {
    try {
      await _storage.initialize();
      // First try to get user-specific key from storage
      final userKey = _storage.getSetting<String>('user_openrouter_api_key');
      if (userKey != null && userKey.isNotEmpty) {
        return userKey;
      }
      // Fall back to .env file key
      final envKey = _config.openRouterApiKey;
      if (envKey.isNotEmpty) {
        return envKey;
      }
      return null;
    } catch (e) {
      if (_config.isDebugMode) {
        print('Error getting user API key: $e');
      }
      return null;
    }
  }

  // Get the selected model (validates it's still available)
  Future<String> _getSelectedModel() async {
    try {
      await _storage.initialize();
      final storedModel = _storage.getSetting<String>('selected_ai_model');

      // If no stored model or stored model is not in available list, use default
      if (storedModel == null || storedModel.isEmpty) {
        return _defaultModel;
      }

      // Check if the stored model is still in the available models list
      final isAvailable = availableModels.values.contains(storedModel);

      if (!isAvailable) {
        // Model no longer available, reset to default
        if (_config.isDebugMode) {
          print(
              'Stored model "$storedModel" is not available, resetting to default: $_defaultModel');
        }
        await _storage.saveSetting('selected_ai_model', _defaultModel);
        return _defaultModel;
      }

      return storedModel;
    } catch (e) {
      return _defaultModel;
    }
  }

  // Set the selected model
  Future<void> setSelectedModel(String modelId) async {
    try {
      await _storage.initialize();
      await _storage.saveSetting('selected_ai_model', modelId);
      if (_config.isDebugMode) {
        print('AI model changed to: $modelId');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Error setting model: $e');
      }
    }
  }

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
      "isKeyStep": true
    }
  ],
  "parentFriendlyTip": "Encouraging tip for the parent",
  "realWorldExample": "How this concept applies in real life",
  "subject": "Math/Science/English/etc",
  "difficulty": "elementary/medium/advanced"
}

Remember: You're helping a parent help their child. Be supportive, clear, and never condescending.
Always respond with valid JSON only, no markdown code blocks.
''';

  // Make API call to OpenRouter
  Future<Map<String, dynamic>?> _callOpenRouter({
    required String prompt,
    String? systemPrompt,
  }) async {
    final apiKey = await _getUserApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
          'OpenRouter API key is not configured. Please add your API key in Settings.');
    }

    final model = await _getSelectedModel();

    final messages = <Map<String, String>>[];

    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    final body = {
      'model': model,
      'messages': messages,
      'max_tokens': 1500,
      'temperature': 0.7,
    };

    if (_config.isDebugMode) {
      print('Calling OpenRouter with model: $model');
    }

    try {
      final response = await http.post(
        Uri.parse(_openRouterBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://edubot.app',
          'X-Title': 'EduBot - AI Homework Helper',
        },
        body: jsonEncode(body),
      );

      if (_config.isDebugMode) {
        print('OpenRouter response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];

        if (content != null) {
          if (_config.isDebugMode) {
            print('OpenRouter response: $content');
          }

          // Clean up the response - remove thinking tags, markdown code blocks, etc.
          String cleanContent = content.toString().trim();

          // Remove <think>...</think> tags (some models include reasoning)
          final thinkRegex = RegExp(r'<think>.*?</think>', dotAll: true);
          cleanContent = cleanContent.replaceAll(thinkRegex, '').trim();

          // Remove markdown code blocks if present
          if (cleanContent.startsWith('```json')) {
            cleanContent = cleanContent.substring(7);
          } else if (cleanContent.startsWith('```')) {
            cleanContent = cleanContent.substring(3);
          }
          if (cleanContent.endsWith('```')) {
            cleanContent = cleanContent.substring(0, cleanContent.length - 3);
          }
          cleanContent = cleanContent.trim();

          // Try to extract JSON from the response if it's not pure JSON
          if (!cleanContent.startsWith('{')) {
            final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanContent);
            if (jsonMatch != null) {
              cleanContent = jsonMatch.group(0) ?? cleanContent;
            }
          }

          // Try to parse as JSON
          try {
            return jsonDecode(cleanContent);
          } catch (e) {
            // Return as raw text if not valid JSON
            return {'raw_response': content};
          }
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        throw Exception(
            'OpenRouter API error: $errorMessage (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('OpenRouter call failed: $e');
      }
      rethrow;
    }

    return null;
  }

  String _getLanguageInstruction(String language) {
    switch (language.toLowerCase()) {
      case 'malay':
        return 'Please respond in Bahasa Malaysia (Malay). Use simple, clear Malay language.';
      case 'spanish':
        return 'Please respond in Spanish. Use simple, clear Spanish.';
      case 'french':
        return 'Please respond in French. Use simple, clear French.';
      case 'german':
        return 'Please respond in German. Use simple, clear German.';
      case 'chinese':
        return 'Please respond in Simplified Chinese.';
      case 'japanese':
        return 'Please respond in Japanese.';
      default:
        return 'Please respond in English.';
    }
  }

  Future<Explanation> explainProblem(String question, String questionId,
      {String language = 'English'}) async {
    try {
      final languageInstruction = _getLanguageInstruction(language);
      final prompt = '$languageInstruction\n\nQuestion: $question';

      if (_config.isDebugMode) {
        print(
            'Sending question to OpenRouter: $question (Language: $language)');
      }

      final response = await _callOpenRouter(
        prompt: prompt,
        systemPrompt: _systemPrompt,
      );

      if (response != null) {
        // Check if we got a raw response (non-JSON)
        if (response.containsKey('raw_response')) {
          return Explanation(
            questionId: questionId,
            question: question,
            answer: response['raw_response'],
            steps: [],
            parentFriendlyTip: "The AI provided a response.",
            realWorldExample: null,
            subject: 'General',
            difficulty: DifficultyLevel.medium,
          );
        }

        return Explanation(
          questionId: questionId,
          question: question,
          answer: response['answer'] ?? 'No answer provided',
          steps: (response['steps'] as List? ?? [])
              .map((step) => ExplanationStep.fromJson(
                  step is Map<String, dynamic>
                      ? step
                      : Map<String, dynamic>.from(step)))
              .toList(),
          parentFriendlyTip: response['parentFriendlyTip'],
          realWorldExample: response['realWorldExample'],
          subject: response['subject'] ?? 'General',
          difficulty: DifficultyLevel.values.firstWhere(
            (e) => e.name == response['difficulty'],
            orElse: () => DifficultyLevel.medium,
          ),
        );
      } else {
        throw Exception('OpenRouter API returned empty response');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('AI Service Error: $e');
      }
      return _createFallbackExplanation(question, questionId,
          error: e.toString());
    }
  }

  Explanation _createFallbackExplanation(String question, String questionId,
      {String? error}) {
    final isApiError = error?.contains('API') == true;
    final isConfigError = error?.contains('not configured') == true;

    String fallbackAnswer;
    String fallbackDescription;

    if (isConfigError) {
      fallbackAnswer = "OpenRouter API is not properly configured.";
      fallbackDescription =
          "The OpenRouter API key is missing or invalid. Please add your API key in the Settings screen.";
    } else if (isApiError) {
      fallbackAnswer = "There was an issue with the AI service.";
      fallbackDescription =
          "The AI service returned an error. This could be due to API limits, invalid requests, or temporary service issues.";
    } else {
      fallbackAnswer =
          "I'm having trouble connecting to our AI service right now. Please try again in a moment.";
      fallbackDescription =
          "Our AI explanation service is temporarily unavailable. This could be due to network connectivity or high demand.";
    }

    return Explanation(
      questionId: questionId,
      question: question,
      answer: fallbackAnswer,
      steps: [
        ExplanationStep(
          stepNumber: 1,
          title: isConfigError ? "Configuration Error" : "Service Unavailable",
          description: fallbackDescription,
          tip: isConfigError
              ? "Please add your OpenRouter API key in the Settings screen to use AI explanations."
              : "Don't worry! You can try asking the question again, or break it down into smaller parts.",
          isKeyStep: true,
        ),
        if (error != null && _config.isDebugMode)
          ExplanationStep(
            stepNumber: 2,
            title: "Debug Information",
            description: "Error details: $error",
            tip: "This information is only shown in debug mode.",
            isKeyStep: false,
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
  Future<bool> get isConfigured async {
    final apiKey = await _getUserApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  // Get configuration status for debugging
  Future<Map<String, dynamic>> getConfigStatus() async {
    final model = await _getSelectedModel();
    return {
      'api_key_configured': await isConfigured,
      'model': model,
      'max_tokens': 1500,
      'temperature': 0.7,
      'service': 'OpenRouter',
    };
  }

  // Save user's API key
  Future<void> saveUserApiKey(String apiKey) async {
    try {
      await _storage.initialize();
      await _storage.saveSetting('user_openrouter_api_key', apiKey);
      if (_config.isDebugMode) {
        print('User API key saved successfully');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Error saving user API key: $e');
      }
      throw Exception('Failed to save API key: $e');
    }
  }

  // Remove user's API key
  Future<void> removeUserApiKey() async {
    try {
      await _storage.initialize();
      await _storage.deleteSetting('user_openrouter_api_key');
      if (_config.isDebugMode) {
        print('User API key removed successfully');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Error removing user API key: $e');
      }
      throw Exception('Failed to remove API key: $e');
    }
  }

  // Method to test if the API key is valid
  Future<bool> testConnection() async {
    if (!await isConfigured) {
      return false;
    }

    try {
      final response = await explainProblem("What is 2 + 2?", "test");
      return response.answer.isNotEmpty &&
          !response.answer.contains('not configured') &&
          !response.answer.contains('error');
    } catch (e) {
      return false;
    }
  }

  /// Generate AI-powered hints for a question
  Future<Map<String, String>> generateQuestionHints({
    required String questionText,
    required String subject,
    required String topic,
    String? answerKey,
  }) async {
    try {
      final prompt = '''
Analyze this question and provide helpful hints for a student trying to solve it.
Do NOT give the answer directly - just help them understand HOW to solve it.

Question: $questionText
Subject: $subject
Topic: $topic

Provide your response as JSON with this exact structure (no markdown, just JSON):
{
  "solvingSteps": "Step-by-step approach to solve this specific question (numbered steps, be specific to this question)",
  "tips": "Specific tips and things to watch out for in this question (bullet points with •)",
  "example": "A similar worked example that teaches the same concept without giving away the answer"
}

Be specific to THIS question. Don't give generic advice.
Focus on teaching the approach, not revealing the answer.
''';

      if (_config.isDebugMode) {
        print('Generating hints for question: $questionText');
      }

      final response = await _callOpenRouter(prompt: prompt);

      if (response != null && !response.containsKey('raw_response')) {
        // Handle solvingSteps - could be a list or string
        String solvingSteps = '';
        final stepsData = response['solvingSteps'];
        if (stepsData is List) {
          solvingSteps = stepsData.join('\n');
        } else if (stepsData != null) {
          solvingSteps = stepsData.toString();
        }

        // Handle tips - could be a list or string
        String tips = '';
        final tipsData = response['tips'];
        if (tipsData is List) {
          tips = tipsData.join('\n');
        } else if (tipsData != null) {
          tips = tipsData.toString();
        }

        // Handle example - usually a string
        String example = response['example']?.toString() ?? '';

        return {
          'solvingSteps': _cleanMarkdown(solvingSteps),
          'tips': _cleanMarkdown(tips),
          'example': _cleanMarkdown(example),
        };
      }
      return _getFallbackHints(questionText, subject, topic);
    } catch (e) {
      if (_config.isDebugMode) {
        print('Error generating hints: $e');
      }
      return _getFallbackHints(questionText, subject, topic);
    }
  }

  /// Clean markdown formatting from text for plain display
  String _cleanMarkdown(String text) {
    if (text.isEmpty) return text;

    String cleaned = text;

    // Remove bold markers (**text** or __text__)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'__(.+?)__'),
      (match) => match.group(1) ?? '',
    );

    // Remove italic markers (*text* or _text_) - be careful not to remove bullet points
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
      (match) => match.group(1) ?? '',
    );

    // Remove inline code markers (`text`)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'`(.+?)`'),
      (match) => match.group(1) ?? '',
    );

    // Clean up any double spaces
    cleaned = cleaned.replaceAll(RegExp(r'  +'), ' ');

    return cleaned.trim();
  }

  Map<String, String> _getFallbackHints(
      String question, String subject, String topic) {
    return {
      'solvingSteps':
          '1. Read the question carefully.\n2. Identify what is being asked.\n3. Recall what you know about $topic.\n4. Apply your knowledge step by step.\n5. Check your answer.',
      'tips':
          '• Take your time to understand the question.\n• Look for key words and numbers.\n• Think about similar problems you\'ve solved.\n• Don\'t rush - accuracy is more important than speed.',
      'example':
          'Think about the concepts from $topic. Break the problem into smaller parts and solve each part.',
    };
  }
}
