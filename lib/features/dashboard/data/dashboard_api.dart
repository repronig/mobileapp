import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../models/member_dashboard_summary.dart';

class DashboardApi {
  DashboardApi(this._dio);

  final Dio _dio;

  /// Returns parsed `data.member`, or `null` if the API omits the member block.
  Future<MemberDashboardSummary?> fetchMemberDashboardSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('me/dashboard-summary');
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid dashboard response.');
      }
      final member = data['member'];
      if (member is! Map<String, dynamic>) {
        return null;
      }
      return MemberDashboardSummary.fromJson(member);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load dashboard.',
      );
    }
  }
}
