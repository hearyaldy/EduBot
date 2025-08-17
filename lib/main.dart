import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/main_navigator.dart';
import 'providers/app_provider.dart';
import 'services/storage_service.dart';
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
            home: const MainNavigator(),
          );
        },
      ),
    );
  }
}
