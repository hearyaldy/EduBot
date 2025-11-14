import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? child;
  final Widget? action;
  final Widget? leading;
  final List<Color> gradientColors;
  final double height;

  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.child,
    this.action,
    this.leading,
    this.gradientColors = const [
      AppColors.gradientStart,
      AppColors.gradientMiddle,
      AppColors.gradientEnd,
    ],
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: child != null ? 120 : height,
        maxHeight: child != null ? double.infinity : height,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Pattern overlay effect
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Leading widget (back button, etc.)
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 8),
                      ],
                      // EduBot Custom Logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'lib/assets/icons/appicon.png',
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to icon if image fails to load
                            return const Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                              size: 28,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.headline1
                                  .copyWith(fontSize: 20),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(width: 12),
                        action!,
                      ],
                    ],
                  ),
                  if (child != null) ...[
                    const SizedBox(height: 15),
                    Flexible(child: child!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
