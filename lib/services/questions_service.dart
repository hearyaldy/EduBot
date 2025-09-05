import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/homework_question.dart';
import '../models/explanation.dart';
import '../utils/environment_config.dart';

class QuestionsService {
  static QuestionsService? _instance;
  static QuestionsService get instance {
    _instance ??= QuestionsService._();
    return _instance!;
  }

  QuestionsService._();

  static SupabaseClient get _client => Supabase.instance.client;
  static final _config = EnvironmentConfig.instance;

  // Check if user is authenticated and can save to cloud
  bool get canSaveToCloud {
    return _client.auth.currentUser != null;
  }

  // Save question to Supabase (will auto-maintain last 10 via trigger)
  Future<bool> saveQuestion(HomeworkQuestion question) async {
    try {
      if (!canSaveToCloud) {
        if (_config.isDebugMode) {
          debugPrint('Cannot save question to cloud - user not authenticated');
        }
        return false;
      }

      final userId = _client.auth.currentUser!.id;
      
      await _client.from('questions').insert({
        'id': question.id,
        'user_id': userId,
        'question_text': question.question,
        'question_type': question.type.name,
        'subject': question.subject,
        'image_path': question.imagePath,
        'created_at': question.createdAt.toIso8601String(),
      });

      if (_config.isDebugMode) {
        debugPrint('Question saved to Supabase: ${question.id}');
      }
      
      return true;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error saving question to Supabase: $e');
      }
      return false;
    }
  }

  // Save explanation to Supabase
  Future<bool> saveExplanation(Explanation explanation) async {
    try {
      if (!canSaveToCloud) {
        if (_config.isDebugMode) {
          debugPrint('Cannot save explanation to cloud - user not authenticated');
        }
        return false;
      }

      final userId = _client.auth.currentUser!.id;

      await _client.from('explanations').insert({
        'id': explanation.id,
        'question_id': explanation.questionId,
        'user_id': userId,
        'answer': explanation.answer,
        'steps': explanation.steps.map((step) => step.toJson()).toList(),
        'parent_friendly_tip': explanation.parentFriendlyTip,
        'real_world_example': explanation.realWorldExample,
        'created_at': explanation.createdAt.toIso8601String(),
      });

      if (_config.isDebugMode) {
        debugPrint('Explanation saved to Supabase: ${explanation.id}');
      }
      
      return true;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error saving explanation to Supabase: $e');
      }
      return false;
    }
  }

  // Get last 10 questions from Supabase
  Future<List<HomeworkQuestion>> getRecentQuestions() async {
    try {
      if (!canSaveToCloud) {
        if (_config.isDebugMode) {
          debugPrint('Cannot fetch questions from cloud - user not authenticated');
        }
        return [];
      }

      final userId = _client.auth.currentUser!.id;
      
      final response = await _client
          .from('questions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      final questions = (response as List).map((data) {
        return HomeworkQuestion(
          id: data['id'] as String,
          question: data['question_text'] as String,
          type: QuestionType.values.firstWhere(
            (type) => type.name == data['question_type'],
            orElse: () => QuestionType.text,
          ),
          subject: data['subject'] as String?,
          imagePath: data['image_path'] as String?,
          createdAt: DateTime.parse(data['created_at'] as String),
        );
      }).toList();

      if (_config.isDebugMode) {
        debugPrint('Fetched ${questions.length} questions from Supabase');
      }

      return questions;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error fetching questions from Supabase: $e');
      }
      return [];
    }
  }

  // Get explanation for a specific question from Supabase
  Future<Explanation?> getExplanation(String questionId) async {
    try {
      if (!canSaveToCloud) {
        if (_config.isDebugMode) {
          debugPrint('Cannot fetch explanation from cloud - user not authenticated');
        }
        return null;
      }

      final userId = _client.auth.currentUser!.id;
      
      final response = await _client
          .from('explanations')
          .select('*')
          .eq('question_id', questionId)
          .eq('user_id', userId)
          .single();

      // Response will throw if no data found, so this line is not needed

      final stepsJson = response['steps'] as List? ?? [];
      final steps = stepsJson.map((stepData) {
        return ExplanationStep.fromJson(Map<String, dynamic>.from(stepData));
      }).toList();

      final explanation = Explanation(
        id: response['id'] as String,
        questionId: response['question_id'] as String,
        question: '', // We don't store question text in explanations table, will be fetched separately 
        answer: response['answer'] as String,
        steps: steps,
        parentFriendlyTip: response['parent_friendly_tip'] as String?,
        realWorldExample: response['real_world_example'] as String?,
        subject: 'Unknown', // Subject is associated with question, not explanation
        createdAt: DateTime.parse(response['created_at'] as String),
      );

      if (_config.isDebugMode) {
        debugPrint('Fetched explanation from Supabase: ${explanation.id}');
      }

      return explanation;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error fetching explanation from Supabase: $e');
      }
      return null;
    }
  }

  // Delete question and its explanation from Supabase
  Future<bool> deleteQuestion(String questionId) async {
    try {
      if (!canSaveToCloud) {
        if (_config.isDebugMode) {
          debugPrint('Cannot delete question from cloud - user not authenticated');
        }
        return false;
      }

      final userId = _client.auth.currentUser!.id;
      
      // Delete explanation first (foreign key constraint)
      await _client
          .from('explanations')
          .delete()
          .eq('question_id', questionId)
          .eq('user_id', userId);

      // Delete question
      await _client
          .from('questions')
          .delete()
          .eq('id', questionId)
          .eq('user_id', userId);

      if (_config.isDebugMode) {
        debugPrint('Question deleted from Supabase: $questionId');
      }
      
      return true;
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error deleting question from Supabase: $e');
      }
      return false;
    }
  }

  // Sync recent questions from Supabase (merge with local storage)
  Future<List<HomeworkQuestion>> syncQuestions(List<HomeworkQuestion> localQuestions) async {
    try {
      if (!canSaveToCloud) {
        if (_config.isDebugMode) {
          debugPrint('Cannot sync questions - user not authenticated');
        }
        return localQuestions;
      }

      final cloudQuestions = await getRecentQuestions();
      
      // Merge local and cloud questions, prioritizing cloud for authenticated users
      final Map<String, HomeworkQuestion> mergedQuestions = {};
      
      // Add local questions first
      for (final question in localQuestions) {
        mergedQuestions[question.id] = question;
      }
      
      // Override with cloud questions (they are the source of truth for authenticated users)
      for (final question in cloudQuestions) {
        mergedQuestions[question.id] = question;
      }
      
      final result = mergedQuestions.values.toList();
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (_config.isDebugMode) {
        debugPrint('Synced questions: ${result.length} total');
      }
      
      return result.take(10).toList(); // Only keep last 10
    } catch (e) {
      if (_config.isDebugMode) {
        debugPrint('Error syncing questions: $e');
      }
      return localQuestions;
    }
  }
}