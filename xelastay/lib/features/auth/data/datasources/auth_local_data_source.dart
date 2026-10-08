import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  static const _tokenKey = 'xelastay_access_token';
  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
