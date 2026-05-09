import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/screen_background_assets.dart';
import '../../app/theme.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../auth/screens/login_screen.dart';

/// First-launch carousel before sign-in. Persists completion in SharedPreferences.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const routePath = '/onboarding';
  static const routeName = 'onboarding';

  static const prefsKey = 'onboarding_completed_v1';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingSlide {
  const _OnboardingSlide({required this.title, required this.body});

  final String title;
  final String body;
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      title: 'Rights.',
      body:
          'Protect and manage your creative works with confidence. '
          'REPRONIG helps authors and publishers safeguard their reprographic rights.',
    ),

    _OnboardingSlide(
      title: 'Royalties.',
      body:
          'Earn royalties from the use of your works through REPRONIG via'
          'our accredited partner associations and licensing channels.',
    ),

    _OnboardingSlide(
      title: 'Recognition.',
      body:
          'Become a verified REPRONIG member and register your works '
          'with us for proper documentation, protection, and distribution.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeAndGoLogin() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(OnboardingScreen.prefsKey, true);
    if (!mounted) return;
    context.go(LoginScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _page == _slides.length - 1;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: AppMotion.slow,
              switchInCurve: AppMotion.emphasized,
              switchOutCurve: AppMotion.emphasized,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: Image.asset(
                ScreenBackgroundAssets.onboarding[_page],
                key: ValueKey<int>(_page),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _completeAndGoLogin,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) => const SizedBox.expand(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: AppMotion.regular,
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: Column(
                          key: ValueKey<int>(_page),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _slides[_page].title,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                                letterSpacing: -0.8,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _slides[_page].body,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _slides.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: i == _page ? 22 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: i == _page
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: () async {
                          if (last) {
                            await _completeAndGoLogin();
                          } else {
                            await _controller.nextPage(
                              duration: AppMotion.regular,
                              curve: AppMotion.emphasized,
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        child: Text(
                          last ? 'Get started' : 'Next',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
