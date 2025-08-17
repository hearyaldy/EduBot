import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/app_provider.dart';
import 'utils/app_theme.dart';
import 'utils/environment_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await EnvironmentConfig.initialize();

  // Validate configuration and show warnings if needed
  final config = EnvironmentConfig.instance;
  final issues = config.validateConfiguration();

  if (issues.isNotEmpty && config.isDebugMode) {
    debugPrint('Configuration Issues:');
    for (final issue in issues) {
      debugPrint('- $issue');
    }
  }

  runApp(const EduBotApp());
}

class EduBotApp extends StatelessWidget {
  const EduBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: MaterialApp(
        title: 'EduBot - AI Homework Helper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
