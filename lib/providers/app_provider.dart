import 'package:flutter/foundation.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../services/storage_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storage = StorageService();
  
  // Current user session
  int _dailyQuestionsUsed = 0;
  bool _isPremium = false;

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
      _isPremium || _dailyQuestionsUsed < 10; // Free tier limit
  List<HomeworkQuestion> get savedQuestions =>
      List.unmodifiable(_savedQuestions);
  Explanation? get currentExplanation => _currentExplanation;
  bool get isLoading => _isLoading;
  bool get isScanningImage => _isScanningImage;
  bool get isProcessingAudio => _isProcessingAudio;
  bool get isInitialized => _isInitialized;

  // Initialize app provider with stored data
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load saved questions from storage
      _savedQuestions = await _storage.getAllQuestions();
      
      // Load user settings
      _dailyQuestionsUsed = _storage.getSetting<int>('daily_questions_used', defaultValue: 0) ?? 0;
      _isPremium = _storage.getSetting<bool>('is_premium', defaultValue: false) ?? false;
      
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
  
  Future<void> saveQuestionWithExplanation(HomeworkQuestion question, Explanation explanation) async {
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
