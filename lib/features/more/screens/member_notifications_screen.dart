import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/ux/member_feedback.dart';
import '../../../widgets/member_async_value_body.dart';
import '../../../widgets/member_brand_app_bar.dart';
import '../../../widgets/member_surface_card.dart';
import '../models/user_notification_item.dart';
import '../providers/more_providers.dart';

class MemberNotificationsScreen extends ConsumerStatefulWidget {
  const MemberNotificationsScreen({super.key});

  static const routeName = 'member-more-notifications';

  @override
  ConsumerState<MemberNotificationsScreen> createState() =>
      _MemberNotificationsScreenState();
}

class _MemberNotificationsScreenState
    extends ConsumerState<MemberNotificationsScreen> {
  final _items = <UserNotificationItem>[];
  var _page = 1;
  var _loading = true;
  var _loadingMore = false;
  var _unreadOnly = false;
  String? _error;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load(reset: true));
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
      final result = await ref
          .read(moreApiProvider)
          .listNotifications(page: _page, perPage: 20, unreadOnly: _unreadOnly);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }
        _lastPage = result.meta.lastPage;
        _error = null;
      });
      ref.invalidate(unreadNotificationsCountProvider);
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

  Future<void> _markAll() async {
    try {
      final n = await ref.read(moreApiProvider).markAllNotificationsRead();
      if (mounted) {
        MemberFeedback.showSuccess(
          context,
          n > 0 ? 'Marked $n as read.' : 'Done.',
        );
        await _load(reset: true);
        ref.invalidate(unreadNotificationsCountProvider);
      }
    } on ApiException catch (e) {
      if (mounted) MemberFeedback.showError(context, e);
    }
  }

  Future<void> _onTap(UserNotificationItem item) async {
    if (item.isUnread) {
      try {
        await ref.read(moreApiProvider).markNotificationRead(item.id);
        ref.invalidate(unreadNotificationsCountProvider);
        if (mounted) await _load(reset: true);
      } on ApiException catch (e) {
        if (mounted) MemberFeedback.showError(context, e);
      }
    }
    final url = item.actionUrl;
    if (url != null && url.isNotEmpty) {
      final u = Uri.tryParse(url);
      if (u != null && await canLaunchUrl(u)) {
        await launchUrl(u, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat.yMMMd().add_jm().format(DateTime.parse(iso).toLocal());
    } on FormatException {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: MemberBrandAppBar(
        title: 'Notifications',
        showAvatar: false,
        actions: [
          TextButton(
            onPressed: _items.isEmpty ? null : _markAll,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              disabledForegroundColor: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.5),
            ),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FilterChip(
              label: const Text('Unread only'),
              selected: _unreadOnly,
              onSelected: (v) {
                setState(() => _unreadOnly = v);
                _load(reset: true);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              child: _loading && _items.isEmpty
                  ? const MemberAsyncLoadingPlaceholder()
                  : _error != null && _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        MemberAsyncErrorCard(
                          message: _error!,
                          onRetry: () => _load(reset: true),
                        ),
                      ],
                    )
                  : _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 24),
                        MemberSurfaceCard(
                          child: Column(
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 46,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No notifications',
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _unreadOnly
                                    ? 'You have no unread notifications.'
                                    : 'Alerts from REPRONIG will appear here.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: _items.length + 1,
                      itemBuilder: (context, i) {
                        if (i == _items.length) {
                          if (_page < _lastPage) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: _loadingMore
                                    ? const CircularProgressIndicator()
                                    : TextButton(
                                        onPressed: () async {
                                          setState(() => _page++);
                                          await _load(reset: false);
                                        },
                                        child: const Text('Load more'),
                                      ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        final n = _items[i];
                        return MemberSurfaceCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              borderColor: n.isUnread
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.45,
                                    )
                                  : null,
                              onTap: () => _onTap(n),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: n.isUnread
                                              ? theme.colorScheme.primary
                                                    .withValues(alpha: 0.14)
                                              : theme
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                        ),
                                        child: Icon(
                                          n.isUnread
                                              ? Icons
                                                    .notifications_active_outlined
                                              : Icons
                                                    .notifications_none_rounded,
                                          size: 18,
                                          color: n.isUnread
                                              ? theme.colorScheme.primary
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: n.isUnread
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                    height: 1.3,
                                                  ),
                                            ),
                                            if (n.createdAt != null) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                _formatTime(n.createdAt),
                                                style: theme
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (n.isUnread) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (n.message != null &&
                                      n.message!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      n.message!,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            height: 1.4,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.9),
                                          ),
                                    ),
                                  ],
                                  if (n.actionUrl != null &&
                                      n.actionUrl!.isNotEmpty)
                                    if (!n.isUnread) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Read',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant
                                                  .withValues(alpha: 0.8),
                                            ),
                                      ),
                                    ],
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: i * 30),
                              duration: AppMotion.regular,
                            )
                            .slideY(
                              begin: 0.08,
                              end: 0,
                              delay: Duration(milliseconds: i * 30),
                              duration: AppMotion.regular,
                              curve: AppMotion.emphasized,
                            );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
