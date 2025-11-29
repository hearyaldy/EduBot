import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Unused
import '../models/question.dart';
import '../services/admin_service.dart';
import '../services/database_service.dart';
import '../services/question_bank_service.dart';
import '../services/firebase_service.dart';
import '../ui/question_editor.dart';
import '../core/theme/app_colors.dart';
// import '../core/theme/app_text_styles.dart'; // Unused

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final QuestionBankService _questionBankService = QuestionBankService();
  final FirebaseService _firebaseService = FirebaseService.instance;
  late final AdminService _adminService;

  List<String> _subjects = [];
  Map<String, List<Question>> _questionsBySubject = {};
  List<Question> _filteredQuestions = [];
  String _selectedSubject = '';
  String _searchText = '';
  bool _isLoading = true;

  // New filter variables
  DifficultyTag? _selectedDifficulty;
  int? _selectedGradeLevel;
  Set<String> _selectedQuestionIds = {};
  bool _isSelectionMode = false;

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
    var filtered = _questionsBySubject[_selectedSubject] ?? [];

    // Apply difficulty filter
    if (_selectedDifficulty != null) {
      filtered =
          filtered.where((q) => q.difficulty == _selectedDifficulty).toList();
    }

    // Apply grade level filter
    if (_selectedGradeLevel != null) {
      filtered =
          filtered.where((q) => q.gradeLevel == _selectedGradeLevel).toList();
    }

    // Apply search text filter
    if (_searchText.isNotEmpty) {
      filtered = filtered
          .where((q) =>
              q.questionText
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              q.answerKey.toLowerCase().contains(_searchText.toLowerCase()) ||
              q.explanation.toLowerCase().contains(_searchText.toLowerCase()) ||
              q.topic.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredQuestions = filtered;
      // Clear selection when filter changes
      _selectedQuestionIds.clear();
    });
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
        content: Text(
            'Are you sure you want to delete this question?\n\n${question.questionText.substring(0, Math.min(question.questionText.length, 50))}...'),
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
        // Delete from local database
        await _databaseService.deleteQuestion(question.id);

        // Delete from QuestionBankService
        _questionBankService.removeQuestion(question.id);

        // Delete from Firestore
        await _firebaseService.deleteQuestionFromBank(question.id);

        await _loadSubjects(); // Refresh data
        _showSuccess('Question deleted successfully');
      } catch (e) {
        _showError('Failed to delete question: $e');
      }
    }
  }

  Future<void> _batchDeleteQuestions() async {
    if (_selectedQuestionIds.isEmpty) {
      _showError('No questions selected');
      return;
    }

    final count = _selectedQuestionIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Batch Delete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete $count question${count > 1 ? 's' : ''}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone. The questions will be removed from:',
            ),
            const SizedBox(height: 8),
            const Text('• Local database'),
            const Text('• Question bank service'),
            const Text('• Firestore cloud database'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete $count Questions'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      int successCount = 0;
      int failCount = 0;

      for (final id in _selectedQuestionIds) {
        try {
          await _databaseService.deleteQuestion(id);
          _questionBankService.removeQuestion(id);
          await _firebaseService.deleteQuestionFromBank(id);
          successCount++;
        } catch (e) {
          debugPrint('Failed to delete question $id: $e');
          failCount++;
        }
      }

      _selectedQuestionIds.clear();
      _isSelectionMode = false;
      await _loadSubjects();

      if (failCount == 0) {
        _showSuccess('Successfully deleted $successCount questions');
      } else {
        _showError('Deleted $successCount questions, $failCount failed');
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedQuestionIds.clear();
      }
    });
  }

  void _toggleQuestionSelection(String id) {
    setState(() {
      if (_selectedQuestionIds.contains(id)) {
        _selectedQuestionIds.remove(id);
      } else {
        _selectedQuestionIds.add(id);
      }
    });
  }

  void _selectAllFiltered() {
    setState(() {
      _selectedQuestionIds = _filteredQuestions.map((q) => q.id).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedQuestionIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canAccess = _adminService.isAdmin;

    if (!canAccess) {
      return _buildAccessDenied();
    }

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedQuestionIds.length} Selected')
            : const Text('Subject Management'),
        backgroundColor:
            _isSelectionMode ? Colors.red.shade600 : AppColors.primary,
        foregroundColor: Colors.white,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  onPressed: _selectAllFiltered,
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Select All',
                ),
                IconButton(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.deselect),
                  tooltip: 'Clear Selection',
                ),
                IconButton(
                  onPressed: _batchDeleteQuestions,
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'Delete Selected',
                ),
              ]
            : [
                IconButton(
                  onPressed: _toggleSelectionMode,
                  icon: const Icon(Icons.checklist),
                  tooltip: 'Batch Select',
                ),
                IconButton(
                  onPressed: () => _showUserDialog(),
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Admin Profile',
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: !_isLoading && _filteredQuestions.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSelectionMode
                  ? _batchDeleteQuestions
                  : _toggleSelectionMode,
              backgroundColor:
                  _isSelectionMode ? Colors.red : AppColors.primary,
              icon: Icon(
                  _isSelectionMode ? Icons.delete_forever : Icons.checklist),
              label: Text(_isSelectionMode
                  ? 'Delete ${_selectedQuestionIds.length}'
                  : 'Batch Delete'),
            )
          : null,
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
    // Get unique grade levels from current subject
    final grades = (_questionsBySubject[_selectedSubject] ?? [])
        .map((q) => q.gradeLevel)
        .toSet()
        .toList()
      ..sort();

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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: _searchTextChanged,
              ),
              const SizedBox(height: 12),
              // Difficulty filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Difficulty: ',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedDifficulty == null,
                      onSelected: (_) {
                        setState(() => _selectedDifficulty = null);
                        _applySearchFilter();
                      },
                    ),
                    const SizedBox(width: 6),
                    ...DifficultyTag.values.map((diff) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(_getDifficultyLabel(diff)),
                            selected: _selectedDifficulty == diff,
                            selectedColor: _getDifficultyColor(diff)
                                .withValues(alpha: 0.3),
                            checkmarkColor: _getDifficultyColor(diff),
                            onSelected: (_) {
                              setState(() => _selectedDifficulty = diff);
                              _applySearchFilter();
                            },
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Grade level filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Grade: ',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedGradeLevel == null,
                      onSelected: (_) {
                        setState(() => _selectedGradeLevel = null);
                        _applySearchFilter();
                      },
                    ),
                    const SizedBox(width: 6),
                    ...grades.map((grade) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text('Grade $grade'),
                            selected: _selectedGradeLevel == grade,
                            selectedColor: Colors.blue.withValues(alpha: 0.3),
                            onSelected: (_) {
                              setState(() => _selectedGradeLevel = grade);
                              _applySearchFilter();
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Filter summary and count
        if (_selectedSubject.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Text(
                  'Showing ${_filteredQuestions.length} questions',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedDifficulty != null ||
                    _selectedGradeLevel != null) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDifficulty = null;
                        _selectedGradeLevel = null;
                      });
                      _applySearchFilter();
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear Filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
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

  String _getDifficultyLabel(DifficultyTag difficulty) {
    switch (difficulty) {
      case DifficultyTag.veryEasy:
        return 'Very Easy';
      case DifficultyTag.easy:
        return 'Easy';
      case DifficultyTag.medium:
        return 'Medium';
      case DifficultyTag.hard:
        return 'Hard';
      case DifficultyTag.veryHard:
        return 'Very Hard';
    }
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
        final isSelected = _selectedQuestionIds.contains(question.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected ? Colors.red.shade50 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isSelected
                ? BorderSide(color: Colors.red.shade300, width: 2)
                : BorderSide.none,
          ),
          child: _isSelectionMode
              ? ListTile(
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleQuestionSelection(question.id),
                    activeColor: Colors.red,
                  ),
                  title: Text(
                    question.questionText.length > 60
                        ? '${question.questionText.substring(0, 60)}...'
                        : question.questionText,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Grade ${question.gradeLevel} • ${_getDifficultyLabel(question.difficulty)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  onTap: () => _toggleQuestionSelection(question.id),
                )
              : ExpansionTile(
                  title: Text(
                    question.questionText.length > 80
                        ? '${question.questionText.substring(0, 80)}...'
                        : question.questionText,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Grade ${question.gradeLevel} • ${question.difficulty.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(question.difficulty)
                              .withValues(alpha: 0.1),
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
                              Flexible(
                                child: Text(
                                  'Topic: ${question.topic}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Text(
                                  'Subtopic: ${question.subtopic}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Text(
                  'Admin Tools',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Clean local duplicates
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.cleaning_services,
                    color: Colors.orange.shade600),
              ),
              title: const Text('Clean Local Duplicates'),
              subtitle:
                  const Text('Remove duplicate questions from local database'),
              onTap: () {
                Navigator.pop(context);
                _cleanLocalDuplicates();
              },
            ),
            const Divider(),
            // Show stats
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics, color: Colors.blue.shade600),
              ),
              title: const Text('Database Statistics'),
              subtitle: const Text('View question counts by subject'),
              onTap: () {
                Navigator.pop(context);
                _showDatabaseStats();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _cleanLocalDuplicates() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning for duplicates in local database...'),
          ],
        ),
      ),
    );

    try {
      final result = await _databaseService.removeDuplicates();
      Navigator.pop(context);

      final total = result['total'] ?? 0;
      final removed = result['duplicates_removed'] ?? 0;
      final remaining = result['unique_remaining'] ?? 0;

      if (removed == 0) {
        _showSuccess(
            'No duplicates found! $total unique questions in local database.');
      } else {
        await _loadSubjects(); // Refresh data
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text('Duplicates Removed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total scanned: $total'),
                const SizedBox(height: 4),
                Text('Duplicates removed: $removed',
                    style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Unique remaining: $remaining',
                    style: TextStyle(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showError('Failed to clean duplicates: $e');
    }
  }

  void _showDatabaseStats() {
    final stats = <String, int>{};
    for (final subject in _subjects) {
      stats[subject] = _questionsBySubject[subject]?.length ?? 0;
    }

    final total = stats.values.fold(0, (sum, count) => sum + count);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade600, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Database Statistics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total: $total questions',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ...stats.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Helper extension
extension Math on int {
  static int min(int a, int b) => a < b ? a : b;
}
