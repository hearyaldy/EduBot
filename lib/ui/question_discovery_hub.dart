import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../services/question_bank_service.dart';
// import 'dart:math'; // Unused

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
  final Map<String, List<Question>> _topicClusters = {};
  String? _selectedTopic;

  // Question similarity state
  Question? _referenceQuestion;
  List<SimilarQuestion> _similarQuestions = [];

  // Curriculum alignment state
  String _selectedGrade = 'All';
  String _selectedStandard = 'All';
  final Map<String, List<Question>> _curriculumMap = {};

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
    // Group topics by subject for better organization
    final Map<String, List<MapEntry<String, List<Question>>>> subjectGroups =
        {};
    for (final entry in _topicClusters.entries) {
      final parts = entry.key.split(' > ');
      final subject = parts.isNotEmpty ? parts[0] : 'Other';
      subjectGroups.putIfAbsent(subject, () => []).add(entry);
    }

    // Subject colors for visual distinction
    final subjectColors = {
      'Math': Colors.blue,
      'Mathematics': Colors.blue,
      'Science': Colors.green,
      'English': Colors.orange,
      'History': Colors.brown,
      'Geography': Colors.teal,
      'Art': Colors.pink,
      'Music': Colors.purple,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_open,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Browse by Topic',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_topicClusters.length} topics • ${_allQuestions.length} questions',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Subject cards with topics
        ...subjectGroups.entries.map((subjectEntry) {
          final subject = subjectEntry.key;
          final topics = subjectEntry.value;
          final color = subjectColors[subject] ?? Colors.grey;
          final totalQuestions =
              topics.fold<int>(0, (sum, t) => sum + t.value.length);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSubjectIcon(subject),
                      color: color,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${topics.length} topics • $totalQuestions questions',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  children: [
                    Container(
                      color: Colors.grey.shade50,
                      child: Column(
                        children: topics.map((topicEntry) {
                          final topicName =
                              topicEntry.key.split(' > ').length > 1
                                  ? topicEntry.key.split(' > ')[1]
                                  : topicEntry.key;
                          final questions = topicEntry.value;
                          final isSelected = _selectedTopic == topicEntry.key;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTopic =
                                    isSelected ? null : topicEntry.key;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.1)
                                    : null,
                                border: Border(
                                  left: BorderSide(
                                    color:
                                        isSelected ? color : Colors.transparent,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: isSelected
                                              ? color
                                              : Colors.grey.shade400,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            topicName,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? color.shade700
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? color.withValues(alpha: 0.2)
                                                : Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${questions.length}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? color
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isSelected
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_right,
                                          color: Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Show questions when topic is selected
                                  if (isSelected)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border(
                                          top: BorderSide(
                                              color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: Column(
                                        children: questions.take(5).map((q) {
                                          return ListTile(
                                            dense: true,
                                            leading: CircleAvatar(
                                              radius: 14,
                                              backgroundColor:
                                                  _getDifficultyColor(
                                                      q.difficulty),
                                              child: Text(
                                                q.difficulty.name[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              q.questionText,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                            trailing: const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            onTap: () =>
                                                _showQuestionDetails(q),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  if (isSelected && questions.length > 5)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border(
                                          top: BorderSide(
                                              color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: TextButton.icon(
                                        onPressed: () => _showAllTopicQuestions(
                                            topicEntry.key, questions),
                                        icon: const Icon(Icons.visibility,
                                            size: 18),
                                        label: Text(
                                            'View all ${questions.length} questions'),
                                      ),
                                    ),
                                  Divider(
                                      height: 1, color: Colors.grey.shade200),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'english':
        return Icons.menu_book;
      case 'history':
        return Icons.history_edu;
      case 'geography':
        return Icons.public;
      case 'art':
        return Icons.palette;
      case 'music':
        return Icons.music_note;
      default:
        return Icons.folder;
    }
  }

  void _showAllTopicQuestions(String topic, List<Question> questions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        topic.split(' > ').last,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${questions.length} questions',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getDifficultyColor(q.difficulty),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            q.questionText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(q.difficulty.name),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.pop(context);
                            _showQuestionDetails(q);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Grade Level',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          items: [
                            'All',
                            ...List.generate(12, (i) => 'Grade ${i + 1}'),
                          ]
                              .map((grade) => DropdownMenuItem(
                                    value: grade,
                                    child: Text(grade,
                                        overflow: TextOverflow.ellipsis),
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
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Curriculum Standard',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
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
                                    child: Text(standard,
                                        overflow: TextOverflow.ellipsis),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(question.difficulty),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.quiz_rounded,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Question Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Question
                      _buildDetailSection(
                        icon: Icons.help_outline_rounded,
                        title: 'Question',
                        content: question.questionText,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      // Answer
                      _buildDetailSection(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Answer',
                        content: question.answerKey,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      // Explanation
                      _buildDetailSection(
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'Explanation',
                        content: question.explanation,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      // Metadata
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildMetadataRow(Icons.subject_rounded, 'Subject',
                                question.subject),
                            _buildMetadataRow(
                                Icons.topic_rounded, 'Topic', question.topic),
                            _buildMetadataRow(Icons.speed_rounded, 'Difficulty',
                                question.difficulty.name),
                            _buildMetadataRow(Icons.school_rounded,
                                'Grade Level', question.gradeLevel.toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _findSimilarQuestions(question);
                                _tabController.animateTo(3);
                              },
                              icon: const Icon(Icons.compare_arrows_rounded),
                              label: const Text('Find Similar'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _addToPractice(question);
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add to Practice'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Reference Question',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Choose a question to find similar ones',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  ),
                ),
                // Question list
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _allQuestions.length.clamp(0, 30),
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final question = _allQuestions[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(question.difficulty),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          question.questionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  question.subject,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  question.topic,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _findSimilarQuestions(question);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover Questions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadQuestions,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'favorites',
                child: ListTile(
                  leading: Icon(Icons.favorite_rounded, color: Colors.red),
                  title: Text('My Favorites'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history_rounded, color: Colors.blue),
                  title: Text('Search History'),
                  dense: true,
                ),
              ),
            ],
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$value feature coming soon!')),
              );
            },
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
              isScrollable: true,
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
              labelColor: Colors.deepPurple.shade700,
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
                  icon: Icon(Icons.search_rounded, size: 20),
                  text: 'Quick',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.psychology_rounded, size: 20),
                  text: 'Semantic',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.explore_rounded, size: 20),
                  text: 'Topics',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.compare_rounded, size: 20),
                  text: 'Similar',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.school_rounded, size: 20),
                  text: 'Curriculum',
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
