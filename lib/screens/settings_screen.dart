import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/gradient_header.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _audioEnabled = true;
  double _speechRate = 0.5;
  String _selectedLanguage = 'English';

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          GradientHeader(
            title: l10n.settings,
            subtitle: l10n.settingsSubtitle,
            gradientColors: [
              AppColors.settingsGradient1,
              AppColors.settingsGradient2,
              AppColors.settingsGradient3,
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountSection(),
                  const SizedBox(height: 24),
                  _buildPreferencesSection(),
                  const SizedBox(height: 24),
                  _buildAudioSection(),
                  const SizedBox(height: 24),
                  _buildPrivacySection(),
                  const SizedBox(height: 24),
                  _buildAboutSection(),
                  const SizedBox(height: 24),
                  _buildDangerZone(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Account',
      icon: Icons.account_circle,
      children: [
        Consumer<AppProvider>(
          builder: (context, provider, child) {
            return ListTile(
              leading: Icon(
                provider.isPremium ? Icons.diamond : Icons.star_border,
                color: provider.isPremium
                    ? AppTheme.warning
                    : AppTheme.textSecondary,
              ),
              title: Text(
                provider.isPremium ? 'Premium Account' : 'Free Account',
              ),
              subtitle: Text(
                provider.isPremium
                    ? 'Unlimited questions and advanced features'
                    : '${provider.dailyQuestionsUsed}/10 questions used today',
              ),
              trailing: provider.isPremium
                  ? null
                  : TextButton(
                      onPressed: _showUpgradeDialog,
                      child: const Text('Upgrade'),
                    ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Question History'),
          subtitle: Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Text('${provider.savedQuestions.length} saved questions');
            },
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/history');
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSection(
      title: 'Preferences',
      icon: Icons.tune,
      children: [
        SwitchListTile(
          title: const Text('Daily Tips'),
          subtitle: const Text('Show helpful parenting tips on home screen'),
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(AppLocalizations.of(context)!.language),
          subtitle: Text(_selectedLanguage),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showLanguageDialog,
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Theme'),
          subtitle: const Text('Modern Blue (Current)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showSnackBar('Theme customization coming soon!');
          },
        ),
      ],
    );
  }

  Widget _buildAudioSection() {
    return _buildSection(
      title: 'Audio Settings',
      icon: Icons.volume_up,
      children: [
        SwitchListTile(
          title: const Text('Audio Explanations'),
          subtitle: const Text('Enable text-to-speech for answers'),
          value: _audioEnabled,
          onChanged: (value) {
            setState(() {
              _audioEnabled = value;
            });
          },
        ),
        if (_audioEnabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speech Rate',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Slow'),
                    Expanded(
                      child: Slider(
                        value: _speechRate,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: '${(_speechRate * 100).round()}%',
                        onChanged: (value) {
                          setState(() {
                            _speechRate = value;
                          });
                        },
                      ),
                    ),
                    const Text('Fast'),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Test Audio'),
            subtitle: const Text('Preview how explanations will sound'),
            onTap: _testAudio,
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSection(
      title: 'Privacy & Data',
      icon: Icons.security,
      children: [
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('Privacy Policy'),
          subtitle: const Text('How we protect your data'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl('https://edubot.app/privacy'),
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Terms of Service'),
          subtitle: const Text('Terms and conditions'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl('https://edubot.app/terms'),
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Clear Question History'),
          subtitle: const Text('Remove all saved questions'),
          onTap: _showClearHistoryDialog,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      icon: Icons.info_outline,
      children: [
        ListTile(
          leading: const Icon(Icons.school),
          title: const Text('EduBot'),
          subtitle: const Text(
            'Version 1.0.0 - AI Homework Helper for Parents',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help Center'),
          subtitle: const Text('Frequently asked questions'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl('https://edubot.app/help'),
        ),
        ListTile(
          leading: const Icon(Icons.feedback),
          title: const Text('Send Feedback'),
          subtitle: const Text('Help us improve EduBot'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl('mailto:feedback@edubot.app'),
        ),
        ListTile(
          leading: const Icon(Icons.star),
          title: const Text('Rate EduBot'),
          subtitle: const Text('Share your experience with other parents'),
          trailing: const Icon(Icons.open_in_new),
          onTap: _rateApp,
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return _buildSection(
      title: 'Account Management',
      icon: Icons.warning,
      isWarning: true,
      children: [
        ListTile(
          leading: Icon(Icons.logout, color: AppTheme.error),
          title: Text('Sign Out', style: TextStyle(color: AppTheme.error)),
          subtitle: const Text('Sign out of your account'),
          onTap: _showSignOutDialog,
        ),
        ListTile(
          leading: Icon(Icons.delete_forever, color: AppTheme.error),
          title: Text(
            'Delete Account',
            style: TextStyle(color: AppTheme.error),
          ),
          subtitle: const Text('Permanently delete your account and data'),
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isWarning = false,
  }) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isWarning ? AppTheme.error : AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isWarning ? AppTheme.error : null,
                      ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get unlimited access to EduBot with Premium:'),
            SizedBox(height: 12),
            Text('• Unlimited daily questions'),
            Text('• Priority support'),
            Text('• Advanced explanations'),
            Text('• Offline mode (coming soon)'),
            Text('• Custom study plans (coming soon)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Premium upgrade coming soon!');
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.pop(context);
                if (language != 'English') {
                  _showSnackBar('Multi-language support coming soon!');
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Question History'),
        content: const Text(
          'This will permanently delete all your saved questions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear history logic here
              Navigator.pop(context);
              _showSnackBar('Question history cleared');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Clear History'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Signed out successfully');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.\n\nAre you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Account deletion process started');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _testAudio() {
    _showSnackBar('Playing test audio...');
    // Audio test logic would go here
  }

  Future<void> _launchUrl(String url) async {
    try {
      _showSnackBar('Opening external link...');
      // URL launching would be implemented here with url_launcher package
      // For now, just show a message
    } catch (e) {
      _showSnackBar('Error opening link: ${e.toString()}', isError: true);
    }
  }

  void _rateApp() {
    // Platform-specific app store rating logic would go here
    _showSnackBar('Thank you for your feedback!');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
