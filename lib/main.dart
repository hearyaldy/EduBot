import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/main_navigator.dart';
import 'screens/splash_screen.dart';
import 'providers/app_provider.dart';
import 'services/storage_service.dart';
import 'services/ad_service.dart';
import 'services/supabase_service.dart';
import 'utils/app_theme.dart';
import 'utils/environment_config.dart';
import 'core/theme/app_colors.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await EnvironmentConfig.initialize();

  // Initialize storage service
  await StorageService().initialize();

  // Initialize ad service
  await AdService().initialize();

  // Initialize Supabase service
  try {
    final config = EnvironmentConfig.instance;
    debugPrint('=== Supabase Configuration Debug ===');
    debugPrint('Supabase URL: ${config.supabaseUrl.substring(0, config.supabaseUrl.length > 20 ? 20 : config.supabaseUrl.length)}...');
    debugPrint('Supabase URL configured: ${config.supabaseUrl.isNotEmpty}');
    debugPrint('Supabase Anon Key configured: ${config.supabaseAnonKey.isNotEmpty}');
    debugPrint('Supabase configuration valid: ${config.isSupabaseConfigured}');
    debugPrint('=====================================');
    
    await SupabaseService.initialize();
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
    debugPrint('App will continue with limited functionality');
  }

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
            final provider = AppProvider();
            // Initialize provider with stored data (don't await in build)
            provider.initialize();
            return provider;
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

            theme: ThemeData(
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: AppColors.gray50,
              textTheme: GoogleFonts.interTextTheme(),
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
              ),
            ).copyWith(
              // Override with our modern theme
              primaryColor: AppColors.primary,
              cardTheme: AppTheme.lightTheme.cardTheme,
              elevatedButtonTheme: AppTheme.lightTheme.elevatedButtonTheme,
              inputDecorationTheme: AppTheme.lightTheme.inputDecorationTheme,
            ),
            home: const AppNavigator(),
          );
        },
      ),
    );
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
      child: _showSplash 
        ? const SplashScreen()
        : const MainNavigator(),
    );
  }
}
