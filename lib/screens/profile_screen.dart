import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/gradient_header.dart';
import '../widgets/glass_card.dart';
import '../providers/app_provider.dart';
import '../screens/registration_screen.dart';
import '../screens/badges_screen.dart';
import '../utils/app_theme.dart';
import '../services/firebase_service.dart';
import 'manage_profiles_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          // Get user details from Firebase Service
          final firebaseService = FirebaseService.instance;
          bool isAuthenticated = firebaseService.isAuthenticated;
          String? userEmail = firebaseService.currentUserEmail;
          String? userName = firebaseService.userName;

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
                gradientColors: const [
                  AppColors.primary,
                  AppColors.secondary,
                  Color(0xFF8B5CF6),
                ],
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
                        _buildChildProfilesSection(provider),
                        const SizedBox(height: 20),
                        _buildAccountActions(provider),
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
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7),
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
                      child: Builder(
                        builder: (context) => Text(
                          benefit,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.7),
                          ),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName ?? userEmail?.split('@').first ?? 'User',
                            style: AppTextStyles.headline3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _showEditNameDialog(context, userName),
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Edit name',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
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
            'View Achievements',
            'See your badges and streak progress',
            Icons.emoji_events_outlined,
            AppColors.success,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BadgesScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Child Profiles Help',
            'How to use child profiles effectively',
            Icons.help_outline,
            AppColors.info,
            () => _showChildProfilesHelpDialog(),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Create Test Explanations',
            'DEBUG: Generate sample AI answers for history',
            Icons.bug_report,
            Colors.orange,
            () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              await provider.createTestExplanations();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Test explanations created! Check your learning history.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Sync Child Profile Metrics',
            'DEBUG: Update child profile with correct question counts',
            Icons.sync,
            Colors.purple,
            () async {
              final provider = Provider.of<AppProvider>(context, listen: false);
              await provider.syncChildProfileMetrics();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Child profile metrics synced! Check manage profiles.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
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

  // Helper methods for account types
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

  void _showEditNameDialog(BuildContext context, String? currentName) {
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Edit Name'),
          ],
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(),
            hintText: 'Enter your full name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  // Update the user profile in Firebase
                  await FirebaseService.instance.updateUserProfile(
                    displayName: newName,
                  );

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name updated successfully'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating name: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid name'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildChildProfilesSection(AppProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Child Profiles',
                style: AppTextStyles.headline3,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Manage profiles for different children to track their individual progress',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (context) => Text(
                      'You have ${provider.childProfiles.length} of ${provider.maxProfiles} child profiles created',
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ManageProfilesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Manage Child Profiles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action handlers
  void _navigateToRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegistrationScreen(),
      ),
    );
  }

  void _showChildProfilesHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.info),
            SizedBox(width: 8),
            Text('About Child Profiles'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Child profiles help you track individual progress for each child using EduBot:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              Icons.person_add,
              'Create Multiple Profiles',
              'Add separate profiles for each child in your family',
            ),
            const SizedBox(height: 8),
            _buildHelpItem(
              Icons.track_changes,
              'Individual Tracking',
              'Each profile tracks questions, streaks, and achievements separately',
            ),
            const SizedBox(height: 8),
            _buildHelpItem(
              Icons.school,
              'Grade-Specific Help',
              'EduBot adapts explanations based on each child\'s grade level',
            ),
            const SizedBox(height: 8),
            _buildHelpItem(
              Icons.emoji_events,
              'Personalized Achievements',
              'Each child can earn badges and maintain streaks independently',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tip:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Switch between child profiles using the profile switcher at the top of the home screen. The active profile determines which child\'s progress and settings are used.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.info, size: 20),
        const SizedBox(width: 8),
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
                  fontSize: 13,
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

    if (confirm == true && mounted) {
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);

        // Sign out from Firebase
        await FirebaseService.signOut();
        await appProvider.setRegisteredStatus(false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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
