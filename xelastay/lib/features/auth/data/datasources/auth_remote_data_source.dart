import '../../../../core/network/api_client.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  Future<Map<String, dynamic>> signIn(String email, String password) =>
      _apiClient.post('/auth/login', body: {'email': email, 'password': password});

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) => _apiClient.post('/auth/register', body: {
    'name': name,
    'email': email,
    'password': password,
    if (phone != null && phone.isNotEmpty) 'phone': phone,
    'role': 'guest',
  });

  Future<Map<String, dynamic>> getMe(String token) =>
      _apiClient.get('/auth/me', token: token);

  Future<Map<String, dynamic>> becomeHost(String token) =>
      _apiClient.post('/auth/become-host', token: token);
}
