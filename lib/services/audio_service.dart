import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  static FlutterTts? _flutterTts;
  static bool _isInitialized = false;

  // Initialize TTS
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();

    // Configure TTS settings
    await _flutterTts!.setLanguage("en-US");
    await _flutterTts!.setSpeechRate(0.5); // Slow and clear for parents
    await _flutterTts!.setVolume(0.8);
    await _flutterTts!.setPitch(1.0);

    _isInitialized = true;
  }

  // Speak explanation text
  static Future<void> speakExplanation(String text) async {
    await initialize();

    // Clean text for better speech
    String cleanText = _cleanTextForSpeech(text);

    await _flutterTts!.speak(cleanText);
  }

  // Speak a specific explanation step
  static Future<void> speakStep(
    String stepTitle,
    String stepDescription,
  ) async {
    await initialize();

    String fullText = "Step: $stepTitle. $stepDescription";
    String cleanText = _cleanTextForSpeech(fullText);

    await _flutterTts!.speak(cleanText);
  }

  // Stop current speech
  static Future<void> stop() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
    }
  }

  // Pause speech
  static Future<void> pause() async {
    if (_flutterTts != null) {
      await _flutterTts!.pause();
    }
  }

  // Check if TTS is available
  static Future<bool> isAvailable() async {
    await initialize();
    return _flutterTts != null;
  }

  // Get available languages
  static Future<List<String>> getAvailableLanguages() async {
    await initialize();

    try {
      List<dynamic> languages = await _flutterTts!.getLanguages;
      return languages.cast<String>();
    } catch (e) {
      return ['en-US']; // Fallback
    }
  }

  // Set language
  static Future<void> setLanguage(String language) async {
    await initialize();
    await _flutterTts!.setLanguage(language);
  }

  // Set speech rate (0.0 to 1.0, where 0.5 is normal)
  static Future<void> setSpeechRate(double rate) async {
    await initialize();
    await _flutterTts!.setSpeechRate(rate);
  }

  // Clean text for better speech synthesis
  static String _cleanTextForSpeech(String text) {
    String cleaned = text;

    // Replace mathematical symbols with words
    cleaned = cleaned.replaceAll('+', ' plus ');
    cleaned = cleaned.replaceAll('-', ' minus ');
    cleaned = cleaned.replaceAll('*', ' times ');
    cleaned = cleaned.replaceAll('/', ' divided by ');
    cleaned = cleaned.replaceAll('=', ' equals ');
    cleaned = cleaned.replaceAll('×', ' times ');
    cleaned = cleaned.replaceAll('÷', ' divided by ');
    cleaned = cleaned.replaceAll('²', ' squared ');
    cleaned = cleaned.replaceAll('³', ' cubed ');

    // Handle fractions
    cleaned = cleaned.replaceAll(RegExp(r'(\d+)/(\d+)'), r'\1 over \2');

    // Add pauses for better comprehension
    cleaned = cleaned.replaceAll('.', '. ');
    cleaned = cleaned.replaceAll(',', ', ');

    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned.trim();
  }

  // Dispose resources
  static void dispose() {
    _flutterTts?.stop();
    _flutterTts = null;
    _isInitialized = false;
  }
}
