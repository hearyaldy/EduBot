import 'dart:convert';
import 'dart:io';
import '../models/question.dart';
import 'question_import_service.dart';

class CsvImportService {
  static final CsvImportService _instance = CsvImportService._internal();
  factory CsvImportService() => _instance;
  CsvImportService._internal();

  final QuestionImportService _questionImportService = QuestionImportService();

  /// Import questions from CSV file
  Future<Map<String, dynamic>> importFromCsvFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }

      final csvContent = await file.readAsString();
      return await importFromCsvString(csvContent);
    } catch (e) {
      throw Exception('Failed to import from CSV file: $e');
    }
  }

  /// Import questions from CSV string
  Future<Map<String, dynamic>> importFromCsvString(String csvContent) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.isEmpty) {
        throw const FormatException('CSV file is empty');
      }

      // Parse header
      final header = _parseCsvLine(lines[0]);
      if (header.isEmpty) {
        throw const FormatException('CSV header is empty');
      }

      // Validate required columns
      final requiredColumns = _getRequiredColumns();
      final missingColumns =
          requiredColumns.where((col) => !header.contains(col)).toList();
      if (missingColumns.isNotEmpty) {
        throw FormatException(
            'Missing required columns: ${missingColumns.join(', ')}');
      }

      // Convert CSV to JSON
      final questions = <Map<String, dynamic>>[];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = _parseCsvLine(line);
        if (values.length != header.length) {
          throw FormatException(
              'Line ${i + 1}: Column count mismatch. Expected ${header.length}, got ${values.length}');
        }

        final questionData = <String, dynamic>{};
        for (int j = 0; j < header.length; j++) {
          questionData[header[j]] = _convertCsvValue(header[j], values[j]);
        }

        questions.add(questionData);
      }

      // Create JSON structure
      final jsonData = {
        'metadata': {
          'version': '1.0',
          'created_by': 'CSV Import',
          'created_at': DateTime.now().toIso8601String(),
          'description': 'Questions imported from CSV',
          'total_questions': questions.length,
        },
        'questions': questions,
      };

      // Use existing JSON import functionality
      return await _questionImportService
          .importFromJsonString(json.encode(jsonData));
    } catch (e) {
      throw Exception('Failed to import CSV: $e');
    }
  }

  /// Parse a CSV line handling quotes and commas
  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    bool escapeNext = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (escapeNext) {
        buffer.write(char);
        escapeNext = false;
        continue;
      }

      if (char == '\\') {
        escapeNext = true;
        continue;
      }

      if (char == '"' && !escapeNext) {
        inQuotes = !inQuotes;
        continue;
      }

      if (char == ',' && !inQuotes) {
        values.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    values.add(buffer.toString().trim());
    return values;
  }

  /// Convert CSV string value to appropriate type
  dynamic _convertCsvValue(String columnName, String value) {
    value = value.trim();
    if (value.isEmpty) {
      return _getDefaultValue(columnName);
    }

    // Remove surrounding quotes if present
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }

    switch (columnName.toLowerCase()) {
      case 'grade_level':
        return int.tryParse(value) ?? 1;

      case 'question_type':
        return _parseQuestionType(value);

      case 'difficulty':
        return _parseDifficulty(value);

      case 'cognitive_level':
        return _parseCognitiveLevel(value);

      case 'estimated_time_minutes':
        return int.tryParse(value) ?? 2;

      case 'choices':
        if (value.isEmpty) return <String>[];
        return value
            .split('|')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

      case 'curriculum_standards':
      case 'tags':
        if (value.isEmpty) return <String>[];
        return value
            .split('|')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

      case 'image_required':
      case 'calculator_allowed':
      case 'real_world_context':
        return value.toLowerCase() == 'true' ||
            value.toLowerCase() == 'yes' ||
            value == '1';

      default:
        return value;
    }
  }

  /// Get default value for a column
  dynamic _getDefaultValue(String columnName) {
    switch (columnName.toLowerCase()) {
      case 'grade_level':
        return 1;
      case 'question_type':
        return QuestionType.fillInTheBlank.index;
      case 'difficulty':
        return DifficultyTag.medium.index;
      case 'cognitive_level':
        return BloomsTaxonomy.understand.index;
      case 'estimated_time_minutes':
        return 2;
      case 'choices':
        return <String>[];
      case 'curriculum_standards':
        return <String>[];
      case 'tags':
        return <String>[];
      case 'target_language':
        return 'English';
      case 'image_required':
        return false;
      case 'calculator_allowed':
        return false;
      case 'real_world_context':
        return false;
      default:
        return '';
    }
  }

  /// Parse question type from string
  int _parseQuestionType(String value) {
    value = value.toLowerCase().trim();
    switch (value) {
      case 'multiple choice':
      case 'multiplechoice':
      case 'mc':
        return QuestionType.multipleChoice.index;
      case 'true false':
      case 'truefalse':
      case 'tf':
        return QuestionType.trueOrFalse.index;
      case 'short answer':
      case 'shortanswer':
      case 'sa':
        return QuestionType.shortAnswer.index;
      case 'fill in the blank':
      case 'fillintheblank':
      case 'fill blank':
      case 'fb':
        return QuestionType.fillInTheBlank.index;
      default:
        // Try to parse as number
        return int.tryParse(value) ?? QuestionType.fillInTheBlank.index;
    }
  }

  /// Parse difficulty from string
  int _parseDifficulty(String value) {
    value = value.toLowerCase().trim();
    switch (value) {
      case 'easy':
      case 'e':
        return DifficultyTag.easy.index;
      case 'medium':
      case 'med':
      case 'm':
        return DifficultyTag.medium.index;
      case 'hard':
      case 'difficult':
      case 'h':
        return DifficultyTag.hard.index;
      default:
        return int.tryParse(value) ?? DifficultyTag.medium.index;
    }
  }

  /// Parse cognitive level from string
  int _parseCognitiveLevel(String value) {
    value = value.toLowerCase().trim();
    switch (value) {
      case 'remember':
      case 'recall':
        return BloomsTaxonomy.remember.index;
      case 'understand':
      case 'comprehend':
        return BloomsTaxonomy.understand.index;
      case 'apply':
      case 'application':
        return BloomsTaxonomy.apply.index;
      case 'analyze':
      case 'analyse':
      case 'analysis':
        return BloomsTaxonomy.analyze.index;
      case 'evaluate':
      case 'evaluation':
        return BloomsTaxonomy.evaluate.index;
      case 'create':
      case 'synthesis':
        return BloomsTaxonomy.create.index;
      default:
        return int.tryParse(value) ?? BloomsTaxonomy.understand.index;
    }
  }

  /// Get list of required columns
  List<String> _getRequiredColumns() {
    return [
      'id',
      'question_text',
      'question_type',
      'subject',
      'topic',
      'subtopic',
      'grade_level',
      'answer_key',
      'explanation',
    ];
  }

  /// Generate sample CSV structure
  String generateSampleCsv() {
    final header = [
      'id',
      'question_text',
      'question_type',
      'subject',
      'topic',
      'subtopic',
      'grade_level',
      'difficulty',
      'answer_key',
      'explanation',
      'choices',
      'target_language',
      'curriculum_standards',
      'tags',
      'estimated_time_minutes',
      'cognitive_level',
      'image_required',
      'calculator_allowed',
      'real_world_context',
    ];

    final sampleRows = [
      [
        'sample_001',
        'What is 5 + 3?',
        'fill in the blank',
        'Mathematics',
        'Addition',
        'Basic Addition',
        '2',
        'easy',
        '8',
        'When we add 5 + 3, we count 5 items and then 3 more items to get 8 total.',
        '',
        'English',
        'KSSR Grade 2 Mathematics|Addition within 20',
        'addition|basic_math|counting',
        '2',
        'apply',
        'false',
        'false',
        'true'
      ],
      [
        'sample_002',
        'Which animal is a mammal?',
        'multiple choice',
        'Science',
        'Animals',
        'Classification',
        '3',
        'medium',
        'Dog',
        'A dog is a mammal because it has fur, feeds milk to its babies, and is warm-blooded.',
        'Fish|Bird|Dog|Insect',
        'English',
        'KSSR Grade 3 Science|Animal Classification',
        'mammals|animal_classification|science',
        '3',
        'understand',
        'true',
        'false',
        'true'
      ],
    ];

    final lines = <String>[];
    lines.add(header.map((h) => '"$h"').join(','));

    for (final row in sampleRows) {
      lines.add(row.map((cell) => '"$cell"').join(','));
    }

    return lines.join('\n');
  }

  /// Export current questions to CSV format
  Future<String> exportQuestionsToCsv() async {
    final jsonString = await _questionImportService.exportQuestionsToJson(
        includeMetadata: false);
    final data = json.decode(jsonString);
    final questions = data['questions'] as List<dynamic>;

    if (questions.isEmpty) {
      return _getCsvHeader();
    }

    final lines = <String>[];
    lines.add(_getCsvHeader());

    for (final question in questions) {
      final row = _convertQuestionToCsvRow(question);
      lines.add(row);
    }

    return lines.join('\n');
  }

  /// Get CSV header
  String _getCsvHeader() {
    final header = [
      'id',
      'question_text',
      'question_type',
      'subject',
      'topic',
      'subtopic',
      'grade_level',
      'difficulty',
      'answer_key',
      'explanation',
      'choices',
      'target_language',
      'curriculum_standards',
      'tags',
      'estimated_time_minutes',
      'cognitive_level',
      'image_required',
      'calculator_allowed',
      'real_world_context',
    ];
    return header.map((h) => '"$h"').join(',');
  }

  /// Convert question JSON to CSV row
  String _convertQuestionToCsvRow(Map<String, dynamic> question) {
    final metadata = question['metadata'] as Map<String, dynamic>? ?? {};
    final additionalData =
        metadata['additional_data'] as Map<String, dynamic>? ?? {};

    String formatListForCsv(List<dynamic>? list) {
      if (list == null || list.isEmpty) return '';
      return list.map((item) => item.toString()).join('|');
    }

    final values = [
      question['id'] ?? '',
      question['question_text'] ?? '',
      _getQuestionTypeString(question['question_type']),
      question['subject'] ?? '',
      question['topic'] ?? '',
      question['subtopic'] ?? '',
      (question['grade_level'] ?? 1).toString(),
      _getDifficultyString(question['difficulty']),
      question['answer_key'] ?? '',
      question['explanation'] ?? '',
      formatListForCsv(question['choices']),
      question['target_language'] ?? 'English',
      formatListForCsv(metadata['curriculum_standards']),
      formatListForCsv(metadata['tags']),
      (metadata['estimated_time_minutes'] ?? 2).toString(),
      _getCognitiveLevelString(metadata['cognitive_level']),
      (additionalData['image_required'] ?? false).toString(),
      (additionalData['calculator_allowed'] ?? false).toString(),
      (additionalData['real_world_context'] ?? false).toString(),
    ];

    return values
        .map((v) => '"${v.toString().replaceAll('"', '""')}"')
        .join(',');
  }

  String _getQuestionTypeString(dynamic type) {
    if (type is int) {
      switch (type) {
        case 0:
          return 'multiple choice';
        case 1:
          return 'true false';
        case 2:
          return 'short answer';
        case 3:
          return 'fill in the blank';
        default:
          return 'fill in the blank';
      }
    }
    return type.toString();
  }

  String _getDifficultyString(dynamic difficulty) {
    if (difficulty is int) {
      switch (difficulty) {
        case 0:
          return 'easy';
        case 1:
          return 'medium';
        case 2:
          return 'hard';
        default:
          return 'medium';
      }
    }
    return difficulty.toString();
  }

  String _getCognitiveLevelString(dynamic level) {
    if (level is int) {
      switch (level) {
        case 0:
          return 'remember';
        case 1:
          return 'understand';
        case 2:
          return 'apply';
        case 3:
          return 'analyze';
        case 4:
          return 'evaluate';
        case 5:
          return 'create';
        default:
          return 'understand';
      }
    }
    return level.toString();
  }
}
