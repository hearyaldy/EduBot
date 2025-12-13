import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/child_profile.dart';
import '../utils/app_theme.dart';
import '../screens/premium_screen.dart';
import '../services/firebase_service.dart';

class ManageProfilesScreen extends StatelessWidget {
  const ManageProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Profiles'),
        elevation: 0,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final profiles = provider.childProfiles;
          final canAdd = provider.canAddProfile;
          final maxProfiles = provider.maxProfiles;
          final isPremium = provider.isPremium;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.info,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have ${profiles.length} of $maxProfiles profile${maxProfiles > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Profiles List
                if (profiles.isEmpty)
                  _buildEmptyState(context)
                else
                  ...profiles.map((profile) => _buildProfileCard(
                        context,
                        provider,
                        profile,
                      )),

                const SizedBox(height: 16),

                // Add Profile Button
                if (canAdd)
                  _buildAddButton(context, provider)
                else
                  _buildUpgradePrompt(
                      context, isPremium, profiles.length, maxProfiles),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No Profiles Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create a profile for each child to track their individual progress',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    AppProvider provider,
    ChildProfile profile,
  ) {
    final isActive = provider.activeProfile?.id == profile.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryBlue.withValues(alpha: 0.1)
            : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppTheme.primaryBlue : AppTheme.divider,
          width: isActive ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: !isActive
            ? () async {
                await provider.setActiveProfile(profile.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to ${profile.name}\'s profile'),
                      backgroundColor: AppTheme.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            : null,
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryBlue,
          child: Text(
            profile.emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                profile.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Sync status indicator
            FutureBuilder<bool>(
              future: FirebaseService.instance.isProfileSyncedToFirestore(profile.id),
              builder: (context, snapshot) {
                final isSynced = snapshot.data ?? false;
                final isLoading = snapshot.connectionState == ConnectionState.waiting;

                if (isLoading) {
                  return const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                return Tooltip(
                  message: isSynced ? 'Synced to cloud' : 'Local only',
                  child: Icon(
                    isSynced ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: isSynced ? AppTheme.success : AppTheme.textSecondary,
                  ),
                );
              },
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              profile.gradeDisplay,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.question_answer,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${profile.questionCount} questions',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.local_fire_department,
                    size: 14, color: AppTheme.warning),
                const SizedBox(width: 4),
                Text(
                  '${profile.currentStreak} day${profile.currentStreak == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showEditProfileDialog(context, provider, profile);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, provider, profile);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: AppTheme.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, AppProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddProfileDialog(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('Add Child Profile'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt(
      BuildContext context, bool isPremium, int currentCount, int maxProfiles) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warning.withValues(alpha: 0.1),
            AppTheme.primaryBlue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 48,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 16),
          const Text(
            'Profile Limit Reached',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'You\'ve reached the maximum of $maxProfiles profiles.'
                : 'Upgrade to Premium to add up to 3 child profiles!',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isPremium) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Upgrade to Premium'),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context, AppProvider provider) {
    final nameController = TextEditingController();
    int selectedGrade = 1;
    String selectedEmoji = ProfileEmojis.all.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Add Child Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Name field
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Child\'s Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Grade dropdown
              const Text(
                'Grade Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: selectedGrade,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                items: List.generate(13, (index) {
                  if (index == 0) {
                    return const DropdownMenuItem(
                      value: 0,
                      child: Text('Kindergarten'),
                    );
                  }
                  return DropdownMenuItem(
                    value: index,
                    child: Text('Grade $index'),
                  );
                }),
                onChanged: (value) {
                  setState(() => selectedGrade = value!);
                },
              ),
              const SizedBox(height: 16),

              // Emoji picker
              const Text(
                'Choose Avatar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ProfileEmojis.all.map((emoji) {
                    final isSelected = emoji == selectedEmoji;
                    return GestureDetector(
                      onTap: () => setState(() => selectedEmoji = emoji),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                              : AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.divider,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a name'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                          return;
                        }

                        try {
                          await provider.addChildProfile(
                            name: nameController.text.trim(),
                            grade: selectedGrade,
                            emoji: selectedEmoji,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Profile created successfully! 🎉'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Profile',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    AppProvider provider,
    ChildProfile profile,
  ) {
    final nameController = TextEditingController(text: profile.name);
    int selectedGrade = profile.grade;
    String selectedEmoji = profile.emoji;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Child\'s Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                const Text('Grade',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: selectedGrade,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: List.generate(13, (index) {
                    if (index == 0) {
                      return const DropdownMenuItem(
                          value: 0, child: Text('Kindergarten'));
                    }
                    return DropdownMenuItem(
                        value: index, child: Text('Grade $index'));
                  }),
                  onChanged: (value) => setState(() => selectedGrade = value!),
                ),
                const SizedBox(height: 16),
                const Text('Avatar Emoji',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.divider),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ProfileEmojis.all.map((emoji) {
                      final isSelected = emoji == selectedEmoji;
                      return GestureDetector(
                        onTap: () => setState(() => selectedEmoji = emoji),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 24))),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }

                final updated = profile.copyWith(
                  name: nameController.text.trim(),
                  grade: selectedGrade,
                  emoji: selectedEmoji,
                );

                await provider.updateChildProfile(updated);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AppProvider provider,
    ChildProfile profile,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Are you sure you want to delete ${profile.name}\'s profile? This action cannot be undone.',
          softWrap: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteChildProfile(profile.id);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile deleted'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
