import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme.dart';
import '../../../widgets/member_async_value_body.dart';
import '../../../widgets/member_brand_app_bar.dart';
import '../../dashboard/models/member_dashboard_summary.dart';
import '../../dashboard/providers/member_dashboard_provider.dart'
    show formatMemberDashboardSummaryError, memberDashboardSummaryProvider;
import '../activity_formatting.dart';

/// Member audit trail from `GET /me/dashboard-summary` → `member.recent_activity` (Pass 6).
class MemberActivityScreen extends ConsumerWidget {
  const MemberActivityScreen({super.key});

  static const routeName = 'member-activity';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memberDashboardSummaryProvider);

    return Scaffold(
      appBar: const MemberBrandAppBar(title: 'Activity'),
      body: MemberAsyncValueBody<MemberDashboardSummary>(
        async: async,
        onRetry: () => ref.invalidate(memberDashboardSummaryProvider),
        errorMessage: (e, _) => formatMemberDashboardSummaryError(e, compact: true),
        data: (summary) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(memberDashboardSummaryProvider);
            await ref.read(memberDashboardSummaryProvider.future);
          },
          child: _ActivityList(items: summary.recentActivity),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, required this.index});

  final DashboardActivityItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rowBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: index.isEven ? 0.20 : 0.32)
        : (index.isEven ? Colors.white : const Color(0xFFFFF7E6));
    final rowBorder = isDark
        ? theme.colorScheme.outline.withValues(alpha: 0.25)
        : const Color(0xFFECE3CF);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: rowBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    humanizeActivityText(item.action),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      letterSpacing: -0.15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (item.actorName != null &&
                      item.actorName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.actorName!.trim(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.items});

  final List<DashboardActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          const SizedBox(height: 32),
          DecoratedBox(
            decoration: AppMemberSurfaces.section(theme),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 46,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No recent activity',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your account activities will appear here as you use the platform.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        DecoratedBox(
          decoration: AppMemberSurfaces.section(theme),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity feed',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your account activities',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  height: 1.42,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ),
        const SizedBox(height: 12),
        for (final entry in items.asMap().entries)
          _ActivityTile(item: entry.value, index: entry.key)
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: entry.key * 35),
                duration: AppMotion.regular,
              )
              .slideY(
                begin: 0.06,
                end: 0,
                delay: Duration(milliseconds: entry.key * 35),
                duration: AppMotion.regular,
                curve: AppMotion.emphasized,
              ),
      ],
    );
  }
}
