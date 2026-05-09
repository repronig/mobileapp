import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/config/env.dart';
import '../more/providers/more_providers.dart';

/// [Scaffold] key for the member shell (drawer). Used by [MemberBrandAppBar] menu.
final GlobalKey<ScaffoldState> memberShellScaffoldKey =
    GlobalKey<ScaffoldState>(debugLabel: 'memberShell');

/// Member area: slide-out drawer navigation (no bottom bar).
class MemberShellScaffold extends StatelessWidget {
  const MemberShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: memberShellScaffoldKey,
      drawer: _MemberNavigationDrawer(navigationShell: navigationShell),
      body: navigationShell,
    );
  }
}

class _MemberNavigationDrawer extends ConsumerWidget {
  const _MemberNavigationDrawer({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <({int index, IconData icon, String label})>[
    (index: 0, icon: Icons.home_rounded, label: 'Home'),
    (index: 1, icon: Icons.article_rounded, label: 'My Mandate'),
    (index: 2, icon: Icons.folder_rounded, label: 'My Works'),
    (index: 3, icon: Icons.timeline_rounded, label: 'Activity'),
    (index: 4, icon: Icons.more_horiz_rounded, label: 'More'),
  ];

  static const _drawerWidth = 280.0;
  static const _sidebarBgLight = Color(0xFFFCFCF7);
  static const _sidebarBgDark = Color(0xFF020617);
  static const _portalTitleLight = Color(0xFF5A0706);
  static const _navInactiveLight = Color(0xFF484848);
  static const _closeIcon = Color(0xFF667085);

  void _close(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final current = navigationShell.currentIndex;
    final unreadCount =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    final sidebarBg = isDark ? _sidebarBgDark : _sidebarBgLight;
    final borderColor = isDark ? const Color(0xFF1E293B) : AppColors.border;
    final headerRuleColor = isDark
        ? const Color(0xFFFBBF24).withValues(alpha: 0.35)
        : AppColors.primary.withValues(alpha: 0.45);
    final portalTitleColor = isDark
        ? const Color(0xFFFEF3C7).withValues(alpha: 0.95)
        : _portalTitleLight;
    final navInactiveColor = isDark
        ? const Color(0xFFCBD5E1)
        : _navInactiveLight;
    final footerBorder = isDark ? const Color(0xFF334155) : AppColors.border;
    final footerBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final footerText = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF6B788E);

    return Drawer(
      width: _drawerWidth,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: sidebarBg,
          border: Border(right: BorderSide(color: borderColor, width: 1)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              'assets/branding/repronig_logo.png',
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2,
                            width: 48,
                            decoration: BoxDecoration(
                              color: headerRuleColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Member Portal',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              letterSpacing: 0.5,
                              color: portalTitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: footerBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        side: BorderSide(color: footerBorder),
                      ),
                      child: InkWell(
                        onTap: () => _close(context),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: _closeIcon,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                      : const Color(0xFFE8DDD4).withValues(alpha: 0.8),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    final selected = current == item.index;
                    return Material(
                      color: selected ? AppColors.primary : Colors.transparent,
                      elevation: selected ? 2 : 0,
                      shadowColor: selected
                          ? AppColors.primary.withValues(alpha: 0.22)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: InkWell(
                        onTap: () {
                          _close(context);
                          navigationShell.goBranch(
                            item.index,
                            initialLocation:
                                item.index == navigationShell.currentIndex,
                          );
                        },
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 22,
                                color: selected
                                    ? Colors.white
                                    : navInactiveColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? Colors.white
                                        : navInactiveColor,
                                  ),
                                ),
                              ),
                              if (item.index == 4 && unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.white.withValues(alpha: 0.22)
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: footerBg,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: footerBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      '${Env.appName} Digital Rights System version 1.0',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.45,
                        color: footerText,
                      ),
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
