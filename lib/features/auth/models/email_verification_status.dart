class EmailVerificationStatus {
  const EmailVerificationStatus({
    required this.emailVerified,
    this.email,
  });

  factory EmailVerificationStatus.fromJson(Map<String, dynamic> json) {
    return EmailVerificationStatus(
      emailVerified: json['email_verified'] == true,
      email: json['email'] as String?,
    );
  }

  final bool emailVerified;
  final String? email;
}
