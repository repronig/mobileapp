class PendingTwoFactor {
  const PendingTwoFactor({
    required this.challengeId,
    required this.email,
    this.expiresAt,
  });

  final int challengeId;
  final String email;
  final String? expiresAt;
}
