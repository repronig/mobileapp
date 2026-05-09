import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/secure_token_store.dart';

/// Secure persistence for the Sanctum bearer token (injectable in tests).
final secureTokenStoreProvider = Provider<SecureTokenStore>((ref) {
  return SecureTokenStore(const FlutterSecureStorage());
});
