class UserResource {
  const UserResource({
    required this.id,
    required this.name,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
  });

  factory UserResource.fromJson(Map<String, dynamic> json) {
    return UserResource(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final int id;
  final String name;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarUrl;
}
