import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../widgets/member_brand_app_bar.dart';
import '../../auth/providers/auth_session_provider.dart';
import '../models/member_work.dart';
import '../providers/works_providers.dart';
import 'work_detail_screen.dart';
import 'work_editor_screen.dart';

/// Paginated works list (Pass 5).
class MemberWorksScreen extends ConsumerStatefulWidget {
  const MemberWorksScreen({super.key});

  static const routeName = 'member-works';

  @override
  ConsumerState<MemberWorksScreen> createState() => _MemberWorksScreenState();
}

class _MemberWorksScreenState extends ConsumerState<MemberWorksScreen> {
  final _search = TextEditingController();
  final _items = <MemberWork>[];
  PaginationMeta? _meta;
  var _page = 1;
  var _loading = true;
  var _loadingMore = false;
  String? _error;
  String? _statusFilter;
  bool _deletingWork = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final api = ref.read(worksApiProvider);
      final result = await api.listWorks(
        page: _page,
        perPage: 20,
        search: _search.text,
        status: _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }
        _meta = result.meta;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    final m = _meta;
    if (m == null || _page >= m.lastPage || _loadingMore) return;
    setState(() => _page++);
    await _load(reset: false);
  }

  bool get _canRegisterWorks =>
      ref.read(authSessionProvider).user?.memberApproved == true;

  static String _humanize(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.replaceAll('_', ' ');
  }

  Future<void> _deleteWork(MemberWork work) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete work'),
        content: Text('Delete "${work.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _deletingWork = true);
    try {
      await ref.read(worksApiProvider).deleteWork(work.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work deleted successfully.')),
      );
      await _load(reset: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _deletingWork = false);
    }
  }

  static (Color bg, Color fg) _chipColors(
    String? raw, {
    bool verification = false,
  }) {
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

  Widget _workRow(ThemeData theme, MemberWork w, int index) {
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final alt = isDark
        ? cs.surfaceContainerHighest.withValues(alpha: index.isEven ? 0.18 : 0.30)
        : (index.isEven ? Colors.white : const Color(0xFFFFF7E6));

    final border = isDark
        ? cs.outline.withValues(alpha: 0.22)
        : const Color(0xFFECE3CF);

    final ws = _humanize(w.workStatus);
    final vs = _humanize(w.verificationStatus);
    final (wsBg, wsFg) = _chipColors(w.workStatus);
    final (vsBg, vsFg) = _chipColors(
      w.verificationStatus,
      verification: true,
    );

    final metaBits = <Widget>[
      if (w.referenceNumber != null && w.referenceNumber!.trim().isNotEmpty) ...[
        Icon(Icons.tag_rounded, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            w.referenceNumber!.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
      if (w.publicationYear != null) ...[
        if (w.referenceNumber != null && w.referenceNumber!.trim().isNotEmpty)
          const SizedBox(width: 10),
        Icon(Icons.calendar_month_rounded, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '${w.publicationYear}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () async {
          await context.push(WorkDetailScreen.routePath(w.id));
          if (mounted) _load(reset: true);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          decoration: BoxDecoration(
            color: alt,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _workCoverThumb(theme, w),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            w.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: -0.2,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                    if (metaBits.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(children: metaBits),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (ws.isNotEmpty) _metaChip(theme, ws, wsBg, wsFg),
                        if (vs.isNotEmpty) _metaChip(theme, vs, vsBg, vsFg),
                        if (w.updateRequestStatus != null &&
                            w.updateRequestStatus!.trim().isNotEmpty)
                          _metaChip(
                            theme,
                            'Update: ${_humanize(w.updateRequestStatus)}',
                            const Color(0xFFFFFAEB),
                            const Color(0xFF92400E),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (w.canEdit)
                          OutlinedButton(
                            onPressed: () async {
                              await context.push(
                                WorkEditorScreen.editRoutePath(w.id),
                              );
                              if (mounted) _load(reset: true);
                            },
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            child: const Text('Edit'),
                          )
                        else if (!_deletingWork &&
                            (w.workStatus == 'draft' ||
                                w.workStatus == 'changes_requested'))
                          OutlinedButton(
                            onPressed: () => _deleteWork(w),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            child: const Text('Delete'),
                          )
                        else if (w.workStatus == 'approved')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: w.updateRequestStatus == 'pending'
                                  ? const Color(0xFFFFFAEB)
                                  : cs.surfaceContainerHighest,
                            ),
                            child: Text(
                              w.updateRequestStatus == 'pending'
                                  ? 'Update request pending'
                                  : 'Locked',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: w.updateRequestStatus == 'pending'
                                    ? const Color(0xFF92400E)
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          'View',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workCoverThumb(ThemeData theme, MemberWork w) {
    final coverUrl = w.coverImageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        width: 70,
        height: 92,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        child: coverUrl != null
            ? CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _workCoverFallback(theme),
              )
            : _workCoverFallback(theme),
      ),
    );
  }

  Widget _workCoverFallback(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 22,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const MemberBrandAppBar(title: 'Works'),
      floatingActionButton: _canRegisterWorks
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push(WorkEditorScreen.newRoutePath);
                if (mounted) _load(reset: true);
              },
              icon: const Icon(Icons.add),
              label: const Text('New work'),
            )
          : null,
      body: Column(
        children: [
          if (!_canRegisterWorks)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Work registration will be available after your membership application is approved. Check back soon.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search by title',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.65,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _search.clear();
                    _load(reset: true);
                  },
                ),
              ),
              onSubmitted: (_) => _load(reset: true),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final opt in <({String? value, String label})>[
                  (value: null, label: 'All'),
                  (value: 'draft', label: 'Draft'),
                  (value: 'submitted', label: 'Submitted'),
                  (value: 'changes_requested', label: 'Changes requested'),
                  (value: 'approved', label: 'Approved'),
                  (value: 'rejected', label: 'Rejected'),
                  (value: 'disputed', label: 'Disputed'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(opt.label),
                      selected: _statusFilter == opt.value,
                      onSelected: (_) {
                        setState(() => _statusFilter = opt.value);
                        _load(reset: true);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: _loading && _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _error != null && _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _load(reset: true),
                          child: const Text('Try again'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: _items.length + 1,
                      itemBuilder: (context, i) {
                        if (i == _items.length) {
                          final m = _meta;
                          if (m != null && _page < m.lastPage) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _loadingMore
                                    ? const CircularProgressIndicator()
                                    : TextButton(
                                        onPressed: _loadMore,
                                        child: const Text('Load more'),
                                      ),
                              ),
                            );
                          }
                          if (m != null && m.total > 0) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '${_items.length} of ${m.total} works',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        final w = _items[i];
                        return _workRow(theme, w, i);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
