import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/gradient_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/modern_button.dart';
import '../widgets/daily_tip_card.dart';
import '../providers/app_provider.dart';
import '../models/homework_question.dart';

class ModernHomeScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ModernHomeScreen({super.key, this.onNavigate});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Gradient Header
            GradientHeader(
              title: 'EduBot',
              subtitle: 'AI Homework Helper',
              child: GlassCard(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good evening, Parent! 👋',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Ready to tackle homework together?',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Primary Scan Button
                      ModernButton(
                        text: 'Scan Homework Problem',
                        icon: Icons.camera_alt,
                        height: 70,
                        gradientColors: const [
                          AppColors.info,
                          AppColors.primary,
                        ],
                        onPressed: () => _navigateToScan(context),
                      ),

                      const SizedBox(height: 20),

                      // Secondary Actions
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedActionCard(
                              title: 'Ask Question',
                              subtitle: 'Type or speak',
                              icon: Icons.chat_bubble_outline,
                              gradientColors: const [
                                Color(0xFF667eea),
                                Color(0xFF764ba2),
                              ],
                              onTap: () => _navigateToAsk(context),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildEnhancedActionCard(
                              title: 'Saved Problems',
                              subtitle: 'Review anytime',
                              icon: Icons.bookmark_outline,
                              gradientColors: const [
                                Color(0xFFf093fb),
                                Color(0xFFf5576c),
                              ],
                              onTap: () => _navigateToSaved(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Interactive Daily Tips Card
                      const DailyTipCard(),

                      const SizedBox(height: 25),

                      // Recent Activity
                      _buildRecentActivity(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildRecentActivity() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final recentQuestions = provider.savedQuestions.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Help', style: AppTextStyles.headline3),
            const SizedBox(height: 15),
            if (recentQuestions.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.history,
                        size: 48, color: AppColors.gray400),
                    const SizedBox(height: 12),
                    Text(
                      'No recent activities',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start by scanning or asking a question!',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...recentQuestions.map(
                (question) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildActivityItem(
                    title: question.question.length > 30
                        ? '${question.question.substring(0, 30)}...'
                        : question.question,
                    subtitle: _formatDateTime(question.createdAt),
                    status: 'Saved',
                    statusColor: AppColors.success,
                    icon: question.type == QuestionType.image
                        ? Icons.camera_alt
                        : Icons.chat_bubble_outline,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success,
                  AppColors.success.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Navigation methods
  void _navigateToScan(BuildContext context) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(1); // Index 1 for Scan tab
    } else {
      Navigator.pushNamed(context, '/scan');
    }
  }

  void _navigateToAsk(BuildContext context) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(2); // Index 2 for Ask tab
    } else {
      Navigator.pushNamed(context, '/ask');
    }
  }

  void _navigateToSaved(BuildContext context) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(3); // Index 3 for History tab
    } else {
      Navigator.pushNamed(context, '/history');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
