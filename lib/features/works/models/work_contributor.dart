/// `WorkContributorResource` from `GET/PATCH /works/:id` (nested `contributors`).
class WorkContributor {
  const WorkContributor({
    required this.id,
    this.memberId,
    required this.contributorName,
    required this.contributorRole,
    required this.rightType,
    required this.ownershipPercentage,
    this.territoryScope,
  });

  final int id;
  final int? memberId;
  final String contributorName;
  final String contributorRole;
  final String rightType;
  final double ownershipPercentage;
  final String? territoryScope;

  factory WorkContributor.fromJson(Map<String, dynamic> json) {
    final pct = json['ownership_percentage'];
    double p;
    if (pct is num) {
      p = pct.toDouble();
    } else if (pct is String) {
      p = double.tryParse(pct) ?? 0;
    } else {
      p = 0;
    }
    return WorkContributor(
      id: (json['id'] as num).toInt(),
      memberId: (json['member_id'] as num?)?.toInt(),
      contributorName: (json['contributor_name'] as String?)?.trim() ?? '',
      contributorRole: (json['contributor_role'] as String?)?.trim() ?? '',
      rightType: (json['right_type'] as String?)?.trim() ?? 'exclusive',
      ownershipPercentage: p,
      territoryScope: json['territory_scope'] as String?,
    );
  }

  Map<String, dynamic> toApiPayload() {
    return <String, dynamic>{
      if (memberId != null) 'member_id': memberId,
      'contributor_name': contributorName,
      'contributor_role': contributorRole,
      'right_type': rightType,
      'ownership_percentage': ownershipPercentage,
      if (territoryScope != null && territoryScope!.trim().isNotEmpty)
        'territory_scope': territoryScope!.trim(),
    };
  }
}

/// Local row while editing (new or existing contributor).
class WorkContributorDraft {
  WorkContributorDraft({
    required this.key,
    this.existingId,
    this.memberId,
    required this.contributorName,
    required this.contributorRole,
    required this.rightType,
    required this.ownershipPercentage,
    required this.territoryScope,
  });

  final String key;
  final int? existingId;
  final int? memberId;
  final String contributorName;
  final String contributorRole;
  final String rightType;
  final double ownershipPercentage;
  final String territoryScope;

  Map<String, dynamic> toApiPayload() {
    return <String, dynamic>{
      if (memberId != null) 'member_id': memberId,
      'contributor_name': contributorName.trim(),
      'contributor_role': contributorRole.trim(),
      'right_type': rightType,
      'ownership_percentage': ownershipPercentage,
      if (territoryScope.trim().isNotEmpty) 'territory_scope': territoryScope.trim(),
    };
  }

  factory WorkContributorDraft.fromContributor(WorkContributor c) {
    return WorkContributorDraft(
      key: 'existing-${c.id}',
      existingId: c.id,
      memberId: c.memberId,
      contributorName: c.contributorName,
      contributorRole: c.contributorRole,
      rightType: c.rightType == 'non_exclusive' ? 'non_exclusive' : 'exclusive',
      ownershipPercentage: c.ownershipPercentage,
      territoryScope: c.territoryScope ?? '',
    );
  }
}
