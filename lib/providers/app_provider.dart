import 'package:flutter/foundation.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';

class AppProvider with ChangeNotifier {
  // Current user session
  int _dailyQuestionsUsed = 0;
  bool _isPremium = false;

  // Questions history
  final List<HomeworkQuestion> _savedQuestions = [];

  // Current explanation being viewed
  Explanation? _currentExplanation;

  // Loading states
  bool _isLoading = false;
  bool _isScanningImage = false;
  bool _isProcessingAudio = false;

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

  // Methods
  void incrementDailyQuestions() {
    _dailyQuestionsUsed++;
    notifyListeners();
  }

  void setPremiumStatus(bool premium) {
    _isPremium = premium;
    notifyListeners();
  }

  void setCurrentExplanation(Explanation explanation) {
    _currentExplanation = explanation;
    notifyListeners();
  }

  void saveQuestion(HomeworkQuestion question) {
    _savedQuestions.insert(0, question); // Add to beginning
    notifyListeners();
  }

  void removeQuestion(String questionId) {
    _savedQuestions.removeWhere((q) => q.id == questionId);
    notifyListeners();
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
  void resetDailyQuestions() {
    _dailyQuestionsUsed = 0;
    notifyListeners();
  }
}
