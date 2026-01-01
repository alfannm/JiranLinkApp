import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'onboarding_slides.dart';
import 'auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentSlide = 0;
  bool _showAuth = false;
  final PageController _pageController = PageController();

  void _handleNext() {
    if (_currentSlide < onboardingSlides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() {
        _showAuth = true;
      });
    }
  }

  void _handleSkip() {
    setState(() {
      _showAuth = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showAuth) {
      return const AuthScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentSlide = index;
                  });
                },
                itemCount: onboardingSlides.length,
                itemBuilder: (context, index) {
                  final slide = onboardingSlides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            gradient: slide.gradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: slide.gradient.colors.first.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            slide.icon,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Title
                        Text(
                          slide.title,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppTheme.foreground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          slide.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  final page = _pageController.hasClients
                      ? (_pageController.page ?? _currentSlide.toDouble())
                      : _currentSlide.toDouble();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(onboardingSlides.length, (index) {
                      final distance = (page - index).abs().clamp(0.0, 1.0);
                      final t = 1.0 - distance;
                      final eased = Curves.easeOutCubic.transform(t);
                      final width = 8 + (24 * eased);
                      final color = Color.lerp(
                        AppTheme.muted,
                        AppTheme.primary,
                        eased,
                      )!;

                      return Container(
                        width: width,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            
            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _handleSkip,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: AppTheme.mutedForeground),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.primaryForeground,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentSlide == onboardingSlides.length - 1
                              ? 'Get Started'
                              : 'Next',
                        ),
                        if (_currentSlide < onboardingSlides.length - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
