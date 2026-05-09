import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/providers/theme_mode_provider.dart';
import '../../widgets/confirm_logout_dialog.dart';
import '../../widgets/member_brand_app_bar.dart';
import '../auth/models/user_resource.dart';
import '../auth/providers/auth_session_provider.dart';
import '../more/providers/more_providers.dart';
import '../auth/screens/login_screen.dart';
import 'member_paths.dart';

class MemberMoreScreen extends ConsumerWidget {
  const MemberMoreScreen({super.key});

  static const routePath = '/member/more';
  static const routeName = 'member-more';

  static String _greetingName(UserResource? u) {
    final fn = u?.firstName?.trim();
    if (fn != null && fn.isNotEmpty) return fn;
    final name = u?.name.trim() ?? '';
    if (name.isEmpty) return 'Member';
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final unreadCount =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final user = ref.watch(authSessionProvider).user?.user;

    return Scaffold(
      appBar: const MemberBrandAppBar(title: 'More'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          _MoreIntroPanel(
            greetingName: _greetingName(user),
            scheme: scheme,
            isDark: isDark,
          ),
          const SizedBox(height: 22),
          const _SectionHeading(text: 'Your account'),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: AppMemberSurfaces.section(theme),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MoreOptionRow(
                    title: 'Member profile',
                    subtitle: 'Name, address, publishing details',
                    icon: Icons.person_rounded,
                    iconBg: const Color(0xFFFCEAEA),
                    iconFg: AppColors.primary,
                    onTap: () => context.push(MemberPaths.moreProfile),
                  ),
                  _MoreRowDivider(scheme: scheme, isDark: isDark),
                  _MoreOptionRow(
                    title: 'Notifications',
                    subtitle: unreadCount > 0
                        ? '$unreadCount unread alert${unreadCount == 1 ? '' : 's'}'
                        : 'Alerts from REPRONIG',
                    icon: Icons.notifications_active_rounded,
                    iconBg: const Color(0xFFEFF4FF),
                    iconFg: const Color(0xFF1D4ED8),
                    badgeCount: unreadCount > 0 ? unreadCount : null,
                    onTap: () => context.push(MemberPaths.moreNotifications),
                  ),
                  _MoreRowDivider(scheme: scheme, isDark: isDark),
                  _MoreOptionRow(
                    title: 'Account settings',
                    subtitle: 'Password and security',
                    icon: Icons.lock_rounded,
                    iconBg: const Color(0xFFEAF8F4),
                    iconFg: const Color(0xFF0F766E),
                    onTap: () => context.push(MemberPaths.moreSettings),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          const _SectionHeading(text: 'Preferences'),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: AppMemberSurfaces.section(theme),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      ref.read(themeModeNotifierProvider.notifier).cycle(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.brandGold.withValues(
                              alpha: isDark ? 0.22 : 0.16,
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(
                              color: AppColors.brandGold.withValues(
                                alpha: isDark ? 0.35 : 0.28,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.palette_rounded,
                            color: isDark
                                ? AppColors.brandGold
                                : const Color(0xFF7C5E0A),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appearance',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.25,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Toggle between dark or light mode',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.38,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          const _SectionHeading(text: 'Session'),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: AppMemberSurfaces.section(theme),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final ok = await showConfirmLogoutDialog(context);
                    if (!ok || !context.mounted) return;
                    await ref.read(authSessionProvider.notifier).logout();
                    if (context.mounted) {
                      context.go(LoginScreen.routePath);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: scheme.error.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(
                              color: scheme.error.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: scheme.error,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sign out',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.25,
                                  height: 1.2,
                                  color: scheme.error,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You will need to sign in again to access the app.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.38,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.error.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'REPRONIG member portal',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.35,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreIntroPanel extends StatelessWidget {
  const _MoreIntroPanel({
    required this.greetingName,
    required this.scheme,
    required this.isDark,
  });

  final String greetingName;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppMemberSurfaces.section(Theme.of(context)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.12)
                : const Color(0xFFFFF8EE),
            border: Border.all(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : const Color(0xFFEFE2CC),
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $greetingName',
                  style: GoogleFonts.inter(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.42,
                    height: 1.15,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Manage your profile, notifications, and preferences from here.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.47,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 17,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.brandGold.withValues(alpha: isDark ? 1 : 0.92),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.05,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreRowDivider extends StatelessWidget {
  const _MoreRowDivider({required this.scheme, required this.isDark});

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 78,
      endIndent: 16,
      color: scheme.outline.withValues(alpha: isDark ? 0.22 : 0.14),
    );
  }
}

class _MoreOptionRow extends StatelessWidget {
  const _MoreOptionRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.onTap,
    this.badgeCount,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  color: iconBg,
                  border: Border.all(color: iconFg.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: iconFg, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.28,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.38,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${badgeCount! > 99 ? '99+' : badgeCount}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
