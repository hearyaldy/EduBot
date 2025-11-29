import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../services/question_import_service.dart';
import '../services/csv_import_service.dart';
import '../services/question_bank_service.dart';
import '../models/question.dart';

class JsonImportDemo extends StatefulWidget {
  const JsonImportDemo({super.key});

  @override
  State<JsonImportDemo> createState() => _JsonImportDemoState();
}

class _JsonImportDemoState extends State<JsonImportDemo> {
  final QuestionImportService _importService = QuestionImportService();
  final CsvImportService _csvService = CsvImportService();
  final QuestionBankService _questionBankService = QuestionBankService();
  final TextEditingController _dataController = TextEditingController();

  Map<String, dynamic>? _lastImportResult;
  List<Question> _currentQuestions = [];
  bool _isLoading = false;
  bool _isJsonMode = true;
  String _selectedSampleFile = 'year2_mathematics_basic.json';

  final List<String> _jsonSampleFiles = [
    'year2_mathematics_basic.json',
    'year3_english_reading.json',
  ];

  final List<String> _csvSampleFiles = [
    'sample_questions.csv',
  ];

  @override
  void initState() {
    super.initState();
    _loadSampleData();
    _refreshQuestionsList();
  }

  Future<void> _loadSampleData() async {
    if (_isJsonMode) {
      await _loadSampleJson();
    } else {
      await _loadSampleCsv();
    }
  }

  Future<void> _loadSampleJson() async {
    try {
      final jsonString = await rootBundle
          .loadString('assets/sample_questions/$_selectedSampleFile');
      setState(() {
        _dataController.text =
            const JsonEncoder.withIndent('  ').convert(json.decode(jsonString));
      });
    } catch (e) {
      _showMessage('Error loading sample file: $e', isError: true);
    }
  }

  Future<void> _loadSampleCsv() async {
    try {
      final csvString = await rootBundle
          .loadString('assets/sample_questions/$_selectedSampleFile');
      setState(() {
        _dataController.text = csvString;
      });
    } catch (e) {
      _showMessage('Error loading sample CSV: $e', isError: true);
    }
  }

  Future<void> _refreshQuestionsList() async {
    try {
      await _questionBankService.initialize();
      const filter = QuestionFilter();
      final questions = await _questionBankService.getQuestions(filter);
      setState(() {
        _currentQuestions = questions;
      });
    } catch (e) {
      _showMessage('Error loading questions: $e', isError: true);
    }
  }

  Future<void> _importData() async {
    if (_dataController.text.trim().isEmpty) {
      _showMessage('Please enter data to import', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;
      if (_isJsonMode) {
        result =
            await _importService.importFromJsonString(_dataController.text);
      } else {
        result = await _csvService.importFromCsvString(_dataController.text);
      }

      setState(() {
        _lastImportResult = result;
      });

      await _refreshQuestionsList();
      _showImportResults(result);
    } catch (e) {
      _showMessage('Import failed: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImportResults(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultRow('Total Processed', result['total_processed']),
              _buildResultRow(
                  'Successfully Imported', result['successfully_imported']),
              _buildResultRow('Failed Imports', result['failed_imports']),
              _buildResultRow(
                  'Duplicates Skipped', result['duplicates_skipped']),
              if ((result['errors'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Errors:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
                ...((result['errors'] as List<String>).take(5).map((error) =>
                    Text('• $error', style: const TextStyle(fontSize: 12)))),
                if ((result['errors'] as List).length > 5)
                  Text(
                      '... and ${(result['errors'] as List).length - 5} more errors'),
              ],
              if ((result['warnings'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Warnings:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.orange)),
                ...((result['warnings'] as List<String>).take(3).map(
                    (warning) => Text('• $warning',
                        style: const TextStyle(fontSize: 12)))),
              ],
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

  Widget _buildResultRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _generateSampleData() async {
    if (_isJsonMode) {
      final sample = _importService.generateSampleJson();
      setState(() {
        _dataController.text =
            const JsonEncoder.withIndent('  ').convert(sample);
      });
    } else {
      final sample = _csvService.generateSampleCsv();
      setState(() {
        _dataController.text = sample;
      });
    }
  }

  Future<void> _exportCurrentQuestions() async {
    try {
      String exportData;
      if (_isJsonMode) {
        exportData = await _importService.exportQuestionsToJson();
      } else {
        exportData = await _csvService.exportQuestionsToCsv();
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Export Questions (${_isJsonMode ? 'JSON' : 'CSV'})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: SelectableText(
                exportData,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: exportData));
                Navigator.of(context).pop();
                _showMessage('Data copied to clipboard!');
              },
              child: const Text('Copy to Clipboard'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showMessage('Export failed: $e', isError: true);
    }
  }

  Future<void> _clearAllQuestions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Questions'),
        content: const Text(
            'Are you sure you want to remove all questions from the question bank? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _questionBankService.initialize();
        await _refreshQuestionsList();
        _showMessage('All questions cleared successfully!');
      } catch (e) {
        _showMessage('Error clearing questions: $e', isError: true);
      }
    }
  }

  void _switchMode() {
    setState(() {
      _isJsonMode = !_isJsonMode;
      if (_isJsonMode) {
        _selectedSampleFile = _jsonSampleFiles.first;
      } else {
        _selectedSampleFile = _csvSampleFiles.first;
      }
      _loadSampleData();
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSampleFiles = _isJsonMode ? _jsonSampleFiles : _csvSampleFiles;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_isJsonMode ? 'JSON' : 'CSV'} Question Import Demo'),
        backgroundColor: Colors.blue.shade50,
        actions: [
          IconButton(
            icon: Icon(_isJsonMode ? Icons.table_chart : Icons.code),
            onPressed: _switchMode,
            tooltip: 'Switch to ${_isJsonMode ? 'CSV' : 'JSON'} mode',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mode selector and sample file selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_isJsonMode ? Icons.code : Icons.table_chart),
                        const SizedBox(width: 8),
                        Text(
                          '${_isJsonMode ? 'JSON' : 'CSV'} Import Mode',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              label: Text('JSON'),
                              icon: Icon(Icons.code, size: 16),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('CSV'),
                              icon: Icon(Icons.table_chart, size: 16),
                            ),
                          ],
                          selected: {_isJsonMode},
                          onSelectionChanged: (Set<bool> selected) {
                            setState(() {
                              _isJsonMode = selected.first;
                              if (_isJsonMode) {
                                _selectedSampleFile = _jsonSampleFiles.first;
                              } else {
                                _selectedSampleFile = _csvSampleFiles.first;
                              }
                            });
                            _loadSampleData();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedSampleFile,
                            isExpanded: true,
                            onChanged: (value) {
                              setState(() {
                                _selectedSampleFile = value!;
                              });
                              _loadSampleData();
                            },
                            items: currentSampleFiles
                                .map((file) => DropdownMenuItem(
                                      value: file,
                                      child: Text(file),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _generateSampleData,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Generate Sample'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Data input area
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_isJsonMode ? 'JSON' : 'CSV'} Question Data',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextField(
                          controller: _dataController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: _isJsonMode
                                ? 'Paste your JSON question data here...'
                                : 'Paste your CSV question data here...',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _importData,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload, size: 16),
                  label: Text('Import ${_isJsonMode ? 'JSON' : 'CSV'}'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _exportCurrentQuestions,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export Current'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _clearAllQuestions,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current questions list
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Questions',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${_currentQuestions.length} questions',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _currentQuestions.isEmpty
                            ? const Center(
                                child: Text(
                                    'No questions in the bank. Import some questions to get started!'))
                            : ListView.builder(
                                itemCount: _currentQuestions.length,
                                itemBuilder: (context, index) {
                                  final question = _currentQuestions[index];
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: ListTile(
                                      dense: true,
                                      title: Text(
                                        question.questionText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        '${question.subject} • ${question.topic} • Grade ${question.gradeLevel} • ${question.difficulty.name}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      trailing: Chip(
                                        label: Text(
                                          question.questionType.name,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        backgroundColor: Colors.blue.shade100,
                                      ),
                                    ),
                                  );
                                },
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
    );
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }
}
