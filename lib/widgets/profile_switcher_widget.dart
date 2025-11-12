import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/child_profile.dart';
import '../utils/app_theme.dart';
import '../screens/manage_profiles_screen.dart';

class ProfileSwitcherWidget extends StatelessWidget {
  final bool isCompact;

  const ProfileSwitcherWidget({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final profiles = provider.childProfiles;
        final activeProfile = provider.activeProfile;

        if (profiles.isEmpty) {
          return _buildEmptyState(context, provider);
        }

        if (isCompact) {
          return _buildCompactView(context, provider, profiles, activeProfile);
        }

        return _buildFullView(context, provider, profiles, activeProfile);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManageProfilesScreen(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Child Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Track progress for each child',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactView(
    BuildContext context,
    AppProvider provider,
    List<ChildProfile> profiles,
    ChildProfile? activeProfile,
  ) {
    return GestureDetector(
      onTap: () {
        if (profiles.length > 1) {
          _showProfilePicker(context, provider, profiles, activeProfile);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManageProfilesScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.success.withValues(alpha: 0.1),
              AppTheme.primaryBlue.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Profile Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  activeProfile?.emoji ?? '👤',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Profile Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeProfile?.name ?? 'No Profile',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeProfile?.gradeDisplay ?? 'Create a profile',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Indicator
            if (profiles.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${profiles.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_drop_down,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView(
    BuildContext context,
    AppProvider provider,
    List<ChildProfile> profiles,
    ChildProfile? activeProfile,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageProfilesScreen(),
                  ),
                ),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...profiles.map((profile) => _buildProfileTile(
                context,
                provider,
                profile,
                profile.id == activeProfile?.id,
              )),
        ],
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context,
    AppProvider provider,
    ChildProfile profile,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () async {
        if (!isActive) {
          await provider.setActiveProfile(profile.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryBlue
                : AppTheme.divider,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              profile.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${profile.gradeDisplay} • ${profile.questionCount} questions',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showProfilePicker(
    BuildContext context,
    AppProvider provider,
    List<ChildProfile> profiles,
    ChildProfile? activeProfile,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Switch Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...profiles.map((profile) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      profile.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(profile.name),
                  subtitle: Text(profile.gradeDisplay),
                  trailing: profile.id == activeProfile?.id
                      ? const Icon(Icons.check_circle, color: AppTheme.success)
                      : null,
                  onTap: () async {
                    await provider.setActiveProfile(profile.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                )),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryBlue,
                child: Icon(Icons.settings, color: Colors.white),
              ),
              title: const Text('Manage Profiles'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageProfilesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
