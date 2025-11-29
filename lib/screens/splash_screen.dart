import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _logoController;
  late AnimationController _textController;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 SplashScreen: initState called');

    try {
      // Set system UI overlay style for splash
      debugPrint('🎨 SplashScreen: Setting system UI overlay style');
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      debugPrint('⚙️ SplashScreen: Initializing animation controllers');
      _controller = AnimationController(
        duration: const Duration(milliseconds: 3000),
        vsync: this,
      );
      debugPrint('✅ SplashScreen: Main controller initialized');

      _logoController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );
      debugPrint('✅ SplashScreen: Logo controller initialized');

      _textController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      debugPrint('✅ SplashScreen: Text controller initialized');

      debugPrint('▶️ SplashScreen: Starting animations');
      _startAnimation();
    } catch (e, stackTrace) {
      debugPrint('❌ SplashScreen ERROR in initState: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  void _startAnimation() async {
    try {
      debugPrint('🎬 SplashScreen: _startAnimation started');

      // Start logo animation
      debugPrint('📱 SplashScreen: Starting logo animation');
      await _logoController.forward();
      debugPrint('✅ SplashScreen: Logo animation forwarded');

      // Delay text animation
      debugPrint('⏱️ SplashScreen: Waiting 800ms for text animation');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        debugPrint('📝 SplashScreen: Starting text animation (mounted: true)');
        await _textController.forward();
        debugPrint('✅ SplashScreen: Text animation forwarded');
      } else {
        debugPrint('⚠️ SplashScreen: Skipping text animation (mounted: false)');
      }

      // Start background animation
      debugPrint('⏱️ SplashScreen: Waiting 400ms for background animation');
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        debugPrint(
            '🎨 SplashScreen: Starting background animation (mounted: true)');
        await _controller.forward();
        debugPrint('✅ SplashScreen: Background animation forwarded');
      } else {
        debugPrint(
            '⚠️ SplashScreen: Skipping background animation (mounted: false)');
      }

      debugPrint('🎉 SplashScreen: All animations complete');
      // Animations complete, navigation is handled by parent
    } catch (e, stackTrace) {
      debugPrint('❌ SplashScreen ERROR in _startAnimation: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 SplashScreen: dispose called');
    try {
      _controller.dispose();
      _logoController.dispose();
      _textController.dispose();
      debugPrint('✅ SplashScreen: All controllers disposed');
    } catch (e, stackTrace) {
      debugPrint('❌ SplashScreen ERROR in dispose: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ SplashScreen: build method called');
    try {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                AppColors.secondary,
              ],
              stops: [0.0, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Background particles
                _buildBackgroundAnimation(),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo with animations
                      _buildAnimatedLogo(),

                      const SizedBox(height: 32),

                      // App name
                      _buildAnimatedTitle(),

                      const SizedBox(height: 16),

                      // Tagline
                      _buildAnimatedTagline(),

                      const SizedBox(height: 80),

                      // Loading indicator
                      _buildLoadingIndicator(),
                    ],
                  ),
                ),

                // Floating elements
                _buildFloatingElements(),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ SplashScreen ERROR in build: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      // Return a simple error view
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading splash screen: $e'),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBackgroundAnimation() {
    try {
      return Positioned.fill(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: BubblePainter(_controller.value),
              child: Container(),
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ SplashScreen ERROR in _buildBackgroundAnimation: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return const SizedBox.shrink();
    }
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.3 + (_logoController.value * 0.7),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main app icon with shadow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 15),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(70),
                    child: Image.asset(
                      'lib/assets/icons/appicon.png',
                      width: 124,
                      height: 124,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if image fails to load
                        debugPrint('⚠️ SplashScreen: App icon failed to load');
                        debugPrint('❌ Image Error: $error');
                        if (stackTrace != null) {
                          debugPrint('📍 Image Stack trace: $stackTrace');
                        }
                        return Container(
                          width: 124,
                          height: 124,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Animated pulsing ring
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_controller.value * 0.4),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.6 - (_controller.value * 0.4),
                          ),
                          width: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Secondary pulsing ring
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_logoController.value * 0.2),
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary.withValues(
                            alpha: 0.4 - (_logoController.value * 0.3),
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Sparkle effects around the logo
              ..._buildSparkleEffects(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSparkleEffects() {
    return [
      // Top sparkle
      Positioned(
        top: 20,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.5 + (_controller.value * 0.8),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // Right sparkle
      Positioned(
        right: 15,
        top: 60,
        child: AnimatedBuilder(
          animation: _logoController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.3 + (_logoController.value * 0.9),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.5),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // Left sparkle
      Positioned(
        left: 25,
        bottom: 40,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.4 + (_controller.value * 0.7),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 2,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _textController.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _textController.value) * 30),
            child: const Text(
              'EduBot',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ).animate().shimmer(
                  duration: const Duration(milliseconds: 1500),
                  delay: const Duration(milliseconds: 800),
                  color: Colors.white.withValues(alpha: 0.5),
                ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTagline() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _textController.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _textController.value) * 20),
            child: Text(
              'AI Homework Helper for Parents',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w300,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 3,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
      ),
    ).animate(onPlay: (controller) => controller.repeat()).rotate(
          duration: const Duration(milliseconds: 1000),
        );
  }

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        // Floating icons with proper animations
        _buildFloatingIcon(Icons.lightbulb, 0.1, 0.2, 3000),
        _buildFloatingIcon(Icons.school, 0.8, 0.3, 3500),
        _buildFloatingIcon(Icons.quiz, 0.2, 0.7, 2800),
        _buildFloatingIcon(Icons.psychology, 0.9, 0.8, 3200),
        _buildFloatingIcon(Icons.calculate, 0.1, 0.5, 2500),
        _buildFloatingIcon(Icons.science, 0.85, 0.6, 3800),
      ],
    );
  }

  Widget _buildFloatingIcon(
      IconData icon, double left, double top, int duration) {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      return Positioned(
        left: screenWidth * left,
        top: screenHeight * top,
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.1),
          size: 24,
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .move(
                begin: const Offset(0, -20),
                end: const Offset(0, 20),
                duration: Duration(milliseconds: duration))
            .then()
            .fadeIn(duration: const Duration(milliseconds: 500))
            .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: Duration(milliseconds: duration)),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ SplashScreen ERROR in _buildFloatingIcon: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return const SizedBox.shrink();
    }
  }
}

// Custom painter for background bubbles
class BubblePainter extends CustomPainter {
  final double animationValue;

  BubblePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;

      // Create floating bubbles
      for (int i = 0; i < 8; i++) {
        final offset = Offset(
          (size.width * (i * 0.15 + 0.1)) +
              (30 * animationValue * (i.isEven ? 1 : -1)),
          (size.height * (i * 0.12 + 0.1)) +
              (50 * animationValue * (i.isOdd ? 1 : -1)),
        );

        final radius = 20 + (i * 5) + (10 * animationValue);

        canvas.drawCircle(offset, radius, paint);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ BubblePainter ERROR in paint: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
