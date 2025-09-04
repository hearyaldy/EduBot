import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';
import '../screens/registration_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/app_theme.dart';
import '../core/theme/app_colors.dart';

class ProfileAvatarButton extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const ProfileAvatarButton({
    super.key,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Safe check for Supabase initialization
        bool isAuthenticated = false;
        String? userEmail;
        String? userName;
        
        try {
          final supabaseService = SupabaseService.instance;
          isAuthenticated = supabaseService.isAuthenticated;
          userEmail = supabaseService.currentUserEmail;
          userName = supabaseService.userName;
        } catch (e) {
          // Supabase not initialized yet, treat as guest user
          isAuthenticated = false;
          userEmail = null;
          userName = null;
        }

        return PopupMenuButton<String>(
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) async {
            switch (value) {
              case 'register':
                _navigateToRegistration(context);
                break;
              case 'profile':
                _navigateToProfile(context);
                break;
              case 'signout':
                await _handleSignOut(context, provider);
                break;
              case 'settings':
                _navigateToSettings(context);
                break;
            }
          },
          itemBuilder: (context) => _buildMenuItems(isAuthenticated, provider),
          child: _buildAvatarButton(isAuthenticated, provider, userName, userEmail),
        );
      },
    );
  }

  Widget _buildAvatarButton(bool isAuthenticated, AppProvider provider, String? userName, String? userEmail) {
    if (!isAuthenticated) {
      // Guest user - show login prompt
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.person_outline,
          color: Colors.white,
          size: 22,
        ),
      );
    } else {
      // Authenticated user - show profile avatar
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getAccountTypeColor(provider),
              _getAccountTypeColor(provider).withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            _getInitials(userName ?? userEmail ?? 'U'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(bool isAuthenticated, AppProvider provider) {
    if (!isAuthenticated) {
      return [
        PopupMenuItem<String>(
          value: 'register',
          child: ListTile(
            leading: Icon(Icons.login, color: AppColors.primary),
            title: const Text('Sign In / Register'),
            subtitle: const Text('Get 60 questions per day!'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings, color: AppTheme.textSecondary),
            title: const Text('Settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ];
    } else {
      return [
        PopupMenuItem<String>(
          value: 'profile',
          child: ListTile(
            leading: Icon(_getAccountTypeIcon(provider), color: _getAccountTypeColor(provider)),
            title: Text(_getAccountTypeTitle(provider)),
            subtitle: Text(_getAccountSubtitle(provider)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings, color: AppTheme.textSecondary),
            title: const Text('Settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'signout',
          child: ListTile(
            leading: Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ];
    }
  }

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

  String _getAccountSubtitle(AppProvider provider) {
    if (provider.isSuperadmin) {
      return 'Unlimited access';
    } else if (provider.isPremium) {
      return 'Unlimited questions';
    } else if (provider.isRegistered) {
      final remaining = 60 - provider.dailyQuestionsUsed;
      return '$remaining questions remaining today';
    } else {
      final remaining = 30 - provider.dailyQuestionsUsed;
      return '$remaining questions remaining today';
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    if (name.contains('@')) {
      // Email address - use first character
      return name.substring(0, 1).toUpperCase();
    } else {
      // Name - use first letter of each word
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        return parts[0].substring(0, 1).toUpperCase();
      }
    }
  }

  void _navigateToRegistration(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegistrationScreen(),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    // Assuming settings is at index 4 in the bottom navigation
    if (onProfileTap != null) {
      onProfileTap!();
    }
  }


  Future<void> _handleSignOut(BuildContext context, AppProvider provider) async {
    try {
      final supabaseService = SupabaseService.instance;
      await supabaseService.signOut();
      await provider.setRegisteredStatus(false);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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