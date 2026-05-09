import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/notifications/one_signal_service.dart';
import '../../../core/providers/secure_token_store_provider.dart';
import '../data/auth_api.dart';
import '../models/current_user_context.dart';
import '../models/pending_two_factor.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

/// Session snapshot after bootstrap or login.
@immutable
class AuthSessionState {
  const AuthSessionState({
    this.hydrated = false,
    this.user,
    this.pendingTwoFactor,
  });

  final bool hydrated;
  final CurrentUserContext? user;
  final PendingTwoFactor? pendingTwoFactor;

  bool get hasMemberAccess => user != null && user!.portalMember;

  bool get needsEmailVerification =>
      hasMemberAccess && user != null && !user!.emailVerified;
}

class AuthSessionNotifier extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() => const AuthSessionState();

  /// Clears user + pending 2FA in memory (token already cleared by interceptor or logout).
  void clearLocalSession() {
    state = const AuthSessionState(hydrated: true);
    _syncPushIdentity(null);
  }

  /// Cold start: if token exists, load `/me` and enforce member portal.
  Future<void> bootstrap() async {
    final token = await ref.read(secureTokenStoreProvider).read();
    if (token == null || token.trim().isEmpty) {
      state = const AuthSessionState(hydrated: true);
      _syncPushIdentity(null);
      return;
    }

    try {
      final me = await ref.read(authApiProvider).getCurrentUser();
      if (!me.portalMember) {
        await ref.read(secureTokenStoreProvider).clear();
        state = const AuthSessionState(hydrated: true);
        return;
      }
      state = AuthSessionState(hydrated: true, user: me);
      _syncPushIdentity(me);
    } on Exception {
      await ref.read(secureTokenStoreProvider).clear();
      state = const AuthSessionState(hydrated: true);
      _syncPushIdentity(null);
    }
  }

  Future<void> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final api = ref.read(authApiProvider);
    final session = await api.login(email: email, password: password);

    if (session.twoFactorRequired && session.challengeId != null) {
      state = AuthSessionState(
        hydrated: true,
        pendingTwoFactor: PendingTwoFactor(
          challengeId: session.challengeId!,
          email: email,
          expiresAt: session.expiresAt,
        ),
      );
      return;
    }

    if (session.token == null || session.token!.isEmpty) {
      throw const ApiException(
        message: 'Login response did not include a token.',
      );
    }

    await ref.read(secureTokenStoreProvider).write(session.token!);
    final me = await api.getCurrentUser();
    if (!me.portalMember) {
      await ref.read(secureTokenStoreProvider).clear();
      throw const ApiException(
        message: 'This account does not have access to the member app.',
      );
    }
    state = AuthSessionState(hydrated: true, user: me);
    _syncPushIdentity(me);
  }

  Future<void> completeTwoFactor({required String code}) async {
    final pending = state.pendingTwoFactor;
    if (pending == null) {
      throw const ApiException(message: 'No two-factor challenge is active.');
    }
    final api = ref.read(authApiProvider);
    final session = await api.verifyTwoFactor(
      challengeId: pending.challengeId,
      code: code,
    );
    if (session.token == null || session.token!.isEmpty) {
      throw const ApiException(
        message: 'Two-factor response did not include a token.',
      );
    }
    await ref.read(secureTokenStoreProvider).write(session.token!);
    final me = await api.getCurrentUser();
    if (!me.portalMember) {
      await ref.read(secureTokenStoreProvider).clear();
      state = const AuthSessionState(hydrated: true);
      throw const ApiException(
        message: 'This account does not have access to the member app.',
      );
    }
    state = AuthSessionState(hydrated: true, user: me);
    _syncPushIdentity(me);
  }

  void abandonTwoFactor() {
    state = const AuthSessionState(hydrated: true);
  }

  Future<void> completeRegistrationOtp({
    required String email,
    required String code,
  }) async {
    final api = ref.read(authApiProvider);
    final session = await api.verifyMemberRegistrationOtp(
      email: email,
      code: code,
    );
    if (session.token == null || session.token!.isEmpty) {
      throw const ApiException(message: 'Verification did not return a token.');
    }
    await ref.read(secureTokenStoreProvider).write(session.token!);
    final me = await api.getCurrentUser();
    if (!me.portalMember) {
      await ref.read(secureTokenStoreProvider).clear();
      throw const ApiException(
        message: 'This account does not have access to the member app.',
      );
    }
    state = AuthSessionState(hydrated: true, user: me);
    _syncPushIdentity(me);
  }

  /// Reload `/me` after email verification or similar.
  Future<void> refreshFromServer() async {
    final token = await ref.read(secureTokenStoreProvider).read();
    if (token == null || token.trim().isEmpty) {
      state = const AuthSessionState(hydrated: true);
      _syncPushIdentity(null);
      return;
    }
    try {
      final me = await ref.read(authApiProvider).getCurrentUser();
      if (!me.portalMember) {
        await ref.read(secureTokenStoreProvider).clear();
        state = const AuthSessionState(hydrated: true);
        return;
      }
      state = AuthSessionState(hydrated: true, user: me);
      _syncPushIdentity(me);
    } on Exception {
      // Keep existing session on transient failure.
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authApiProvider).logout();
    } on Object {
      // ignore
    }
    await ref.read(secureTokenStoreProvider).clear();
    state = const AuthSessionState(hydrated: true);
    _syncPushIdentity(null);
  }

  void _syncPushIdentity(CurrentUserContext? me) {
    final push = ref.read(oneSignalServiceProvider);
    if (me == null) {
      Future<void>(() => push.logout());
      return;
    }
    Future<void>(() => push.loginForUser(me.user.id));
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSessionState>(
      AuthSessionNotifier.new,
    );
