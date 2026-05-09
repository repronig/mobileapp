import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/screen_background_assets.dart';
import '../../app/theme.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../auth/providers/auth_session_provider.dart';
import '../more/providers/more_providers.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/member_paths.dart';

/// Animated brand splash; validates session with `/me` when a token exists (Pass 1).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const routePath = '/splash';
  static const routeName = 'splash';

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _minDisplay = Duration(milliseconds: 2600);

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait<void>([
      ref.read(authSessionProvider.notifier).bootstrap(),
      Future<void>.delayed(_minDisplay),
    ]);
    if (!mounted) return;
    final auth = ref.read(authSessionProvider);
    if (auth.hasMemberAccess) {
      ref.invalidate(unreadNotificationsCountProvider);
      try {
        await ref.read(unreadNotificationsCountProvider.future);
      } catch (_) {
        // Avoid blocking app launch on unread-count fetch failures.
      }
      if (!mounted) return;
      context.go(
        MemberPaths.afterAuth(emailVerified: auth.user!.emailVerified),
      );
    } else {
      final prefs = ref.read(sharedPreferencesProvider);
      final onboardingDone = prefs.getBool(OnboardingScreen.prefsKey) ?? false;
      if (!mounted) return;
      if (!onboardingDone) {
        context.go(OnboardingScreen.routePath);
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              ScreenBackgroundAssets.splash,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 100, 32, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                          builder: (context, c) {
                            return Semantics(
                              label: 'REPRONIG',
                              child: SizedBox(
                                width: 189,
                                height: 120,
                                child: Image.asset(
                                  'assets/branding/repronig_logo_stacked.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  gaplessPlayback: true,
                                ),
                              ),
                            );
                          },
                        )
                        .animate()
                        .fadeIn(
                          duration: AppMotion.regular,
                          curve: AppMotion.emphasized,
                        )
                        .scale(
                          begin: const Offset(0.82, 0.82),
                          end: const Offset(1, 1),
                          duration: AppMotion.slow,
                          curve: AppMotion.emphasized,
                        ),
                    const SizedBox(height: 18),
                    Text(
                      'Rights. Royalties. Recognition.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF18181B),
                        letterSpacing: 0.2,
                        height: 1.25,
                      ),
                    ).animate().fadeIn(delay: 220.ms, duration: 420.ms),
                    const SizedBox(height: 80),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppColors.primary.withValues(alpha: 0.82),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Text(
                          'Member',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 420.ms),
                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: 148,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 4,
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.12,
                            ),
                            color: AppColors.brandGold,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 420.ms, duration: 360.ms),
                    const SizedBox(height: 16),
                    Text(
                      'Loading…',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF27272A),
                        letterSpacing: 0.8,
                      ),
                    ).animate().fadeIn(delay: 460.ms, duration: 360.ms),
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
