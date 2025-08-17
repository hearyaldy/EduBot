// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EduBot - AI Homework Helper';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSubtitle => 'Customize your learning experience';

  @override
  String get account => 'Account';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get preferences => 'Preferences';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get tutorialMode => 'Tutorial Mode';

  @override
  String get about => 'About';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get version => 'Version';

  @override
  String get scanHomework => 'Scan Homework';

  @override
  String get askQuestion => 'Ask Question';

  @override
  String get dailyTips => 'Daily Tips';

  @override
  String get home => 'Home';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get typeYourQuestion => 'Type your question here...';

  @override
  String get send => 'Send';

  @override
  String get parentingTipsTitle => 'Parenting Tips';

  @override
  String get dailyUsage => 'Daily Usage';

  @override
  String get requests => 'Requests';

  @override
  String get tokens => 'Tokens';

  @override
  String get globalUsage => 'Global Usage';

  @override
  String get malayLanguageEnabled => 'Malay language support enabled! 🇲🇾';

  @override
  String languageComingSoon(String language) {
    return '$language support coming soon!';
  }

  @override
  String get error => 'Error';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get developerSettings => 'Developer Settings';

  @override
  String get superadminMode => 'Superadmin Mode';

  @override
  String get superadminDescription =>
      'Override all question limits for testing purposes';

  @override
  String get superadminAccount => 'Superadmin Account';

  @override
  String get superadminSubtitle => 'All limits bypassed - Developer mode';

  @override
  String get enableSuperadminMode => 'Enable Superadmin Mode?';

  @override
  String get superadminWarning =>
      'This will bypass all question limits and API restrictions. This mode is intended for developers and testing purposes only.\n\nAre you sure you want to continue?';

  @override
  String get superadminActive => 'Superadmin mode active - All limits bypassed';

  @override
  String get superadminEnabled =>
      'Superadmin mode enabled - All limits bypassed';

  @override
  String get superadminDisabled => 'Superadmin mode disabled';
}
