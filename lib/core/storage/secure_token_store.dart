import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

/// Minimal secure persistence for the Sanctum bearer token.
class SecureTokenStore {
  SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: StorageKeys.accessToken);

  Future<void> write(String token) =>
      _storage.write(key: StorageKeys.accessToken, value: token);

  Future<void> clear() => _storage.delete(key: StorageKeys.accessToken);
}
