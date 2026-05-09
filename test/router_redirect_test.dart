import 'package:flutter_test/flutter_test.dart';

import 'package:repronig_mobile/app/router.dart';
import 'package:repronig_mobile/features/auth/models/current_user_context.dart';
import 'package:repronig_mobile/features/auth/models/pending_two_factor.dart';
import 'package:repronig_mobile/features/auth/providers/auth_session_provider.dart';
import 'package:repronig_mobile/features/auth/screens/login_screen.dart';
import 'package:repronig_mobile/features/auth/screens/two_factor_screen.dart';
import 'package:repronig_mobile/features/auth/screens/verify_email_screen.dart';
import 'package:repronig_mobile/features/shell/member_paths.dart';
import 'package:repronig_mobile/features/splash/splash_screen.dart';

CurrentUserContext _buildUserContext({
  required bool portalMember,
  required bool emailVerified,
}) {
  return CurrentUserContext.fromJson({
    'user': {
      'id': 1,
      'name': 'Member User',
      'email': 'member@example.com',
    },
    'portal_access': {'member': portalMember},
    'security': {'email_verified': emailVerified},
    'onboarding_status': {'member_approved': true},
  });
}

void main() {
  group('resolveAuthRedirect', () {
    test('keeps unauthenticated splash route while hydrating', () {
      const auth = AuthSessionState(hydrated: false);
      final result = resolveAuthRedirect(auth: auth, location: SplashScreen.routePath);
      expect(result, isNull);
    });

    test('redirects to splash for protected routes while hydrating', () {
      const auth = AuthSessionState(hydrated: false);
      final result = resolveAuthRedirect(auth: auth, location: MemberPaths.home);
      expect(result, SplashScreen.routePath);
    });

    test('forces two-factor route when challenge is pending', () {
      const auth = AuthSessionState(
        hydrated: true,
        pendingTwoFactor: PendingTwoFactor(
          challengeId: 42,
          email: 'member@example.com',
        ),
      );
      final result = resolveAuthRedirect(auth: auth, location: MemberPaths.home);
      expect(result, TwoFactorScreen.routePath);
    });

    test('redirects unauthenticated member-area access to login', () {
      const auth = AuthSessionState(hydrated: true);
      final result = resolveAuthRedirect(auth: auth, location: MemberPaths.home);
      expect(result, LoginScreen.routePath);
    });

    test('redirects authenticated unverified member to verify-email', () {
      final auth = AuthSessionState(
        hydrated: true,
        user: _buildUserContext(portalMember: true, emailVerified: false),
      );
      final result = resolveAuthRedirect(auth: auth, location: MemberPaths.home);
      expect(result, VerifyEmailPaths.screen);
    });

    test('allows verified member to stay on member route', () {
      final auth = AuthSessionState(
        hydrated: true,
        user: _buildUserContext(portalMember: true, emailVerified: true),
      );
      final result = resolveAuthRedirect(auth: auth, location: MemberPaths.home);
      expect(result, isNull);
    });

    test('redirects verified member away from verify-email page', () {
      final auth = AuthSessionState(
        hydrated: true,
        user: _buildUserContext(portalMember: true, emailVerified: true),
      );
      final result = resolveAuthRedirect(auth: auth, location: VerifyEmailScreen.routePath);
      expect(result, MemberPaths.home);
    });
  });
}
