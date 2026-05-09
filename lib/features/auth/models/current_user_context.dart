import 'user_resource.dart';

/// Subset of `/me` payload used for routing and headers; full JSON kept in [raw].
class CurrentUserContext {
  CurrentUserContext._(this.raw, this.user);

  factory CurrentUserContext.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'];
    final user = userMap is Map<String, dynamic>
        ? UserResource.fromJson(userMap)
        : UserResource(id: 0, name: '', email: '');
    return CurrentUserContext._(Map<String, dynamic>.from(json), user);
  }

  final Map<String, dynamic> raw;
  final UserResource user;

  bool get portalMember {
    final access = raw['portal_access'];
    if (access is! Map<String, dynamic>) return false;
    return access['member'] == true;
  }

  bool get emailVerified {
    final sec = raw['security'];
    if (sec is! Map<String, dynamic>) return false;
    return sec['email_verified'] == true;
  }

  /// From `onboarding_status.member_approved` (approved member can register works).
  bool get memberApproved {
    final ob = raw['onboarding_status'];
    if (ob is! Map<String, dynamic>) return false;
    return ob['member_approved'] == true;
  }
}
