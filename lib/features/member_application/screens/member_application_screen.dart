import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/member_async_value_body.dart';
import '../../../widgets/member_brand_app_bar.dart';
import '../../auth/providers/auth_session_provider.dart';
import '../providers/member_application_workspace_provider.dart'
    show MemberApplicationWorkspace, memberApplicationWorkspaceProvider;
import '../widgets/member_application_body.dart';

class MemberApplicationScreen extends ConsumerWidget {
  const MemberApplicationScreen({super.key});

  static const routeName = 'member-application';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memberApplicationWorkspaceProvider);

    return Scaffold(
      appBar: const MemberBrandAppBar(title: 'My Mandate'),
      body: MemberAsyncValueBody<MemberApplicationWorkspace>(
        async: async,
        onRetry: () => ref.invalidate(memberApplicationWorkspaceProvider),
        data: (workspace) => MemberApplicationBody(
          key: ValueKey(
            '${workspace.application?.id ?? 0}_${workspace.application?.applicationStatus ?? 'none'}',
          ),
          workspace: workspace,
          user: ref.watch(authSessionProvider).user?.user,
        ),
      ),
    );
  }
}
