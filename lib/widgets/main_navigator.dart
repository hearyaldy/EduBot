import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../screens/modern_home_screen.dart';
import '../screens/scan_homework_screen.dart';
import '../screens/ask_question_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart' hide SizedBox;
import '../widgets/glass_card.dart';
import '../widgets/gradient_header.dart';
import '../l10n/app_localizations.dart';

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
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                icon: const Icon(Icons.camera_alt_outlined),
                activeIcon: const Icon(Icons.camera_alt),
                label: l10n.scanHomework,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.help_outline),
                activeIcon: const Icon(Icons.help),
                label: l10n.askQuestion,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.bookmark_outline),
                activeIcon: const Icon(Icons.bookmark),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                activeIcon: const Icon(Icons.settings),
                label: l10n.settings,
              ),
            ],
          ),
        ),
      ),
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
          GradientHeader(
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
                      decoration: BoxDecoration(
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
              Text(
                'Learning Progress',
                style: const TextStyle(
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
                          decoration: BoxDecoration(
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
