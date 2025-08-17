import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/explanation.dart';
import '../utils/environment_config.dart';

class AIService {
  // Get configuration from environment
  static final _config = EnvironmentConfig.instance;
  static String get _model => _config.geminiModel;
  static String get _apiKey => _config.geminiApiKey;
  static int get _maxTokens => _config.geminiMaxTokens;
  static double get _temperature => _config.geminiTemperature;
  
  // Initialize Gemini model
  late final GenerativeModel _geminiModel;
  
  // Constructor to initialize the model
  AIService() {
    _geminiModel = GenerativeModel(
      model: _model,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: _temperature,
        maxOutputTokens: _maxTokens,
        responseMimeType: 'application/json',
      ),
      systemInstruction: Content.system(_systemPrompt),
    );
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
      if (!isConfigured) {
        throw Exception('Gemini API key is not configured. Please check your .env file.');
      }

      // Create the prompt for the user question
      final prompt = question;
      
      if (_config.isDebugMode) {
        print('Sending question to Gemini: $question');
      }

      // Generate content using Gemini
      final response = await _geminiModel.generateContent([
        Content.text(prompt),
      ]);

      if (_config.isDebugMode) {
        print('Gemini Response: ${response.text}');
      }

      if (response.text != null && response.text!.isNotEmpty) {
        final content = response.text!;

        // Try to parse the JSON response from Gemini
        try {
          final explanationData = jsonDecode(content);

          return Explanation(
            questionId: questionId,
            question: question,
            answer: explanationData['answer'] ?? 'No answer provided',
            steps: (explanationData['steps'] as List? ?? [])
                .map((step) => ExplanationStep.fromJson(step))
                .toList(),
            parentFriendlyTip: explanationData['parentFriendlyTip'],
            realWorldExample: explanationData['realWorldExample'],
            subject: explanationData['subject'] ?? 'General',
            difficulty: DifficultyLevel.values.firstWhere(
              (e) => e.name == explanationData['difficulty'],
              orElse: () => DifficultyLevel.medium,
            ),
          );
        } catch (jsonError) {
          // If JSON parsing fails, create a simple explanation
          if (_config.isDebugMode) {
            print('JSON Parsing Error: $jsonError');
            print('Content that failed to parse: $content');
          }
          
          return Explanation(
            questionId: questionId,
            question: question,
            answer: content, // Use the raw content as answer
            steps: [],
            parentFriendlyTip: "The AI provided a response, but it wasn't in the expected format.",
            realWorldExample: null,
            subject: 'General',
            difficulty: DifficultyLevel.medium,
          );
        }
      } else {
        throw Exception('Gemini API returned empty response');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('AI Service Error: $e');
      }
      
      // Return a fallback explanation with the actual error
      return _createFallbackExplanation(question, questionId, error: e.toString());
    }
  }

  Explanation _createFallbackExplanation(String question, String questionId, {String? error}) {
    final isApiError = error?.contains('API') == true;
    final isConfigError = error?.contains('not configured') == true;
    
    String fallbackAnswer;
    String fallbackDescription;
    
    if (isConfigError) {
      fallbackAnswer = "OpenAI API is not properly configured.";
      fallbackDescription = "The OpenAI API key is missing or invalid. Please check your .env file and ensure OPENAI_API_KEY is set with a valid key.";
    } else if (isApiError) {
      fallbackAnswer = "There was an issue with the AI service.";
      fallbackDescription = "The AI service returned an error. This could be due to API limits, invalid requests, or temporary service issues.";
    } else {
      fallbackAnswer = "I'm having trouble connecting to our AI service right now. Please try again in a moment.";
      fallbackDescription = "Our AI explanation service is temporarily unavailable. This could be due to network connectivity or high demand.";
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
              ? "Ask the app developer to properly configure the OpenAI API key."
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
  static bool get isConfigured => _config.isGeminiConfigured;

  // Get configuration status for debugging
  static Map<String, dynamic> getConfigStatus() {
    return {
      'api_key_configured': isConfigured,
      'model': _model,
      'max_tokens': _maxTokens,
      'temperature': _temperature,
      'service': 'Google Gemini',
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
