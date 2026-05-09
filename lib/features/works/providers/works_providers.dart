import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/works_api.dart';
import '../models/member_work.dart';

final worksApiProvider = Provider<WorksApi>((ref) {
  return WorksApi(ref.watch(dioProvider));
});

final workDetailProvider =
    FutureProvider.autoDispose.family<MemberWork, int>((ref, workId) async {
      return ref.read(worksApiProvider).getWork(workId);
    });
