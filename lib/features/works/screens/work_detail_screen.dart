import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/ux/member_feedback.dart';
import '../../../widgets/member_async_value_body.dart';
import '../../../widgets/member_brand_app_bar.dart';
import '../models/member_work.dart';
import '../providers/works_providers.dart';
import 'work_editor_screen.dart';

class WorkDetailScreen extends ConsumerWidget {
  const WorkDetailScreen({super.key, required this.workId});

  final int workId;

  static String routePath(int id) => '/member/works/view/$id';

  static const routeName = 'member-work-detail';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workDetailProvider(workId));

    return Scaffold(
      appBar: async.maybeWhen(
        data: (w) => MemberBrandAppBar(
          title: 'Work details',
          actions: [
            if (w.canEdit)
              IconButton(
                tooltip: 'Edit work',
                icon: const Icon(Icons.edit_rounded),
                onPressed: () =>
                    context.push(WorkEditorScreen.editRoutePath(w.id)),
              ),
          ],
        ),
        orElse: () => const MemberBrandAppBar(title: 'Work details'),
      ),
      body: MemberAsyncValueBody<MemberWork>(
        async: async,
        retryLabel: 'Retry',
        onRetry: () => ref.invalidate(workDetailProvider(workId)),
        data: (w) => _WorkDetailBody(
          work: w,
          onSubmit: () async {
            try {
              await ref.read(worksApiProvider).submitWork(w.id);
              ref.invalidate(workDetailProvider(workId));
              if (context.mounted) {
                MemberFeedback.showSuccess(context, 'Work submitted.');
              }
            } on ApiException catch (err) {
              if (context.mounted) MemberFeedback.showError(context, err);
            }
          },
          onRequestUpdate: () async {
            try {
              await ref.read(worksApiProvider).requestWorkUpdate(w.id);
              ref.invalidate(workDetailProvider(workId));
              if (context.mounted) {
                MemberFeedback.showSuccess(context, 'Update request sent to admin.');
              }
            } on ApiException catch (err) {
              if (context.mounted) MemberFeedback.showError(context, err);
            }
          },
        ),
      ),
    );
  }
}

class _WorkDetailBody extends StatefulWidget {
  const _WorkDetailBody({
    required this.work,
    required this.onSubmit,
    required this.onRequestUpdate,
  });

  final MemberWork work;
  final Future<void> Function() onSubmit;
  final Future<void> Function() onRequestUpdate;

  @override
  State<_WorkDetailBody> createState() => _WorkDetailBodyState();
}

class _WorkDetailBodyState extends State<_WorkDetailBody> {
  var _submitting = false;
  var _requestingUpdate = false;

  MemberWork get work => widget.work;

  Future<void> _handleSubmit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleRequestUpdate() async {
    setState(() => _requestingUpdate = true);
    try {
      await widget.onRequestUpdate();
    } finally {
      if (mounted) setState(() => _requestingUpdate = false);
    }
  }

  static String _humanize(String? v) {
    if (v == null || v.isEmpty) return '—';
    return v.replaceAll('_', ' ');
  }

  static String _humanizeChip(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.replaceAll('_', ' ');
  }

  static (Color bg, Color fg) _chipColors(String? raw, {bool verification = false}) {
    final s = (raw ?? '').toLowerCase();
    if (verification) {
      if (s.contains('verified') || s.contains('approved')) {
        return (const Color(0xFFECFDF3), const Color(0xFF027A48));
      }
      if (s.contains('pending') || s.contains('await')) {
        return (const Color(0xFFFFFAEB), const Color(0xFFB45309));
      }
      if (s.contains('reject') || s.contains('fail')) {
        return (const Color(0xFFFEF3F2), const Color(0xFFB42318));
      }
      return (const Color(0xFFF2F4F7), const Color(0xFF475467));
    }
    if (s.contains('approved')) {
      return (const Color(0xFFECFDF3), const Color(0xFF027A48));
    }
    if (s.contains('draft')) {
      return (const Color(0xFFF1F5F9), const Color(0xFF475569));
    }
    if (s.contains('submit')) {
      return (const Color(0xFFEFF6FF), const Color(0xFF1D4ED8));
    }
    if (s.contains('change') || s.contains('review')) {
      return (const Color(0xFFE0F2FE), const Color(0xFF0369A1));
    }
    if (s.contains('reject')) {
      return (const Color(0xFFFEF3F2), const Color(0xFFB42318));
    }
    return (const Color(0xFFF2F4F7), const Color(0xFF475467));
  }

  Widget _metaChip(ThemeData theme, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _panel(
    ThemeData theme, {
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(18, 18, 18, 16),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 14),
    required Widget child,
  }) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: AppMemberSurfaces.section(theme),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }

  Widget _fieldBlock(ThemeData theme, String label, String? value) {
    final raw = value?.trim() ?? '';
    final display = raw.isEmpty ? '—' : raw;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              height: 1.25,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            display,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return _panel(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.primary.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 10),
              ],
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
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  static String _formatDate(String? v) {
    if (v == null || v.isEmpty) return '—';
    try {
      return DateFormat.yMMMd().format(DateTime.parse(v));
    } on FormatException {
      return v;
    }
  }

  Widget _coverPreview(ThemeData theme, MemberWork work) {
    final coverUrl = work.coverImageUrl;
    final coverName = work.coverImageFile?.fileName.trim();
    return _section(
      context,
      title: 'Cover page',
      icon: Icons.photo_library_outlined,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
              ),
              child: coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _coverFallback(theme),
                    )
                  : _coverFallback(theme),
            ),
          ),
        ),
        if (coverName != null && coverName.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            coverName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _coverFallback(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 30,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = work;
    final ws = _humanizeChip(w.workStatus);
    final vs = _humanizeChip(w.verificationStatus);
    final (wsBg, wsFg) = _chipColors(w.workStatus);
    final (vsBg, vsFg) = _chipColors(w.verificationStatus, verification: true);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 64),
      children: [
        _panel(
          theme,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                w.title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  letterSpacing: -0.35,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (w.subtitle != null && w.subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  w.subtitle!.trim(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (ws.isNotEmpty) _metaChip(theme, ws, wsBg, wsFg),
                  if (vs.isNotEmpty) _metaChip(theme, vs, vsBg, vsFg),
                  if (w.publicationYear != null)
                    _metaChip(
                      theme,
                      '${w.publicationYear}',
                      theme.colorScheme.surfaceContainerHighest,
                      theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              if (w.referenceNumber != null &&
                  w.referenceNumber!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        w.referenceNumber!.trim(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (w.submittedAt != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Submitted ${_formatDate(w.submittedAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        _coverPreview(theme, w),
        _section(
          context,
          title: 'Summary',
          icon: Icons.info_outline_rounded,
          children: [
            _fieldBlock(theme, 'Type of work', _humanize(w.typeOfWork)),
            _fieldBlock(
              theme,
              'Publication year',
              w.publicationYear != null ? '${w.publicationYear}' : '—',
            ),
            _fieldBlock(theme, 'Primary language', w.primaryLanguage),
            _fieldBlock(theme, 'Format', _humanize(w.workFormat)),
            _fieldBlock(
              theme,
              'Identifier',
              '${w.identifierType ?? ''} ${w.identifierValue ?? ''}'.trim(),
            ),
            _fieldBlock(theme, 'DOI', w.doi ?? ''),
            _fieldBlock(theme, 'Publisher', w.publisherName),
            _fieldBlock(theme, 'Target market', _humanize(w.targetMarket)),
            if (w.targetMarket == 'other')
              _fieldBlock(theme, 'Target (other)', w.targetMarketOther),
            _fieldBlock(theme, 'Production', _humanize(w.productionStatus)),
            _fieldBlock(theme, 'Contributors', '${w.contributorsCount}'),
            _fieldBlock(theme, 'Files', '${w.filesCount}'),
          ],
        ),
        _section(
          context,
          title: 'Description',
          icon: Icons.subject_rounded,
          children: [
            Text(
              w.synopsis?.trim().isNotEmpty == true ? w.synopsis! : '—',
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.55,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (w.notes != null && w.notes!.trim().isNotEmpty)
          _section(
            context,
            title: 'Notes',
            icon: Icons.sticky_note_2_outlined,
            children: [
              Text(
                w.notes!,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        _section(
          context,
          title: 'Agreement',
          icon: Icons.verified_user_outlined,
          children: [
            _fieldBlock(
              theme,
              'Accepted',
              w.agreementAccepted ? 'Yes' : 'No',
            ),
            _fieldBlock(theme, 'Consent date', _formatDate(w.dateOfConsent)),
          ],
        ),
        if (w.workStatus == 'approved' && !w.canEdit) ...[
          _panel(
            theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'This work has been approved and is locked for edits.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Request an update to ask admin for edit access.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                if (w.updateRequestStatus == 'pending')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      color: const Color(0xFFFFFAEB),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Text(
                      'Update request pending admin review.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _requestingUpdate ? null : _handleRequestUpdate,
                    icon: _requestingUpdate
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text(
                      _requestingUpdate ? 'Requesting…' : 'Request update',
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (w.isDraft && !w.isRestricted) ...[
          _panel(
            theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.mark_email_unread_outlined,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Submission requires a cover image and contributor '
                        'ownership totaling 100%. If submit fails, complete '
                        'files and contributors on the web portal.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _submitting ? null : _handleSubmit,
                  icon: _submitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(_submitting ? 'Submitting…' : 'Submit for review'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
