import 'package:flutter_test/flutter_test.dart';

import 'package:repronig_mobile/features/auth/models/current_user_context.dart';
import 'package:repronig_mobile/features/dashboard/models/member_dashboard_summary.dart';
import 'package:repronig_mobile/features/member_application/models/member_application_detail.dart';
import 'package:repronig_mobile/features/works/models/member_work.dart';

void main() {
  group('CurrentUserContext (/me data)', () {
    test('parses member portal user with security and onboarding', () {
      final ctx = CurrentUserContext.fromJson(_mePayload);
      expect(ctx.user.id, 42);
      expect(ctx.user.email, 'member@example.com');
      expect(ctx.portalMember, isTrue);
      expect(ctx.emailVerified, isTrue);
      expect(ctx.memberApproved, isTrue);
    });

    test('treats missing portal_access as non-member', () {
      final ctx = CurrentUserContext.fromJson({
        'user': {'id': 1, 'name': 'X', 'email': 'x@y.com'},
      });
      expect(ctx.portalMember, isFalse);
    });
  });

  group('MemberDashboardSummary (data.member)', () {
    test('parses stats, lists, and pending actions', () {
      final summary = MemberDashboardSummary.fromJson(_dashboardMemberPayload);
      expect(summary.stats.totalWorks, 3);
      expect(summary.stats.draftWorks, 1);
      expect(summary.onboardingStatus.applicationStatus, 'approved');
      expect(summary.recentWorks, hasLength(1));
      expect(summary.recentWorks.first.title, 'My Song');
      expect(summary.recentActivity, hasLength(1));
      expect(summary.recentActivity.first.action, 'work.submitted');
      expect(summary.pendingActions, hasLength(1));
      expect(summary.pendingActions.first.key, 'complete_profile');
      expect(summary.pendingActions.first.priority, PendingPriority.high);
    });

    test('defaults missing stats and lists to safe empty values', () {
      final summary = MemberDashboardSummary.fromJson(<String, dynamic>{});
      expect(summary.stats.totalWorks, 0);
      expect(summary.recentWorks, isEmpty);
      expect(summary.recentActivity, isEmpty);
      expect(summary.pendingActions, isEmpty);
    });
  });

  group('MemberWork (works list/detail)', () {
    test('parses core fields and contributors', () {
      final w = MemberWork.fromJson(_workPayload);
      expect(w.id, 100);
      expect(w.title, 'Licensed Work');
      expect(w.workStatus, 'draft');
      expect(w.contributors, hasLength(1));
      expect(w.contributors.first.contributorRole, 'author');
      expect(w.filesCount, 2);
    });

    test('uses Untitled work when title blank', () {
      final w = MemberWork.fromJson({
        'id': 1,
        'title': '   ',
        'work_status': 'draft',
      });
      expect(w.title, 'Untitled work');
    });
  });

  group('MemberApplicationDetail (member-applications/me)', () {
    test('parses application with association and documents', () {
      final d = MemberApplicationDetail.fromJson(_applicationPayload);
      expect(d.id, 7);
      expect(d.applicationStatus, 'draft');
      expect(d.applicantType, 'author');
      expect(d.association?.id, 3);
      expect(d.association?.name, 'COSON');
      expect(d.documents, hasLength(1));
      expect(d.documents.first.documentType, 'proof_of_id');
      expect(d.hasProofOfId, isTrue);
    });
  });
}

/// Minimal `/me`-shaped envelope `data` object (as returned inside API success body).
final Map<String, dynamic> _mePayload = {
  'user': {
    'id': 42,
    'name': 'Ada Lovelace',
    'email': 'member@example.com',
    'first_name': 'Ada',
    'last_name': 'Lovelace',
  },
  'portal_access': {'member': true},
  'security': {'email_verified': true},
  'onboarding_status': {'member_approved': true},
};

/// `GET /me/dashboard-summary` → `data.member` slice.
final Map<String, dynamic> _dashboardMemberPayload = {
  'stats': {
    'total_works': 3,
    'draft_works': 1,
    'submitted_works': 1,
    'verified_works': 1,
  },
  'onboarding_status': {
    'application_status': 'approved',
    'submission_stage': null,
    'approved_member': true,
  },
  'recent_works': [
    {
      'id': 10,
      'title': 'My Song',
      'work_status': 'submitted',
      'publisher_name': 'Test Publisher',
    },
  ],
  'recent_submissions': [],
  'recent_activity': [
    {
      'id': 1,
      'action': 'work.submitted',
      'subject_type': 'work',
      'subject_id': 10,
      'created_at': '2025-01-15T10:00:00Z',
      'actor': {'name': 'Ada'},
    },
  ],
  'pending_actions': [
    {
      'key': 'complete_profile',
      'label': 'Complete profile',
      'description': 'Add missing fields',
      'priority': 'high',
    },
  ],
};

final Map<String, dynamic> _workPayload = {
  'id': 100,
  'title': 'Licensed Work',
  'work_status': 'draft',
  'contributors': [
    {
      'id': 1,
      'contributor_role': 'author',
      'contributor_name': 'Ada',
      'right_type': 'exclusive',
      'ownership_percentage': 100,
    },
  ],
  'files': [
    {'id': 1},
    {'id': 2},
  ],
};

final Map<String, dynamic> _applicationPayload = {
  'id': 7,
  'application_status': 'draft',
  'applicant_type': 'author',
  'consent_accepted': true,
  'association': {'id': 3, 'name': 'COSON'},
  'documents': [
    {
      'id': 1,
      'document_type': 'proof_of_id',
      'file_name': 'id.pdf',
    },
  ],
};
