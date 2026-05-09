import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_session_provider.dart';
import '../features/auth/screens/confirm_otp_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/two_factor_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/home/member_dashboard_screen.dart';
import '../features/member_application/screens/member_application_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/more/screens/account_settings_screen.dart';
import '../features/more/screens/member_notifications_screen.dart';
import '../features/more/screens/member_profile_screen.dart';
import '../features/shell/member_more_screen.dart';
import '../features/works/screens/member_works_screen.dart';
import '../features/works/screens/work_detail_screen.dart';
import '../features/works/screens/work_editor_screen.dart';
import '../features/activity/screens/member_activity_screen.dart';
import '../features/shell/member_paths.dart';
import '../features/shell/member_shell_scaffold.dart';
import '../features/splash/splash_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

bool _isGuestAuthRoute(String loc) {
  const routes = <String>{
    SplashScreen.routePath,
    OnboardingScreen.routePath,
    LoginScreen.routePath,
    RegisterScreen.routePath,
    ConfirmOtpScreen.routePath,
    TwoFactorScreen.routePath,
    ForgotPasswordScreen.routePath,
    ResetPasswordScreen.routePath,
  };
  return routes.contains(loc);
}

bool _isMemberAreaPath(String loc) =>
    MemberPaths.shellPaths.contains(loc) ||
    loc == '/member' ||
    loc.startsWith('/member/');

String? resolveAuthRedirect({
  required AuthSessionState auth,
  required String location,
}) {
  if (!auth.hydrated) {
    return location == SplashScreen.routePath ? null : SplashScreen.routePath;
  }

  if (auth.hydrated && location == SplashScreen.routePath) {
    if (auth.pendingTwoFactor != null) {
      return TwoFactorScreen.routePath;
    }
    if (!auth.hasMemberAccess) {
      return null;
    }
    return MemberPaths.afterAuth(emailVerified: auth.user!.emailVerified);
  }

  if (auth.pendingTwoFactor != null) {
    if (location == TwoFactorScreen.routePath) {
      return null;
    }
    return TwoFactorScreen.routePath;
  }

  if (!auth.hasMemberAccess) {
    if (VerifyEmailPaths.isVerifyRoute(location)) {
      return LoginScreen.routePath;
    }
    if (_isMemberAreaPath(location) || location == '/home') {
      return LoginScreen.routePath;
    }
    return null;
  }

  if (auth.needsEmailVerification) {
    if (VerifyEmailPaths.isVerifyRoute(location)) {
      return null;
    }
    if (_isMemberAreaPath(location) || location == '/home') {
      return VerifyEmailPaths.screen;
    }
    if (_isGuestAuthRoute(location)) {
      return VerifyEmailPaths.screen;
    }
    return null;
  }

  if (VerifyEmailPaths.isVerifyRoute(location)) {
    return MemberPaths.home;
  }
  if (_isGuestAuthRoute(location)) {
    return MemberPaths.home;
  }
  if (location == '/home') {
    return MemberPaths.home;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authSessionProvider, (_, __) {
    refresh.value++;
  });

  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: SplashScreen.routePath,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final auth = ref.read(authSessionProvider);
      return resolveAuthRedirect(auth: auth, location: loc);
    },
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: OnboardingScreen.routePath,
        name: OnboardingScreen.routeName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        name: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.routePath,
        name: RegisterScreen.routeName,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: ConfirmOtpScreen.routePath,
        name: ConfirmOtpScreen.routeName,
        builder: (context, state) {
          final email = state.extra is String ? state.extra! as String : '';
          return ConfirmOtpScreen(initialEmail: email);
        },
      ),
      GoRoute(
        path: TwoFactorScreen.routePath,
        name: TwoFactorScreen.routeName,
        builder: (context, state) => const TwoFactorScreen(),
      ),
      GoRoute(
        path: ForgotPasswordScreen.routePath,
        name: ForgotPasswordScreen.routeName,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: ResetPasswordScreen.routePath,
        name: ResetPasswordScreen.routeName,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: VerifyEmailScreen.routePath,
        name: VerifyEmailScreen.routeName,
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/verify-email/:userId/:hash',
        name: 'verify-email-linked',
        builder: (context, state) {
          final id = state.pathParameters['userId'] ?? '';
          final hash = state.pathParameters['hash'] ?? '';
          return VerifyEmailScreen(
            linkedUserId: id,
            linkedHash: hash,
            signedQuery: Map<String, String>.from(state.uri.queryParameters),
          );
        },
      ),
      GoRoute(
        path: '/member',
        redirect: (context, state) => MemberPaths.home,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MemberShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MemberPaths.home,
                name: MemberDashboardScreen.routeName,
                builder: (context, state) => const MemberDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MemberPaths.application,
                name: MemberApplicationScreen.routeName,
                builder: (context, state) => const MemberApplicationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MemberPaths.works,
                name: MemberWorksScreen.routeName,
                builder: (context, state) => const MemberWorksScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: WorkEditorScreen.routeNameNew,
                    builder: (context, state) => const WorkEditorScreen(),
                  ),
                  GoRoute(
                    path: 'view/:workId',
                    name: WorkDetailScreen.routeName,
                    builder: (context, state) {
                      final id = int.tryParse(
                            state.pathParameters['workId'] ?? '',
                          ) ??
                          0;
                      return WorkDetailScreen(workId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: WorkEditorScreen.routeNameEdit,
                        builder: (context, state) {
                          final id = int.tryParse(
                                state.pathParameters['workId'] ?? '',
                              ) ??
                              0;
                          return WorkEditorScreen(workId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MemberPaths.activity,
                name: MemberActivityScreen.routeName,
                builder: (context, state) => const MemberActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MemberPaths.more,
                name: MemberMoreScreen.routeName,
                builder: (context, state) => const MemberMoreScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    name: MemberProfileScreen.routeName,
                    builder: (context, state) => const MemberProfileScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: MemberNotificationsScreen.routeName,
                    builder: (context, state) => const MemberNotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: AccountSettingsScreen.routeName,
                    builder: (context, state) => const AccountSettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
