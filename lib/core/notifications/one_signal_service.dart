import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../config/env.dart';

final oneSignalServiceProvider = Provider<OneSignalService>((ref) {
  return OneSignalService();
});

class OneSignalService {
  bool _initialized = false;

  bool get _enabled => Env.oneSignalAppId.trim().isNotEmpty;

  Future<void> ensureInitialized() async {
    if (!_enabled || _initialized) return;
    OneSignal.initialize(Env.oneSignalAppId.trim());
    await OneSignal.Notifications.requestPermission(false);
    _initialized = true;
  }

  Future<void> loginForUser(int userId) async {
    if (!_enabled) return;
    await ensureInitialized();
    OneSignal.login('user-$userId');
  }

  Future<void> logout() async {
    if (!_enabled || !_initialized) return;
    OneSignal.logout();
  }
}

