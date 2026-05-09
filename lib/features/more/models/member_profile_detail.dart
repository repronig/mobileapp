/// Parsed `MemberProfileResource` from `GET member/profile`.
class MemberProfileDetail {
  const MemberProfileDetail({
    this.memberId,
    this.memberCode,
    this.approvalStatus,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.associationName,
    this.dateOfBirth,
    this.occupation,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.publisherName,
    this.corporateName,
    this.memberProvidedId,
  });

  final int? memberId;
  final String? memberCode;
  final String? approvalStatus;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? associationName;
  final String? dateOfBirth;
  final String? occupation;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? publisherName;
  final String? corporateName;
  final String? memberProvidedId;

  factory MemberProfileDetail.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String first = '';
    String last = '';
    String email = '';
    String? phone;
    if (user is Map<String, dynamic>) {
      first = user['first_name'] as String? ?? '';
      last = user['last_name'] as String? ?? '';
      email = user['email'] as String? ?? '';
      phone = user['phone'] as String?;
      if (first.isEmpty && last.isEmpty) {
        final name = user['name'] as String? ?? '';
        final parts = name.trim().split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          first = parts.first;
          if (parts.length > 1) last = parts.sublist(1).join(' ');
        }
      }
    }

    final assoc = json['association'];
    String? assocName;
    if (assoc is Map<String, dynamic>) {
      assocName = assoc['name'] as String?;
    }

    final profile = json['profile'];
    String? dob;
    String? occupation;
    String? a1;
    String? a2;
    String? city;
    String? state;
    String? country;
    String? postal;
    String? pubName;
    String? corpName;
    if (profile is Map<String, dynamic>) {
      dob = profile['date_of_birth'] as String?;
      occupation = profile['occupation'] as String?;
      a1 = profile['residential_address_line_1'] as String?;
      a2 = profile['residential_address_line_2'] as String?;
      city = profile['city'] as String?;
      state = profile['state'] as String?;
      country = profile['country'] as String?;
      postal = profile['postal_code'] as String?;
      pubName = profile['publisher_name'] as String?;
      corpName = profile['corporate_name'] as String?;
    }

    return MemberProfileDetail(
      memberId: (json['member_id'] as num?)?.toInt(),
      memberCode: json['member_code'] as String?,
      approvalStatus: json['approval_status'] as String?,
      firstName: first,
      lastName: last,
      email: email,
      phone: phone,
      associationName: assocName,
      dateOfBirth: dob,
      occupation: occupation,
      addressLine1: a1,
      addressLine2: a2,
      city: city,
      state: state,
      country: country,
      postalCode: postal,
      publisherName: pubName,
      corporateName: corpName,
      memberProvidedId: json['member_provided_id'] as String?,
    );
  }
}
