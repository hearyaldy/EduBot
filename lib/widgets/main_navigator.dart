import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_provider.dart';
import '../screens/modern_home_screen.dart';
import '../screens/scan_homework_screen.dart';
import '../screens/ask_question_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/premium_screen.dart';
import '../screens/subject_management_screen.dart';
import '../ui/question_bank_manager.dart';
import '../ui/analytics_dashboard.dart';
import '../ui/adaptive_learning_interface.dart';
import '../ui/question_discovery_hub.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_header.dart';
import '../l10n/app_localizations.dart';
import '../services/admin_service.dart';
import '../services/admin_auth_service.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  late final List<Widget> _screens = [
    ModernHomeScreen(onNavigate: _onTabChanged),
    const ScanHomeworkScreen(),
    const AskQuestionScreen(),
  ];

  // Check if user is admin
  bool get _isAdmin => AdminService.instance.isAdmin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Force rebuild when provider changes (including admin status)
        return Scaffold(
          body: _screens[_currentIndex],
          floatingActionButton: _buildFloatingActionMenu(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              backgroundColor: Colors.white.withValues(alpha: 0.95),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.gray400,
                selectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home_outlined),
                    activeIcon: const Icon(Icons.home),
                    label: l10n.home,
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                          color: Colors.white, size: 28),
                    ),
                    activeIcon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 28),
                    ),
                    label: l10n.scanHomework,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.help_outline),
                    activeIcon: const Icon(Icons.help),
                    label: l10n.askQuestion,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionMenu() {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8.0,
      spacing: 4,
      childPadding: const EdgeInsets.all(4),
      spaceBetweenChildren: 4,
      visible: true,
      curve: Curves.bounceIn,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      onOpen: () {},
      onClose: () {},
      tooltip: 'Menu',
      heroTag: 'speed-dial-hero-tag',
      children: [
        SpeedDialChild(
          child: const Icon(Icons.history),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          label: 'History',
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          labelBackgroundColor: Colors.white,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryScreen()),
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.settings),
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          label: 'Settings',
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          labelBackgroundColor: Colors.white,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.explore),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          label: 'Discover',
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          labelBackgroundColor: Colors.white,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const QuestionDiscoveryHub()),
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.psychology),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          label: 'AI Learning',
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          labelBackgroundColor: Colors.white,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AdaptiveLearningInterface()),
          ),
        ),
        if (_isAdmin) ...[
          SpeedDialChild(
            child: const Icon(Icons.quiz),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            label: 'Question Bank',
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            labelBackgroundColor: Colors.white,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const QuestionBankManager()),
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.analytics),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            label: 'Analytics',
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            labelBackgroundColor: Colors.white,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AnalyticsDashboard()),
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.subject),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            label: 'Subject Management',
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            labelBackgroundColor: Colors.white,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SubjectManagementScreen()),
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.dashboard),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Admin',
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            labelBackgroundColor: Colors.white,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen()),
            ),
          ),
        ],
        SpeedDialChild(
          child: const Icon(Icons.star),
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          label: 'Premium Upgrade',
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          labelBackgroundColor: Colors.white,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PremiumScreen()),
          ),
        ),
      ],
    );
  }
}

// Placeholder for Progress Screen
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const GradientHeader(
            title: 'Learning Progress',
            subtitle: 'Track your homework journey',
            gradientColors: [
              AppColors.primary,
              AppColors.secondary,
              Color(0xFF8B5CF6),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: AppColors.analyticsGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.analytics,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Progress Analytics',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Track your learning journey and see how you\'re improving over time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Coming Soon!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Learning Progress',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            gradient: AppColors.analyticsGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.analytics,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Progress Analytics',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Track your learning journey and see how you\'re improving over time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.gray600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Coming Soon!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
