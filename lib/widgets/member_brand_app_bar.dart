import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../features/auth/models/user_resource.dart';
import '../features/auth/providers/auth_session_provider.dart';
import '../features/more/providers/more_providers.dart';
import '../features/shell/member_paths.dart';
import '../features/shell/member_shell_scaffold.dart';

/// Member shell app bar: deepened wine-red toolbar with clean bottom spacing,
/// light chrome, centred page titles, unread badge on avatar.
class MemberBrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MemberBrandAppBar({
    super.key,
    this.title,
    this.welcomeBackLine,
    this.headline,
    this.actions,
    this.showAvatar = true,
    this.showNotifications = false,
    this.toolbarBottomGap = 0,
  }) : assert(
         (title != null && welcomeBackLine == null && headline == null) ||
             (title == null && welcomeBackLine != null && headline != null),
         'Use either title or welcomeBackLine+headline.',
       );

  final String? title;
  final String? welcomeBackLine;
  final String? headline;
  final List<Widget>? actions;
  final bool showAvatar;
  final bool showNotifications;

  /// Visible gap below the wine bar (default height 72).
  final double toolbarBottomGap;

  bool get _isHome =>
      welcomeBackLine != null && headline != null && title == null;

  double get _toolbarH => kToolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(_toolbarH + toolbarBottomGap);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final theme = Theme.of(context);
        final beneath = theme.scaffoldBackgroundColor;

        const onBar = Colors.white;
        final trailing = <Widget>[
          ...?actions,
          if (showNotifications) _MemberAppBarNotifications(ref: ref),
          if (showAvatar)
            _MemberAppBarAvatar(ref: ref, showUnreadBadge: !showNotifications),
          const SizedBox(width: 8),
        ];

        final router = GoRouter.of(context);
        final canPop = router.canPop();
        final barBg = Color.alphaBlend(
          Colors.black.withValues(alpha: 0.14),
          AppColors.primary,
        );

        final leadingRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canPop)
              IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded, size: 24),
                style: IconButton.styleFrom(
                  foregroundColor: onBar,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  if (router.canPop()) {
                    router.pop();
                  }
                },
              ),
            IconButton(
              tooltip: 'Navigation menu',
              icon: const Icon(Icons.subject_rounded, size: 28),
              style: IconButton.styleFrom(
                foregroundColor: onBar,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () =>
                  memberShellScaffoldKey.currentState?.openDrawer(),
            ),
          ],
        );

        final trailingRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: trailing,
        );

        return AppBar(
          toolbarHeight: _toolbarH,
          automaticallyImplyLeading: false,
          leadingWidth: 0,
          leading: const SizedBox.shrink(),
          title: const SizedBox.shrink(),
          actions: const [],
          backgroundColor: Colors.transparent,
          foregroundColor: onBar,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          forceMaterialTransparency: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          iconTheme: const IconThemeData(color: onBar),
          actionsIconTheme: const IconThemeData(color: onBar),
          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(decoration: BoxDecoration(color: barBg)),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _isHome
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              leadingRow,
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      _homeGreetingText(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: onBar,
                                        letterSpacing: -0.35,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              trailingRow,
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              leadingRow,
                              Expanded(
                                child: Center(
                                  child: Text(
                                    title!,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: onBar,
                                      letterSpacing: -0.45,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ),
                              trailingRow,
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
          bottom: toolbarBottomGap <= 0
              ? null
              : PreferredSize(
                  preferredSize: Size.fromHeight(toolbarBottomGap),
                  child: SizedBox(
                    height: toolbarBottomGap,
                    width: double.infinity,
                    child: ColoredBox(color: beneath),
                  ),
                ),
        );
      },
    );
  }

  String _homeGreetingText() {
    final a = welcomeBackLine?.trim() ?? '';
    final b = headline?.trim() ?? '';
    if (b.isEmpty) return a;
    if (a.isEmpty) return b;
    return '$a $b';
  }
}

class _MemberAppBarAvatar extends StatelessWidget {
  const _MemberAppBarAvatar({required this.ref, this.showUnreadBadge = true});

  final WidgetRef ref;
  final bool showUnreadBadge;

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(authSessionProvider).user?.user;
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unread = unreadAsync.valueOrNull ?? 0;
    final url = u?.avatarUrl?.trim();
    final initials = _initialsFromUser(u);
    const avatarSize = 38.0;
    final border = Colors.white.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 4),
      child: SizedBox(
        width: avatarSize + 10,
        height: avatarSize + 10,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(MemberPaths.moreProfile),
                customBorder: const CircleBorder(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: border, width: 2),
                  ),
                  child: ClipOval(
                    child: url != null && url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _BrandBarInitialsPlate(initials: initials),
                          )
                        : _BrandBarInitialsPlate(initials: initials),
                  ),
                ),
              ),
            ),
            if (showUnreadBadge && unread > 0)
              Positioned(
                right: -2,
                top: -4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push(MemberPaths.moreNotifications),
                    borderRadius: BorderRadius.circular(11),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.95),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _initialsFromUser(UserResource? u) {
    if (u == null) return 'M';
    final first = u.firstName;
    final last = u.lastName;
    final name = u.name;
    if (first != null && first.trim().isNotEmpty) {
      final a = first.trim()[0].toUpperCase();
      if (last != null && last.trim().isNotEmpty) {
        return '$a${last.trim()[0].toUpperCase()}';
      }
      return a;
    }
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'M';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

class _MemberAppBarNotifications extends StatelessWidget {
  const _MemberAppBarNotifications({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unread = unreadAsync.valueOrNull ?? 0;

    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(MemberPaths.moreNotifications),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: SizedBox(
              width: 26,
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -10,
                      top: -7,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A0C0C),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFACC15),
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandBarInitialsPlate extends StatelessWidget {
  const _BrandBarInitialsPlate({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      color: Colors.white.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
