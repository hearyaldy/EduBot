import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../services/question_bank_service.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import '../services/student_progress_service.dart';
import '../services/year6_science_importer.dart';
import 'question_editor.dart';
import 'dart:convert';

class QuestionBankManager extends StatefulWidget {
  const QuestionBankManager({super.key});

  @override
  State<QuestionBankManager> createState() => _QuestionBankManagerState();
}

class _QuestionBankManagerState extends State<QuestionBankManager>
    with TickerProviderStateMixin {
  final QuestionBankService _questionBankService = QuestionBankService();
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseService _firebaseService = FirebaseService.instance;
  final StudentProgressService _progressService = StudentProgressService();

  late TabController _tabController;

  List<Question> _allQuestions = [];
  List<Question> _filteredQuestions = [];
  Set<Question> _selectedQuestions = {};

  // Filter states
  String _searchText = '';
  Set<String> _selectedSubjects = {};
  Set<int> _selectedGrades = {};
  Set<DifficultyTag> _selectedDifficulties = {};
  Set<QuestionType> _selectedTypes = {};
  String _sortBy = 'subject'; // subject, grade, difficulty, created
  bool _sortAscending = true;

  // UI states
  bool _isLoading = true;
  bool _isGridView = false;
  Question? _selectedQuestion;

  // Available filter options
  Set<String> _allSubjects = {};
  Set<int> _allGrades = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadQuestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.initialize();
      await _questionBankService.initialize();

      // Load questions from multiple sources:
      // 1. Local database (Hive)
      final dbQuestions = _databaseService.getAllQuestions();

      // 2. Question bank service
      final serviceQuestions =
          await _questionBankService.getQuestions(const QuestionFilter());

      // 3. Firestore (global shared question bank)
      List<Question> firestoreQuestions = [];
      if (FirebaseService.isInitialized) {
        try {
          final firestoreData = await _firebaseService.getQuestionsFromBank();
          firestoreQuestions = firestoreData
              .map((data) {
                try {
                  return Question.fromJson(data);
                } catch (e) {
                  debugPrint('Error parsing question from Firestore: $e');
                  return null;
                }
              })
              .whereType<Question>()
              .toList();
          debugPrint('Loaded ${firestoreQuestions.length} questions from Firestore');
        } catch (e) {
          debugPrint('Error loading from Firestore: $e');
        }
      }

      // Combine and deduplicate (Firestore takes priority)
      final allQuestions = <String, Question>{};

      // Add local questions first
      for (final question in [...dbQuestions, ...serviceQuestions]) {
        allQuestions[question.id] = question;
      }

      // Firestore questions override local ones
      for (final question in firestoreQuestions) {
        allQuestions[question.id] = question;
      }

      setState(() {
        _allQuestions = allQuestions.values.toList();
        _filteredQuestions = List.from(_allQuestions);

        // Extract filter options
        _allSubjects = _allQuestions.map((q) => q.subject).toSet();
        _allGrades = _allQuestions.map((q) => q.gradeLevel).toSet();

        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load questions: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredQuestions = _allQuestions.where((question) {
        // Search text filter
        if (_searchText.isNotEmpty) {
          final searchLower = _searchText.toLowerCase();
          if (!question.questionText.toLowerCase().contains(searchLower) &&
              !question.answerKey.toLowerCase().contains(searchLower) &&
              !question.explanation.toLowerCase().contains(searchLower) &&
              !question.topic.toLowerCase().contains(searchLower) &&
              !question.subtopic.toLowerCase().contains(searchLower)) {
            return false;
          }
        }

        // Subject filter
        if (_selectedSubjects.isNotEmpty &&
            !_selectedSubjects.contains(question.subject)) {
          return false;
        }

        // Grade filter
        if (_selectedGrades.isNotEmpty &&
            !_selectedGrades.contains(question.gradeLevel)) {
          return false;
        }

        // Difficulty filter
        if (_selectedDifficulties.isNotEmpty &&
            !_selectedDifficulties.contains(question.difficulty)) {
          return false;
        }

        // Question type filter
        if (_selectedTypes.isNotEmpty &&
            !_selectedTypes.contains(question.questionType)) {
          return false;
        }

        return true;
      }).toList();

      _sortQuestions();
    });
  }

  void _sortQuestions() {
    _filteredQuestions.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'subject':
          comparison = a.subject.compareTo(b.subject);
          break;
        case 'grade':
          comparison = a.gradeLevel.compareTo(b.gradeLevel);
          break;
        case 'difficulty':
          comparison = a.difficulty.index.compareTo(b.difficulty.index);
          break;
        case 'topic':
          comparison = a.topic.compareTo(b.topic);
          break;
        case 'type':
          comparison = a.questionType.index.compareTo(b.questionType.index);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchText = '';
      _selectedSubjects.clear();
      _selectedGrades.clear();
      _selectedDifficulties.clear();
      _selectedTypes.clear();
    });
    _applyFilters();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteSelectedQuestions() async {
    if (_selectedQuestions.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Questions'),
        content: Text(
            'Are you sure you want to delete ${_selectedQuestions.length} selected questions? This will delete them from both local storage and Firestore.'),
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
        for (final question in _selectedQuestions) {
          // Delete from local database
          await _databaseService.deleteQuestion(question.id);

          // Delete from Firestore if initialized
          if (FirebaseService.isInitialized) {
            try {
              await _firebaseService.deleteQuestionFromBank(question.id);
            } catch (e) {
              debugPrint('Failed to delete from Firestore: $e');
            }
          }
        }

        setState(() {
          _selectedQuestions.clear();
        });

        await _loadQuestions();
        _showSuccessSnackBar('Questions deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete questions: $e');
      }
    }
  }

  Future<void> _exportQuestions() async {
    try {
      final questionsToExport = _selectedQuestions.isNotEmpty
          ? _selectedQuestions.toList()
          : _filteredQuestions;

      final exportData = {
        'metadata': {
          'exported_at': DateTime.now().toIso8601String(),
          'total_questions': questionsToExport.length,
          'filters_applied': {
            'search': _searchText,
            'subjects': _selectedSubjects.toList(),
            'grades': _selectedGrades.toList(),
            'difficulties': _selectedDifficulties.map((d) => d.name).toList(),
            'types': _selectedTypes.map((t) => t.name).toList(),
          },
        },
        'questions': questionsToExport.map((q) => q.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      await Clipboard.setData(ClipboardData(text: jsonString));
      _showSuccessSnackBar(
          'Questions exported to clipboard (${questionsToExport.length} items)');
    } catch (e) {
      _showErrorSnackBar('Export failed: $e');
    }
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // Subject filters
        ..._selectedSubjects.map((subject) => FilterChip(
              label: Text(subject),
              selected: true,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSubjects.add(subject);
                  } else {
                    _selectedSubjects.remove(subject);
                  }
                });
                _applyFilters();
              },
            )),

        // Grade filters
        ..._selectedGrades.map((grade) => FilterChip(
              label: Text('Grade $grade'),
              selected: true,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedGrades.add(grade);
                  } else {
                    _selectedGrades.remove(grade);
                  }
                });
                _applyFilters();
              },
            )),

        // Difficulty filters
        ..._selectedDifficulties.map((difficulty) => FilterChip(
              label: Text(difficulty.name.toUpperCase()),
              selected: true,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDifficulties.add(difficulty);
                  } else {
                    _selectedDifficulties.remove(difficulty);
                  }
                });
                _applyFilters();
              },
            )),

        // Type filters
        ..._selectedTypes.map((type) => FilterChip(
              label: Text(type.name),
              selected: true,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTypes.add(type);
                  } else {
                    _selectedTypes.remove(type);
                  }
                });
                _applyFilters();
              },
            )),

        // Clear all button
        if (_selectedSubjects.isNotEmpty ||
            _selectedGrades.isNotEmpty ||
            _selectedDifficulties.isNotEmpty ||
            _selectedTypes.isNotEmpty)
          ActionChip(
            label: const Text('Clear All'),
            onPressed: _clearFilters,
            backgroundColor: Colors.red.shade100,
          ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search questions...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
                _applyFilters();
              },
            ),

            const SizedBox(height: 16),

            // Filter controls
            Row(
              children: [
                // Subject filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Subjects',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        children: _allSubjects
                            .map((subject) => FilterChip(
                                  label: Text(subject),
                                  selected: _selectedSubjects.contains(subject),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedSubjects.add(subject);
                                      } else {
                                        _selectedSubjects.remove(subject);
                                      }
                                    });
                                    _applyFilters();
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Grade filter
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Grades',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        children: _allGrades
                            .map((grade) => FilterChip(
                                  label: Text('$grade'),
                                  selected: _selectedGrades.contains(grade),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedGrades.add(grade);
                                      } else {
                                        _selectedGrades.remove(grade);
                                      }
                                    });
                                    _applyFilters();
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Difficulty and Type filters
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Difficulty',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        children: DifficultyTag.values
                            .map((difficulty) => FilterChip(
                                  label: Text(difficulty.name),
                                  selected: _selectedDifficulties
                                      .contains(difficulty),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedDifficulties.add(difficulty);
                                      } else {
                                        _selectedDifficulties
                                            .remove(difficulty);
                                      }
                                    });
                                    _applyFilters();
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Question Type',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        children: QuestionType.values
                            .map((type) => FilterChip(
                                  label: Text(type.name),
                                  selected: _selectedTypes.contains(type),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedTypes.add(type);
                                      } else {
                                        _selectedTypes.remove(type);
                                      }
                                    });
                                    _applyFilters();
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Active filters display
            if (_selectedSubjects.isNotEmpty ||
                _selectedGrades.isNotEmpty ||
                _selectedDifficulties.isNotEmpty ||
                _selectedTypes.isNotEmpty) ...[
              const Text('Active Filters:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFilterChips(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No questions found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Try adjusting your filters or search terms'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Column(
            children: [
              // First row: Count, selection info, and select all
              Row(
                children: [
                  Text(
                    '${_filteredQuestions.length} questions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),

                  if (_selectedQuestions.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_selectedQuestions.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => setState(() => _selectedQuestions.clear()),
                      icon: const Icon(Icons.clear, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                      tooltip: 'Clear selection',
                      color: Colors.red,
                    ),
                  ],

                  const Spacer(),

                  // Select All / Deselect All button (compact)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedQuestions.length == _filteredQuestions.length) {
                          _selectedQuestions.clear();
                        } else {
                          _selectedQuestions = Set.from(_filteredQuestions);
                        }
                      });
                    },
                    icon: Icon(
                      _selectedQuestions.length == _filteredQuestions.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 14,
                    ),
                    label: Text(
                      _selectedQuestions.length == _filteredQuestions.length
                          ? 'All'
                          : 'All',
                      style: const TextStyle(fontSize: 10),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 24),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Sort options (compact)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      isDense: true,
                      iconSize: 14,
                      items: const [
                        DropdownMenuItem(value: 'subject', child: Text('Sbj', style: TextStyle(fontSize: 10))),
                        DropdownMenuItem(value: 'grade', child: Text('Gr', style: TextStyle(fontSize: 10))),
                        DropdownMenuItem(
                            value: 'difficulty', child: Text('Diff', style: TextStyle(fontSize: 10))),
                        DropdownMenuItem(value: 'topic', child: Text('Top', style: TextStyle(fontSize: 10))),
                        DropdownMenuItem(value: 'type', child: Text('Typ', style: TextStyle(fontSize: 10))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                        _sortQuestions();
                      },
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                      _sortQuestions();
                    },
                    icon: Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16),
                    tooltip: _sortAscending ? 'Sort descending' : 'Sort ascending',
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                  ),

                  IconButton(
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                    icon: Icon(_isGridView ? Icons.list : Icons.grid_view, size: 16),
                    tooltip: _isGridView ? 'List view' : 'Grid view',
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                  ),
                ],
              ),

              // Submit button when questions are selected
              if (_selectedQuestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitSelectedQuestions,
                    icon: const Icon(Icons.send),
                    label: Text(
                      'Submit ${_selectedQuestions.length} Question${_selectedQuestions.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Questions list/grid
        Expanded(
          child:
              _isGridView ? _buildQuestionsGrid() : _buildQuestionsListView(),
        ),
      ],
    );
  }

  Widget _buildQuestionsListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredQuestions.length,
      itemBuilder: (context, index) {
        final question = _filteredQuestions[index];
        final isSelected = _selectedQuestions.contains(question);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showQuestionDetails(question),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedQuestions.add(question);
                        } else {
                          _selectedQuestions.remove(question);
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question text
                        Text(
                          question.questionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tags/Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChip(
                              question.subject,
                              Colors.blue.shade600,
                              Icons.book,
                            ),
                            _buildChip(
                              'Grade ${question.gradeLevel}',
                              Colors.green.shade600,
                              Icons.school,
                            ),
                            _buildChip(
                              question.difficulty.name,
                              _getDifficultyColor(question.difficulty),
                              Icons.speed,
                            ),
                            _buildChip(
                              question.questionType.name,
                              Colors.purple.shade600,
                              Icons.quiz,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Topic info
                        Row(
                          children: [
                            Icon(Icons.topic, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${question.topic} • ${question.subtopic}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Duplicate'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'preview',
                        child: ListTile(
                          leading: Icon(Icons.preview),
                          title: Text('Preview'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'analytics',
                        child: ListTile(
                          leading: Icon(Icons.analytics),
                          title: Text('Analytics'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          dense: true,
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleQuestionAction(value, question),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredQuestions.length,
      itemBuilder: (context, index) {
        final question = _filteredQuestions[index];
        final isSelected = _selectedQuestions.contains(question);

        return Card(
          elevation: isSelected ? 6 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? Colors.blue.shade600 : Colors.transparent,
              width: isSelected ? 3 : 0,
            ),
          ),
          child: InkWell(
            onTap: () => _showQuestionDetails(question),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedQuestions.add(question);
                            } else {
                              _selectedQuestions.remove(question);
                            }
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(
                              value: 'duplicate', child: Text('Duplicate')),
                          const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete',
                                style: TextStyle(color: Colors.red))),
                        ],
                        onSelected: (value) =>
                            _handleQuestionAction(value, question),
                      ),
                    ],
                  ),

                  // Question text
                  Expanded(
                    child: Text(
                      question.questionText,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subject badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      question.subject,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Info row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school, size: 16, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Gr ${question.gradeLevel}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(question.difficulty).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getDifficultyColor(question.difficulty),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          question.difficulty.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getDifficultyColor(question.difficulty),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(DifficultyTag difficulty) {
    switch (difficulty) {
      case DifficultyTag.veryEasy:
        return Colors.green.shade700;
      case DifficultyTag.easy:
        return Colors.lightGreen.shade700;
      case DifficultyTag.medium:
        return Colors.amber.shade700;
      case DifficultyTag.hard:
        return Colors.orange.shade700;
      case DifficultyTag.veryHard:
        return Colors.red.shade700;
    }
  }

  Widget _buildChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _submitSelectedQuestions() async {
    if (_selectedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one question'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Questions'),
        content: Text(
          'Submit ${_selectedQuestions.length} selected question${_selectedQuestions.length > 1 ? 's' : ''} to Firebase?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Submitting questions...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Submit to Firebase
      int successCount = 0;
      int failCount = 0;

      for (final question in _selectedQuestions) {
        try {
          await _firebaseService.saveQuestionToBank(question.toJson());
          successCount++;
        } catch (e) {
          debugPrint('Error submitting question: $e');
          failCount++;
        }
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Submitted $successCount question${successCount > 1 ? 's' : ''} successfully'
              '${failCount > 0 ? ', $failCount failed' : ''}',
            ),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Clear selection
        setState(() {
          _selectedQuestions.clear();
        });
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleQuestionAction(String action, Question question) {
    switch (action) {
      case 'edit':
        _editQuestion(question);
        break;
      case 'duplicate':
        _duplicateQuestion(question);
        break;
      case 'preview':
        _showQuestionDetails(question);
        break;
      case 'analytics':
        _showQuestionAnalytics(question);
        break;
      case 'delete':
        _deleteQuestion(question);
        break;
    }
  }

  void _editQuestion(Question question) {
    // TODO: Navigate to question editor
    _showSuccessSnackBar('Edit functionality coming soon');
  }

  void _duplicateQuestion(Question question) {
    // TODO: Create duplicate with new ID
    _showSuccessSnackBar('Duplicate functionality coming soon');
  }

  void _deleteQuestion(Question question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text(
            'Are you sure you want to delete this question from both local storage and Firestore?\n\n"${question.questionText}"'),
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

        // Delete from Firestore if initialized
        if (FirebaseService.isInitialized) {
          try {
            await _firebaseService.deleteQuestionFromBank(question.id);
          } catch (e) {
            debugPrint('Failed to delete from Firestore: $e');
          }
        }

        await _loadQuestions();
        _showSuccessSnackBar('Question deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete question: $e');
      }
    }
  }

  void _showQuestionDetails(Question question) {
    setState(() {
      _selectedQuestion = question;
    });
  }

  void _showQuestionAnalytics(Question question) {
    // TODO: Show analytics for this question
    _showSuccessSnackBar('Analytics functionality coming soon');
  }

  Future<void> _addNewQuestion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuestionEditor()),
    );

    if (result == true) {
      // Question was added successfully, reload questions
      await _loadQuestions();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_question':
        _addNewQuestion();
        break;
      case 'import_json':
        _showImportJsonDialog();
        break;
      case 'import_csv':
        _showImportCsvDialog();
        break;
      case 'import_year6_science':
        _importYear6ScienceQuestions();
        break;
      case 'export_all':
        _exportQuestions();
        break;
      case 'sync_to_firestore':
        _syncLocalQuestionsToFirestore();
        break;
      case 'refresh':
        _loadQuestions();
        break;
    }
  }

  Future<void> _syncLocalQuestionsToFirestore() async {
    if (!FirebaseService.isInitialized) {
      _showErrorSnackBar('Firebase is not initialized. Cannot sync to Firestore.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync to Firestore'),
        content: Text(
            'This will upload ${_allQuestions.length} questions to Firestore so all users can access them. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Convert questions to JSON format
        final questionsData = _allQuestions.map((q) => q.toJson()).toList();

        // Sync to Firestore
        await _firebaseService.syncQuestionsToFirestore(questionsData);

        setState(() {
          _isLoading = false;
        });

        _showSuccessSnackBar(
            'Successfully synced ${_allQuestions.length} questions to Firestore');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to sync to Firestore: $e');
      }
    }
  }

  void _showImportJsonDialog() {
    final TextEditingController jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import JSON Questions'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paste your JSON questions below:'),
              const SizedBox(height: 8),
              const Text(
                'Expected format: Array of question objects or {questions: [...]}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jsonController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '[\n  {\n    "id": "q1",\n    "question_text": "...",\n    ...\n  }\n]',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tip: Create questions in Question Bank Manager and use Export to see the expected format.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _importQuestionsFromJson(jsonController.text);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importQuestionsFromJson(String jsonText) async {
    if (jsonText.trim().isEmpty) {
      _showErrorSnackBar('Please paste JSON content');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Parse JSON
      final dynamic jsonData = json.decode(jsonText);

      List<dynamic> questionsJson;

      // Handle different JSON formats
      if (jsonData is List) {
        questionsJson = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('questions')) {
        questionsJson = jsonData['questions'] as List;
      } else if (jsonData is Map && jsonData.containsKey('metadata')) {
        // Handle export format with metadata
        questionsJson = jsonData['questions'] as List;
      } else {
        throw const FormatException('Invalid JSON format. Expected array of questions or object with "questions" key.');
      }

      // Parse questions
      final questions = <Question>[];
      int successCount = 0;
      int errorCount = 0;

      for (var i = 0; i < questionsJson.length; i++) {
        try {
          final questionData = questionsJson[i] as Map<String, dynamic>;
          final question = Question.fromJson(questionData);
          questions.add(question);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('Error parsing question at index $i: $e');
        }
      }

      if (questions.isEmpty) {
        throw Exception('No valid questions found in JSON');
      }

      // Save to local database
      for (final question in questions) {
        await _databaseService.saveQuestion(question);
      }

      // Save to Firestore if initialized
      if (FirebaseService.isInitialized) {
        try {
          final questionsData = questions.map((q) => q.toJson()).toList();
          await _firebaseService.syncQuestionsToFirestore(questionsData);
        } catch (e) {
          debugPrint('Failed to sync to Firestore: $e');
        }
      }

      setState(() {
        _isLoading = false;
      });

      // Reload questions
      await _loadQuestions();

      _showSuccessSnackBar(
        'Successfully imported $successCount questions' +
        (errorCount > 0 ? ' ($errorCount failed)' : '')
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to import JSON: ${e.toString()}');
    }
  }

  Future<void> _importYear6ScienceQuestions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Import using the new service
      final importer = Year6ScienceImporter();
      final result = await importer.importYear6ScienceQuestions();
      
      setState(() {
        _isLoading = false;
      });

      // Show results
      final successCount = result['successfully_imported'];
      final errorCount = result['failed_imports'];
      final errors = result['errors'] as List<String>?;
      final errorList = errors ?? [];

      if (successCount > 0) {
        // Reload questions
        await _loadQuestions();
        
        _showSuccessSnackBar(
          'Successfully imported $successCount Year 6 Science questions!' +
          (errorCount > 0 ? ' ($errorCount failed)' : '')
        );
      } else {
        _showErrorSnackBar('No questions were imported. Errors occurred: ${errorList.join(', ')}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to import Year 6 Science questions: ${e.toString()}');
    }
  }

  void _showImportCsvDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import CSV Questions'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('To import questions from a CSV file:'),
            SizedBox(height: 8),
            Text('1. Prepare your CSV file with columns:'),
            Text('   - Question, Answer, Subject, Topic, etc.'),
            Text('2. Use the CSV import service'),
            Text('3. Questions will be added to the bank'),
            SizedBox(height: 16),
            Text('This feature requires file picker implementation.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionDetails() {
    if (_selectedQuestion == null) {
      return const Center(
        child: Text('Select a question to view details'),
      );
    }

    final question = _selectedQuestion!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Question Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _selectedQuestion = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('ID', question.id),
                    _buildDetailRow('Question', question.questionText),
                    _buildDetailRow('Type', question.questionType.name),
                    _buildDetailRow('Subject', question.subject),
                    _buildDetailRow('Topic', question.topic),
                    _buildDetailRow('Subtopic', question.subtopic),
                    _buildDetailRow(
                        'Grade Level', question.gradeLevel.toString()),
                    _buildDetailRow('Difficulty', question.difficulty.name),
                    _buildDetailRow('Answer', question.answerKey),
                    _buildDetailRow('Explanation', question.explanation),
                    if (question.choices.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Choices:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...question.choices.asMap().entries.map((entry) {
                        final index = entry.key;
                        final choice = entry.value;
                        final isCorrect = choice == question.answerKey;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${String.fromCharCode(65 + index)}. '),
                              Expanded(child: Text(choice)),
                              if (isCorrect)
                                const Icon(Icons.check,
                                    color: Colors.green, size: 16),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                    const Text('Metadata:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildDetailRow('Target Language', question.targetLanguage),
                    _buildDetailRow('Estimated Time',
                        '${question.metadata.estimatedTime.inMinutes} minutes'),
                    _buildDetailRow('Cognitive Level',
                        question.metadata.cognitiveLevel.name),
                    if (question.metadata.curriculumStandards.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Curriculum Standards:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...question.metadata.curriculumStandards
                          .map((standard) => Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text('• $standard'),
                              )),
                    ],
                    if (question.metadata.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Tags:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        children: question.metadata.tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: Colors.grey.shade200,
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildQuestionBankStats() {
    // Show loading state while database is initializing
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading question bank statistics...'),
          ],
        ),
      );
    }

    // Check if there are any questions loaded
    if (_allQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No questions in the database',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add questions using the + button or import from JSON',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addNewQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Add First Question'),
            ),
          ],
        ),
      );
    }

    final stats = _databaseService.getQuestionBankStats();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.quiz, size: 48, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text(
                          '${stats['total_questions']}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Total Questions'),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.school, size: 48, color: Colors.green),
                        const SizedBox(height: 8),
                        Text(
                          '${(stats['subjects'] as Map?)?.length ?? 0}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Subjects'),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.trending_up,
                            size: 48, color: Colors.orange),
                        const SizedBox(height: 8),
                        Text(
                          '${(stats['coverage_grade_levels'] as List?)?.length ?? 0}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Text('Grade Levels'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Detailed stats
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('By Subject',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              children:
                                  (stats['subjects'] is Map
                                      ? Map<String, dynamic>.from(stats['subjects'] as Map)
                                      : <String, dynamic>{})
                                      .entries
                                      .map((entry) => ListTile(
                                            title: Text(entry.key),
                                            trailing: Text('${entry.value}'),
                                            dense: true,
                                          ))
                                      .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('By Grade',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              children: (stats['grade_levels'] is Map
                                      ? Map<String, dynamic>.from(stats['grade_levels'] as Map)
                                      : <String, dynamic>{})
                                  .entries
                                  .map((entry) => ListTile(
                                        title: Text('Grade ${entry.key}'),
                                        trailing: Text('${entry.value}'),
                                        dense: true,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('By Difficulty',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              children: (stats['difficulties'] is Map
                                      ? Map<String, dynamic>.from(stats['difficulties'] as Map)
                                      : <String, dynamic>{})
                                  .entries
                                  .map((entry) => ListTile(
                                        title: Text(entry.key),
                                        trailing: Text('${entry.value}'),
                                        dense: true,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Question Bank Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Add New Question button
          IconButton(
            onPressed: () => _addNewQuestion(),
            icon: const Icon(Icons.add_circle),
            tooltip: 'Add New Question',
            iconSize: 28,
          ),
          if (_selectedQuestions.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedQuestions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _exportQuestions,
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export selected',
            ),
            IconButton(
              onPressed: _deleteSelectedQuestions,
              icon: const Icon(Icons.delete_rounded),
              tooltip: 'Delete selected',
            ),
          ],
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_question',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Add Question'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'import_json',
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Import JSON'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'import_csv',
                child: ListTile(
                  leading: Icon(Icons.table_chart),
                  title: Text('Import CSV'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'import_year6_science',
                child: ListTile(
                  leading: Icon(Icons.science),
                  title: Text('Import Year 6 Science'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'export_all',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export All'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'sync_to_firestore',
                child: ListTile(
                  leading: Icon(Icons.cloud_upload, color: Colors.blue),
                  title: Text('Sync to Firestore'),
                  subtitle: Text('Upload to cloud for all users', style: TextStyle(fontSize: 11)),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  dense: true,
                ),
              ),
            ],
            onSelected: (value) => _handleMenuAction(value),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.list_rounded), text: 'Browse'),
            Tab(icon: Icon(Icons.search_rounded), text: 'Search'),
            Tab(icon: Icon(Icons.info_rounded), text: 'Details'),
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Browse tab
          _buildQuestionsList(),

          // Search tab
          _buildSearchAndFilters(),

          // Details tab
          _buildQuestionDetails(),

          // Statistics tab
          _buildQuestionBankStats(),
        ],
      ),
    );
  }
}
