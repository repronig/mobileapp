/// Member slice of `GET /me/dashboard-summary` (`data.member`).
class MemberDashboardSummary {
  const MemberDashboardSummary({
    required this.stats,
    required this.onboardingStatus,
    this.memberProfile,
    this.memberApplication,
    this.profileCompleteness,
    required this.recentWorks,
    required this.recentSubmissions,
    required this.recentActivity,
    required this.pendingActions,
  });

  final MemberDashboardStats stats;
  final OnboardingStatusSummary onboardingStatus;
  final MemberProfileBrief? memberProfile;
  final MemberApplicationBrief? memberApplication;
  final ProfileCompletenessSummary? profileCompleteness;
  final List<DashboardWorkRow> recentWorks;
  final List<DashboardWorkRow> recentSubmissions;
  final List<DashboardActivityItem> recentActivity;
  final List<PendingDashboardAction> pendingActions;

  factory MemberDashboardSummary.fromJson(Map<String, dynamic> json) {
    final statsMap = json['stats'];
    final stats = statsMap is Map<String, dynamic>
        ? MemberDashboardStats.fromJson(statsMap)
        : const MemberDashboardStats(
            totalWorks: 0,
            draftWorks: 0,
            submittedWorks: 0,
            verifiedWorks: 0,
            approvedWorks: 0,
          );

    final onboardMap = json['onboarding_status'];
    final onboarding = onboardMap is Map<String, dynamic>
        ? OnboardingStatusSummary.fromJson(onboardMap)
        : const OnboardingStatusSummary(
            applicationStatus: null,
            submissionStage: null,
            approvedMember: false,
          );

    final mp = json['member_profile'];
    final ma = json['member_application'];
    final pc = json['profile_completeness'];

    return MemberDashboardSummary(
      stats: stats,
      onboardingStatus: onboarding,
      memberProfile: mp is Map<String, dynamic>
          ? MemberProfileBrief.fromJson(mp)
          : null,
      memberApplication: ma is Map<String, dynamic>
          ? MemberApplicationBrief.fromJson(ma)
          : null,
      profileCompleteness: pc is Map<String, dynamic>
          ? ProfileCompletenessSummary.fromJson(pc)
          : null,
      recentWorks: _parseWorkList(json['recent_works']),
      recentSubmissions: _parseWorkList(json['recent_submissions']),
      recentActivity: _parseActivityList(json['recent_activity']),
      pendingActions: _parsePendingList(json['pending_actions']),
    );
  }

  static List<DashboardWorkRow> _parseWorkList(Object? raw) {
    if (raw is! List<dynamic>) return [];
    return raw
        .map((e) => DashboardWorkRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static List<DashboardActivityItem> _parseActivityList(Object? raw) {
    if (raw is! List<dynamic>) return [];
    return raw
        .map(
          (e) =>
              DashboardActivityItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  static List<PendingDashboardAction> _parsePendingList(Object? raw) {
    if (raw is! List<dynamic>) return [];
    return raw
        .map(
          (e) =>
              PendingDashboardAction.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}

class MemberDashboardStats {
  const MemberDashboardStats({
    required this.totalWorks,
    required this.draftWorks,
    required this.submittedWorks,
    required this.verifiedWorks,
    required this.approvedWorks,
  });

  final int totalWorks;
  final int draftWorks;
  final int submittedWorks;
  final int verifiedWorks;
  final int approvedWorks;

  factory MemberDashboardStats.fromJson(Map<String, dynamic> json) {
    return MemberDashboardStats(
      totalWorks: _int(json['total_works']),
      draftWorks: _int(json['draft_works']),
      submittedWorks: _int(json['submitted_works']),
      verifiedWorks: _int(json['verified_works']),
      approvedWorks: _int(json['approved_works'] ?? json['verified_works']),
    );
  }
}

class OnboardingStatusSummary {
  const OnboardingStatusSummary({
    required this.applicationStatus,
    required this.submissionStage,
    required this.approvedMember,
  });

  final String? applicationStatus;
  final String? submissionStage;
  final bool approvedMember;

  factory OnboardingStatusSummary.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusSummary(
      applicationStatus: json['application_status'] as String?,
      submissionStage: json['submission_stage'] as String?,
      approvedMember: json['approved_member'] == true,
    );
  }
}

class MemberProfileBrief {
  const MemberProfileBrief({this.approvalStatus});

  final String? approvalStatus;

  factory MemberProfileBrief.fromJson(Map<String, dynamic> json) {
    return MemberProfileBrief(approvalStatus: json['approval_status'] as String?);
  }
}

class MemberApplicationBrief {
  const MemberApplicationBrief({
    this.applicationStatus,
    this.submissionStage,
  });

  final String? applicationStatus;
  final String? submissionStage;

  factory MemberApplicationBrief.fromJson(Map<String, dynamic> json) {
    return MemberApplicationBrief(
      applicationStatus: json['application_status'] as String?,
      submissionStage: json['submission_stage'] as String?,
    );
  }
}

class ProfileCompletenessSummary {
  const ProfileCompletenessSummary({
    required this.completedFields,
    required this.totalFields,
    required this.percentage,
    required this.isComplete,
    required this.missingFields,
  });

  final int completedFields;
  final int totalFields;
  final int percentage;
  final bool isComplete;
  final List<String> missingFields;

  factory ProfileCompletenessSummary.fromJson(Map<String, dynamic> json) {
    final missing = json['missing_fields'];
    return ProfileCompletenessSummary(
      completedFields: _int(json['completed_fields']),
      totalFields: _int(json['total_fields']),
      percentage: _int(json['percentage']),
      isComplete: json['is_complete'] == true,
      missingFields: missing is List<dynamic>
          ? missing.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class DashboardWorkRow {
  const DashboardWorkRow({
    required this.id,
    required this.title,
    this.subtitle,
    this.publisherName,
    this.typeOfWork,
    this.workStatus,
    this.verificationStatus,
    this.referenceNumber,
    this.submittedAt,
  });

  final int id;
  final String title;
  final String? subtitle;
  final String? publisherName;
  final String? typeOfWork;
  final String? workStatus;
  final String? verificationStatus;
  final String? referenceNumber;
  final String? submittedAt;

  factory DashboardWorkRow.fromJson(Map<String, dynamic> json) {
    return DashboardWorkRow(
      id: _int(json['id']),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Untitled work',
      subtitle: json['subtitle'] as String?,
      publisherName: json['publisher_name'] as String?,
      typeOfWork: json['type_of_work'] as String?,
      workStatus: json['work_status'] as String?,
      verificationStatus: json['verification_status'] as String?,
      referenceNumber: json['reference_number'] as String?,
      submittedAt: _isoString(json['submitted_at']),
    );
  }

  String get secondaryLine =>
      publisherName?.trim().isNotEmpty == true
          ? publisherName!
          : (typeOfWork?.replaceAll('_', ' ') ?? 'Work record');
}

class DashboardActivityItem {
  const DashboardActivityItem({
    required this.id,
    required this.action,
    this.subjectType,
    this.subjectId,
    this.createdAt,
    this.actorName,
  });

  final int id;
  final String action;
  final String? subjectType;
  final int? subjectId;
  final String? createdAt;
  final String? actorName;

  factory DashboardActivityItem.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'];
    String? actorName;
    if (actor is Map<String, dynamic>) {
      actorName = actor['name'] as String?;
    }
    return DashboardActivityItem(
      id: _int(json['id']),
      action: (json['action'] as String?) ?? '—',
      subjectType: json['subject_type'] as String?,
      subjectId: json['subject_id'] is int
          ? json['subject_id'] as int
          : int.tryParse('${json['subject_id']}'),
      createdAt: _isoString(json['created_at']),
      actorName: actorName,
    );
  }
}

class PendingDashboardAction {
  const PendingDashboardAction({
    required this.key,
    required this.label,
    required this.description,
    required this.priority,
    this.missingFields,
  });

  final String key;
  final String label;
  final String description;
  final PendingPriority priority;
  final List<String>? missingFields;

  factory PendingDashboardAction.fromJson(Map<String, dynamic> json) {
    final mf = json['missing_fields'];
    return PendingDashboardAction(
      key: (json['key'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      priority: PendingPriority.parse(json['priority'] as String?),
      missingFields: mf is List<dynamic>
          ? mf.map((e) => e.toString()).toList()
          : null,
    );
  }
}

enum PendingPriority {
  high,
  medium,
  low;

  static PendingPriority parse(String? raw) {
    switch (raw) {
      case 'high':
        return PendingPriority.high;
      case 'low':
        return PendingPriority.low;
      default:
        return PendingPriority.medium;
    }
  }
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String? _isoString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}
