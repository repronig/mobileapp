import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../models/auth_session.dart';
import '../models/current_user_context.dart';
import '../models/email_verification_status.dart';
import '../models/public_association.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/login',
        data: <String, dynamic>{'email': email, 'password': password},
      );
      return _parseAuthSession(response);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Login failed.',
      );
    }
  }

  Future<AuthSession> verifyTwoFactor({
    required int challengeId,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/two-factor/verify',
        data: <String, dynamic>{'challenge_id': challengeId, 'code': code},
      );
      return _parseAuthSession(response);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Two-factor verification failed.',
      );
    }
  }

  Future<void> registerMember(Map<String, dynamic> body) async {
    try {
      await _dio.post<Map<String, dynamic>>('auth/register-member', data: body);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Registration failed.',
      );
    }
  }

  Future<AuthSession> verifyMemberRegistrationOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/member-registration/verify-otp',
        data: <String, dynamic>{'email': email, 'code': code},
      );
      return _parseAuthSession(response);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'OTP verification failed.',
      );
    }
  }

  Future<String?> resendMemberRegistrationOtp({required String email}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/member-registration/resend-otp',
        data: <String, dynamic>{'email': email},
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return data['expires_at'] as String?;
      }
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not resend email verification OTP.',
      );
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        'auth/forgot-password',
        data: <String, dynamic>{'email': email},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not request password reset.',
      );
    }
  }

  Future<void> verifyResetToken({
    required String email,
    required String token,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        'auth/verify-reset-token',
        data: <String, dynamic>{'email': email, 'token': token},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Reset link is invalid or expired.',
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        'auth/reset-password',
        data: <String, dynamic>{
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Password reset failed.',
      );
    }
  }

  Future<CurrentUserContext> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('me');
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid /me response.');
      }
      return CurrentUserContext.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load your account.',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<Map<String, dynamic>>('auth/logout');
    } on DioException {
      // Token may already be invalid; still clear locally.
    }
  }

  Future<List<PublicAssociation>> listAssociations({int perPage = 100}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'associations',
        queryParameters: <String, dynamic>{'per_page': perPage},
      );
      final list = response.data?['data'];
      if (list is! List<dynamic>) return [];
      return list
          .map(
            (e) =>
                PublicAssociation.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load associations.',
      );
    }
  }

  Future<EmailVerificationStatus> getEmailVerificationStatus() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('email/verify');
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid email verification status.');
      }
      return EmailVerificationStatus.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load verification status.',
      );
    }
  }

  /// Signed verification link (same contract as web `verifyEmailWithSignedUrl`).
  Future<EmailVerificationStatus> verifyEmailSigned({
    required String userId,
    required String hash,
    Map<String, String> queryParameters = const {},
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'email/verify/$userId/$hash',
        queryParameters: queryParameters,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid verification response.');
      }
      return EmailVerificationStatus.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Email verification failed.',
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _dio.post<Map<String, dynamic>>('email/verification-notification');
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not resend email verification OTP.',
      );
    }
  }

  // OTP-named aliases for newer callers.
  Future<EmailVerificationStatus> getOtpVerificationStatus() =>
      getEmailVerificationStatus();
  Future<EmailVerificationStatus> verifyOtpSigned({
    required String userId,
    required String hash,
    Map<String, String> queryParameters = const {},
  }) => verifyEmailSigned(
    userId: userId,
    hash: hash,
    queryParameters: queryParameters,
  );
  Future<void> resendOtpVerification() => resendVerificationEmail();

  Future<Map<String, dynamic>?> activeTerms({
    String audience = 'member',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'terms-and-conditions/active',
        queryParameters: <String, dynamic>{'audience': audience},
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) return data;
      return null;
    } on DioException catch (e) {
      throw ApiException.fromDioResponse(
        statusCode: e.response?.statusCode,
        data: e.response?.data,
        fallbackMessage: 'Could not load terms.',
      );
    }
  }

  AuthSession _parseAuthSession(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) {
      throw const ApiException(message: 'Empty response from server.');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        message: body['message'] as String? ?? 'Unexpected response.',
      );
    }
    return AuthSession.fromJson(data);
  }
}
