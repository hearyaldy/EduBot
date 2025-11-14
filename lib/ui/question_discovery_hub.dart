import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../services/question_bank_service.dart';
import 'dart:math';

class QuestionDiscoveryHub extends StatefulWidget {
  const QuestionDiscoveryHub({super.key});

  @override
  State<QuestionDiscoveryHub> createState() => _QuestionDiscoveryHubState();
}

class _QuestionDiscoveryHubState extends State<QuestionDiscoveryHub>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final QuestionBankService _questionBankService = QuestionBankService();

  late TabController _tabController;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  List<Question> _searchResults = [];
  List<Question> _allQuestions = [];
  bool _isLoading = false;

  // Semantic search state
  String _semanticQuery = '';
  List<Question> _semanticResults = [];

  // Topic exploration state
  Map<String, List<Question>> _topicClusters = {};
  String? _selectedTopic;

  // Question similarity state
  Question? _referenceQuestion;
  List<SimilarQuestion> _similarQuestions = [];

  // Curriculum alignment state
  String _selectedGrade = 'All';
  String _selectedStandard = 'All';
  Map<String, List<Question>> _curriculumMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadQuestions();
    _searchController.addListener(_performQuickSearch);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.initialize();
      await _questionBankService.initialize();

      _allQuestions = [
        ..._databaseService.getAllQuestions(),
        ...await _questionBankService.getQuestions(const QuestionFilter()),
      ];

      // Remove duplicates
      final questionMap = <String, Question>{};
      for (final question in _allQuestions) {
        questionMap[question.id] = question;
      }
      _allQuestions = questionMap.values.toList();

      _buildTopicClusters();
      _buildCurriculumMap();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load questions: $e');
    }
  }

  void _buildTopicClusters() {
    _topicClusters.clear();

    for (final question in _allQuestions) {
      final key = '${question.subject} > ${question.topic}';
      _topicClusters.putIfAbsent(key, () => []).add(question);
    }
  }

  void _buildCurriculumMap() {
    _curriculumMap.clear();

    for (final question in _allQuestions) {
      final key = 'Grade ${question.gradeLevel}';
      _curriculumMap.putIfAbsent(key, () => []).add(question);
    }
  }

  void _performQuickSearch() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchResults = _allQuestions.where((question) {
        return question.questionText.toLowerCase().contains(query) ||
            question.answerKey.toLowerCase().contains(query) ||
            question.explanation.toLowerCase().contains(query) ||
            question.topic.toLowerCase().contains(query) ||
            question.subtopic.toLowerCase().contains(query) ||
            question.subject.toLowerCase().contains(query) ||
            question.metadata.tags
                .any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    });
  }

  Future<void> _performSemanticSearch() async {
    if (_semanticQuery.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate semantic search using keyword matching and concept analysis
      final semanticResults = <Question>[];
      final queryTerms = _semanticQuery.toLowerCase().split(' ');

      for (final question in _allQuestions) {
        double relevanceScore = 0.0;

        // Direct text matching
        for (final term in queryTerms) {
          if (question.questionText.toLowerCase().contains(term)) {
            relevanceScore += 2.0;
          }
          if (question.explanation.toLowerCase().contains(term)) {
            relevanceScore += 1.5;
          }
          if (question.topic.toLowerCase().contains(term)) {
            relevanceScore += 1.0;
          }
          if (question.metadata.tags
              .any((tag) => tag.toLowerCase().contains(term))) {
            relevanceScore += 1.0;
          }
        }

        // Concept-based matching
        relevanceScore +=
            _calculateConceptualRelevance(question, _semanticQuery);

        if (relevanceScore > 1.0) {
          semanticResults.add(question);
        }
      }

      // Sort by relevance
      semanticResults.sort((a, b) {
        final scoreA = _calculateTotalRelevance(a, _semanticQuery);
        final scoreB = _calculateTotalRelevance(b, _semanticQuery);
        return scoreB.compareTo(scoreA);
      });

      setState(() {
        _semanticResults = semanticResults.take(20).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Semantic search failed: $e');
    }
  }

  double _calculateConceptualRelevance(Question question, String query) {
    // Simulate conceptual matching using domain knowledge
    final concepts = {
      'algebra': ['equation', 'variable', 'solve', 'expression', 'polynomial'],
      'geometry': [
        'angle',
        'triangle',
        'circle',
        'area',
        'perimeter',
        'volume'
      ],
      'statistics': ['mean', 'median', 'mode', 'probability', 'graph', 'data'],
      'physics': ['force', 'energy', 'motion', 'velocity', 'acceleration'],
      'chemistry': ['atom', 'molecule', 'reaction', 'element', 'compound'],
      'biology': ['cell', 'organism', 'evolution', 'genetics', 'ecosystem'],
      'grammar': ['verb', 'noun', 'adjective', 'sentence', 'clause'],
      'literature': ['poem', 'story', 'character', 'theme', 'analysis'],
    };

    double conceptScore = 0.0;
    final queryLower = query.toLowerCase();

    for (final entry in concepts.entries) {
      if (question.topic.toLowerCase().contains(entry.key) ||
          question.subtopic.toLowerCase().contains(entry.key)) {
        for (final concept in entry.value) {
          if (queryLower.contains(concept)) {
            conceptScore += 0.5;
          }
        }
      }
    }

    return conceptScore;
  }

  double _calculateTotalRelevance(Question question, String query) {
    double score = 0.0;
    final queryLower = query.toLowerCase();

    // Text relevance
    if (question.questionText.toLowerCase().contains(queryLower)) score += 3.0;
    if (question.explanation.toLowerCase().contains(queryLower)) score += 2.0;
    if (question.topic.toLowerCase().contains(queryLower)) score += 2.0;

    // Conceptual relevance
    score += _calculateConceptualRelevance(question, query);

    // Difficulty appropriateness (prefer medium difficulty)
    if (question.difficulty == DifficultyTag.medium) score += 0.5;

    return score;
  }

  void _findSimilarQuestions(Question reference) {
    setState(() {
      _referenceQuestion = reference;
      _isLoading = true;
    });

    try {
      final similarities = <SimilarQuestion>[];

      for (final question in _allQuestions) {
        if (question.id == reference.id) continue;

        final similarity = _calculateQuestionSimilarity(reference, question);
        if (similarity > 0.3) {
          similarities.add(SimilarQuestion(
            question: question,
            similarity: similarity,
            reasons: _getSimilarityReasons(reference, question),
          ));
        }
      }

      similarities.sort((a, b) => b.similarity.compareTo(a.similarity));

      setState(() {
        _similarQuestions = similarities.take(15).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to find similar questions: $e');
    }
  }

  double _calculateQuestionSimilarity(Question q1, Question q2) {
    double similarity = 0.0;

    // Subject and topic similarity
    if (q1.subject == q2.subject) similarity += 0.3;
    if (q1.topic == q2.topic) similarity += 0.2;
    if (q1.subtopic == q2.subtopic) similarity += 0.1;

    // Difficulty similarity
    final difficultyDistance =
        (q1.difficulty.index - q2.difficulty.index).abs();
    similarity += (1.0 - difficultyDistance / 4.0) * 0.1;

    // Question type similarity
    if (q1.questionType == q2.questionType) similarity += 0.1;

    // Content similarity (simplified)
    final words1 = q1.questionText.toLowerCase().split(' ').toSet();
    final words2 = q2.questionText.toLowerCase().split(' ').toSet();
    final commonWords = words1.intersection(words2);
    final totalWords = words1.union(words2);

    if (totalWords.isNotEmpty) {
      similarity += (commonWords.length / totalWords.length) * 0.2;
    }

    return similarity.clamp(0.0, 1.0);
  }

  List<String> _getSimilarityReasons(Question q1, Question q2) {
    final reasons = <String>[];

    if (q1.subject == q2.subject) reasons.add('Same subject');
    if (q1.topic == q2.topic) reasons.add('Same topic');
    if (q1.subtopic == q2.subtopic) reasons.add('Same subtopic');
    if (q1.difficulty == q2.difficulty) reasons.add('Same difficulty');
    if (q1.questionType == q2.questionType) reasons.add('Same question type');
    if (q1.gradeLevel == q2.gradeLevel) reasons.add('Same grade level');

    return reasons;
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

  Widget _buildQuickSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search questions, topics, or concepts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // Search results
          Expanded(
            child: _searchResults.isEmpty && _searchController.text.isEmpty
                ? _buildSearchSuggestions()
                : _searchResults.isEmpty
                    ? const Center(child: Text('No questions found'))
                    : ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          return _buildQuestionTile(_searchResults[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      'Quadratic equations',
      'Photosynthesis process',
      'Shakespeare sonnets',
      'World War II',
      'Probability calculations',
      'Chemical reactions',
      'Grammar rules',
      'Geometric shapes',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Try searching for:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map((suggestion) => ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      _searchController.text = suggestion;
                      _performQuickSearch();
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSemanticSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Semantic search explanation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Semantic search understands concepts and context. Try describing what you\'re looking for in natural language.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Semantic search input
          TextField(
            decoration: const InputDecoration(
              hintText:
                  'Describe what you\'re looking for (e.g., "problems about finding the area of irregular shapes")...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.psychology),
            ),
            maxLines: 3,
            onChanged: (value) {
              _semanticQuery = value;
            },
            onSubmitted: (value) => _performSemanticSearch(),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _performSemanticSearch,
            icon: const Icon(Icons.search),
            label: const Text('Search by Concept'),
          ),

          const SizedBox(height: 16),

          // Semantic search results
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _semanticResults.isEmpty
                    ? SingleChildScrollView(
                        child: _buildSemanticExamples(),
                      )
                    : ListView.separated(
                        itemCount: _semanticResults.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          return _buildQuestionTile(_semanticResults[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemanticExamples() {
    final examples = [
      'Questions about solving equations with multiple variables',
      'Problems involving photosynthesis and plant biology',
      'Literary analysis of metaphors and symbolism',
      'Historical events leading to major wars',
      'Probability problems with real-world applications',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Example semantic searches:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...examples.map((example) => Card(
              child: ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: Text(example),
                onTap: () {
                  _semanticQuery = example;
                  _performSemanticSearch();
                },
              ),
            )),
      ],
    );
  }

  Widget _buildTopicExplorationTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Topic list
          Expanded(
            flex: 1,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Topics',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _topicClusters.keys.length,
                      itemBuilder: (context, index) {
                        final topic = _topicClusters.keys.elementAt(index);
                        final count = _topicClusters[topic]!.length;
                        final isSelected = _selectedTopic == topic;

                        return ListTile(
                          title: Text(topic),
                          subtitle: Text('$count questions'),
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedTopic = topic;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Topic questions
          Expanded(
            flex: 2,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedTopic ?? 'Select a topic',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_selectedTopic != null) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                                '${_topicClusters[_selectedTopic!]!.length} questions'),
                            backgroundColor: Colors.blue.shade100,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: _selectedTopic == null
                        ? const Center(
                            child: Text('Select a topic to explore questions'))
                        : ListView.separated(
                            itemCount: _topicClusters[_selectedTopic!]!.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              return _buildQuestionTile(
                                  _topicClusters[_selectedTopic!]![index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarityTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Reference question selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Find Similar Questions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Select a reference question to find similar ones:'),
                  const SizedBox(height: 12),
                  if (_referenceQuestion == null) ...[
                    ElevatedButton.icon(
                      onPressed: () => _showQuestionSelectionDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Select Reference Question'),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reference Question:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_referenceQuestion!.questionText),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              Chip(label: Text(_referenceQuestion!.subject)),
                              Chip(label: Text(_referenceQuestion!.topic)),
                              Chip(
                                  label: Text(
                                      _referenceQuestion!.difficulty.name)),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _referenceQuestion = null;
                                    _similarQuestions = [];
                                  });
                                },
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Similar questions
          Expanded(
            child: _similarQuestions.isEmpty && _referenceQuestion != null
                ? const Center(child: Text('No similar questions found'))
                : _similarQuestions.isEmpty
                    ? const Center(
                        child: Text(
                            'Select a reference question to find similarities'))
                    : ListView.separated(
                        itemCount: _similarQuestions.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _similarQuestions[index];
                          return _buildSimilarQuestionTile(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Curriculum filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Curriculum Alignment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGrade,
                          decoration: const InputDecoration(
                            labelText: 'Grade Level',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            'All',
                            ...List.generate(12, (i) => 'Grade ${i + 1}'),
                          ]
                              .map((grade) => DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGrade = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStandard,
                          decoration: const InputDecoration(
                            labelText: 'Curriculum Standard',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            'All',
                            'Common Core',
                            'NGSS',
                            'State Standards',
                            'International',
                          ]
                              .map((standard) => DropdownMenuItem(
                                    value: standard,
                                    child: Text(standard),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStandard = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Curriculum-aligned questions
          Expanded(
            child: _buildCurriculumQuestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumQuestions() {
    final filteredQuestions = _allQuestions.where((question) {
      if (_selectedGrade != 'All' &&
          'Grade ${question.gradeLevel}' != _selectedGrade) {
        return false;
      }

      if (_selectedStandard != 'All') {
        // Simulate curriculum standard filtering
        return question.metadata.curriculumStandards.any((standard) =>
            standard.toLowerCase().contains(_selectedStandard.toLowerCase()));
      }

      return true;
    }).toList();

    if (filteredQuestions.isEmpty) {
      return const Center(
        child: Text('No questions match the selected curriculum criteria'),
      );
    }

    // Group by subject for better organization
    final subjectGroups = <String, List<Question>>{};
    for (final question in filteredQuestions) {
      subjectGroups.putIfAbsent(question.subject, () => []).add(question);
    }

    return ListView.builder(
      itemCount: subjectGroups.keys.length,
      itemBuilder: (context, index) {
        final subject = subjectGroups.keys.elementAt(index);
        final questions = subjectGroups[subject]!;

        return ExpansionTile(
          title: Text(subject),
          subtitle: Text('${questions.length} questions'),
          children: questions
              .map((question) => _buildQuestionTile(question))
              .toList(),
        );
      },
    );
  }

  Widget _buildQuestionTile(Question question) {
    return ListTile(
      title: Text(
        question.questionText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(question.subject),
                backgroundColor: Colors.blue.shade100,
              ),
              Chip(
                label: Text(question.topic),
                backgroundColor: Colors.green.shade100,
              ),
              Chip(
                label: Text(question.difficulty.name),
                backgroundColor: _getDifficultyColor(question.difficulty),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view',
            child: ListTile(
              leading: Icon(Icons.visibility),
              title: Text('View Details'),
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'similar',
            child: ListTile(
              leading: Icon(Icons.find_in_page),
              title: Text('Find Similar'),
              dense: true,
            ),
          ),
          const PopupMenuItem(
            value: 'add_to_practice',
            child: ListTile(
              leading: Icon(Icons.add),
              title: Text('Add to Practice'),
              dense: true,
            ),
          ),
        ],
        onSelected: (value) => _handleQuestionAction(value, question),
      ),
    );
  }

  Widget _buildSimilarQuestionTile(SimilarQuestion item) {
    return ListTile(
      title: Text(
        item.question.questionText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                size: 16,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '${(item.similarity * 100).toInt()}% similar',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: item.reasons
                .map((reason) => Chip(
                      label: Text(reason),
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: const TextStyle(fontSize: 10),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(DifficultyTag difficulty) {
    switch (difficulty) {
      case DifficultyTag.veryEasy:
        return Colors.green.shade100;
      case DifficultyTag.easy:
        return Colors.lightGreen.shade100;
      case DifficultyTag.medium:
        return Colors.yellow.shade100;
      case DifficultyTag.hard:
        return Colors.orange.shade100;
      case DifficultyTag.veryHard:
        return Colors.red.shade100;
    }
  }

  void _handleQuestionAction(String action, Question question) {
    switch (action) {
      case 'view':
        _showQuestionDetails(question);
        break;
      case 'similar':
        _findSimilarQuestions(question);
        _tabController.animateTo(3); // Switch to similarity tab
        break;
      case 'add_to_practice':
        _addToPractice(question);
        break;
    }
  }

  void _showQuestionDetails(Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Question Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Question: ${question.questionText}'),
              const SizedBox(height: 8),
              Text('Answer: ${question.answerKey}'),
              const SizedBox(height: 8),
              Text('Explanation: ${question.explanation}'),
              const SizedBox(height: 8),
              Text('Subject: ${question.subject}'),
              Text('Topic: ${question.topic}'),
              Text('Difficulty: ${question.difficulty.name}'),
              Text('Grade Level: ${question.gradeLevel}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addToPractice(Question question) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question added to practice session!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showQuestionSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Reference Question'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _allQuestions.length.clamp(0, 20),
            itemBuilder: (context, index) {
              final question = _allQuestions[index];
              return ListTile(
                title: Text(
                  question.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${question.subject} - ${question.topic}'),
                onTap: () {
                  Navigator.of(context).pop();
                  _findSimilarQuestions(question);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Discovery Hub'),
        backgroundColor: Colors.purple.shade50,
        actions: [
          IconButton(
            onPressed: _loadQuestions,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Quick Search'),
            Tab(icon: Icon(Icons.psychology), text: 'Semantic'),
            Tab(icon: Icon(Icons.explore), text: 'Topics'),
            Tab(icon: Icon(Icons.compare), text: 'Similarity'),
            Tab(icon: Icon(Icons.school), text: 'Curriculum'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuickSearchTab(),
          _buildSemanticSearchTab(),
          _buildTopicExplorationTab(),
          _buildSimilarityTab(),
          _buildCurriculumTab(),
        ],
      ),
    );
  }
}

class SimilarQuestion {
  final Question question;
  final double similarity;
  final List<String> reasons;

  SimilarQuestion({
    required this.question,
    required this.similarity,
    required this.reasons,
  });
}
