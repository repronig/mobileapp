/// Email verification routes (via OTP).
abstract final class VerifyEmailPaths {
  static const screen = '/verify-email';
  static const linkedPrefix = '/verify-email/';

  static bool isVerifyRoute(String loc) {
    if (loc == screen) return true;
    if (!loc.startsWith(linkedPrefix)) return false;
    final parts = loc.split('/').where((s) => s.isNotEmpty).toList();
    return parts.length >= 3;
  }
}

/// Member app shell routes (Pass 2+). Application: Pass 4. Works: Pass 5. Activity: Pass 6. More subpages: Pass 7. Dashboard links: Pass 8.
abstract final class MemberPaths {
  static const home = '/member/home';
  static const application = '/member/application';
  static const works = '/member/works';
  static const activity = '/member/activity';
  static const more = '/member/more';
  static const moreProfile = '$more/profile';
  static const moreNotifications = '$more/notifications';
  static const moreSettings = '$more/settings';

  static String afterAuth({required bool emailVerified}) =>
      emailVerified ? home : VerifyEmailPaths.screen;

  static const shellPaths = <String>{
    home,
    application,
    works,
    activity,
    more,
  };
}

// Backward-compatible alias.
abstract final class VerifyOtpPaths {
  static const screen = VerifyEmailPaths.screen;
  static const linkedPrefix = VerifyEmailPaths.linkedPrefix;
  static bool isVerifyRoute(String loc) => VerifyEmailPaths.isVerifyRoute(loc);
}
