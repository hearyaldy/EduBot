import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../services/admin_service.dart';
import '../services/database_service.dart';
import '../services/question_bank_service.dart';
import '../ui/question_editor.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() => _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {  
  final DatabaseService _databaseService = DatabaseService();
  final QuestionBankService _questionBankService = QuestionBankService();
  late final AdminService _adminService;

  List<String> _subjects = [];
  Map<String, List<Question>> _questionsBySubject = {};
  List<Question> _filteredQuestions = [];
  String _selectedSubject = '';
  String _searchText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _adminService = AdminService.instance;
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _databaseService.initialize();
    await _questionBankService.initialize();
    await _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all questions
      final allQuestions = _databaseService.getAllQuestions();
      
      // Group by subject
      final subjectsMap = <String, List<Question>>{};
      for (final question in allQuestions) {
        subjectsMap.putIfAbsent(question.subject, () => []).add(question);
      }

      setState(() {
        _subjects = subjectsMap.keys.toList()..sort();
        _questionsBySubject = subjectsMap;
        if (_subjects.isNotEmpty && _selectedSubject.isEmpty) {
          _selectedSubject = _subjects.first;
          _filteredQuestions = _questionsBySubject[_selectedSubject] ?? [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load subjects: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _selectSubject(String subject) {
    setState(() {
      _selectedSubject = subject;
      _filteredQuestions = _questionsBySubject[subject] ?? [];
      _applySearchFilter();
    });
  }

  void _applySearchFilter() {
    if (_searchText.isEmpty) {
      setState(() {
        _filteredQuestions = _questionsBySubject[_selectedSubject] ?? [];
      });
    } else {
      final filtered = (_questionsBySubject[_selectedSubject] ?? [])
          .where((q) => q.questionText.toLowerCase().contains(_searchText.toLowerCase()) ||
                      q.answerKey.toLowerCase().contains(_searchText.toLowerCase()) ||
                      q.explanation.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
      
      setState(() {
        _filteredQuestions = filtered;
      });
    }
  }

  void _searchTextChanged(String value) {
    setState(() {
      _searchText = value;
    });
    _applySearchFilter();
  }

  Future<void> _editQuestion(Question question) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionEditor(
          question: question,
        ),
      ),
    );

    if (result == true) {
      await _loadSubjects(); // Refresh data after edit
      _showSuccess('Question updated successfully');
    }
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text('Are you sure you want to delete this question?\n\n${question.questionText.substring(0, Math.min(question.questionText.length, 50))}...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteQuestion(question.id);
        await _loadSubjects(); // Refresh data
        _showSuccess('Question deleted successfully');
      } catch (e) {
        _showError('Failed to delete question: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAccess = _adminService.isAdmin;
    
    if (!canAccess) {
      return _buildAccessDenied();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showUserDialog(),
            icon: Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Profile',
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You need admin privileges to access this feature',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Subject selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Subject',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text('Select a subject'),
                  items: _subjects.map((subject) {
                    final count = _questionsBySubject[subject]?.length ?? 0;
                    return DropdownMenuItem(
                      value: subject,
                      child: Row(
                        children: [
                          Text(subject),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _selectSubject(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search questions...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _searchTextChanged,
              ),
            ],
          ),
        ),

        // Question list
        Expanded(
          child: _selectedSubject.isEmpty 
              ? _buildEmptyState() 
              : _buildQuestionList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Subject Selected',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Please select a subject from the dropdown above',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    if (_filteredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Questions Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'This subject has no questions or your search returned no results',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredQuestions.length,
      itemBuilder: (context, index) {
        final question = _filteredQuestions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              question.questionText.length > 80 
                  ? '${question.questionText.substring(0, 80)}...' 
                  : question.questionText,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Row(
              children: [
                Text(
                  'Grade ${question.gradeLevel} • ${question.difficulty.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(question.difficulty).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    question.questionType.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getDifficultyColor(question.difficulty),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Answer: ${question.answerKey}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explanation: ${question.explanation.length > 100 ? '${question.explanation.substring(0, 100)}...' : question.explanation}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Topic: ${question.topic}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Subtopic: ${question.subtopic}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _editQuestion(question),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _deleteQuestion(question),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(DifficultyTag difficulty) {
    switch (difficulty) {
      case DifficultyTag.veryEasy:
        return Colors.green.shade600;
      case DifficultyTag.easy:
        return Colors.lightGreen.shade600;
      case DifficultyTag.medium:
        return Colors.orange.shade600;
      case DifficultyTag.hard:
        return Colors.red.shade600;
      case DifficultyTag.veryHard:
        return Colors.purple.shade600;
    }
  }

  void _showUserDialog() {
    // Since we're using the existing AdminService, we don't have detailed user info
    // Just show a simple dialog indicating admin access
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Admin Access'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You have admin access to the subject management system.'),
              SizedBox(height: 8),
              Text('Use this panel to manage questions and subjects.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
  }
}

// Helper extension
extension Math on int {
  static int min(int a, int b) => a < b ? a : b;
}