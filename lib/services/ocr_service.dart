import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  // Extract text from an image file
  static Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      // Combine all text blocks into a single string
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        extractedText += '${block.text}\n';
      }

      return extractedText.trim();
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  // Extract text from XFile (camera/gallery image)
  static Future<String> extractTextFromXFile(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        extractedText += '${block.text}\n';
      }

      return extractedText.trim();
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  // Clean up extracted text (remove noise, fix common OCR errors)
  static String cleanExtractedText(String rawText) {
    String cleaned = rawText;

    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Fix common OCR errors for math
    cleaned = cleaned.replaceAll('×', '*');
    cleaned = cleaned.replaceAll('÷', '/');
    cleaned = cleaned.replaceAll('−', '-');
    cleaned = cleaned.replaceAll('±', '±');

    // Remove common noise patterns
    cleaned = cleaned.replaceAll(RegExp(r'[|_]+'), '');

    return cleaned.trim();
  }

  // Check if the extracted text looks like a math problem
  static bool looksLikeMathProblem(String text) {
    final mathPatterns = [
      RegExp(r'\d+\s*[+\-*/÷×]\s*\d+'), // Basic arithmetic
      RegExp(r'[a-zA-Z]\s*[=+\-*/]\s*\d+'), // Algebra
      RegExp(r'\d+\s*[a-zA-Z]\s*[+\-*/]'), // Variables
      RegExp(r'solve|find|calculate|what is', caseSensitive: false),
    ];

    return mathPatterns.any((pattern) => pattern.hasMatch(text));
  }

  // Dispose of resources
  static void dispose() {
    _textRecognizer.close();
  }
}
