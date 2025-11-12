import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/badge_card.dart';
import '../widgets/streak_counter_widget.dart';
import '../utils/app_theme.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        elevation: 0,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final badges = provider.badges;
          final unlockedCount = provider.unlockedBadgeCount;
          final totalCount = provider.totalBadgeCount;
          final completionPercentage = provider.badgeCompletionPercentage;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak Display
                const StreakCounterWidget(isCompact: false),
                const SizedBox(height: 24),

                // Progress Overview
                _buildProgressOverview(
                  context,
                  unlockedCount,
                  totalCount,
                  completionPercentage,
                ),
                const SizedBox(height: 24),

                // Section Title
                Text(
                  'Your Badges',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep using EduBot to unlock more achievements!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Badges Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: badges.length,
                  itemBuilder: (context, index) {
                    final badge = badges[index];
                    final progress = provider.getBadgeProgress(badge.id);

                    return BadgeCard(
                      badge: badge,
                      current: progress.current,
                      required: progress.required,
                      showProgress: true,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Encouragement Message
                _buildEncouragementMessage(context, unlockedCount, totalCount),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressOverview(
    BuildContext context,
    int unlocked,
    int total,
    double percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.success.withValues(alpha: 0.1),
            AppTheme.info.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Badge Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$unlocked of $total unlocked',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppTheme.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncouragementMessage(
    BuildContext context,
    int unlocked,
    int total,
  ) {
    String message;
    IconData icon;
    Color color;

    if (unlocked == total) {
      message = "Amazing! You've unlocked all badges! You're a true EduBot champion! 🏆";
      icon = Icons.emoji_events;
      color = AppTheme.success;
    } else if (unlocked >= total * 0.75) {
      message = "Almost there! Just a few more badges to go! Keep up the great work! 💪";
      icon = Icons.trending_up;
      color = AppTheme.info;
    } else if (unlocked >= total * 0.5) {
      message = "You're doing great! You've unlocked more than half of all badges! 🌟";
      icon = Icons.star;
      color = AppTheme.warning;
    } else if (unlocked > 0) {
      message = "Great start! Keep using EduBot to unlock more badges! 🚀";
      icon = Icons.rocket_launch;
      color = AppTheme.primaryBlue;
    } else {
      message = "Start your journey! Ask your first question to unlock your first badge! 🎯";
      icon = Icons.flag;
      color = AppTheme.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
