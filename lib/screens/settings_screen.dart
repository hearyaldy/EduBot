import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/environment_config.dart';
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

  // Get superadmin password from environment config
  String get _superadminPassword =>
      EnvironmentConfig.instance.superadminPassword;

  final List<String> _languages = [
    'English',
    'Malay',
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
                  _buildSuperadminSection(),
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
            final l10n = AppLocalizations.of(context)!;
            String accountType = 'Free Account';
            String accountSubtitle =
                '${provider.dailyQuestionsUsed}/10 questions used today';
            IconData accountIcon = Icons.star_border;
            Color accountColor = AppTheme.textSecondary;

            if (provider.isSuperadmin) {
              accountType = l10n.superadminAccount;
              accountSubtitle = l10n.superadminSubtitle;
              accountIcon = Icons.admin_panel_settings;
              accountColor = AppTheme.warning;
            } else if (provider.isPremium) {
              accountType = 'Premium Account';
              accountSubtitle = 'Unlimited questions and advanced features';
              accountIcon = Icons.diamond;
              accountColor = AppTheme.warning;
            }

            return ListTile(
              leading: Icon(
                accountIcon,
                color: accountColor,
              ),
              title: Text(accountType),
              subtitle: Text(accountSubtitle),
              trailing: (!provider.isSuperadmin && !provider.isPremium)
                  ? TextButton(
                      onPressed: _showUpgradeDialog,
                      child: const Text('Upgrade'),
                    )
                  : null,
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
        Consumer<AppProvider>(
          builder: (context, provider, child) {
            return ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)!.language),
              subtitle: Text(provider.selectedLanguage),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(provider),
            );
          },
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
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isWarning ? AppTheme.error : null,
                        ),
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

  Widget _buildSuperadminSection() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return _buildSection(
          title: l10n.developerSettings,
          icon: Icons.admin_panel_settings,
          children: [
            SwitchListTile(
              title: Text(l10n.superadminMode),
              subtitle: Text(l10n.superadminDescription),
              value: provider.isSuperadmin,
              onChanged: (value) {
                if (value) {
                  _showPasswordDialog(provider);
                } else {
                  provider.setSuperadmin(false);
                  _showSnackBar(l10n.superadminDisabled);
                }
              },
              secondary: Icon(
                provider.isSuperadmin
                    ? Icons.security
                    : Icons.security_outlined,
                color: provider.isSuperadmin
                    ? AppTheme.warning
                    : AppTheme.textSecondary,
              ),
            ),
            if (provider.isSuperadmin)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppTheme.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.superadminActive,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showPasswordDialog(AppProvider provider) {
    final TextEditingController passwordController = TextEditingController();
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Admin Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                        'Enter the administrator password to enable superadmin mode:'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
                onSubmitted: (value) {
                  if (value == _superadminPassword) {
                    Navigator.pop(context);
                    _showSuperadminConfirmationDialog(provider);
                  } else {
                    _showSnackBar('Incorrect password');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text == _superadminPassword) {
                  Navigator.pop(context);
                  _showSuperadminConfirmationDialog(provider);
                } else {
                  _showSnackBar('Incorrect password');
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuperadminConfirmationDialog(AppProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.enableSuperadminMode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.superadminWarning),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.setSuperadmin(true);
              Navigator.pop(context);
              _showSnackBar(l10n.superadminEnabled);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
            child: const Text('Enable'),
          ),
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

  void _showLanguageDialog(AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: provider.selectedLanguage,
              onChanged: (value) {
                provider.setSelectedLanguage(value!);
                Navigator.pop(context);
                if (language == 'Malay') {
                  _showSnackBar(
                      AppLocalizations.of(context)!.malayLanguageEnabled);
                } else if (language != 'English') {
                  _showSnackBar(AppLocalizations.of(context)!
                      .languageComingSoon(language));
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
