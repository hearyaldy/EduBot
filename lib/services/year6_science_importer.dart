import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import 'dart:convert';

class Year6ScienceImporter {
  static final Year6ScienceImporter _instance = Year6ScienceImporter._internal();
  factory Year6ScienceImporter() => _instance;
  Year6ScienceImporter._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Import the Year 6 Science questions from assets
  Future<Map<String, dynamic>> importYear6ScienceQuestions() async {
    try {
      await _databaseService.initialize();

      // Load the JSON file from assets
      final jsonString = await rootBundle.loadString('assets/sample_questions/year6_science.json');
      
      // Parse the JSON
      final jsonData = json.decode(jsonString);
      
      // Handle different JSON formats
      List<dynamic> questionsJson;
      if (jsonData is List) {
        questionsJson = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('questions')) {
        questionsJson = jsonData['questions'] as List;
      } else {
        throw const FormatException('Invalid JSON format. Expected array of questions or object with "questions" key.');
      }

      int successCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      // Parse and save each question
      for (var i = 0; i < questionsJson.length; i++) {
        try {
          final questionData = questionsJson[i] as Map<String, dynamic>;
          final question = Question.fromJson(questionData);
          
          // Save to database
          await _databaseService.saveQuestion(question);
          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('Error at index $i: $e');
          debugPrint('Failed to import question at index $i: $e');
        }
      }

      return {
        'total_processed': questionsJson.length,
        'successfully_imported': successCount,
        'failed_imports': errorCount,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('Failed to import Year 6 Science questions: $e');
      return {
        'total_processed': 0,
        'successfully_imported': 0,
        'failed_imports': 0,
        'errors': ['Error loading file: $e'],
      };
    }
  }
}