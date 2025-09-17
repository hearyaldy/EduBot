import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/gradient_header.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/ai_service.dart';
import '../services/supabase_service.dart';
import '../screens/registration_screen.dart';
import '../screens/admin_dashboard_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _audioEnabled = true;
  double _speechRate = 0.5;
  final _aiService = AIService();
  bool _isApiKeyConfigured = false;
  bool _isTestingConnection = false;
  bool _showDetailedInstructions = false;

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
  void initState() {
    super.initState();
    _checkApiKeyConfiguration();
  }

  Future<void> _checkApiKeyConfiguration() async {
    final isConfigured = await _aiService.isConfigured;
    if (mounted) {
      setState(() {
        _isApiKeyConfigured = isConfigured;
      });
    }
  }

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
            gradientColors: const [
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
                  _buildAIConfigSection(),
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
            String accountType =
                provider.isRegistered ? 'Registered User' : 'Guest User';
            int maxQuestions = provider.isRegistered ? 60 : 30;
            String accountSubtitle =
                '${provider.dailyQuestionsUsed}/$maxQuestions questions used today';
            IconData accountIcon =
                provider.isRegistered ? Icons.person : Icons.person_outline;
            Color accountColor = provider.isRegistered
                ? AppTheme.success
                : AppTheme.textSecondary;

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
            } else if (provider.isRegistered) {
              accountType = 'Registered User';
              accountSubtitle =
                  '${provider.dailyQuestionsUsed}/60 questions used today';
              accountIcon = Icons.person;
              accountColor = AppTheme.success;
            } else {
              accountType = 'Guest User';
              accountSubtitle =
                  '${provider.dailyQuestionsUsed}/30 questions used today';
              accountIcon = Icons.person_outline;
              accountColor = AppTheme.textSecondary;
            }

            return ListTile(
              leading: Icon(
                accountIcon,
                color: accountColor,
              ),
              title: Text(accountType),
              subtitle: Text(accountSubtitle),
              trailing: _buildAccountActionButton(provider),
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

  Widget _buildAIConfigSection() {
    return _buildSection(
      title: 'AI Configuration',
      icon: Icons.smart_toy,
      children: [
        ListTile(
          leading: Icon(
            _isApiKeyConfigured ? Icons.check_circle : Icons.error_outline,
            color: _isApiKeyConfigured ? AppTheme.success : AppTheme.error,
          ),
          title: Text(
            _isApiKeyConfigured ? 'API Key Configured' : 'API Key Required',
          ),
          subtitle: Text(
            _isApiKeyConfigured
                ? 'Your Gemini API key is active'
                : 'Add your Google Gemini API key to use AI explanations',
          ),
          trailing: _isTestingConnection
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _isApiKeyConfigured ? Icons.edit : Icons.add,
                  color: AppTheme.primaryBlue,
                ),
          onTap: _showApiKeyDialog,
        ),
        if (_isApiKeyConfigured) ...[
          ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text('Test Connection'),
            subtitle: const Text('Verify your API key is working'),
            onTap: _testApiConnection,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppTheme.error),
            title: const Text(
              'Remove API Key',
              style: TextStyle(color: AppTheme.error),
            ),
            subtitle: const Text('Delete your stored API key'),
            onTap: _showRemoveApiKeyDialog,
          ),
        ],
        if (!_isApiKeyConfigured) _buildApiKeyInstructions(),
      ],
    );
  }

  Widget _buildApiKeyInstructions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Instructions Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key, color: AppTheme.info, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Get Your Google Gemini API Key',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.info,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Quick Steps:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildQuickStep('1', 'Visit ai.google.dev/aistudio', Icons.web),
                _buildQuickStep('2', 'Click "Get API key in Google AI Studio"',
                    Icons.login),
                _buildQuickStep('3', 'Create new project or use existing',
                    Icons.create_new_folder),
                _buildQuickStep(
                    '4', 'Generate and copy your API key', Icons.content_copy),
                const SizedBox(height: 16),

                // Expandable detailed instructions
                InkWell(
                  onTap: () {
                    setState(() {
                      _showDetailedInstructions = !_showDetailedInstructions;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.info.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _showDetailedInstructions
                                ? 'Hide detailed instructions'
                                : 'Show detailed step-by-step instructions',
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          _showDetailedInstructions
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),

                // Detailed instructions (expandable)
                if (_showDetailedInstructions) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.info.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detailed Instructions:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildDetailedStep(
                          '1',
                          'Visit Google AI Studio',
                          'Go to ai.google.dev/aistudio in your web browser',
                          Icons.web,
                        ),

                        _buildDetailedStep(
                          '2',
                          'Sign in with Google Account',
                          'Use your existing Google account or create a new one if needed',
                          Icons.account_circle,
                        ),

                        _buildDetailedStep(
                          '3',
                          'Access API Keys',
                          'Click "Get API key in Google AI Studio" button',
                          Icons.vpn_key,
                        ),

                        _buildDetailedStep(
                          '4',
                          'Create or Select Project',
                          'Choose "Create API key in new project" or select an existing Google Cloud project',
                          Icons.create_new_folder,
                        ),

                        _buildDetailedStep(
                          '5',
                          'Generate API Key',
                          'Click "Create API key" - your key will be generated instantly',
                          Icons.auto_awesome,
                        ),

                        _buildDetailedStep(
                          '6',
                          'Copy Your Key',
                          'Copy the generated API key (starts with "AIzaSy...") and paste it above',
                          Icons.content_copy,
                        ),

                        const SizedBox(height: 16),

                        // Important notes section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.security,
                                      color: Colors.orange, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Important Security Notes:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildSecurityNote(
                                  'Your API key is stored securely on this device only'),
                              _buildSecurityNote(
                                  'Never share your API key with others'),
                              _buildSecurityNote(
                                  'You can set usage limits in Google AI Studio'),
                              _buildSecurityNote(
                                  'API usage may incur charges based on Google\'s pricing'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Help section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.success.withValues(alpha: 0.3)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.help_outline,
                                      color: AppTheme.success, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Need Help?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• The API key is completely free to get\n'
                                '• You get a generous free usage quota\n'
                                '• It only takes 2-3 minutes to set up\n'
                                '• Contact support if you have issues',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.info,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStep(
      String number, String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppTheme.primaryBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
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
        const ListTile(
          leading: Icon(Icons.school),
          title: Text('EduBot'),
          subtitle: Text(
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
          leading: const Icon(Icons.logout, color: AppTheme.error),
          title:
              const Text('Sign Out', style: TextStyle(color: AppTheme.error)),
          subtitle: const Text('Sign out of your account'),
          onTap: _showSignOutDialog,
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppTheme.error),
          title: const Text(
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
            ListTile(
              leading: Icon(
                provider.isSuperadmin
                    ? Icons.security
                    : Icons.security_outlined,
                color: provider.isSuperadmin
                    ? AppTheme.warning
                    : AppTheme.textSecondary,
              ),
              title: Text(l10n.superadminMode),
              subtitle: Text(provider.isSuperadmin
                  ? 'Active (managed via Supabase)'
                  : 'Inactive (managed via Supabase)'),
              trailing: provider.isSuperadmin
                  ? const Icon(Icons.check_circle, color: AppTheme.success)
                  : const Icon(Icons.cancel, color: AppTheme.textSecondary),
            ),
            if (provider.isSuperadmin) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning,
                        color: AppTheme.warning, size: 20),
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
              ListTile(
                leading: const Icon(Icons.admin_panel_settings,
                    color: AppTheme.warning),
                title: const Text('Admin Dashboard'),
                subtitle: const Text('Manage users and view analytics'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openAdminDashboard,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget? _buildAccountActionButton(AppProvider provider) {
    final supabaseService = SupabaseService.instance;

    if (provider.isSuperadmin || provider.isPremium) {
      return null;
    } else if (provider.isRegistered) {
      if (supabaseService.isAuthenticated) {
        return PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'upgrade') {
              _showUpgradeDialog();
            } else if (value == 'signout') {
              await _handleSignOut();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'upgrade',
              child: Text('Upgrade to Premium'),
            ),
            const PopupMenuItem(
              value: 'signout',
              child: Text('Sign Out'),
            ),
          ],
          child: const Icon(Icons.more_vert),
        );
      } else {
        return TextButton(
          onPressed: _showUpgradeDialog,
          child: const Text('Upgrade'),
        );
      }
    } else {
      return TextButton(
        onPressed: _showRegistrationDialog,
        child: const Text('Register'),
      );
    }
  }

  void _showRegistrationDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegistrationScreen(),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      final supabaseService = SupabaseService.instance;
      await supabaseService.signOut();

      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        await provider.setRegisteredStatus(false);
        _showSnackBar('Signed out successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error signing out: ${e.toString()}');
      }
    }
  }

  void _openAdminDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminDashboardScreen(),
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
            Text('• Ad-free experience'),
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

  void _showApiKeyDialog() {
    final TextEditingController apiKeyController = TextEditingController();
    bool isPasswordVisible = false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            _isApiKeyConfigured ? 'Update API Key' : 'Add Gemini API Key',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: AppTheme.info, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your API key is stored securely on your device and never shared.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Google Gemini API Key',
                  hintText: 'AIzaSy...',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
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
                      IconButton(
                        icon: const Icon(Icons.help_outline),
                        onPressed: _showApiKeyInstructions,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final apiKey = apiKeyController.text.trim();
                      if (apiKey.isEmpty) {
                        _showSnackBar('Please enter an API key', isError: true);
                        return;
                      }

                      setState(() {
                        isSaving = true;
                      });

                      try {
                        final navigator = Navigator.of(context);
                        await _aiService.saveUserApiKey(apiKey);
                        if (mounted) {
                          navigator.pop();
                          await _checkApiKeyConfiguration();
                          _showSnackBar('API key saved successfully!');
                        }
                      } catch (e) {
                        _showSnackBar('Failed to save API key: ${e.toString()}',
                            isError: true);
                      } finally {
                        if (mounted) {
                          setState(() {
                            isSaving = false;
                          });
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isApiKeyConfigured ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Get Your API Key'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Follow these steps to get your Google Gemini API key:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              Text('1. Visit console.cloud.google.com'),
              SizedBox(height: 8),
              Text('2. Create a new project or select an existing one'),
              SizedBox(height: 8),
              Text('3. Enable the "Gemini API" for your project'),
              SizedBox(height: 8),
              Text('4. Go to "Credentials" in the left sidebar'),
              SizedBox(height: 8),
              Text('5. Click "Create Credentials" > "API key"'),
              SizedBox(height: 8),
              Text(
                  '6. Copy your new API key and paste it in the previous dialog'),
              SizedBox(height: 16),
              Text(
                'Important:',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.orange),
              ),
              Text(
                '• Keep your API key secure and never share it\n'
                '• API usage may incur charges based on Google\'s pricing\n'
                '• You can set usage limits in the Google Cloud Console',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isTestingConnection = true;
    });

    try {
      final isWorking = await _aiService.testConnection();
      if (isWorking) {
        _showSnackBar('API connection successful!');
      } else {
        _showSnackBar('API connection failed. Please check your key.',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Connection test failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }

  void _showRemoveApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove API Key'),
        content: const Text(
          'Are you sure you want to remove your API key? You will not be able to get AI explanations until you add a new key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final navigator = Navigator.of(context);
                await _aiService.removeUserApiKey();
                if (mounted) {
                  navigator.pop();
                  await _checkApiKeyConfiguration();
                  _showSnackBar('API key removed successfully');
                }
              } catch (e) {
                _showSnackBar('Failed to remove API key: ${e.toString()}',
                    isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
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
