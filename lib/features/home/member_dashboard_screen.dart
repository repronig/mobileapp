import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../widgets/member_async_value_body.dart';
import '../../widgets/member_brand_app_bar.dart';
import '../../widgets/member_surface_card.dart';
import '../auth/models/user_resource.dart';
import '../auth/providers/auth_session_provider.dart';
import '../dashboard/models/member_dashboard_summary.dart';
import '../dashboard/providers/member_dashboard_provider.dart'
    show formatMemberDashboardSummaryError, memberDashboardSummaryProvider;
import '../more/providers/more_providers.dart';
import '../shell/member_paths.dart';
import '../works/screens/work_detail_screen.dart';
import '../works/screens/work_editor_screen.dart';

/// Member home tab: dashboard summary (`GET /me/dashboard-summary`) and Pass 8 deep links.
class MemberDashboardScreen extends ConsumerStatefulWidget {
  const MemberDashboardScreen({super.key});

  static const routePath = '/member/home';
  static const routeName = 'member-home';

  @override
  ConsumerState<MemberDashboardScreen> createState() =>
      _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends ConsumerState<MemberDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(unreadNotificationsCountProvider));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider).user;
    final async = ref.watch(memberDashboardSummaryProvider);

    final firstName = _firstNameFromUser(user?.user);
    return Scaffold(
      appBar: MemberBrandAppBar(
        welcomeBackLine: 'Hi,',
        headline: firstName,
        showNotifications: true,
      ),
      body: MemberAsyncValueBody<MemberDashboardSummary>(
        async: async,
        onRetry: () => ref.invalidate(memberDashboardSummaryProvider),
        errorMessage: (e, _) => formatMemberDashboardSummaryError(e),
        data: (dashboard) => _DashboardBody(
          userEmail: user?.user.email ?? '',
          dashboard: dashboard,
          onRefresh: () async {
            ref.invalidate(memberDashboardSummaryProvider);
            await ref.read(memberDashboardSummaryProvider.future);
          },
        ),
      ),
    );
  }

  static String _firstNameFromUser(UserResource? u) {
    if (u == null) return 'Member';
    final fn = u.firstName;
    if (fn != null && fn.trim().isNotEmpty) return fn.trim();
    final name = u.name.trim();
    if (name.isEmpty) return 'Member';
    return name.split(RegExp(r'\s+')).first;
  }
}

/// Shared section chrome for dashboard cards.
class _DashSectionHeader extends StatelessWidget {
  const _DashSectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: AppColors.primary.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.42,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _DashboardFieldChip extends StatelessWidget {
  const _DashboardFieldChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.userEmail,
    required this.dashboard,
    required this.onRefresh,
  });

  final String userEmail;
  final MemberDashboardSummary dashboard;
  final Future<void> Function() onRefresh;

  static void _openPendingAction(BuildContext context, String key) {
    switch (key) {
      case 'complete_profile':
        context.go(MemberPaths.moreProfile);
        break;
      case 'register_first_work':
        context.go(WorkEditorScreen.newRoutePath);
        break;
      default:
        context.go(MemberPaths.application);
    }
  }

  static Widget _animatedSection(Widget child, int index) {
    final delay = Duration(milliseconds: math.min(index * 45, 260));
    return child
        .animate()
        .fadeIn(delay: delay, duration: AppMotion.regular)
        .slideY(
          begin: 0.08,
          end: 0,
          delay: delay,
          duration: AppMotion.regular,
          curve: AppMotion.emphasized,
        );
  }

  @override
  Widget build(BuildContext context) {
    final showOnboardingBanner =
        dashboard.memberApplication != null &&
        !dashboard.onboardingStatus.approvedMember;
    final showMembershipReadiness =
        dashboard.profileCompleteness != null &&
        !dashboard.profileCompleteness!.isComplete;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          if (showOnboardingBanner) ...[
            _animatedSection(
              _OnboardingBanner(
                status: dashboard.memberApplication?.applicationStatus,
                onOpenApplication: () => context.go(MemberPaths.application),
              ),
              0,
            ),
            const SizedBox(height: 12),
          ],
          _animatedSection(_StatGrid(stats: dashboard.stats), 1),
          const SizedBox(height: 12),
          if (showMembershipReadiness) ...[
            _animatedSection(
              _ProfileReadinessCard(
                completeness: dashboard.profileCompleteness!,
                onEditProfile: () => context.go(MemberPaths.moreProfile),
              ),
              2,
            ),
            const SizedBox(height: 12),
          ],
          _animatedSection(
            _RecentSubmissionsSection(
              works: dashboard.recentSubmissions,
              onOpen: (id) {
                if (id > 0) context.push(WorkDetailScreen.routePath(id));
              },
            ),
            3,
          ),
          const SizedBox(height: 12),
          _animatedSection(
            _PendingActionsSection(
              actions: dashboard.pendingActions,
              onActionTap: (key) => _openPendingAction(context, key),
            ),
            4,
          ),
        ],
      ),
    );
  }
}

class _OnboardingBanner extends StatelessWidget {
  const _OnboardingBanner({this.status, this.onOpenApplication});

  final String? status;
  final VoidCallback? onOpenApplication;

  @override
  Widget build(BuildContext context) {
    final label = status?.replaceAll('_', ' ') ?? 'in progress';
    final theme = Theme.of(context);
    final titleColor = AppMemberSurfaces.onboardingBannerTitleColor(theme);
    final iconColor = AppMemberSurfaces.onboardingBannerIconColor(theme);
    return MemberSurfaceCard(
      margin: const EdgeInsets.only(bottom: 0),
      onTap: onOpenApplication,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: DecoratedBox(
        decoration: AppMemberSurfaces.onboardingBanner(theme),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onboarding in progress. Your application and mandate is currently $label.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if (onOpenApplication != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Open application →',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final MemberDashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, int value, IconData icon})>[
      (
        label: 'Total works',
        value: stats.totalWorks,
        icon: Icons.layers_outlined,
      ),
      (
        label: 'Draft works',
        value: stats.draftWorks,
        icon: Icons.description_outlined,
      ),
      (
        label: 'Submitted',
        value: stats.submittedWorks,
        icon: Icons.upload_outlined,
      ),
      (
        label: 'Verified (${stats.approvedWorks} Approved)',
        value: stats.verifiedWorks,
        icon: Icons.verified_outlined,
      ),
    ];

    return MemberSurfaceCard(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DashSectionHeader(
            title: 'Overview',
            subtitle: 'Summary of uploaded works',
            icon: Icons.insights_outlined,
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.88,
            children: [
              for (var i = 0; i < items.length; i++)
                _StatTile(
                  label: items[i].label,
                  value: items[i].value,
                  icon: items[i].icon,
                  paletteIndex: i,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Pastel card fill + strong foreground for icon and figures.
  static (Color fill, Color fg) _statPalette(int index) {
    const pairs = <(Color, Color)>[
      (Color(0xFFFFE4E4), Color(0xFF8B1110)),
      (Color(0xFFE0EDFF), Color(0xFF1E40AF)),
      (Color(0xFFEDE9FE), Color(0xFF5B21B6)),
      (Color(0xFFD1FAE5), Color(0xFF065F46)),
    ];
    return pairs[index % pairs.length];
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.paletteIndex,
  });

  final String label;
  final int value;
  final IconData icon;
  final int paletteIndex;

  @override
  Widget build(BuildContext context) {
    final (fill, fg) = _StatGrid._statPalette(paletteIndex);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardFill = isDark ? fill.withValues(alpha: 0.22) : fill;
    final onCard = isDark ? Theme.of(context).colorScheme.onSurface : fg;
    final labelColor = isDark
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : fg.withValues(alpha: 0.82);
    final iconColor = fg.withValues(alpha: isDark ? 0.62 : 0.52);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: fg.withValues(alpha: isDark ? 0.35 : 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.52),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '$value',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.28,
                    color: onCard,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileReadinessCard extends StatelessWidget {
  const _ProfileReadinessCard({required this.completeness, this.onEditProfile});

  final ProfileCompletenessSummary completeness;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MemberSurfaceCard(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppColors.brandGold.withValues(alpha: 0.10)
              : const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? AppColors.brandGold.withValues(alpha: 0.28)
                : const Color(0xFFEADCBF),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashSectionHeader(
                title: 'Membership readiness',
                subtitle: 'Profile fields still needed.',
                icon: Icons.task_alt_rounded,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: completeness.totalFields > 0
                      ? completeness.percentage / 100
                      : 0,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${completeness.percentage}% complete '
                '(${completeness.completedFields}/${completeness.totalFields} fields)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (completeness.missingFields.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final field in completeness.missingFields.take(8))
                      _DashboardFieldChip(text: _formatFieldLabel(field)),
                  ],
                ),
              ],
              if (onEditProfile != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: onEditProfile,
                    child: const Text('Edit your profile'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingActionsSection extends StatelessWidget {
  const _PendingActionsSection({
    required this.actions,
    required this.onActionTap,
  });

  final List<PendingDashboardAction> actions;
  final void Function(String key) onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MemberSurfaceCard(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashSectionHeader(
            title: 'Pending actions',
            subtitle: 'Open tasks for your account.',
            icon: Icons.checklist_rounded,
          ),
          const SizedBox(height: 4),
          if (actions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No pending actions. Your account does not have urgent follow-up items.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final a in actions)
              _PendingActionTile(action: a, onTap: () => onActionTap(a.key)),
        ],
      ),
    );
  }
}

class _RecentSubmissionsSection extends StatelessWidget {
  const _RecentSubmissionsSection({required this.works, required this.onOpen});

  final List<DashboardWorkRow> works;
  final void Function(int workId) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MemberSurfaceCard(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DashSectionHeader(
            title: 'Recent work submissions',
            subtitle: 'Latest works submitted for review.',
            icon: Icons.outbox_rounded,
          ),
          if (works.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
              child: Text(
                'No recent submissions yet.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final e in works.take(5).toList().asMap().entries)
              _RecentSubmissionRow(
                row: e.value,
                index: e.key,
                onTap: e.value.id > 0 ? () => onOpen(e.value.id) : null,
              ),
        ],
      ),
    );
  }
}

class _RecentSubmissionRow extends StatelessWidget {
  const _RecentSubmissionRow({
    required this.row,
    required this.index,
    this.onTap,
  });

  final DashboardWorkRow row;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final separator = theme.colorScheme.outline.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.82 : 0.84,
    );
    final subtitle = row.submittedAt != null
        ? 'Submitted ${_formatDate(row.submittedAt!)}'
        : row.secondaryLine;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: separator)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.26,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingActionTile extends StatelessWidget {
  const _PendingActionTile({required this.action, required this.onTap});

  final PendingDashboardAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.label,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            action.description,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PriorityChip(priority: action.priority),
                  ],
                ),
                if (action.missingFields != null &&
                    action.missingFields!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in action.missingFields!.take(4))
                          _DashboardFieldChip(text: _formatFieldLabel(f)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final PendingPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color, onColor) = switch (priority) {
      PendingPriority.high => (
        'High',
        const Color(0xFFFEF3F2),
        const Color(0xFFB42318),
      ),
      PendingPriority.medium => (
        'Medium',
        const Color(0xFFEFF6FF),
        const Color(0xFF1D4ED8),
      ),
      PendingPriority.low => (
        'Low',
        const Color(0xFFECFDF3),
        const Color(0xFF027A48),
      ),
    };
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? color.withValues(alpha: 0.35) : color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: dark ? Theme.of(context).colorScheme.onSurface : onColor,
        ),
      ),
    );
  }
}

String _formatFieldLabel(String field) {
  return field
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String _formatDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.day.toString().padLeft(2, '0')} '
      '${_monthShort(d.month)} ${d.year}';
}

String _monthShort(int m) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[(m - 1).clamp(0, 11)];
}
