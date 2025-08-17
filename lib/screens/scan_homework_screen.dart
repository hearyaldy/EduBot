import 'package:flutter/material.dart';

class ScanHomeworkScreen extends StatelessWidget {
  const ScanHomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Homework'), centerTitle: true),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Scan Homework Screen', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              'Coming soon! This will allow you to scan homework problems.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
