import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';

/// Shared layout for member auth screens: soft brand gradient, horizontal wordmark
/// logo, and a frosted card for the form (max width for large phones / tablets).
class MemberAuthLayout extends StatelessWidget {
  const MemberAuthLayout({
    super.key,
    this.title,
    required this.child,
    this.actions,
  });

  /// When `null` or empty, the app bar shows no title (e.g. login / register).
  final String? title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.darkBackground,
              Color.lerp(AppColors.darkBackground, AppColors.primary, 0.35)!,
              AppColors.darkCard,
            ]
          : [
              Color.lerp(AppColors.muted, AppColors.brandGold, 0.12)!,
              theme.colorScheme.surface,
              Color.lerp(Colors.white, AppColors.primary, 0.04)!,
            ],
      stops: const [0.0, 0.45, 1.0],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: (title == null || title!.trim().isEmpty)
            ? const SizedBox.shrink()
            : Text(
                title!.trim(),
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
        actions: actions,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  static const _asset = 'assets/branding/repronig_logo_full.png';

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    // Matches [SingleChildScrollView] horizontal inset (20 + 20) + [ConstrainedBox] max 440.
    final contentW = math.min(440.0, screenW - 40);
    final logoW = (contentW - 4).clamp(128.0, 208.0);
    return Semantics(
      label: 'REPRONIG',
      child: Image.asset(
        _asset,
        width: logoW,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}
