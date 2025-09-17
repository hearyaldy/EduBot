import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/gradient_header.dart';
import '../widgets/glass_card.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';
import '../screens/registration_screen.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabaseService = SupabaseService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          bool isAuthenticated = false;
          String? userEmail;
          String? userName;

          try {
            isAuthenticated = _supabaseService.isAuthenticated;
            userEmail = _supabaseService.currentUserEmail;
            userName = _supabaseService.userName;
          } catch (e) {
            isAuthenticated = false;
            userEmail = null;
            userName = null;
          }

          return Column(
            children: [
              // Profile Header
              GradientHeader(
                title: 'Profile',
                subtitle: isAuthenticated
                    ? 'Manage your account'
                    : 'Sign in to access your profile',
                height: 130,
                action: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Back',
                ),
              ),

              // Profile Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (!isAuthenticated) ...[
                        _buildSignInPrompt(),
                      ] else ...[
                        _buildUserProfile(provider, userName, userEmail),
                        const SizedBox(height: 20),
                        _buildAccountStats(provider),
                        const SizedBox(height: 20),
                        _buildAccountActions(provider),
                        const SizedBox(height: 20),
                        _buildDangerZone(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return GlassCard(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to EduBot!',
            style: AppTextStyles.headline2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Sign in or create an account to unlock more features and sync your data across devices.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gray600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildBenefitsList(),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _navigateToRegistration(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign In / Register',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      'Increase daily questions from 30 to 60',
      'Save and sync your question history',
      'Access from multiple devices',
      'Priority customer support',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.star,
                color: AppColors.success,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Registration Benefits',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildUserProfile(
      AppProvider provider, String? userName, String? userEmail) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar and basic info
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getAccountTypeColor(provider),
                      _getAccountTypeColor(provider).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(userName ?? userEmail ?? 'U'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName ?? userEmail?.split('@').first ?? 'User',
                      style: AppTextStyles.headline3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildAccountTypeBadge(provider),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeBadge(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getAccountTypeColor(provider),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAccountTypeIcon(provider),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _getAccountTypeTitle(provider),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStats(AppProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Statistics',
            style: AppTextStyles.headline3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Questions Used Today',
                  '${provider.dailyQuestionsUsed}',
                  Icons.help_outline,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Questions Remaining',
                  _getQuestionLimit(provider),
                  Icons.battery_charging_full,
                  AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Saved Questions',
                  '${provider.savedQuestions.length}',
                  Icons.bookmark,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Account Type',
                  _getAccountTypeTitle(provider),
                  _getAccountTypeIcon(provider),
                  _getAccountTypeColor(provider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(AppProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: AppTextStyles.headline3,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            'Edit Profile',
            'Update your name and preferences',
            Icons.edit_outlined,
            AppColors.primary,
            () => _showEditProfileDialog(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Reset Password',
            'Send password reset email',
            Icons.lock_reset,
            AppColors.warning,
            () => _handleResetPassword(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Export Data',
            'Download your question history',
            Icons.download,
            AppColors.info,
            () => _handleExportData(),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            'Sign Out',
            'Sign out of your account',
            Icons.logout,
            AppColors.error,
            () => _handleSignOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.gray600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for account types (same as ProfileAvatarButton)
  Color _getAccountTypeColor(AppProvider provider) {
    if (provider.isSuperadmin) {
      return AppColors.error;
    } else if (provider.isPremium) {
      return AppColors.warning;
    } else if (provider.isRegistered) {
      return AppColors.success;
    } else {
      return AppTheme.textSecondary;
    }
  }

  IconData _getAccountTypeIcon(AppProvider provider) {
    if (provider.isSuperadmin) {
      return Icons.admin_panel_settings;
    } else if (provider.isPremium) {
      return Icons.diamond;
    } else if (provider.isRegistered) {
      return Icons.person;
    } else {
      return Icons.person_outline;
    }
  }

  String _getAccountTypeTitle(AppProvider provider) {
    if (provider.isSuperadmin) {
      return 'Super Admin';
    } else if (provider.isPremium) {
      return 'Premium User';
    } else if (provider.isRegistered) {
      return 'Registered User';
    } else {
      return 'Guest User';
    }
  }

  String _getQuestionLimit(AppProvider provider) {
    if (provider.isSuperadmin || provider.isPremium) {
      return 'Unlimited';
    } else if (provider.isRegistered) {
      return '${60 - provider.dailyQuestionsUsed}';
    } else {
      return '${30 - provider.dailyQuestionsUsed}';
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    if (name.contains('@')) {
      return name.substring(0, 1).toUpperCase();
    } else {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        return parts[0].substring(0, 1).toUpperCase();
      }
    }
  }

  // Action handlers
  void _navigateToRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegistrationScreen(),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController();
    String? currentUserName;
    String? currentUserEmail;

    // Get current user information
    try {
      currentUserName = _supabaseService.userName;
      currentUserEmail = _supabaseService.currentUserEmail;
      nameController.text = currentUserName ?? '';
    } catch (e) {
      currentUserName = null;
      currentUserEmail = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Edit Profile'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Email (read-only)
              TextFormField(
                initialValue: currentUserEmail ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Your email address',
                  prefixIcon: const Icon(Icons.email, color: AppColors.gray600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.gray100,
                ),
              ),
              const SizedBox(height: 16),

              // Name (editable)
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'Enter your display name',
                  prefixIcon:
                      const Icon(Icons.person, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 50,
              ),

              const SizedBox(height: 8),
              const Text(
                'Note: Email address cannot be changed for security reasons.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                _saveProfileChanges(context, nameController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfileChanges(BuildContext context, String newName) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (newName.isNotEmpty) {
        await _supabaseService.updateProfile(name: newName);

        if (mounted) {
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Trigger a rebuild to show the updated name
          setState(() {});
        }
      } else {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid name'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleResetPassword() async {
    try {
      final email = _supabaseService.currentUserEmail;
      if (email == null) {
        throw Exception('No email found for current user');
      }

      await _supabaseService.resetPassword(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent! Check your inbox.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reset email: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleExportData() async {
    // Show export options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.download, color: AppColors.info),
            SizedBox(width: 8),
            Text('Export Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose what data you want to export:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 20),
            _buildExportOption(
              'Saved Questions & Answers',
              'Export all your saved homework questions and AI responses',
              Icons.quiz,
              () => _exportSavedQuestions(context),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              'Account Information',
              'Export your profile and account settings',
              Icons.person_outline,
              () => _exportAccountInfo(context),
            ),
            const SizedBox(height: 12),
            _buildExportOption(
              'Usage Statistics',
              'Export your app usage data and question history',
              Icons.analytics_outlined,
              () => _exportUsageStats(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _exportAllData(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
            child: const Text('Export All'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.gray500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportSavedQuestions(BuildContext context) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final savedQuestions = provider.savedQuestions;

      if (savedQuestions.isEmpty) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('No saved questions to export'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Create JSON export of saved questions
      final exportData = {
        'export_type': 'saved_questions',
        'export_date': DateTime.now().toIso8601String(),
        'total_questions': savedQuestions.length,
        'questions': savedQuestions
            .map((q) => {
                  'id': q.id,
                  'question': q.question,
                  'image_path': q.imagePath,
                  'type': q.type.toString(),
                  'created_at': q.createdAt.toIso8601String(),
                  'subject': q.subject,
                })
            .toList(),
      };

      _showExportPreview(context, 'Saved Questions', exportData);
    } catch (e) {
      if (context.mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error exporting questions: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportAccountInfo(BuildContext context) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      String? userEmail;
      String? userName;

      try {
        userEmail = _supabaseService.currentUserEmail;
        userName = _supabaseService.userName;
      } catch (e) {
        userEmail = 'Guest User';
        userName = 'Guest User';
      }

      final provider = Provider.of<AppProvider>(context, listen: false);

      final exportData = {
        'export_type': 'account_info',
        'export_date': DateTime.now().toIso8601String(),
        'account': {
          'email': userEmail,
          'name': userName,
          'account_type': provider.isSuperadmin
              ? 'superadmin'
              : provider.isPremium
                  ? 'premium'
                  : provider.isRegistered
                      ? 'registered'
                      : 'guest',
          'is_registered': provider.isRegistered,
          'is_premium': provider.isPremium,
          'is_superadmin': provider.isSuperadmin,
        },
        'preferences': {
          'selected_language': provider.selectedLanguage,
          'daily_questions_used': provider.dailyQuestionsUsed,
        }
      };

      _showExportPreview(context, 'Account Information', exportData);
    } catch (e) {
      if (context.mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error exporting account info: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportUsageStats(BuildContext context) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);

      final exportData = {
        'export_type': 'usage_statistics',
        'export_date': DateTime.now().toIso8601String(),
        'statistics': {
          'daily_questions_used': provider.dailyQuestionsUsed,
          'total_saved_questions': provider.savedQuestions.length,
          'account_created':
              'Available in full export', // Could be enhanced with actual data
          'last_active': DateTime.now().toIso8601String(),
          'question_types_breakdown': {
            'text_questions': provider.savedQuestions
                .where((q) => q.type.toString().contains('text'))
                .length,
            'image_questions': provider.savedQuestions
                .where((q) => q.type.toString().contains('image'))
                .length,
          }
        }
      };

      _showExportPreview(context, 'Usage Statistics', exportData);
    } catch (e) {
      if (context.mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error exporting usage stats: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportAllData(BuildContext context) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      String? userEmail;
      String? userName;

      try {
        userEmail = _supabaseService.currentUserEmail;
        userName = _supabaseService.userName;
      } catch (e) {
        userEmail = 'Guest User';
        userName = 'Guest User';
      }

      final exportData = {
        'export_type': 'complete_data_export',
        'export_date': DateTime.now().toIso8601String(),
        'account': {
          'email': userEmail,
          'name': userName,
          'account_type': provider.isSuperadmin
              ? 'superadmin'
              : provider.isPremium
                  ? 'premium'
                  : provider.isRegistered
                      ? 'registered'
                      : 'guest',
          'is_registered': provider.isRegistered,
          'is_premium': provider.isPremium,
          'is_superadmin': provider.isSuperadmin,
        },
        'preferences': {
          'selected_language': provider.selectedLanguage,
          'daily_questions_used': provider.dailyQuestionsUsed,
        },
        'saved_questions': provider.savedQuestions
            .map((q) => {
                  'id': q.id,
                  'question': q.question,
                  'image_path': q.imagePath,
                  'type': q.type.toString(),
                  'created_at': q.createdAt.toIso8601String(),
                  'subject': q.subject,
                })
            .toList(),
        'statistics': {
          'total_questions_asked': provider.dailyQuestionsUsed,
          'total_saved_questions': provider.savedQuestions.length,
          'export_timestamp': DateTime.now().toIso8601String(),
        }
      };

      _showExportPreview(context, 'Complete Data Export', exportData);
    } catch (e) {
      if (context.mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error exporting data: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showExportPreview(
      BuildContext context, String title, Map<String, dynamic> data) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title Export'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your data is ready for export. You can copy this JSON data:',
                style: TextStyle(color: AppColors.gray700),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gray300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonString,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.gray800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close both dialogs
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard functionality
              _copyToClipboard(context, jsonString);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) async {
    try {
      // For now, show a message about manual copy
      // In a real implementation, you'd use Clipboard.setData()
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please manually select and copy the text above'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error copying to clipboard: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleSignOut() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        await _supabaseService.signOut();
        await appProvider.setRegisteredStatus(false);

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Signed out successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
