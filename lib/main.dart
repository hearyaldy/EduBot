import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/main_navigator.dart';
import 'screens/splash_screen.dart';
import 'screens/scan_homework_screen.dart';
import 'screens/ask_question_screen.dart';
import 'screens/history_screen.dart';
import 'screens/badges_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/registration_screen.dart';
import 'providers/app_provider.dart';
import 'services/storage_service.dart';
import 'services/ad_service.dart';
import 'services/firebase_service.dart';
import 'services/lesson_service.dart';
import 'services/question_bank_initializer.dart';
import 'services/science_question_importer.dart';
import 'utils/app_theme.dart';
import 'utils/environment_config.dart';
import 'l10n/app_localizations.dart';

void main() async {
  debugPrint('=== EDUBOT APP STARTING ===');

  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('✓ Flutter binding initialized');

    // Initialize environment configuration
    debugPrint('Initializing environment config...');
    await EnvironmentConfig.initialize();
    debugPrint('✓ Environment config initialized');

    // Initialize storage service
    debugPrint('Initializing storage service...');
    await StorageService().initialize();
    debugPrint('✓ Storage service initialized');

    // Initialize ad service
    debugPrint('Initializing ad service...');
    await AdService().initialize();
    debugPrint('✓ Ad service initialized');

    // Initialize Firebase service
    try {
      debugPrint('=== Firebase Configuration Debug ===');
      debugPrint('Initializing Firebase...');

      await FirebaseService.initialize();
      debugPrint('✓ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Firebase initialization failed: $e');
      debugPrint('⚠️ App will continue with limited functionality');
    }

    // Initialize question bank if empty
    try {
      debugPrint('Checking question bank status...');
      final initializer = QuestionBankInitializer();
      final isInitialized = await initializer.isQuestionBankInitialized();

      if (!isInitialized) {
        debugPrint('⚠️ Question bank is empty, importing sample questions...');
        final result = await initializer.importAllSampleQuestions();
        debugPrint('✓ Question bank initialized: ${result['successfully_imported']} questions imported');
      } else {
        final stats = await initializer.getQuestionBankStats();
        debugPrint('✓ Question bank already initialized: ${stats['total_questions']} questions available');
      }
      
      // Import hardcoded lessons to the question bank (always do this to ensure they exist)
      try {
        debugPrint('📚 Importing hardcoded lessons to question bank...');
        final exportResult = await initializer.importHardcodedLessons();
        debugPrint('✓ Hardcoded lessons imported: ${exportResult['questions_exported']} questions');
      } catch (e) {
        debugPrint('⚠️ Failed to import hardcoded lessons: $e');
      }
    } catch (e) {
      debugPrint('⚠️ Question bank initialization failed: $e');
      debugPrint('   You can manually import questions from Settings > Question Bank');
    }

    // Import Year 6 Science questions after question bank is initialized
    try {
      debugPrint('📚 Importing Year 6 Science questions...');
      final scienceImporter = ScienceQuestionImporter();
      final importResult = await scienceImporter.importYear6ScienceQuestions();
      if (importResult['successfully_imported'] > 0) {
        debugPrint('✅ Successfully imported ${importResult['successfully_imported']} Year 6 Science questions');
      } else {
        debugPrint('⚠️ Science questions import completed with ${importResult['failed_imports']} failures');
        if (importResult['errors'].isNotEmpty) {
          debugPrint('   Errors: ${importResult['errors']}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to import Year 6 Science questions: $e');
    }

    // Initialize LessonService
    try {
      debugPrint('Initializing LessonService...');
      final lessonService = LessonService();
      await lessonService.initialize(); // Initialize to load hardcoded lessons and prepare service
      debugPrint('✓ LessonService initialized');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize LessonService: $e');
    }

    // Validate configuration and show warnings if needed
    final config = EnvironmentConfig.instance;
    final issues = config.validateConfiguration();

    if (issues.isNotEmpty && config.isDebugMode) {
      debugPrint('⚠️ Configuration Issues:');
      for (final issue in issues) {
        debugPrint('  - $issue');
      }
    }

    debugPrint('=== LAUNCHING APP ===');
    runApp(const EduBotApp());
  } catch (e, stackTrace) {
    debugPrint('❌ FATAL ERROR IN MAIN: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

class EduBotApp extends StatelessWidget {
  const EduBotApp({super.key});

  Locale _getLocaleFromLanguage(String language) {
    switch (language) {
      case 'Malay':
        return const Locale('ms');
      default:
        return const Locale('en');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            debugPrint('=== Creating AppProvider ===');
            try {
              final provider = AppProvider();
              debugPrint('✓ AppProvider instance created');
              // Initialize provider with stored data (don't await in build)
              debugPrint('Calling provider.initialize()...');
              provider.initialize();
              debugPrint('✓ Provider initialization started');
              return provider;
            } catch (e, stackTrace) {
              debugPrint('❌ ERROR creating AppProvider: $e');
              debugPrint('Stack trace: $stackTrace');
              rethrow;
            }
          },
        ),
      ],
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'EduBot - AI Homework Helper',
            debugShowCheckedModeBanner: false,

            // Localization setup
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ms'), // Malay
            ],
            locale: _getLocaleFromLanguage(provider.selectedLanguage),

            theme: AppTheme.lightTheme.copyWith(
              textTheme: GoogleFonts.interTextTheme(
                AppTheme.lightTheme.textTheme,
              ),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              textTheme: GoogleFonts.interTextTheme(
                AppTheme.darkTheme.textTheme,
              ),
            ),
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/',
            routes: _buildRoutes(),
          );
        },
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => const AppNavigator(),
      '/scan': (context) => const ScanHomeworkScreen(),
      '/ask': (context) => const AskQuestionScreen(),
      '/history': (context) => const HistoryScreen(),
      '/badges': (context) => const BadgesScreen(),
      '/settings': (context) => const SettingsScreen(),
      '/premium': (context) => const PremiumScreen(),
      '/register': (context) => const RegistrationScreen(),
    };
  }
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _hideSplashAfterDelay();
  }

  void _hideSplashAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 4000));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _showSplash ? const SplashScreen() : const MainNavigator(),
    );
  }
}
