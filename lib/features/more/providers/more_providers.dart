import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/more_api.dart';

final moreApiProvider = Provider<MoreApi>((ref) {
  return MoreApi(ref.watch(dioProvider));
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.read(moreApiProvider).unreadNotificationCount();
});
