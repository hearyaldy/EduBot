import 'package:flutter/foundation.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../services/storage_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storage = StorageService();

  // Current user session
  int _dailyQuestionsUsed = 0;
  bool _isPremium = false;

  // AI Token tracking
  int _dailyTokensUsed = 0;
  int _totalTokensUsed = 0;
  int _lastQuestionTokens = 0;

  // Global AI usage tracking (across all users)
  static int _globalDailyRequests = 0;
  static int _globalDailyTokens = 0;
  static String _lastResetDate = '';

  // Global API limits (Gemini 2.5 Flash free tier)
  static const int _maxGlobalDailyRequests =
      240; // Keep 10 request buffer from 250 limit
  static const int _maxGlobalDailyTokens = 200000; // Conservative token limit

  // User preferences
  bool _notificationsEnabled = true;
  bool _audioEnabled = true;
  double _speechRate = 0.5;
  String _selectedLanguage = 'English';
  bool _showDailyTips = true;

  // Questions history
  List<HomeworkQuestion> _savedQuestions = [];

  // Current explanation being viewed
  Explanation? _currentExplanation;

  // Loading states
  bool _isLoading = false;
  bool _isScanningImage = false;
  bool _isProcessingAudio = false;
  bool _isInitialized = false;

  // Getters
  int get dailyQuestionsUsed => _dailyQuestionsUsed;
  bool get isPremium => _isPremium;
  bool get canAskQuestion =>
      _isPremium ||
      (_dailyQuestionsUsed < 10 &&
          canMakeGlobalRequest); // Check both user and global limits
  List<HomeworkQuestion> get savedQuestions =>
      List.unmodifiable(_savedQuestions);
  Explanation? get currentExplanation => _currentExplanation;
  bool get isLoading => _isLoading;
  bool get isScanningImage => _isScanningImage;
  bool get isProcessingAudio => _isProcessingAudio;
  bool get isInitialized => _isInitialized;

  // Token usage getters
  int get dailyTokensUsed => _dailyTokensUsed;
  int get totalTokensUsed => _totalTokensUsed;
  int get lastQuestionTokens => _lastQuestionTokens;
  int get remainingQuestions => _isPremium ? -1 : (10 - _dailyQuestionsUsed);
  int get estimatedDailyTokenLimit =>
      _isPremium ? -1 : 50000; // 50k tokens per day for free users
  int get remainingTokens =>
      _isPremium ? -1 : (estimatedDailyTokenLimit - _dailyTokensUsed);
  double get tokenUsagePercentage => _isPremium
      ? 0.0
      : (_dailyTokensUsed / estimatedDailyTokenLimit).clamp(0.0, 1.0);

  // Global usage getters
  static int get globalDailyRequests => _globalDailyRequests;
  static int get globalDailyTokens => _globalDailyTokens;
  static int get remainingGlobalRequests =>
      _maxGlobalDailyRequests - _globalDailyRequests;
  static int get remainingGlobalTokens =>
      _maxGlobalDailyTokens - _globalDailyTokens;
  static double get globalRequestUsagePercentage =>
      (_globalDailyRequests / _maxGlobalDailyRequests).clamp(0.0, 1.0);
  static double get globalTokenUsagePercentage =>
      (_globalDailyTokens / _maxGlobalDailyTokens).clamp(0.0, 1.0);
  static bool get canMakeGlobalRequest =>
      _globalDailyRequests < _maxGlobalDailyRequests;
  static bool get isNearGlobalLimit =>
      _globalDailyRequests > (_maxGlobalDailyRequests * 0.9); // 90% threshold

  // Settings getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get audioEnabled => _audioEnabled;
  double get speechRate => _speechRate;
  String get selectedLanguage => _selectedLanguage;
  bool get showDailyTips => _showDailyTips;

  // Initialize app provider with stored data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load saved questions from storage
      _savedQuestions = await _storage.getAllQuestions();

      // Load user settings
      _dailyQuestionsUsed =
          _storage.getSetting<int>('daily_questions_used', defaultValue: 0) ??
              0;
      _isPremium =
          _storage.getSetting<bool>('is_premium', defaultValue: false) ?? false;

      // Load user preferences
      _notificationsEnabled = _storage.getSetting<bool>('notifications_enabled',
              defaultValue: true) ??
          true;
      _audioEnabled =
          _storage.getSetting<bool>('audio_enabled', defaultValue: true) ??
              true;
      _speechRate =
          _storage.getSetting<double>('speech_rate', defaultValue: 0.5) ?? 0.5;
      _selectedLanguage = _storage.getSetting<String>('selected_language',
              defaultValue: 'English') ??
          'English';
      _showDailyTips =
          _storage.getSetting<bool>('show_daily_tips', defaultValue: true) ??
              true;

      // Load token usage data
      _dailyTokensUsed =
          _storage.getSetting<int>('daily_tokens_used', defaultValue: 0) ?? 0;
      _totalTokensUsed =
          _storage.getSetting<int>('total_tokens_used', defaultValue: 0) ?? 0;
      _lastQuestionTokens =
          _storage.getSetting<int>('last_question_tokens', defaultValue: 0) ??
              0;

      // Load global usage data and check for daily reset
      await _loadGlobalUsageData();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize app provider: $e');
    }
  }

  // Methods
  Future<void> incrementDailyQuestions() async {
    _dailyQuestionsUsed++;
    await _storage.saveSetting('daily_questions_used', _dailyQuestionsUsed);
    notifyListeners();
  }

  // Token usage tracking methods
  Future<void> addTokenUsage(int tokens) async {
    // Check global limits first
    if (!canMakeGlobalRequest) {
      throw Exception(
          'Global daily request limit exceeded. Please try again tomorrow.');
    }

    // Track global usage
    await trackGlobalRequest(tokens);

    // Track user usage
    _dailyTokensUsed += tokens;
    _totalTokensUsed += tokens;
    _lastQuestionTokens = tokens;

    await _storage.saveSetting('daily_tokens_used', _dailyTokensUsed);
    await _storage.saveSetting('total_tokens_used', _totalTokensUsed);
    await _storage.saveSetting('last_question_tokens', _lastQuestionTokens);

    notifyListeners();
  }

  Future<void> resetDailyTokens() async {
    _dailyTokensUsed = 0;
    await _storage.saveSetting('daily_tokens_used', _dailyTokensUsed);
    notifyListeners();
  }

  // Global usage tracking methods
  Future<void> _loadGlobalUsageData() async {
    final today =
        DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format

    // Check if we need to reset daily counters
    _lastResetDate = _storage.getSetting<String>('global_last_reset_date',
            defaultValue: '') ??
        '';

    if (_lastResetDate != today) {
      // Reset daily counters for new day
      _globalDailyRequests = 0;
      _globalDailyTokens = 0;
      _lastResetDate = today;

      await _storage.saveSetting('global_daily_requests', _globalDailyRequests);
      await _storage.saveSetting('global_daily_tokens', _globalDailyTokens);
      await _storage.saveSetting('global_last_reset_date', _lastResetDate);
    } else {
      // Load existing daily data
      _globalDailyRequests =
          _storage.getSetting<int>('global_daily_requests', defaultValue: 0) ??
              0;
      _globalDailyTokens =
          _storage.getSetting<int>('global_daily_tokens', defaultValue: 0) ?? 0;
    }
  }

  static Future<void> trackGlobalRequest(int tokens) async {
    final storage = StorageService();

    // Check if can make request
    if (!canMakeGlobalRequest) {
      throw Exception(
          'Global daily request limit exceeded. Please try again tomorrow.');
    }

    _globalDailyRequests++;
    _globalDailyTokens += tokens;

    // Save to storage
    await storage.saveSetting('global_daily_requests', _globalDailyRequests);
    await storage.saveSetting('global_daily_tokens', _globalDailyTokens);
  }

  static Future<void> resetGlobalCounters() async {
    final storage = StorageService();
    final today = DateTime.now().toIso8601String().split('T')[0];

    _globalDailyRequests = 0;
    _globalDailyTokens = 0;
    _lastResetDate = today;

    await storage.saveSetting('global_daily_requests', _globalDailyRequests);
    await storage.saveSetting('global_daily_tokens', _globalDailyTokens);
    await storage.saveSetting('global_last_reset_date', _lastResetDate);
  }

  Future<void> setPremiumStatus(bool premium) async {
    _isPremium = premium;
    await _storage.saveSetting('is_premium', _isPremium);
    notifyListeners();
  }

  void setCurrentExplanation(Explanation explanation) {
    _currentExplanation = explanation;
    notifyListeners();
  }

  Future<void> saveQuestion(HomeworkQuestion question) async {
    try {
      // Save to storage
      await _storage.saveQuestion(question);

      // Update local list
      _savedQuestions.insert(0, question); // Add to beginning
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save question: $e');
    }
  }

  Future<void> saveQuestionWithExplanation(
      HomeworkQuestion question, Explanation explanation) async {
    try {
      // Save both question and explanation
      await _storage.saveQuestion(question);
      await _storage.saveExplanation(explanation);

      // Update local list
      _savedQuestions.insert(0, question);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save question and explanation: $e');
    }
  }

  Future<void> removeQuestion(String questionId) async {
    try {
      // Remove from storage
      await _storage.deleteQuestion(questionId);

      // Update local list
      _savedQuestions.removeWhere((q) => q.id == questionId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to remove question: $e');
    }
  }

  Future<Explanation?> getExplanationForQuestion(String questionId) async {
    try {
      return await _storage.getExplanation(questionId);
    } catch (e) {
      debugPrint('Failed to get explanation: $e');
      return null;
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setScanningImage(bool scanning) {
    _isScanningImage = scanning;
    notifyListeners();
  }

  void setProcessingAudio(bool processing) {
    _isProcessingAudio = processing;
    notifyListeners();
  }

  void clearCurrentExplanation() {
    _currentExplanation = null;
    notifyListeners();
  }

  // Reset daily questions (typically called at midnight)
  Future<void> resetDailyQuestions() async {
    _dailyQuestionsUsed = 0;
    await _storage.saveSetting('daily_questions_used', _dailyQuestionsUsed);
    notifyListeners();
  }

  // Clear all question history
  Future<void> clearQuestionHistory() async {
    try {
      await _storage.clearAllQuestions();
      _savedQuestions.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear question history: $e');
    }
  }

  // Settings methods
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _storage.saveSetting('notifications_enabled', enabled);
    notifyListeners();
  }

  Future<void> setAudioEnabled(bool enabled) async {
    _audioEnabled = enabled;
    await _storage.saveSetting('audio_enabled', enabled);
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _storage.saveSetting('speech_rate', rate);
    notifyListeners();
  }

  Future<void> setSelectedLanguage(String language) async {
    _selectedLanguage = language;
    await _storage.saveSetting('selected_language', language);
    notifyListeners();
  }

  Future<void> setShowDailyTips(bool show) async {
    _showDailyTips = show;
    await _storage.saveSetting('show_daily_tips', show);
    notifyListeners();
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final questionCounts = await _storage.getQuestionCountsByType();
      final subjectCounts = await _storage.getQuestionCountsBySubject();

      return {
        'total_questions': _storage.totalQuestionsCount,
        'by_type': questionCounts,
        'by_subject': subjectCounts,
      };
    } catch (e) {
      debugPrint('Failed to get storage stats: $e');
      return {};
    }
  }
}
