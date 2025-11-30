import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../widgets/gradient_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/modern_button.dart';
import '../widgets/daily_tip_card.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/profile_avatar_button.dart';
import '../widgets/streak_counter_widget.dart';
import '../providers/app_provider.dart';
import '../models/homework_question.dart';
import '../services/firebase_service.dart';
import '../screens/badges_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/explanation_detail_screen.dart';
import '../screens/history_screen.dart';
import '../screens/manage_profiles_screen.dart';
import '../screens/exercises_screen.dart';

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
  final _firebaseService = FirebaseService.instance;

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Gradient Header
            GradientHeader(
              title: 'EduBot',
              subtitle: 'AI Homework Helper',
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Login/Logout Icon
                  Builder(
                    builder: (context) {
                      final isAuthenticated =
                          FirebaseService.instance.isAuthenticated;
                      return IconButton(
                        onPressed: () {
                          if (isAuthenticated) {
                            _showLogoutDialog(context);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegistrationScreen(),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          isAuthenticated ? Icons.logout : Icons.login,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: isAuthenticated ? 'Logout' : 'Login',
                        splashRadius: 24,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Profile Avatar Button
                  const ProfileAvatarButton(),
                ],
              ),
              child: GlassCard(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final userInfo = _getUserInfo();
                          final greeting = _getTimeBasedGreeting();
                          final displayName = _getDisplayName(userInfo);
                          final isAuthenticated =
                              userInfo['isAuthenticated'] as bool;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting, $displayName! 👋',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                isAuthenticated
                                    ? 'Let\'s learn something awesome today! 🚀'
                                    : 'Ready for some learning fun? 🎯',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
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
                      // Primary Scan Button - Kid Friendly
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF667EEA),
                              Color(0xFF764BA2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _navigateToScan(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '📸 Scan Homework',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Take a photo and get help!',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Secondary Actions - Kid Friendly
                      Row(
                        children: [
                          Expanded(
                            child: _buildKidFriendlyActionCard(
                              emoji: '💬',
                              title: 'Ask Question',
                              subtitle: 'Type or speak!',
                              gradientColors: const [
                                Color(0xFFFF6B6B),
                                Color(0xFFFF8E53),
                              ],
                              onTap: () => _navigateToAsk(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKidFriendlyActionCard(
                              emoji: '✏️',
                              title: 'Practice',
                              subtitle: 'Fun exercises!',
                              gradientColors: const [
                                Color(0xFF4CAF50),
                                Color(0xFF45B649),
                              ],
                              onTap: () => _navigateToExercises(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Third Row Actions
                      Row(
                        children: [
                          Expanded(
                            child: _buildKidFriendlyActionCard(
                              emoji: '📚',
                              title: 'My History',
                              subtitle: 'Review anytime',
                              gradientColors: const [
                                Color(0xFFFF9800),
                                Color(0xFFFF5722),
                              ],
                              onTap: () => _navigateToSaved(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Streak Counter (compact view)
                      const StreakCounterWidget(isCompact: true),

                      const SizedBox(height: 20),

                      // Manage Profiles Card
                      _buildManageProfilesCard(),

                      const SizedBox(height: 25),

                      // Interactive Daily Tips Card
                      const DailyTipCard(),

                      const SizedBox(height: 25),

                      // Ad Banner (only for non-premium users)
                      const AdBannerWidget(),

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

  Widget _buildManageProfilesCard() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final profileCount = provider.childProfiles.length;
        final maxProfiles = provider.maxProfiles;

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                // Navigate to ManageProfilesScreen using direct navigation
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ManageProfilesScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '👨‍👩‍👧‍👦',
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Profiles',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$profileCount of $maxProfiles profile${maxProfiles > 1 ? 's' : ''} 🎯',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  // Kid-friendly action card with emojis
  Widget _buildKidFriendlyActionCard({
    required String emoji,
    required String title,
    required String subtitle,
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji in a circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      '📝 Recent Help',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _navigateToBadges(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events,
                                size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            const Text(
                              'Badges',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (recentQuestions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No activities yet! 🎯',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start learning by scanning homework\nor asking a question above!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
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
                    onTap: () => _navigateToQuestionDetail(context, question),
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
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                shape: BoxShape.circle,
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
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
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

  void _navigateToExercises(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExercisesScreen(),
      ),
    );
  }

  void _navigateToSaved(BuildContext context) {
    // Navigate directly to History screen instead of using tab navigation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    );
  }

  void _navigateToBadges(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BadgesScreen(),
      ),
    );
  }

  void _navigateToQuestionDetail(
      BuildContext context, HomeworkQuestion question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExplanationDetailScreen(question: question),
      ),
    );
  }

  // Helper method to get time-based greeting
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  // Helper method to get user name and authentication status
  Map<String, dynamic> _getUserInfo() {
    bool isAuthenticated = false;
    String? userName;
    String? userEmail;

    try {
      isAuthenticated = _firebaseService.isAuthenticated;
      userName = _firebaseService.userName;
      userEmail = _firebaseService.currentUserEmail;
    } catch (e) {
      isAuthenticated = false;
      userName = null;
      userEmail = null;
    }

    return {
      'isAuthenticated': isAuthenticated,
      'userName': userName,
      'userEmail': userEmail,
    };
  }

  // Helper method to get display name
  String _getDisplayName(Map<String, dynamic> userInfo) {
    if (!userInfo['isAuthenticated']) {
      return 'there';
    }

    final userName = userInfo['userName'] as String?;
    final userEmail = userInfo['userEmail'] as String?;

    if (userName != null && userName.isNotEmpty) {
      // If name is available, use first name only
      final nameParts = userName.split(' ');
      return nameParts.first;
    } else if (userEmail != null && userEmail.isNotEmpty) {
      // If no name but email available, use part before @
      final emailParts = userEmail.split('@');
      return emailParts.first;
    } else {
      return 'there';
    }
  }

  // Show logout confirmation dialog
  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await FirebaseService.signOut();
                // Simply refresh the current screen to update UI - just rebuild
                if (widget.onNavigate != null) {
                  widget.onNavigate!(0); // Navigate to first tab (home)
                } else {
                  // Use a global key or just let the UI update via the provider
                  // The UI should update automatically through the builder functions
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully logged out'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
