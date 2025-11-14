import 'package:flutter/material.dart';
import '../services/question_bank_initializer.dart';
import '../utils/app_theme.dart';

class QuestionImportScreen extends StatefulWidget {
  const QuestionImportScreen({super.key});

  @override
  State<QuestionImportScreen> createState() => _QuestionImportScreenState();
}

class _QuestionImportScreenState extends State<QuestionImportScreen> {
  final QuestionBankInitializer _initializer = QuestionBankInitializer();
  bool _isLoading = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _lastImportResult;

  @override
  void initState() {
    super.initState();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    setState(() => _isLoading = true);

    final isInit = await _initializer.isQuestionBankInitialized();
    final stats = await _initializer.getQuestionBankStats();

    setState(() {
      _isInitialized = isInit;
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _importAllQuestions() async {
    setState(() => _isLoading = true);

    try {
      final result = await _initializer.importAllSampleQuestions();

      if (mounted) {
        setState(() {
          _lastImportResult = result;
          _isLoading = false;
        });

        // Refresh stats
        await _checkInitialization();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Imported ${result['successfully_imported']} questions!',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _reimportQuestions() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-import Questions?'),
        content: const Text(
          'This will delete all existing questions and import fresh copies from the sample files. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Re-import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await _initializer.reimportAllQuestions();

      if (mounted) {
        setState(() {
          _lastImportResult = result;
          _isLoading = false;
        });

        // Refresh stats
        await _checkInitialization();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Re-imported ${result['successfully_imported']} questions!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Bank Setup'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isInitialized
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: _isInitialized
                                    ? Colors.green
                                    : Colors.orange,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isInitialized
                                          ? 'Question Bank Initialized'
                                          : 'Question Bank Empty',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_stats != null)
                                      Text(
                                        '${_stats!['total_questions']} questions available',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Statistics Card
                  if (_stats != null && _stats!['total_questions'] > 0) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Question Bank Statistics',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatRow(
                                'Total Questions',
                                _stats!['total_questions'].toString()),
                            if (_stats!['subjects'] != null) ...[
                              const Divider(),
                              const Text(
                                'By Subject:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(_stats!['subjects'] as Map).entries.map(
                                    (e) => _buildStatRow(
                                        e.key, e.value.toString()),
                                  ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Import Buttons
                  if (!_isInitialized)
                    ElevatedButton.icon(
                      onPressed: _importAllQuestions,
                      icon: const Icon(Icons.download),
                      label: const Text('Import Sample Questions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _reimportQuestions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Re-import Questions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Last Import Result
                  if (_lastImportResult != null) ...[
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last Import Result',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatRow(
                              'Files Imported',
                              _lastImportResult!['files_imported'].toString(),
                            ),
                            _buildStatRow(
                              'Total Processed',
                              _lastImportResult!['total_processed'].toString(),
                            ),
                            _buildStatRow(
                              'Successfully Imported',
                              _lastImportResult!['successfully_imported']
                                  .toString(),
                              valueColor: Colors.green,
                            ),
                            if (_lastImportResult!['failed_imports'] > 0)
                              _buildStatRow(
                                'Failed Imports',
                                _lastImportResult!['failed_imports'].toString(),
                                valueColor: Colors.red,
                              ),
                            if (_lastImportResult!['errors'].isNotEmpty) ...[
                              const Divider(),
                              const Text(
                                'Errors:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(_lastImportResult!['errors'] as List)
                                  .take(5)
                                  .map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '• $e',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Info Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'About Sample Questions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The question bank includes:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text('• Year 6 Science (Human Reproduction)'),
                        const Text('• Year 2 Mathematics (Basic)'),
                        const Text('• Year 3 English (Reading)'),
                        const SizedBox(height: 8),
                        const Text(
                          'These questions are used for:\n• Practice exercises\n• Adaptive learning recommendations\n• Student progress tracking',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
