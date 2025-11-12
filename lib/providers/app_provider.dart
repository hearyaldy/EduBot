import 'package:flutter/foundation.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../models/streak_data.dart';
import '../models/badge.dart';
import '../models/child_profile.dart';
import '../services/storage_service.dart';
import '../services/ad_service.dart';
import '../services/admin_service.dart';
import '../services/streak_service.dart';
import '../services/badge_service.dart' show BadgeService, BadgeProgress;
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/purchase_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  final AdService _adService = AdService();
  final StreakService _streakService = StreakService();
  final BadgeService _badgeService = BadgeService();
  final NotificationService _notificationService = NotificationService();
  final ProfileService _profileService = ProfileService();
  final PurchaseService _purchaseService = PurchaseService();

  // Current user session
  int _dailyQuestionsUsed = 0;
  bool _isPremium = false;
  bool _isRegistered = false;

  // AI Token tracking
  int _dailyTokensUsed = 0;
  int _totalTokensUsed = 0;
  int _lastQuestionTokens = 0;

  // Global AI usage tracking (across all users)
  static int _globalDailyRequests = 0;
  static int _globalDailyTokens = 0;
  static String _lastResetDate = '';

  // Gemini API Free Tier Limits (actual Google limits)
  // Daily limits (Free tier: ai.google.dev)
  static const int _maxDailyRequests = 1500;
  static const int _maxDailyTokens = 1000000; // 1 million tokens per day

  // Per-minute rate limits (for future rate limiting implementation)
  // static const int _maxRequestsPerMinute = 15;
  // static const int _maxTokensPerMinute = 32000;

  // Conservative app limits (safety buffer)
  static const int _maxGlobalDailyRequests = 1400; // Keep 100 request buffer
  static const int _maxGlobalDailyTokens = 950000; // Keep 50k token buffer

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
  bool get isSuperadmin => AdminService.instance.isAdmin;
  bool get isRegistered => _isRegistered;
  bool get canAskQuestion =>
      isSuperadmin ||
      _isPremium ||
      (_dailyQuestionsUsed < _getMaxQuestionsPerDay() &&
          canMakeGlobalRequest); // Check superadmin first, then premium, then limits
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
  int get remainingQuestions =>
      _isPremium ? -1 : (_getMaxQuestionsPerDay() - _dailyQuestionsUsed);
  int get maxQuestionsPerDay => _getMaxQuestionsPerDay();
  String get questionUsageDisplay => isSuperadmin || _isPremium
      ? '$_dailyQuestionsUsed / ∞'
      : '$_dailyQuestionsUsed / ${_getMaxQuestionsPerDay()}';
  int get estimatedDailyTokenLimit => _isPremium
      ? -1
      : _maxDailyTokens; // 1M tokens per day for free users (Gemini free tier)
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

  // Gemini API limit monitoring
  int get dailyRequestsUsed => _dailyQuestionsUsed;
  int get remainingDailyRequests => _maxDailyRequests - _dailyQuestionsUsed;
  double get dailyRequestUsagePercentage =>
      (_dailyQuestionsUsed / _maxDailyRequests).clamp(0.0, 1.0);

  // Usage warnings (different thresholds)
  bool get isNearDailyRequestLimit => dailyRequestUsagePercentage > 0.8; // 80%
  bool get isNearDailyTokenLimit => tokenUsagePercentage > 0.8; // 80%
  bool get isApproachingRequestLimit =>
      dailyRequestUsagePercentage > 0.9; // 90%
  bool get isApproachingTokenLimit => tokenUsagePercentage > 0.9; // 90%

  // Status text for UI
  String get apiUsageStatus {
    if (isApproachingRequestLimit || isApproachingTokenLimit) {
      return 'Near daily limit - use carefully';
    } else if (isNearDailyRequestLimit || isNearDailyTokenLimit) {
      return 'Approaching daily limit';
    } else if (dailyRequestUsagePercentage > 0.5 ||
        tokenUsagePercentage > 0.5) {
      return 'Good usage - plenty remaining';
    } else {
      return 'Excellent - minimal usage today';
    }
  }

  // Usage level for UI colors
  ApiUsageLevel get usageLevel {
    final maxUsage = [dailyRequestUsagePercentage, tokenUsagePercentage]
        .reduce((a, b) => a > b ? a : b);
    if (maxUsage > 0.9) return ApiUsageLevel.critical;
    if (maxUsage > 0.8) return ApiUsageLevel.warning;
    if (maxUsage > 0.5) return ApiUsageLevel.moderate;
    return ApiUsageLevel.excellent;
  }

  // Settings getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get audioEnabled => _audioEnabled;
  double get speechRate => _speechRate;
  String get selectedLanguage => _selectedLanguage;
  bool get showDailyTips => _showDailyTips;

  // Streak and Badge getters
  StreakData get streakData => _streakService.streakData;
  int get currentStreak => _streakService.streakData.currentStreak;
  int get longestStreak => _streakService.streakData.longestStreak;
  List<Badge> get badges => _badgeService.badges;
  List<Badge> get unlockedBadges => _badgeService.unlockedBadges;
  int get unlockedBadgeCount => _badgeService.unlockedCount;
  int get totalBadgeCount => _badgeService.totalCount;
  double get badgeCompletionPercentage => _badgeService.completionPercentage;

  // Child Profile getters
  List<ChildProfile> get childProfiles => _profileService.profiles;
  ChildProfile? get activeProfile => _profileService.activeProfile;
  bool get hasProfiles => _profileService.hasProfiles;
  int get profileCount => _profileService.profileCount;
  bool get canAddProfile =>
      _profileService.canAddProfile(_purchaseService.isPremium);
  int get maxProfiles =>
      _profileService.getMaxProfiles(_purchaseService.isPremium);

  // Get max questions per day based on user status
  int _getMaxQuestionsPerDay() {
    // Check purchase service for premium status
    if (_purchaseService.isPremium || _isPremium)
      return -1; // Unlimited for premium
    if (_isRegistered)
      return 10; // 10 for registered users (increased from old model)
    return 5; // 5 for non-registered users (FREEMIUM MODEL)
  }

  // Initialize app provider with stored data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize services
      await _streakService.initialize();
      await _badgeService.initialize();
      await _notificationService.initialize();
      await _profileService.initialize();
      await _purchaseService.initialize();

      // Set up purchase status change listener
      _purchaseService.onPremiumStatusChanged = (isPremium) {
        _isPremium = isPremium;
        // Enable/disable ads based on premium status
        _adService.setAdsEnabled(!isPremium && !isSuperadmin);
        notifyListeners();
      };

      // Check subscription status
      await _purchaseService.checkSubscriptionStatus();

      // Update premium status from purchase service
      _isPremium = _purchaseService.isPremium;

      // Check and update streak on app start
      final streakReset = await _streakService.checkAndResetIfNeeded();
      if (streakReset) {
        debugPrint('Streak was reset due to inactivity');
      }

      // Load saved questions from storage
      _savedQuestions = await _storage.getAllQuestions();

      // Load user settings
      _dailyQuestionsUsed =
          _storage.getSetting<int>('daily_questions_used', defaultValue: 0) ??
              0;
      _isPremium =
          _storage.getSetting<bool>('is_premium', defaultValue: false) ?? false;
      _isRegistered =
          _storage.getSetting<bool>('is_registered', defaultValue: false) ??
              false;

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

      // Configure ad service based on user status
      _adService.setAdsEnabled(!_isPremium && !isSuperadmin);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize app provider: $e');
    }
  }

  // Methods
  Future<void> incrementDailyQuestions({String? subject}) async {
    _dailyQuestionsUsed++;
    await _storage.saveSetting('daily_questions_used', _dailyQuestionsUsed);

    // Record usage for streak tracking
    await _recordUsageAndCheckAchievements(subject: subject);

    notifyListeners();
  }

  /// Record app usage and check for streak/badge achievements
  Future<void> _recordUsageAndCheckAchievements({String? subject}) async {
    try {
      // Update streak
      final streakResult = await _streakService.recordUsage();

      // Check if milestone was reached
      if (streakResult.milestoneReached != null) {
        final milestoneText = _streakService.getMilestoneText(
          streakResult.milestoneReached!,
        );

        // Show milestone notification
        await _notificationService.showStreakMilestoneNotification(
          streak: streakResult.milestoneReached!,
          message: milestoneText,
        );
      }

      // Check and unlock badges
      final newBadges = await _badgeService.checkBadges(
        totalQuestions: _dailyQuestionsUsed,
        currentStreak: currentStreak,
        subject: subject,
      );

      // Show notifications for newly unlocked badges
      for (final badge in newBadges) {
        await _notificationService.showBadgeUnlockedNotification(
          badgeTitle: badge.title,
          badgeEmoji: badge.emoji,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error recording usage and checking achievements: $e');
    }
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

    // Enable/disable ads based on premium status
    _adService.setAdsEnabled(!premium && !isSuperadmin);

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
      // Remove question and its explanation from storage
      await _storage.deleteQuestion(questionId);
      await _storage.deleteExplanation(questionId);

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

    // Schedule or cancel daily reminder based on setting
    await _notificationService.setNotificationsEnabled(enabled);

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

  Future<void> setRegisteredStatus(bool registered) async {
    _isRegistered = registered;
    await _storage.saveSetting('is_registered', registered);
    notifyListeners();
  }

  // Streak and Badge methods
  BadgeProgress getBadgeProgress(String badgeId) {
    return _badgeService.getBadgeProgress(
      badgeId,
      totalQuestions: _dailyQuestionsUsed,
      currentStreak: currentStreak,
    );
  }

  int daysUntilNextMilestone() {
    return _streakService.daysUntilNextMilestone();
  }

  // Child Profile methods
  Future<ChildProfile> addChildProfile({
    required String name,
    required int grade,
    required String emoji,
  }) async {
    final profile = await _profileService.addProfile(
      name: name,
      grade: grade,
      emoji: emoji,
      isPremium: _purchaseService.isPremium,
    );
    notifyListeners();
    return profile;
  }

  Future<void> updateChildProfile(ChildProfile profile) async {
    await _profileService.updateProfile(profile);
    notifyListeners();
  }

  Future<void> deleteChildProfile(String profileId) async {
    await _profileService.deleteProfile(profileId);
    notifyListeners();
  }

  Future<void> setActiveProfile(String profileId) async {
    await _profileService.setActiveProfile(profileId);
    notifyListeners();
  }

  // Purchase methods
  Future<bool> purchasePremiumMonthly() async {
    return await _purchaseService.purchaseProduct(
      PurchaseService.premiumMonthlyId,
    );
  }

  Future<bool> purchasePremiumYearly() async {
    return await _purchaseService.purchaseProduct(
      PurchaseService.premiumYearlyId,
    );
  }

  Future<void> restorePurchases() async {
    await _purchaseService.restorePurchases();
  }

  String? get monthlyPrice => _purchaseService.monthlyProduct?.price;
  String? get yearlyPrice => _purchaseService.yearlyProduct?.price;
  String get savingsPercentage => _purchaseService.getSavingsPercentage();

  // Test method (development only)
  Future<void> setTestPremiumStatus(bool isPremium) async {
    await _purchaseService.setTestPremiumStatus(isPremium);
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

// API usage levels for UI indication
enum ApiUsageLevel {
  excellent, // 0-50% usage - green
  moderate, // 50-80% usage - blue
  warning, // 80-90% usage - orange
  critical, // 90-100% usage - red
}
