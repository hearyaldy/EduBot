import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../services/question_bank_service.dart';
import 'package:uuid/uuid.dart';

class QuestionEditor extends StatefulWidget {
  final Question? question; // null for new question, existing for editing

  const QuestionEditor({super.key, this.question});

  @override
  State<QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final QuestionBankService _questionBankService = QuestionBankService();

  late TabController _tabController;
  bool _isLoading = false;

  // Form controllers
  final _questionTextController = TextEditingController();
  final _answerKeyController = TextEditingController();
  final _explanationController = TextEditingController();
  final _topicController = TextEditingController();
  final _subtopicController = TextEditingController();
  final _targetLanguageController = TextEditingController();
  final _estimatedTimeController = TextEditingController();

  // Choice controllers for multiple choice questions
  final List<TextEditingController> _choiceControllers =
      List.generate(6, (index) => TextEditingController());

  // Tags controller
  final _tagsController = TextEditingController();
  final _curriculumStandardsController = TextEditingController();

  // Selected values
  String _selectedSubject = 'Mathematics';
  int _selectedGradeLevel = 6;
  DifficultyTag _selectedDifficulty = DifficultyTag.medium;
  QuestionType _selectedQuestionType = QuestionType.multipleChoice;
  BloomsTaxonomy _selectedCognitiveLevel = BloomsTaxonomy.understand;

  // Multiple choice options
  int _numberOfChoices = 4;

  bool get _isEditing => widget.question != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _estimatedTimeController.text = '5'; // Default 5 minutes
    _targetLanguageController.text = 'English';

    if (_isEditing) {
      _loadExistingQuestion();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionTextController.dispose();
    _answerKeyController.dispose();
    _explanationController.dispose();
    _topicController.dispose();
    _subtopicController.dispose();
    _targetLanguageController.dispose();
    _estimatedTimeController.dispose();
    _tagsController.dispose();
    _curriculumStandardsController.dispose();
    for (var controller in _choiceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadExistingQuestion() {
    final question = widget.question!;
    _questionTextController.text = question.questionText;
    _answerKeyController.text = question.answerKey;
    _explanationController.text = question.explanation;
    _topicController.text = question.topic;
    _subtopicController.text = question.subtopic;
    _targetLanguageController.text = question.targetLanguage;
    _estimatedTimeController.text =
        question.metadata.estimatedTime.inMinutes.toString();
    _tagsController.text = question.metadata.tags.join(', ');
    _curriculumStandardsController.text =
        question.metadata.curriculumStandards.join(', ');

    _selectedSubject = question.subject;
    _selectedGradeLevel = question.gradeLevel;
    _selectedDifficulty = question.difficulty;
    _selectedQuestionType = question.questionType;
    _selectedCognitiveLevel = question.metadata.cognitiveLevel;

    // Load choices for multiple choice questions
    if (question.questionType == QuestionType.multipleChoice &&
        question.choices.isNotEmpty) {
      _numberOfChoices = question.choices.length;
      for (int i = 0;
          i < question.choices.length && i < _choiceControllers.length;
          i++) {
        _choiceControllers[i].text = question.choices[i];
      }
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create choices list for multiple choice questions
      List<String> choices = [];
      if (_selectedQuestionType == QuestionType.multipleChoice) {
        for (int i = 0; i < _numberOfChoices; i++) {
          if (_choiceControllers[i].text.trim().isNotEmpty) {
            choices.add(_choiceControllers[i].text.trim());
          }
        }
      }

      // Parse tags and curriculum standards
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      final standards = _curriculumStandardsController.text
          .split(',')
          .map((std) => std.trim())
          .where((std) => std.isNotEmpty)
          .toList();

      // Create question metadata
      final metadata = QuestionMetadata(
        estimatedTime:
            Duration(minutes: int.tryParse(_estimatedTimeController.text) ?? 5),
        cognitiveLevel: _selectedCognitiveLevel,
        tags: tags,
        curriculumStandards: standards,
        additionalData: {
          'created_at': _isEditing
              ? (widget.question!.metadata.additionalData['created_at'] ??
                  DateTime.now().toIso8601String())
              : DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'author': 'User',
          'version': _isEditing
              ? ((widget.question!.metadata.additionalData['version'] ?? 0) + 1)
              : 1,
        },
      );

      // Create the question
      final question = Question(
        id: _isEditing ? widget.question!.id : const Uuid().v4(),
        questionText: _questionTextController.text.trim(),
        questionType: _selectedQuestionType,
        choices: choices,
        answerKey: _answerKeyController.text.trim(),
        explanation: _explanationController.text.trim(),
        subject: _selectedSubject,
        topic: _topicController.text.trim(),
        subtopic: _subtopicController.text.trim(),
        gradeLevel: _selectedGradeLevel,
        difficulty: _selectedDifficulty,
        targetLanguage: _targetLanguageController.text.trim(),
        metadata: metadata,
      );

      // Save to database and question bank service
      await _databaseService.initialize();
      await _databaseService.saveQuestion(question);
      _questionBankService.addQuestion(question);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Question updated successfully!'
                : 'Question added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving question: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text
            TextFormField(
              controller: _questionTextController,
              decoration: const InputDecoration(
                labelText: 'Question Text *',
                hintText: 'Enter the question that students will see...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Question text is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Question Type
            DropdownButtonFormField<QuestionType>(
              initialValue: _selectedQuestionType,
              decoration: const InputDecoration(
                labelText: 'Question Type *',
                border: OutlineInputBorder(),
              ),
              items: QuestionType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(_getQuestionTypeDisplayName(type)),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedQuestionType = value!;
                  if (value != QuestionType.multipleChoice) {
                    // Clear choices if not multiple choice
                    for (var controller in _choiceControllers) {
                      controller.clear();
                    }
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // Multiple Choice Options (show only for multiple choice questions)
            if (_selectedQuestionType == QuestionType.multipleChoice) ...[
              const Text(
                'Answer Choices',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Number of choices selector
              Row(
                children: [
                  const Text('Number of choices: '),
                  DropdownButton<int>(
                    value: _numberOfChoices,
                    items: [2, 3, 4, 5, 6]
                        .map((count) => DropdownMenuItem(
                              value: count,
                              child: Text(count.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _numberOfChoices = value!;
                        // Clear controllers beyond the selected number
                        for (int i = _numberOfChoices;
                            i < _choiceControllers.length;
                            i++) {
                          _choiceControllers[i].clear();
                        }
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Choice input fields
              ...List.generate(_numberOfChoices, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _choiceControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Choice ${String.fromCharCode(65 + index)} *',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Choice ${String.fromCharCode(65 + index)} is required';
                      }
                      return null;
                    },
                  ),
                );
              }),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'For multiple choice questions, enter the correct answer choice (A, B, C, etc.) in the Answer Key field below.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],

            // Answer Key
            TextFormField(
              controller: _answerKeyController,
              decoration: InputDecoration(
                labelText: 'Answer Key *',
                hintText: _selectedQuestionType == QuestionType.multipleChoice
                    ? 'Enter the letter of the correct choice (A, B, C, etc.)'
                    : 'Enter the correct answer...',
                border: const OutlineInputBorder(),
              ),
              maxLines:
                  _selectedQuestionType == QuestionType.multipleChoice ? 1 : 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Answer key is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Explanation
            TextFormField(
              controller: _explanationController,
              decoration: const InputDecoration(
                labelText: 'Explanation *',
                hintText: 'Explain why this is the correct answer...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Explanation is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject
          DropdownButtonFormField<String>(
            initialValue: _selectedSubject,
            decoration: const InputDecoration(
              labelText: 'Subject *',
              border: OutlineInputBorder(),
            ),
            items: [
              'Mathematics',
              'Matematik',
              'Science',
              'Sains',
              'English',
              'Bahasa Melayu',
              'History',
              'Geography',
              'Physics',
              'Chemistry',
              'Biology',
              'Computer Science',
              'Art',
              'Music',
              'Physical Education',
              'Other'
            ]
                .map((subject) => DropdownMenuItem(
                      value: subject,
                      child: Text(subject),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubject = value!;
              });
            },
          ),

          const SizedBox(height: 16),

          // Topic
          TextFormField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: 'Topic *',
              hintText: 'e.g., Algebra, Photosynthesis, World War II...',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Topic is required';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Subtopic
          TextFormField(
            controller: _subtopicController,
            decoration: const InputDecoration(
              labelText: 'Subtopic',
              hintText: 'More specific topic area (optional)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // Grade Level
          DropdownButtonFormField<int>(
            initialValue: _selectedGradeLevel,
            decoration: const InputDecoration(
              labelText: 'Grade Level *',
              border: OutlineInputBorder(),
            ),
            items: List.generate(12, (index) => index + 1)
                .map((grade) => DropdownMenuItem(
                      value: grade,
                      child: Text('Grade $grade'),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedGradeLevel = value!;
              });
            },
          ),

          const SizedBox(height: 16),

          // Difficulty
          DropdownButtonFormField<DifficultyTag>(
            initialValue: _selectedDifficulty,
            decoration: const InputDecoration(
              labelText: 'Difficulty Level *',
              border: OutlineInputBorder(),
            ),
            items: DifficultyTag.values
                .map((difficulty) => DropdownMenuItem(
                      value: difficulty,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(difficulty),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_getDifficultyDisplayName(difficulty)),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDifficulty = value!;
              });
            },
          ),

          const SizedBox(height: 16),

          // Cognitive Level
          DropdownButtonFormField<BloomsTaxonomy>(
            initialValue: _selectedCognitiveLevel,
            decoration: const InputDecoration(
              labelText: 'Cognitive Level (Bloom\'s Taxonomy) *',
              border: OutlineInputBorder(),
            ),
            items: BloomsTaxonomy.values
                .map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(_getCognitiveLevelDisplayName(level)),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCognitiveLevel = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target Language
          TextFormField(
            controller: _targetLanguageController,
            decoration: const InputDecoration(
              labelText: 'Target Language',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // Estimated Time
          TextFormField(
            controller: _estimatedTimeController,
            decoration: const InputDecoration(
              labelText: 'Estimated Time (minutes)',
              border: OutlineInputBorder(),
              suffixText: 'min',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final time = int.tryParse(value);
                if (time == null || time <= 0) {
                  return 'Please enter a valid time in minutes';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Tags
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText:
                  'Enter tags separated by commas (e.g., equations, word-problems, geometry)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          // Curriculum Standards
          TextFormField(
            controller: _curriculumStandardsController,
            decoration: const InputDecoration(
              labelText: 'Curriculum Standards',
              hintText:
                  'Enter standards separated by commas (e.g., CCSS.MATH.6.EE.A.1, NGSS.5-PS1-1)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          // Helpful information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Tips for Better Questions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                    '• Use clear, concise language appropriate for the grade level'),
                Text('• Include relevant context or real-world applications'),
                Text(
                    '• Ensure answer choices are plausible for multiple choice'),
                Text('• Add detailed explanations to help students learn'),
                Text(
                    '• Tag questions with relevant keywords for easy discovery'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getQuestionTypeDisplayName(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueOrFalse:
        return 'True/False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.essay:
        return 'Essay';
      case QuestionType.fillInTheBlank:
        return 'Fill in the Blank';
      case QuestionType.matching:
        return 'Matching';
      case QuestionType.ordering:
        return 'Ordering';
      case QuestionType.calculation:
        return 'Calculation';
    }
  }

  String _getDifficultyDisplayName(DifficultyTag difficulty) {
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

  Color _getDifficultyColor(DifficultyTag difficulty) {
    switch (difficulty) {
      case DifficultyTag.veryEasy:
        return Colors.green;
      case DifficultyTag.easy:
        return Colors.lightGreen;
      case DifficultyTag.medium:
        return Colors.orange;
      case DifficultyTag.hard:
        return Colors.deepOrange;
      case DifficultyTag.veryHard:
        return Colors.red;
    }
  }

  String _getCognitiveLevelDisplayName(BloomsTaxonomy level) {
    switch (level) {
      case BloomsTaxonomy.remember:
        return 'Remember (recall facts)';
      case BloomsTaxonomy.understand:
        return 'Understand (explain ideas)';
      case BloomsTaxonomy.apply:
        return 'Apply (use knowledge)';
      case BloomsTaxonomy.analyze:
        return 'Analyze (break down)';
      case BloomsTaxonomy.evaluate:
        return 'Evaluate (judge value)';
      case BloomsTaxonomy.create:
        return 'Create (produce new)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Question' : 'Add New Question'),
        backgroundColor: Colors.blue.shade50,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            TextButton.icon(
              onPressed: _saveQuestion,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Update' : 'Save'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: 'Question'),
            Tab(icon: Icon(Icons.category), text: 'Classification'),
            Tab(icon: Icon(Icons.info), text: 'Metadata'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildClassificationTab(),
          _buildMetadataTab(),
        ],
      ),
    );
  }
}
