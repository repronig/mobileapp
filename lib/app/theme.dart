import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// REPRONIG brand tokens aligned with `app.repronig/src/index.css`.
/// Card and surface corner radius is capped at **5** logical pixels app-wide.
abstract final class AppRadii {
  static const double sm = 4;

  /// Default for cards, list tiles, nav rows, dialogs, and themed surfaces.
  static const double md = 5;
  static const double lg = 5;
  static const double xl = 5;
  static const double xxl = 5;
}

/// Text field outline (auth, profile, work editor, etc.).
abstract final class AppFormInput {
  static const Color outlineColor = Color(0xFF444444);
  static const double borderWidth = 2;
  static const double borderRadius = 4;
}

abstract final class AppColors {
  /// `--primary`
  static const Color primary = Color(0xFFAF1512);

  /// `--accent`
  static const Color accent = Color(0xFF6A1025);

  /// Brand gold accent (web / print harmony; use for highlights, splash, nav).
  static const Color brandGold = Color(0xFFC9A227);

  static const Color background = Color(0xFFFDFDFD);
  static const Color foreground = Color(0xFF1E2024);
  static const Color card = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFF6F7F8);
  static const Color mutedForeground = Color(0xFF6B788E);
  static const Color border = Color(0xFFEAECF0);
  static const Color pageTitle = Color(0xFF2B2B2D);

  /// Soft app canvas behind elevated cards (light mode).
  static const Color canvas = Color(0xFFF0F2F5);

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkForeground = Color(0xFFE5E7EB);
  static const Color darkCard = Color(0xFF111827);
  static const Color darkMuted = Color(0xFF1F2937);
  static const Color darkMutedForeground = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration regular = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve emphasized = Curves.easeOutCubic;
}

/// Grouped panels on member forms (application, work editor, etc.). Stronger
/// contrast on light canvas than `outline` alone.
abstract final class AppMemberSurfaces {
  static BoxDecoration section(ThemeData theme) {
    final isLight = theme.brightness == Brightness.light;
    final cs = theme.colorScheme;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(
        color: isLight
            ? const Color(0xFFD0D5DD)
            : cs.outline.withValues(alpha: 0.38),
      ),
      color: isLight
          ? cs.surface
          : cs.surfaceContainerHighest.withValues(alpha: 0.28),
      boxShadow: isLight
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration inset(ThemeData theme) {
    final isLight = theme.brightness == Brightness.light;
    final cs = theme.colorScheme;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(
        color: isLight
            ? const Color(0xFFC5CCD6)
            : cs.outline.withValues(alpha: 0.35),
      ),
      color: isLight
          ? const Color(0xFFF3F5F7)
          : cs.surfaceContainerHighest.withValues(alpha: 0.26),
    );
  }

  /// Home onboarding notice: warm cream panel with readable contrast (light);
  /// muted warm panel in dark mode.
  static BoxDecoration onboardingBanner(ThemeData theme) {
    final isLight = theme.brightness == Brightness.light;
    if (isLight) {
      return BoxDecoration(
        color: const Color(0xFFFFF6EB),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFE8D4BC), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      );
    }
    return BoxDecoration(
      color: const Color(0xFF2A2420),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(
        color: AppColors.brandGold.withValues(alpha: 0.35),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static Color onboardingBannerTitleColor(ThemeData theme) {
    return theme.brightness == Brightness.light
        ? const Color(0xFF3D2918)
        : const Color(0xFFF5ECD8);
  }

  static Color onboardingBannerIconColor(ThemeData theme) {
    return theme.brightness == Brightness.light
        ? AppColors.accent
        : AppColors.brandGold;
  }
}

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      tertiary: AppColors.brandGold,
      onTertiary: const Color(0xFF2A1F00),
      surface: AppColors.card,
      onSurface: AppColors.foreground,
      surfaceContainerHighest: AppColors.muted,
      error: const Color(0xFFB42318),
      outline: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      splashFactory: InkRipple.splashFactory,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        modalElevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 10,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.mutedForeground,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
            color: selected ? AppColors.primary : AppColors.mutedForeground,
          );
        }),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.pageTitle,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.pageTitle,
        ),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: _textTheme(Brightness.light),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.pageTitle,
          height: 1.1,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.pageTitle,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedForeground,
        ),
        helperStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.mutedForeground,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.45)),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      tertiary: AppColors.brandGold,
      onTertiary: const Color(0xFF1A1200),
      surface: AppColors.darkCard,
      onSurface: AppColors.darkForeground,
      surfaceContainerHighest: AppColors.darkMuted,
      error: const Color(0xFFF97066),
      outline: AppColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      splashFactory: InkRipple.splashFactory,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.brandGold,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        modalElevation: 12,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 10,
        shadowColor: Colors.black54,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brandGold.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? AppColors.brandGold
                : AppColors.darkMutedForeground,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
            color: selected
                ? AppColors.brandGold
                : AppColors.darkMutedForeground,
          );
        }),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkForeground,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkForeground,
        ),
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: _textTheme(Brightness.dark),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkMuted,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.darkForeground,
          height: 1.1,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.darkForeground,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.darkMutedForeground,
        ),
        helperStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.darkMutedForeground,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFF97066), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: Color(0xFFF97066), width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.65)),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.light
        ? GoogleFonts.interTextTheme()
        : GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return base.copyWith(
      headlineLarge: GoogleFonts.inter(textStyle: base.headlineLarge).copyWith(
        fontWeight: FontWeight.w800,
        color: brightness == Brightness.light
            ? AppColors.pageTitle
            : AppColors.darkForeground,
      ),
      headlineMedium: GoogleFonts.inter(textStyle: base.headlineMedium)
          .copyWith(
            fontWeight: FontWeight.w700,
            color: brightness == Brightness.light
                ? AppColors.pageTitle
                : AppColors.darkForeground,
          ),
      titleLarge: GoogleFonts.inter(textStyle: base.titleLarge).copyWith(
        fontWeight: FontWeight.w700,
        color: brightness == Brightness.light
            ? AppColors.pageTitle
            : AppColors.darkForeground,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        color: brightness == Brightness.light
            ? AppColors.foreground
            : AppColors.darkForeground,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
        color: brightness == Brightness.light
            ? AppColors.mutedForeground
            : AppColors.darkMutedForeground,
      ),
    );
  }
}
