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

/// Helper to deeply convert Map<dynamic, dynamic> to Map<String, dynamic>
Map<String, dynamic> _deepConvertMap(Map map) {
  return map.map((key, value) {
    final stringKey = key.toString();
    if (value is Map) {
      return MapEntry(stringKey, _deepConvertMap(value));
    } else if (value is List) {
      return MapEntry(
          stringKey,
          value.map((item) {
            if (item is Map) {
              return _deepConvertMap(item);
            }
            return item;
          }).toList());
    }
    return MapEntry(stringKey, value);
  });
}

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
      debugPrint('Firebase initialized: ${FirebaseService.isInitialized}');
      if (FirebaseService.isInitialized) {
        try {
          debugPrint('Fetching questions from Firestore...');
          final firestoreData = await _firebaseService.getQuestionsFromBank();
          debugPrint('Firestore raw data count: ${firestoreData.length}');

          if (firestoreData.isNotEmpty) {
            debugPrint('Sample Firestore data: ${firestoreData.first}');
          }

          firestoreQuestions = firestoreData
              .map((data) {
                try {
                  // Deep convert Map<dynamic, dynamic> to Map<String, dynamic>
                  final convertedData = _deepConvertMap(data);
                  final question = Question.fromJson(convertedData);
                  return question;
                } catch (e) {
                  debugPrint('Error parsing question from Firestore: $e');
                  debugPrint('Problematic data: $data');
                  return null;
                }
              })
              .whereType<Question>()
              .toList();
          debugPrint(
              'Successfully loaded ${firestoreQuestions.length} questions from Firestore');
        } catch (e, stackTrace) {
          debugPrint('Error loading from Firestore: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      } else {
        debugPrint(
            'Firebase is not initialized. Skipping Firestore questions.');
      }

      // Combine and deduplicate by ID first, then by content
      final allQuestionsById = <String, Question>{};
      final contentHashes = <String, String>{}; // hash -> first question id

      // Helper to generate content hash
      String generateContentHash(Question q) {
        final normalizedText = q.questionText.toLowerCase().trim();
        final normalizedAnswer = q.answerKey.toLowerCase().trim();
        final subject = q.subject.toLowerCase().trim();
        final topic = q.topic.toLowerCase().trim();
        return '$normalizedText|$subject|$topic|$normalizedAnswer';
      }

      // Add local questions first
      for (final question in [...dbQuestions, ...serviceQuestions]) {
        final hash = generateContentHash(question);
        if (!contentHashes.containsKey(hash)) {
          contentHashes[hash] = question.id;
          allQuestionsById[question.id] = question;
        }
      }
      debugPrint(
          'After adding local+service (deduplicated): ${allQuestionsById.length} questions');

      // Firestore questions - only add if content is new
      int firestoreNew = 0;
      int firestoreDuplicates = 0;
      for (final question in firestoreQuestions) {
        final hash = generateContentHash(question);
        if (!contentHashes.containsKey(hash)) {
          contentHashes[hash] = question.id;
          allQuestionsById[question.id] = question;
          firestoreNew++;
        } else {
          firestoreDuplicates++;
        }
      }
      debugPrint(
          'Firestore: $firestoreNew new, $firestoreDuplicates duplicates skipped');
      debugPrint('Total unique questions: ${allQuestionsById.length}');

      setState(() {
        _allQuestions = allQuestionsById.values.toList();
        _filteredQuestions = List.from(_allQuestions);

        // Extract filter options
        _allSubjects = _allQuestions.map((q) => q.subject).toSet();
        _allGrades = _allQuestions.map((q) => q.gradeLevel).toSet();

        _isLoading = false;
      });

      debugPrint(
          'Final question count: ${_allQuestions.length}, filtered: ${_filteredQuestions.length}');
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search questions...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.blue.shade600, size: 24),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: Colors.grey.shade400),
                        onPressed: () {
                          setState(() {
                            _searchText = '';
                          });
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
                _applyFilters();
              },
            ),
          ),

          const SizedBox(height: 24),

          // Filter sections
          _buildFilterSection(
            'Subjects',
            Icons.book_rounded,
            Colors.blue.shade600,
            _allSubjects.map((subject) {
              return _buildFilterChipItem(
                subject,
                _selectedSubjects.contains(subject),
                Colors.blue.shade600,
                (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSubjects.add(subject);
                    } else {
                      _selectedSubjects.remove(subject);
                    }
                  });
                  _applyFilters();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          _buildFilterSection(
            'Grade Levels',
            Icons.school_rounded,
            Colors.green.shade600,
            _allGrades.map((grade) {
              return _buildFilterChipItem(
                'Grade $grade',
                _selectedGrades.contains(grade),
                Colors.green.shade600,
                (selected) {
                  setState(() {
                    if (selected) {
                      _selectedGrades.add(grade);
                    } else {
                      _selectedGrades.remove(grade);
                    }
                  });
                  _applyFilters();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          _buildFilterSection(
            'Difficulty',
            Icons.speed_rounded,
            Colors.orange.shade600,
            DifficultyTag.values.map((difficulty) {
              return _buildFilterChipItem(
                difficulty.name,
                _selectedDifficulties.contains(difficulty),
                _getDifficultyColor(difficulty),
                (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDifficulties.add(difficulty);
                    } else {
                      _selectedDifficulties.remove(difficulty);
                    }
                  });
                  _applyFilters();
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          _buildFilterSection(
            'Question Type',
            Icons.quiz_rounded,
            Colors.purple.shade600,
            QuestionType.values.map((type) {
              return _buildFilterChipItem(
                type.name,
                _selectedTypes.contains(type),
                Colors.purple.shade600,
                (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTypes.add(type);
                    } else {
                      _selectedTypes.remove(type);
                    }
                  });
                  _applyFilters();
                },
              );
            }).toList(),
          ),

          // Active filters summary
          if (_selectedSubjects.isNotEmpty ||
              _selectedGrades.isNotEmpty ||
              _selectedDifficulties.isNotEmpty ||
              _selectedTypes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.purple.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_alt_rounded,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Active Filters',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                        label: const Text('Clear All'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                ],
              ),
            ),
          ],

          const SizedBox(height: 100), // Extra padding at bottom
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> chips,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipItem(
    String label,
    bool selected,
    Color color,
    Function(bool) onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? color : Colors.grey.shade300,
          width: selected ? 2 : 1,
        ),
      ),
      labelStyle: TextStyle(
        color: selected ? color : Colors.grey.shade700,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildQuestionsList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading questions...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredQuestions.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 56,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'No Questions Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Try adjusting your filters or search terms\nto find what you\'re looking for',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('Clear All Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Modern Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // First row: Count, selection info, and controls
              Row(
                children: [
                  // Question count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade600,
                          Colors.blue.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.quiz_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '${_filteredQuestions.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_selectedQuestions.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${_selectedQuestions.length} selected',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () =>
                                setState(() => _selectedQuestions.clear()),
                            child: Icon(Icons.close_rounded,
                                size: 16, color: Colors.green.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Controls row
                  Row(
                    children: [
                      // Select All button
                      _buildToolbarButton(
                        icon: _selectedQuestions.length ==
                                _filteredQuestions.length
                            ? Icons.deselect_rounded
                            : Icons.select_all_rounded,
                        tooltip: _selectedQuestions.length ==
                                _filteredQuestions.length
                            ? 'Deselect All'
                            : 'Select All',
                        onPressed: () {
                          setState(() {
                            if (_selectedQuestions.length ==
                                _filteredQuestions.length) {
                              _selectedQuestions.clear();
                            } else {
                              _selectedQuestions = Set.from(_filteredQuestions);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),

                      // Sort dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          underline: const SizedBox(),
                          isDense: true,
                          icon: Icon(Icons.unfold_more_rounded,
                              size: 18, color: Colors.grey.shade600),
                          items: [
                            _buildSortMenuItem(
                                'subject', 'Subject', Icons.book_rounded),
                            _buildSortMenuItem(
                                'grade', 'Grade', Icons.school_rounded),
                            _buildSortMenuItem('difficulty', 'Difficulty',
                                Icons.speed_rounded),
                            _buildSortMenuItem(
                                'topic', 'Topic', Icons.topic_rounded),
                            _buildSortMenuItem(
                                'type', 'Type', Icons.quiz_rounded),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                            _sortQuestions();
                          },
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Sort direction
                      _buildToolbarButton(
                        icon: _sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        tooltip: _sortAscending
                            ? 'Sort Descending'
                            : 'Sort Ascending',
                        onPressed: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                          _sortQuestions();
                        },
                      ),

                      const SizedBox(width: 6),

                      // View toggle
                      _buildToolbarButton(
                        icon: _isGridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        tooltip: _isGridView ? 'List View' : 'Grid View',
                        onPressed: () =>
                            setState(() => _isGridView = !_isGridView),
                      ),
                    ],
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
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: Text(
                      'Submit ${_selectedQuestions.length} Question${_selectedQuestions.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                      shadowColor: Colors.green.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
      padding: const EdgeInsets.all(16),
      itemCount: _filteredQuestions.length,
      itemBuilder: (context, index) {
        final question = _filteredQuestions[index];
        final isSelected = _selectedQuestions.contains(question);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.blue.shade100.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _showQuestionDetails(question),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue.shade400
                        : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checkbox with custom styling
                      Transform.scale(
                        scale: 1.1,
                        child: Checkbox(
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          activeColor: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question text with better typography
                            Text(
                              question.questionText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tags/Chips with modern design
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildModernChip(
                                  question.subject,
                                  Colors.blue.shade600,
                                  Icons.book_rounded,
                                ),
                                _buildModernChip(
                                  'Grade ${question.gradeLevel}',
                                  Colors.green.shade600,
                                  Icons.school_rounded,
                                ),
                                _buildModernChip(
                                  question.difficulty.name,
                                  _getDifficultyColor(question.difficulty),
                                  Icons.speed_rounded,
                                ),
                                _buildModernChip(
                                  question.questionType.name,
                                  Colors.purple.shade600,
                                  Icons.quiz_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Topic info with better design
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.topic_rounded,
                                      size: 16, color: Colors.grey.shade700),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${question.topic} • ${question.subtopic}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Actions with modern icon button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PopupMenuButton(
                          icon: Icon(Icons.more_vert_rounded,
                              color: Colors.grey.shade700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded,
                                      size: 20, color: Colors.blue.shade600),
                                  const SizedBox(width: 12),
                                  const Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded,
                                      size: 20, color: Colors.green.shade600),
                                  const SizedBox(width: 12),
                                  const Text('Duplicate'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'preview',
                              child: Row(
                                children: [
                                  Icon(Icons.preview_rounded,
                                      size: 20, color: Colors.purple.shade600),
                                  const SizedBox(width: 12),
                                  const Text('Preview'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'analytics',
                              child: Row(
                                children: [
                                  Icon(Icons.analytics_rounded,
                                      size: 20, color: Colors.orange.shade600),
                                  const SizedBox(width: 12),
                                  const Text('Analytics'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_rounded,
                                      size: 20, color: Colors.red.shade600),
                                  const SizedBox(width: 12),
                                  Text('Delete',
                                      style: TextStyle(
                                          color: Colors.red.shade600)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) =>
                              _handleQuestionAction(value, question),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Colors.grey.shade700),
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildSortMenuItem(
      String value, String label, IconData icon) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildModernChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded,
                            color: Colors.grey.shade600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded,
                                    size: 18, color: Colors.blue.shade600),
                                const SizedBox(width: 10),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded,
                                    size: 18, color: Colors.green.shade600),
                                const SizedBox(width: 10),
                                const Text('Duplicate'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'preview',
                            child: Row(
                              children: [
                                Icon(Icons.preview_rounded,
                                    size: 18, color: Colors.purple.shade600),
                                const SizedBox(width: 10),
                                const Text('Preview'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'analytics',
                            child: Row(
                              children: [
                                Icon(Icons.analytics_rounded,
                                    size: 18, color: Colors.orange.shade600),
                                const SizedBox(width: 10),
                                const Text('Analytics'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded,
                                    size: 18, color: Colors.red.shade600),
                                const SizedBox(width: 10),
                                Text('Delete',
                                    style:
                                        TextStyle(color: Colors.red.shade600)),
                              ],
                            ),
                          ),
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
                          Icon(Icons.school,
                              size: 16, color: Colors.green.shade600),
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
                          color: _getDifficultyColor(question.difficulty)
                              .withOpacity(0.2),
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

  Future<void> _editQuestion(Question question) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionEditor(question: question),
      ),
    );

    if (result == true) {
      // Question was updated successfully, reload questions
      await _loadQuestions();
      _showSuccessSnackBar('Question updated successfully');
    }
  }

  Future<void> _duplicateQuestion(Question question) async {
    // Create a new question with the same data but a new ID
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final duplicatedQuestion = Question(
      id: newId,
      questionText: '${question.questionText} (Copy)',
      questionType: question.questionType,
      subject: question.subject,
      topic: question.topic,
      subtopic: question.subtopic,
      gradeLevel: question.gradeLevel,
      difficulty: question.difficulty,
      choices: List<String>.from(question.choices),
      answerKey: question.answerKey,
      explanation: question.explanation,
      targetLanguage: question.targetLanguage,
      metadata: QuestionMetadata(
        estimatedTime: question.metadata.estimatedTime,
        cognitiveLevel: question.metadata.cognitiveLevel,
        curriculumStandards:
            List<String>.from(question.metadata.curriculumStandards),
        tags: List<String>.from(question.metadata.tags),
        additionalData:
            Map<String, dynamic>.from(question.metadata.additionalData),
      ),
    );

    try {
      // Save to local database
      await _databaseService.saveQuestion(duplicatedQuestion);

      // Also sync to Firestore if available
      if (FirebaseService.isInitialized) {
        try {
          await _firebaseService
              .saveQuestionToBank(duplicatedQuestion.toJson());
        } catch (e) {
          debugPrint('Failed to sync duplicated question to Firestore: $e');
        }
      }

      await _loadQuestions();
      _showSuccessSnackBar('Question duplicated successfully');

      // Optionally open the editor for the duplicated question
      final editDuplicate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Text('Question Duplicated'),
            ],
          ),
          content:
              const Text('Would you like to edit the duplicated question now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Edit Now'),
            ),
          ],
        ),
      );

      if (editDuplicate == true) {
        _editQuestion(duplicatedQuestion);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to duplicate question: $e');
    }
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.analytics_rounded,
                  color: Colors.orange.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Question Analytics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  question.questionText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20),

              // Analytics cards
              _buildAnalyticsRow(
                Icons.speed_rounded,
                'Difficulty',
                question.difficulty.name,
                _getDifficultyColor(question.difficulty),
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow(
                Icons.timer_rounded,
                'Est. Time',
                '${question.metadata.estimatedTime.inMinutes} min',
                Colors.blue.shade600,
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow(
                Icons.psychology_rounded,
                'Cognitive Level',
                question.metadata.cognitiveLevel.name,
                Colors.purple.shade600,
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow(
                Icons.quiz_rounded,
                'Question Type',
                question.questionType.name,
                Colors.teal.shade600,
              ),
              const SizedBox(height: 12),
              _buildAnalyticsRow(
                Icons.school_rounded,
                'Grade Level',
                'Grade ${question.gradeLevel}',
                Colors.green.shade600,
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Tags
              if (question.metadata.tags.isNotEmpty) ...[
                Text(
                  'Tags',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: question.metadata.tags
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Curriculum Standards
              if (question.metadata.curriculumStandards.isNotEmpty) ...[
                Text(
                  'Curriculum Standards',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...question.metadata.curriculumStandards
                    .map((standard) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 16, color: Colors.green.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  standard,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _showQuestionDetails(question);
            },
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
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
      case 'check_firestore':
        _checkFirestoreConnection();
        break;
      case 'remove_duplicates':
        _removeDuplicateQuestions();
        break;
    }
  }

  Future<void> _checkFirestoreConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking Firestore connection...'),
          ],
        ),
      ),
    );

    try {
      // Check Firebase initialization
      final isInitialized = FirebaseService.isInitialized;
      debugPrint('Firebase initialized: $isInitialized');

      if (!isInitialized) {
        Navigator.pop(context);
        _showErrorSnackBar(
            'Firebase is not initialized. Please check your Firebase configuration.');
        return;
      }

      // Try to get question count
      final count = await _firebaseService.getQuestionBankCount();
      debugPrint('Question bank count: $count');

      // Try to get questions
      final questions = await _firebaseService.getQuestionsFromBank(limit: 5);
      debugPrint('Sample questions fetched: ${questions.length}');

      Navigator.pop(context);

      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Firestore Connection Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Firebase Initialized: $isInitialized'),
              const SizedBox(height: 8),
              Text('📊 Total Questions in Firestore: $count'),
              const SizedBox(height: 8),
              Text('📥 Sample Questions Fetched: ${questions.length}'),
              const SizedBox(height: 16),
              if (count == 0)
                const Text(
                  'ℹ️ No questions found in Firestore. Try syncing your local questions using "Sync to Firestore" option.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              if (count > 0 && questions.isEmpty)
                const Text(
                  '⚠️ Questions exist but failed to fetch. Check debug logs for parsing errors.',
                  style: TextStyle(color: Colors.orange),
                ),
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
    } catch (e, stackTrace) {
      Navigator.pop(context);
      debugPrint('Firestore connection check failed: $e');
      debugPrint('Stack trace: $stackTrace');
      _showErrorSnackBar('Firestore connection check failed: $e');
    }
  }

  Future<void> _syncLocalQuestionsToFirestore() async {
    if (!FirebaseService.isInitialized) {
      _showErrorSnackBar(
          'Firebase is not initialized. Cannot sync to Firestore.');
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
                  hintText:
                      '[\n  {\n    "id": "q1",\n    "question_text": "...",\n    ...\n  }\n]',
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
        throw const FormatException(
            'Invalid JSON format. Expected array of questions or object with "questions" key.');
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

      _showSuccessSnackBar('Successfully imported $successCount questions' +
          (errorCount > 0 ? ' ($errorCount failed)' : ''));
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
                (errorCount > 0 ? ' ($errorCount failed)' : ''));
      } else {
        _showErrorSnackBar(
            'No questions were imported. Errors occurred: ${errorList.join(', ')}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(
          'Failed to import Year 6 Science questions: ${e.toString()}');
    }
  }

  Future<void> _removeDuplicateQuestions() async {
    // First, find duplicates to show preview
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning for duplicate questions...'),
          ],
        ),
      ),
    );

    try {
      final duplicates = await _questionBankService.findDuplicates();
      Navigator.pop(context);

      if (duplicates.isEmpty) {
        _showSuccessSnackBar('No duplicate questions found!');
        return;
      }

      // Calculate total duplicates
      int totalDuplicates = 0;
      for (final group in duplicates) {
        totalDuplicates +=
            (group['count'] as int) - 1; // Keep one, count rest as duplicates
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Duplicates Found'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found $totalDuplicates duplicate questions in ${duplicates.length} groups.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('Sample duplicate groups:'),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: duplicates.length > 5 ? 5 : duplicates.length,
                    itemBuilder: (context, index) {
                      final group = duplicates[index];
                      final questions = group['questions'] as List;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${group['count']} copies:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                questions.isNotEmpty
                                    ? questions[0]['question_text'] ?? ''
                                    : '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (duplicates.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '... and ${duplicates.length - 5} more duplicate groups',
                      style: const TextStyle(
                          fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Do you want to remove these duplicates?\n(One copy of each will be kept)',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Remove $totalDuplicates Duplicates'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() {
          _isLoading = true;
        });

        // Remove duplicates from QuestionBankService
        final result = await _questionBankService.removeDuplicates();

        // Also remove from local database
        final duplicateIds = result['duplicate_ids'] as List<String>;
        for (final id in duplicateIds) {
          try {
            await _databaseService.deleteQuestion(id);
          } catch (e) {
            debugPrint('Error removing duplicate from database: $e');
          }
        }

        // Reload questions
        await _loadQuestions();

        _showSuccessSnackBar(
          'Removed ${result['duplicates_removed']} duplicate questions. '
          '${result['questions_remaining']} questions remaining.',
        );
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorSnackBar('Failed to scan for duplicates: $e');
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
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade100,
                      Colors.purple.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.touch_app_rounded,
                  size: 56,
                  color: Colors.indigo.shade600,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Select a Question',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap on any question from the Browse tab\nto view its full details here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final question = _selectedQuestion!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade600,
                  Colors.purple.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.quiz_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Question Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedQuestion = null),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildDetailTag(question.subject, Icons.book_rounded),
                    _buildDetailTag(
                        'Grade ${question.gradeLevel}', Icons.school_rounded),
                    _buildDetailTag(
                        question.difficulty.name, Icons.speed_rounded),
                    _buildDetailTag(
                        question.questionType.name, Icons.quiz_rounded),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Question Text Card
          _buildDetailSection(
            'Question',
            Icons.help_outline_rounded,
            Colors.blue.shade600,
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                question.questionText,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Choices Card (if applicable)
          if (question.choices.isNotEmpty)
            _buildDetailSection(
              'Choices',
              Icons.list_alt_rounded,
              Colors.purple.shade600,
              Column(
                children: question.choices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final choice = entry.value;
                  final isCorrect = choice == question.answerKey;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.shade300
                            : Colors.grey.shade200,
                        width: isCorrect ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.shade600
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            choice,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                              fontWeight: isCorrect
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isCorrect)
                          Icon(Icons.check_circle_rounded,
                              color: Colors.green.shade600, size: 22),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          if (question.choices.isNotEmpty) const SizedBox(height: 16),

          // Answer & Explanation Card
          _buildDetailSection(
            'Answer & Explanation',
            Icons.lightbulb_outline_rounded,
            Colors.amber.shade700,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Answer: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          question.answerKey,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (question.explanation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    question.explanation,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Topic Info Card
          _buildDetailSection(
            'Topic Information',
            Icons.topic_rounded,
            Colors.teal.shade600,
            Column(
              children: [
                _buildInfoRow('Subject', question.subject, Icons.book_rounded),
                _buildInfoRow('Topic', question.topic, Icons.folder_rounded),
                _buildInfoRow(
                    'Subtopic', question.subtopic, Icons.article_rounded),
                _buildInfoRow('Target Language', question.targetLanguage,
                    Icons.language_rounded),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Metadata Card
          _buildDetailSection(
            'Metadata',
            Icons.info_outline_rounded,
            Colors.grey.shade600,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                    'Estimated Time',
                    '${question.metadata.estimatedTime.inMinutes} minutes',
                    Icons.timer_rounded),
                _buildInfoRow('Cognitive Level',
                    question.metadata.cognitiveLevel.name, Icons.psychology),
                if (question.metadata.curriculumStandards.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Curriculum Standards',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: question.metadata.curriculumStandards
                        .map((standard) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Text(
                                standard,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                if (question.metadata.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Tags',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: question.metadata.tags
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDetailTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
      String title, IconData icon, Color color, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBankStats() {
    // Show loading state while database is initializing
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading statistics...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Check if there are any questions loaded
    if (_allQuestions.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.quiz_outlined,
                    size: 64, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 24),
              Text(
                'No Questions Available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add questions using the + button or import from JSON',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _addNewQuestion,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _databaseService.getQuestionBankStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Questions',
                    '${stats['total_questions']}',
                    Icons.quiz_rounded,
                    Colors.blue.shade600,
                    Colors.blue.shade50,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Subjects',
                    '${(stats['subjects'] as Map?)?.length ?? 0}',
                    Icons.book_rounded,
                    Colors.green.shade600,
                    Colors.green.shade50,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Grade Levels',
                    '${(stats['coverage_grade_levels'] as List?)?.length ?? 0}',
                    Icons.school_rounded,
                    Colors.orange.shade600,
                    Colors.orange.shade50,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Detailed breakdown - vertical layout for better readability
          _buildStatBreakdownCard(
            'By Subject',
            Icons.book_rounded,
            Colors.blue.shade600,
            (stats['subjects'] is Map
                    ? Map<String, dynamic>.from(stats['subjects'] as Map)
                    : <String, dynamic>{})
                .entries
                .toList(),
          ),
          const SizedBox(height: 16),
          _buildStatBreakdownCard(
            'By Grade',
            Icons.school_rounded,
            Colors.green.shade600,
            (stats['grade_levels'] is Map
                    ? Map<String, dynamic>.from(stats['grade_levels'] as Map)
                    : <String, dynamic>{})
                .entries
                .map((e) => MapEntry('Grade ${e.key}', e.value))
                .toList(),
          ),
          const SizedBox(height: 16),
          _buildStatBreakdownCard(
            'By Difficulty',
            Icons.speed_rounded,
            Colors.orange.shade600,
            (stats['difficulties'] is Map
                    ? Map<String, dynamic>.from(stats['difficulties'] as Map)
                    : <String, dynamic>{})
                .entries
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -10,
            child: Icon(
              icon,
              size: 60,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 22, color: Colors.white),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBreakdownCard(
    String title,
    IconData icon,
    Color color,
    List<MapEntry<String, dynamic>> entries,
  ) {
    // Calculate total for percentage
    final total =
        entries.fold<int>(0, (sum, entry) => sum + (entry.value as int));

    return Container(
      constraints: const BoxConstraints(maxHeight: 350),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: color.withOpacity(0.2),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.8),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entries.length} categories',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics_rounded, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '$total total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final count = entry.value as int;
                      final percentage = total > 0 ? (count / total * 100) : 0;

                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              color.withOpacity(0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background bar (full width at low opacity)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      color.withOpacity(0.05),
                                      color.withOpacity(0.02),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Percentage bar
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              right: 0,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: percentage / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors: [
                                        color.withOpacity(0.2),
                                        color.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // Icon/number indicator
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Label
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.grey.shade800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${percentage.toStringAsFixed(1)}% of total',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Percentage badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color.withOpacity(0.9),
                                          color,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                  subtitle: Text('Upload to cloud for all users',
                      style: TextStyle(fontSize: 11)),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'check_firestore',
                child: ListTile(
                  leading: Icon(Icons.cloud_done, color: Colors.green),
                  title: Text('Check Firestore Connection'),
                  subtitle: Text('Diagnose connection issues',
                      style: TextStyle(fontSize: 11)),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'remove_duplicates',
                child: ListTile(
                  leading: Icon(Icons.cleaning_services, color: Colors.orange),
                  title: Text('Remove Duplicates'),
                  subtitle: Text('Find and remove duplicate questions',
                      style: TextStyle(fontSize: 11)),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.white.withOpacity(0.9),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.list_rounded, size: 20),
                  text: 'Browse',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.search_rounded, size: 20),
                  text: 'Search',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.info_rounded, size: 20),
                  text: 'Details',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.analytics_rounded, size: 20),
                  text: 'Stats',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),
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
