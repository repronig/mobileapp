import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../providers/secure_token_store_provider.dart';
import '../../features/auth/providers/auth_session_provider.dart';

/// Shared [Dio] for the REPRONIG API: JSON base URL, bearer token, 401 session clear.
///
/// Lives under `core/network` so feature APIs only depend on [dioProvider], not auth internals.
final dioProvider = Provider<Dio>((ref) {
  final base = Env.apiBaseUrl.endsWith('/')
      ? Env.apiBaseUrl
      : '${Env.apiBaseUrl}/';
  final dio = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 45),
      headers: <String, dynamic>{Headers.acceptHeader: 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(secureTokenStoreProvider).read();
        if (token != null && token.trim().isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          final path = error.requestOptions.uri.path;
          const suffixes = <String>[
            '/auth/login',
            '/auth/register-member',
            '/auth/member-registration/verify-otp',
            '/auth/member-registration/resend-otp',
            '/auth/two-factor/verify',
            '/auth/forgot-password',
            '/auth/reset-password',
            '/auth/verify-reset-token',
          ];
          final isPublicAuth = suffixes.any(path.endsWith);
          if (!isPublicAuth) {
            await ref.read(secureTokenStoreProvider).clear();
            ref.read(authSessionProvider.notifier).clearLocalSession();
          }
        }
        return handler.next(error);
      },
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});
