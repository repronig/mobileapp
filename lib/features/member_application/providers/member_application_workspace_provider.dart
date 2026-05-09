import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../auth/models/public_association.dart';
import '../../auth/providers/auth_session_provider.dart' show authApiProvider;
import '../data/member_application_api.dart';
import '../models/member_application_detail.dart';

final memberApplicationApiProvider = Provider<MemberApplicationApi>((ref) {
  return MemberApplicationApi(ref.watch(dioProvider));
});

/// Associations list + current `member-applications/me` (Pass 4).
class MemberApplicationWorkspace {
  const MemberApplicationWorkspace({
    required this.associations,
    required this.application,
  });

  final List<PublicAssociation> associations;
  final MemberApplicationDetail? application;
}

final memberApplicationWorkspaceProvider =
    FutureProvider.autoDispose<MemberApplicationWorkspace>((ref) async {
      final authApi = ref.read(authApiProvider);
      final memberApi = ref.read(memberApplicationApiProvider);
      final associations = await authApi.listAssociations(perPage: 100);
      final application = await memberApi.fetchMyApplication();
      return MemberApplicationWorkspace(
        associations: associations,
        application: application,
      );
    });
