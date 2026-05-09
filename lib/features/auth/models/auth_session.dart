import 'user_resource.dart';

/// Matches `AuthSession` from the web app (`auth.ts`).
class AuthSession {
  const AuthSession({
    required this.twoFactorRequired,
    required this.challengeId,
    required this.expiresAt,
    required this.token,
    required this.tokenType,
    this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return AuthSession(
      twoFactorRequired: json['two_factor_required'] == true,
      challengeId: (json['challenge_id'] as num?)?.toInt(),
      expiresAt: json['expires_at'] as String?,
      token: json['token'] as String?,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      user: userRaw is Map<String, dynamic>
          ? UserResource.fromJson(userRaw)
          : null,
    );
  }

  final bool twoFactorRequired;
  final int? challengeId;
  final String? expiresAt;
  final String? token;
  final String tokenType;
  final UserResource? user;
}
