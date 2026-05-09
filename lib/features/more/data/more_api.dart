import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../models/member_profile_detail.dart';
import '../models/paginated_notifications.dart';
import '../models/user_notification_item.dart';

class MoreApi {
  MoreApi(this._dio);

  final Dio _dio;

  Future<List<LocationOption>> listStates() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('locations/states');
      final data = response.data?['data'];
      if (data is! List<dynamic>) return const [];
      return data
          .map(
            (e) => LocationOption.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load states.',
      );
    }
  }

  Future<List<LocationOption>> listCitiesForState(String stateId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'locations/states/$stateId/cities',
      );
      final data = response.data?['data'];
      if (data is! List<dynamic>) return const [];
      return data
          .map(
            (e) => LocationOption.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load cities.',
      );
    }
  }

  Future<MemberProfileDetail?> fetchMemberProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('member/profile');
      final data = response.data?['data'];
      if (data == null) return null;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid member profile response.');
      }
      return MemberProfileDetail.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load member profile.',
      );
    }
  }

  Future<MemberProfileDetail> updateMemberProfile(Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.patch<Map<String, dynamic>>('member/profile', data: body);
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid member profile response.');
      }
      return MemberProfileDetail.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not update profile.',
      );
    }
  }

  Future<void> uploadAvatar({required String filePath, required String fileName}) async {
    try {
      final formData = FormData.fromMap(<String, dynamic>{
        'avatar': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      await _dio.post<Map<String, dynamic>>('me/avatar', data: formData);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not upload avatar.',
      );
    }
  }

  Future<PaginatedNotificationsResult> listNotifications({
    int page = 1,
    int perPage = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'me/notifications',
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (unreadOnly) 'unread': 1,
        },
      );
      final data = response.data?['data'];
      final metaRaw = response.data?['meta'];
      if (data is! List<dynamic>) {
        throw const ApiException(message: 'Invalid notifications response.');
      }
      final items = data
          .map(
            (e) => UserNotificationItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      final meta = metaRaw is Map<String, dynamic>
          ? NotificationListMeta.fromJson(metaRaw)
          : NotificationListMeta(
              currentPage: 1,
              lastPage: 1,
              perPage: perPage,
              total: items.length,
            );
      return PaginatedNotificationsResult(items: items, meta: meta);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load notifications.',
      );
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        'me/notifications/${Uri.encodeComponent(notificationId)}/read',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not mark notification read.',
      );
    }
  }

  Future<int> unreadNotificationCount() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'me/notifications/unread-count',
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        final value = data['unread_count'] ?? data['count'];
        if (value is int) return value;
        if (value is num) return value.toInt();
      }
      return 0;
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load unread notifications.',
      );
    }
  }

  Future<int> markAllNotificationsRead() async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('me/notifications/read-all');
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        final n = data['marked_count'];
        if (n is int) return n;
        if (n is num) return n.toInt();
      }
      return 0;
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not mark notifications read.',
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        'me/change-password',
        data: <String, dynamic>{
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not change password.',
      );
    }
  }
}

class LocationOption {
  const LocationOption({required this.id, required this.name});

  final String id;
  final String name;

  factory LocationOption.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['value'] ?? json['code'] ?? '';
    final nameRaw = json['name'] ?? json['title'] ?? json['label'] ?? '';
    return LocationOption(
      id: '$idRaw',
      name: '$nameRaw',
    );
  }
}
