import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/environment_config.dart';

class VoiceInputService {
  static final VoiceInputService _instance = VoiceInputService._internal();
  factory VoiceInputService() => _instance;
  VoiceInputService._internal();

  final SpeechToText _speechToText = SpeechToText();
  static final _config = EnvironmentConfig.instance;
  
  bool _isInitialized = false;
  bool _isListening = false;
  
  // Getters
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  
  // Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();
      if (!permissionStatus.isGranted) {
        if (_config.isDebugMode) {
          print('Microphone permission denied');
        }
        return false;
      }
      
      // Initialize speech to text
      final available = await _speechToText.initialize(
        onError: (error) {
          if (_config.isDebugMode) {
            print('Speech recognition error: ${error.errorMsg}');
          }
        },
        onStatus: (status) {
          if (_config.isDebugMode) {
            print('Speech recognition status: $status');
          }
        },
      );
      
      _isInitialized = available;
      return available;
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to initialize speech recognition: $e');
      }
      return false;
    }
  }
  
  // Start listening for speech
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onPartialResult,
    required Function() onListeningComplete,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Speech recognition not available');
      }
    }
    
    if (_isListening) {
      await stopListening();
    }
    
    _isListening = true;
    
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          _isListening = false;
          onListeningComplete();
        } else {
          onPartialResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30), // Maximum listening time
      pauseFor: const Duration(seconds: 3), // Pause detection
      localeId: localeId,
      onSoundLevelChange: (level) {
        // Could be used for visual feedback (sound wave animation)
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.confirmation,
      ),
    );
  }
  
  // Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }
  
  // Cancel listening
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speechToText.cancel();
      _isListening = false;
    }
  }
  
  // Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }
  
  // Check if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
  
  // Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  // Get default locale (English US)
  String get defaultLocale => 'en_US';
  
  // Dispose resources
  void dispose() {
    if (_isListening) {
      _speechToText.stop();
    }
    _isInitialized = false;
    _isListening = false;
  }
}