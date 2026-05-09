import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../data/dashboard_api.dart';
import '../models/member_dashboard_summary.dart';

final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(ref.watch(dioProvider));
});

/// User-facing copy for [memberDashboardSummaryProvider] failures (home + activity).
String formatMemberDashboardSummaryError(Object error, {bool compact = false}) {
  if (error is ApiException) return error.message;
  if (error is MemberDashboardUnavailableException) {
    return compact
        ? 'Activity could not be loaded for this account.'
        : 'Your member dashboard could not be loaded. '
            'If this continues, contact support.';
  }
  return error.toString();
}

/// Member dashboard from `GET /me/dashboard-summary`.
final memberDashboardSummaryProvider =
    FutureProvider.autoDispose<MemberDashboardSummary>((ref) async {
      final api = ref.read(dashboardApiProvider);
      final summary = await api.fetchMemberDashboardSummary();
      if (summary == null) {
        throw const MemberDashboardUnavailableException();
      }
      return summary;
    });

/// Thrown when `data.member` is missing (unexpected for the member app).
class MemberDashboardUnavailableException implements Exception {
  const MemberDashboardUnavailableException();

  @override
  String toString() =>
      'Member dashboard is unavailable for this account.';
}
