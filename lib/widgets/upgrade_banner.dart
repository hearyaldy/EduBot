import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../screens/premium_screen.dart';

class UpgradeBanner extends StatelessWidget {
  const UpgradeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Don't show banner if user is premium
        if (provider.isPremium) {
          return const SizedBox.shrink();
        }

        final questionsUsed = provider.dailyQuestionsUsed;
        final maxQuestions = provider.maxQuestionsPerDay;
        final remainingQuestions = maxQuestions - questionsUsed;
        final percentage = maxQuestions > 0 ? (questionsUsed / maxQuestions) : 0.0;

        // Only show banner when approaching or at limit
        if (percentage < 0.6) {
          return const SizedBox.shrink();
        }

        String title;
        String message;
        Color bannerColor;
        IconData icon;

        if (remainingQuestions == 0) {
          title = 'Daily Limit Reached! 🚫';
          message = 'Upgrade to Premium for unlimited questions';
          bannerColor = AppTheme.error;
          icon = Icons.block;
        } else if (remainingQuestions == 1) {
          title = 'Last Question! ⚠️';
          message = 'You have only 1 question left today';
          bannerColor = AppTheme.warning;
          icon = Icons.warning_amber;
        } else {
          title = 'Running Low! ⏰';
          message = 'You have $remainingQuestions questions left today';
          bannerColor = AppTheme.warning;
          icon = Icons.access_time;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PremiumScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  bannerColor.withValues(alpha: 0.15),
                  bannerColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: bannerColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bannerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: bannerColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.warning,
                              AppTheme.warning.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Upgrade to Premium',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
      },
    );
  }
}
