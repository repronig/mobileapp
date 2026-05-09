import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../models/member_work.dart';
import '../models/work_contributor.dart';

class WorksApi {
  WorksApi(this._dio);

  final Dio _dio;

  Future<PaginatedWorksResult> listWorks({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'works',
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (status != null && status.trim().isNotEmpty) 'work_status': status.trim(),
        },
      );
      final data = response.data?['data'];
      final metaRaw = response.data?['meta'];
      if (data is! List<dynamic>) {
        throw const ApiException(message: 'Invalid works list response.');
      }
      final items = data
          .map((e) => MemberWork.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final meta = metaRaw is Map<String, dynamic>
          ? PaginationMeta.fromJson(metaRaw)
          : const PaginationMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 0);
      return PaginatedWorksResult(items: items, meta: meta);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load works.',
      );
    }
  }

  Future<MemberWork> getWork(int workId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('works/$workId');
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid work response.');
      }
      return MemberWork.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load work.',
      );
    }
  }

  Future<MemberWork> createWork(Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('works', data: body);
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid create work response.');
      }
      return MemberWork.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not create work.',
      );
    }
  }

  Future<MemberWork> updateWork(int workId, Map<String, dynamic> body) async {
    try {
      final response =
          await _dio.patch<Map<String, dynamic>>('works/$workId', data: body);
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid update work response.');
      }
      return MemberWork.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not update work.',
      );
    }
  }

  Future<void> deleteWork(int workId) async {
    try {
      await _dio.delete<void>('works/$workId');
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not delete work.',
      );
    }
  }

  /// Public `GET /languages` (active languages for work forms).
  Future<List<LanguageOption>> listLanguages() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('languages');
      final data = response.data?['data'];
      if (data is! List<dynamic>) {
        return const [LanguageOption(id: 0, name: 'English')];
      }
      final list = data
          .map(
            (e) => LanguageOption.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      if (list.isEmpty) {
        return const [LanguageOption(id: 0, name: 'English')];
      }
      return list;
    } on DioException {
      return const [LanguageOption(id: 0, name: 'English')];
    }
  }

  /// `POST /works/:id/files` — multipart `file_type` + `file` (same as web `uploadWorkFile`).
  Future<void> uploadWorkFile(
    int workId, {
    required String fileType,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap(<String, dynamic>{
        'file_type': fileType,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      await _dio.post<void>('works/$workId/files', data: formData);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not upload file.',
      );
    }
  }

  Future<WorkContributor> addWorkContributor(
    int workId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'works/$workId/contributors',
        data: body,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid add contributor response.');
      }
      return WorkContributor.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not add contributor.',
      );
    }
  }

  Future<WorkContributor> updateWorkContributor(
    int workId,
    int contributorId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        'works/$workId/contributors/$contributorId',
        data: body,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid update contributor response.');
      }
      return WorkContributor.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not update contributor.',
      );
    }
  }

  Future<void> deleteWorkContributor(int workId, int contributorId) async {
    try {
      await _dio.delete<void>('works/$workId/contributors/$contributorId');
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not delete contributor.',
      );
    }
  }

  Future<MemberWork> submitWork(int workId) async {
    try {
      final response =
          await _dio.post<Map<String, dynamic>>('works/$workId/submit');
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid submit work response.');
      }
      return MemberWork.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not submit work.',
      );
    }
  }

  Future<MemberWork> requestWorkUpdate(
    int workId, {
    String? note,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'works/$workId/request-update',
        data: <String, dynamic>{
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid request update response.');
      }
      return MemberWork.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not request work update.',
      );
    }
  }
}
