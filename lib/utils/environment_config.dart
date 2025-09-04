import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class EnvironmentConfig {
  // Private constructor
  EnvironmentConfig._();

  // Singleton instance
  static final EnvironmentConfig _instance = EnvironmentConfig._();
  static EnvironmentConfig get instance => _instance;

  // Initialize environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('Environment configuration loaded successfully');
      debugPrint('Loaded environment variables count: ${dotenv.env.length}');
      debugPrint('Supabase URL from env: ${dotenv.env['SUPABASE_URL']?.substring(0, 20)}...');
      
      // Additional validation for critical variables
      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
      
      if (supabaseUrl == null || supabaseUrl.isEmpty) {
        debugPrint('WARNING: SUPABASE_URL is not set in .env file');
      }
      if (supabaseKey == null || supabaseKey.isEmpty) {
        debugPrint('WARNING: SUPABASE_ANON_KEY is not set in .env file');
      }
      
    } catch (e) {
      // If .env file doesn't exist, initialize with empty map
      debugPrint('Warning: .env file not found. Using default configuration: $e');
      debugPrint('This might be normal for release builds, but configuration will be limited');
      // Manually initialize the dotenv to prevent NotInitializedError
      dotenv.testLoad(fileInput: '');
    }
  }

  // Google Gemini Configuration
  String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get geminiModel => dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
  int get geminiMaxTokens =>
      int.tryParse(dotenv.env['GEMINI_MAX_TOKENS'] ?? '1500') ?? 1500;
  double get geminiTemperature =>
      double.tryParse(dotenv.env['GEMINI_TEMPERATURE'] ?? '0.7') ?? 0.7;

  // Legacy OpenAI Configuration (kept for reference)
  String get openAIApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  String get openAIModel => dotenv.env['OPENAI_MODEL'] ?? 'gpt-3.5-turbo';
  int get openAIMaxTokens =>
      int.tryParse(dotenv.env['OPENAI_MAX_TOKENS'] ?? '1500') ?? 1500;
  double get openAITemperature =>
      double.tryParse(dotenv.env['OPENAI_TEMPERATURE'] ?? '0.7') ?? 0.7;

  // App Configuration
  String get appEnvironment => dotenv.env['APP_ENV'] ?? 'development';
  bool get isDebugMode =>
      _parseBool(dotenv.env['DEBUG_MODE'], defaultValue: true);
  bool get enableLogging =>
      _parseBool(dotenv.env['ENABLE_LOGGING'], defaultValue: true);

  // Security Configuration
  String get superadminPassword =>
      dotenv.env['SUPERADMIN_PASSWORD'] ?? 'admin123';

  // Feature Flags
  bool get enablePremiumFeatures =>
      _parseBool(dotenv.env['ENABLE_PREMIUM_FEATURES'], defaultValue: true);
  bool get enableVoiceInput =>
      _parseBool(dotenv.env['ENABLE_VOICE_INPUT'], defaultValue: true);
  bool get enableAudioOutput =>
      _parseBool(dotenv.env['ENABLE_AUDIO_OUTPUT'], defaultValue: true);
  bool get enableCameraScanning =>
      _parseBool(dotenv.env['ENABLE_CAMERA_SCANNING'], defaultValue: true);

  // Limits
  int get dailyFreeQuestionLimit =>
      int.tryParse(dotenv.env['DAILY_FREE_QUESTION_LIMIT'] ?? '30') ?? 30;
  int get dailyRegisteredQuestionLimit =>
      int.tryParse(dotenv.env['DAILY_REGISTERED_QUESTION_LIMIT'] ?? '60') ?? 60;
  int get maxSavedQuestions =>
      int.tryParse(dotenv.env['MAX_SAVED_QUESTIONS'] ?? '100') ?? 100;
  int get maxQuestionLength =>
      int.tryParse(dotenv.env['MAX_QUESTION_LENGTH'] ?? '500') ?? 500;

  // Supabase Configuration
  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  String get supabaseServiceRoleKey => dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  // Support Information
  String get supportEmail =>
      dotenv.env['SUPPORT_EMAIL'] ?? 'support@edubot.app';
  String get privacyPolicyUrl =>
      dotenv.env['PRIVACY_POLICY_URL'] ?? 'https://edubot.app/privacy';
  String get termsOfServiceUrl =>
      dotenv.env['TERMS_OF_SERVICE_URL'] ?? 'https://edubot.app/terms';
  String get helpUrl => dotenv.env['HELP_URL'] ?? 'https://edubot.app/help';

  // API Endpoints (optional)
  String? get apiBaseUrl => dotenv.env['API_BASE_URL'];
  String get apiVersion => dotenv.env['API_VERSION'] ?? 'v1';

  // Analytics (optional)
  String? get analyticsApiKey => dotenv.env['ANALYTICS_API_KEY'];
  bool get enableAnalytics =>
      _parseBool(dotenv.env['ENABLE_ANALYTICS'], defaultValue: false);

  // AdMob Configuration
  String get admobAppIdAndroid => dotenv.env['ADMOB_APP_ID_ANDROID'] ?? '';
  String get admobAppIdIOS => dotenv.env['ADMOB_APP_ID_IOS'] ?? '';
  String get admobBannerAdUnitIdAndroid =>
      dotenv.env['ADMOB_BANNER_AD_UNIT_ID_ANDROID'] ?? '';
  String get admobBannerAdUnitIdIOS =>
      dotenv.env['ADMOB_BANNER_AD_UNIT_ID_IOS'] ?? '';
  String get admobInterstitialAdUnitIdAndroid =>
      dotenv.env['ADMOB_INTERSTITIAL_AD_UNIT_ID_ANDROID'] ?? '';
  String get admobInterstitialAdUnitIdIOS =>
      dotenv.env['ADMOB_INTERSTITIAL_AD_UNIT_ID_IOS'] ?? '';
  
  bool get isAdMobConfigured =>
      admobAppIdAndroid.isNotEmpty && 
      admobAppIdIOS.isNotEmpty && 
      admobBannerAdUnitIdAndroid.isNotEmpty &&
      admobBannerAdUnitIdIOS.isNotEmpty;

  // Validation - Gemini API key is now user-specific
  bool get isGeminiConfigured => false; // Always false since API key is user-specific

  // Supabase validation
  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && 
      supabaseAnonKey.isNotEmpty && 
      supabaseUrl != 'your_supabase_url_here' &&
      supabaseAnonKey != 'your_supabase_anon_key_here';

  // Supabase admin validation (for admin operations)
  bool get isSupabaseAdminConfigured =>
      isSupabaseConfigured &&
      supabaseServiceRoleKey.isNotEmpty &&
      supabaseServiceRoleKey != 'your_supabase_service_role_key_here';

  // Legacy validation
  bool get isOpenAIConfigured =>
      openAIApiKey.isNotEmpty && openAIApiKey != 'your_openai_api_key_here';

  bool get isProductionEnvironment =>
      appEnvironment.toLowerCase() == 'production';
  bool get isDevelopmentEnvironment =>
      appEnvironment.toLowerCase() == 'development';

  // Helper method to parse boolean values from environment
  bool _parseBool(String? value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  // Get all configuration as a map (for debugging, excluding sensitive data)
  Map<String, dynamic> getConfigSummary() {
    return {
      'app_environment': appEnvironment,
      'debug_mode': isDebugMode,
      'enable_logging': enableLogging,
      'gemini_configured': isGeminiConfigured,
      'gemini_model': geminiModel,
      'openai_configured': isOpenAIConfigured,
      'openai_model': openAIModel,
      'daily_question_limit': dailyFreeQuestionLimit,
      'daily_registered_question_limit': dailyRegisteredQuestionLimit,
      'max_saved_questions': maxSavedQuestions,
      'supabase_configured': isSupabaseConfigured,
      'supabase_admin_configured': isSupabaseAdminConfigured,
      'enable_premium_features': enablePremiumFeatures,
      'enable_voice_input': enableVoiceInput,
      'enable_audio_output': enableAudioOutput,
      'enable_camera_scanning': enableCameraScanning,
      'analytics_enabled': enableAnalytics,
      'admob_configured': isAdMobConfigured,
    };
  }

  // Validate critical configuration
  List<String> validateConfiguration() {
    List<String> issues = [];

    // Note: Gemini API key validation is now handled per-user in the app
    // No longer checking for global API key in .env file

    if (dailyFreeQuestionLimit <= 0) {
      issues.add('Daily free question limit must be greater than 0.');
    }

    if (maxSavedQuestions <= 0) {
      issues.add('Max saved questions must be greater than 0.');
    }

    if (geminiMaxTokens <= 0) {
      issues.add('Gemini max tokens must be greater than 0.');
    }

    if (geminiTemperature < 0 || geminiTemperature > 2) {
      issues.add('Gemini temperature must be between 0 and 2.');
    }

    return issues;
  }
}
