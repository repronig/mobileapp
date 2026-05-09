import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../core/network/api_exception.dart';
import 'member_surface_card.dart';

/// Maps [ApiException] and fallbacks for async [Riverpod] screens.
String defaultMemberAsyncErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  return error.toString();
}

/// Standard **loading** / **error + retry** / **data** layout for member [AsyncValue] bodies.
///
/// Use inside a [Scaffold] `body` (or nested scroll views). Keeps copy and actions consistent
/// across dashboard, activity, application, work detail, etc.
class MemberAsyncValueBody<T> extends StatelessWidget {
  const MemberAsyncValueBody({
    super.key,
    required this.async,
    required this.data,
    required this.onRetry,
    this.errorMessage,
    this.retryLabel = 'Try again',
    this.emptyWhen,
    this.empty,
  });

  final AsyncValue<T> async;
  final Widget Function(T value) data;
  final VoidCallback onRetry;
  final String Function(Object error, StackTrace? stackTrace)? errorMessage;
  final String retryLabel;
  final bool Function(T value)? emptyWhen;
  final Widget? empty;

  @override
  Widget build(BuildContext context) {
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const MemberAsyncLoadingPlaceholder(),
      error: (error, stackTrace) => MemberAsyncErrorCard(
        message: errorMessage?.call(error, stackTrace) ??
            defaultMemberAsyncErrorMessage(error),
        onRetry: onRetry,
        retryLabel: retryLabel,
      ),
      data: (value) {
        if (emptyWhen != null && emptyWhen!(value)) {
          return empty ?? const MemberAsyncEmptyPlaceholder();
        }
        return data(value);
      },
    );
  }
}

class MemberAsyncLoadingPlaceholder extends StatelessWidget {
  const MemberAsyncLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MemberSurfaceCard(
              child: Shimmer.fromColors(
                baseColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                highlightColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: double.infinity, color: Colors.white),
                    const SizedBox(height: 10),
                    Container(height: 12, width: 180, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 12, width: 120, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Centered error card with retry (matches dashboard / activity styling).
class MemberAsyncErrorCard extends StatelessWidget {
  const MemberAsyncErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Try again',
    this.useSurfaceCard = true,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;
  final bool useSurfaceCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 40,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.45,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onRetry,
          child: Text(retryLabel),
        ),
      ],
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: useSurfaceCard
            ? MemberSurfaceCard(child: content)
            : content,
      ),
    );
  }
}

/// Minimal empty placeholder when [MemberAsyncValueBody.emptyWhen] is true and [empty] is null.
class MemberAsyncEmptyPlaceholder extends StatelessWidget {
  const MemberAsyncEmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Nothing to show yet.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
