import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../models/member_application_detail.dart';

class MemberApplicationApi {
  MemberApplicationApi(this._dio);

  final Dio _dio;

  Future<MemberApplicationDetail?> fetchMyApplication() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'member-applications/me',
      );
      final data = response.data?['data'];
      if (data == null) return null;
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Invalid member application response.',
        );
      }
      return MemberApplicationDetail.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load your application.',
      );
    }
  }

  Future<MemberApplicationDetail> createApplication(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'member-applications',
        data: body,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Invalid create application response.',
        );
      }
      return MemberApplicationDetail.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not create application/mandate.',
      );
    }
  }

  Future<MemberApplicationDetail> updateApplication(
    int applicationId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        'member-applications/$applicationId',
        data: body,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Invalid update application response.',
        );
      }
      return MemberApplicationDetail.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not save application.',
      );
    }
  }

  Future<MemberApplicationDetail> submitApplication(int applicationId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'member-applications/$applicationId/submit',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(
          message: 'Invalid submit application response.',
        );
      }
      return MemberApplicationDetail.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not submit application.',
      );
    }
  }

  Future<Response<List<int>>> downloadMandate(int applicationId) async {
    try {
      return _dio.get<List<int>>(
        'member-applications/$applicationId/mandate',
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not download mandate form.',
      );
    }
  }

  Future<MemberApplicationDocumentRow> uploadDocument({
    required int applicationId,
    required String documentType,
    required String fileName,
    String? filePath,
    List<int>? fileBytes,
  }) async {
    try {
      final MultipartFile file;
      if (fileBytes != null && fileBytes.isNotEmpty) {
        file = MultipartFile.fromBytes(fileBytes, filename: fileName);
      } else if (filePath != null && filePath.isNotEmpty) {
        file = await MultipartFile.fromFile(filePath, filename: fileName);
      } else {
        throw const ApiException(message: 'No file data to upload.');
      }

      final formData = FormData.fromMap(<String, dynamic>{
        'document_type': documentType,
        'file': file,
      });
      final response = await _dio.post<Map<String, dynamic>>(
        'member-applications/$applicationId/documents',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid document upload response.');
      }
      return MemberApplicationDocumentRow.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not upload document.',
      );
    }
  }

  Future<void> deleteDocument({
    required int applicationId,
    required int documentId,
  }) async {
    try {
      await _dio.delete<void>(
        'member-applications/$applicationId/documents/$documentId',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not delete document.',
      );
    }
  }
}
