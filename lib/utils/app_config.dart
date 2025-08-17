import 'environment_config.dart';

// App configuration constants that can be overridden by environment variables
class AppConfig {
  static final _env = EnvironmentConfig.instance;

  // App Information
  static const String appName = 'EduBot';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI Homework Helper for Parents';

  // Feature Flags (can be overridden by environment)
  static bool get enablePremiumFeatures => _env.enablePremiumFeatures;
  static bool get enableVoiceInput => _env.enableVoiceInput;
  static bool get enableAudioOutput => _env.enableAudioOutput;
  static bool get enableCameraScanning => _env.enableCameraScanning;

  // Limits (can be overridden by environment)
  static int get dailyFreeQuestionLimit => _env.dailyFreeQuestionLimit;
  static int get maxSavedQuestions => _env.maxSavedQuestions;
  static int get maxQuestionLength => _env.maxQuestionLength;

  // AI Configuration (can be overridden by environment)
  static String get defaultAIModel => _env.openAIModel;
  static int get maxAIResponseTokens => _env.openAIMaxTokens;
  static double get aiTemperature => _env.openAITemperature;

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Audio Configuration
  static const double defaultSpeechRate = 0.5; // Slow and clear for parents
  static const double defaultVolume = 0.8;
  static const double defaultPitch = 1.0;

  // OCR Configuration
  static const double minTextConfidence = 0.7;
  static const int maxImageSize = 1024; // pixels

  // Development flags (can be overridden by environment)
  static bool get isDebugMode => _env.isDebugMode;
  static bool get enableDetailedLogging => _env.enableLogging;
  static const bool showPerformanceMetrics = false;

  // Support Information (can be overridden by environment)
  static String get supportEmail => _env.supportEmail;
  static String get privacyPolicyUrl => _env.privacyPolicyUrl;
  static String get termsOfServiceUrl => _env.termsOfServiceUrl;
  static String get helpUrl => _env.helpUrl;
}
