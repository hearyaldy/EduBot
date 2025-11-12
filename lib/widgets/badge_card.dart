import 'package:flutter/material.dart';
import '../models/badge.dart' as model;
import '../utils/app_theme.dart';

class BadgeCard extends StatelessWidget {
  final model.Badge badge;
  final int current;
  final int required;
  final bool showProgress;

  const BadgeCard({
    super.key,
    required this.badge,
    this.current = 0,
    this.required = 1,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked;
    final progress = required > 0 ? (current / required).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                colors: [
                  AppTheme.primaryBlue,
                  AppTheme.info,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUnlocked ? null : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.primaryBlue.withValues(alpha: 0.5)
              : AppTheme.divider,
          width: 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge emoji/icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppTheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        badge.emoji,
                        style: TextStyle(
                          fontSize: 32,
                          color: isUnlocked
                              ? null
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Badge title
                  Text(
                    badge.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Badge description
                  Text(
                    badge.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isUnlocked
                          ? Colors.white70
                          : AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Progress indicator for locked badges
                  if (!isUnlocked && showProgress) ...[
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                AppTheme.divider.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBlue,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$current / $required',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Unlocked date
                  if (isUnlocked && badge.unlockedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(badge.unlockedAt!),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Locked overlay
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline,
                      color: AppTheme.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ),

            // Unlocked checkmark
            if (isUnlocked)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: AppTheme.success,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
