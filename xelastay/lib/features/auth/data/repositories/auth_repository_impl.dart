import '../../../../core/network/api_client.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.remote, required this.local});

  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  @override
  Future<AuthSession> signIn({required String email, required String password}) async {
    final session = AuthSessionModel.fromJson(await remote.signIn(email, password));
    await local.saveToken(session.accessToken);
    return session;
  }

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final session = AuthSessionModel.fromJson(await remote.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    ));
    await local.saveToken(session.accessToken);
    return session;
  }

  @override
  Future<AppUser?> restoreSession() async {
    final token = await local.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await remote.getMe(token);
      final userJson = response['user'];
      if (userJson is! Map<String, dynamic>) {
        throw const FormatException('La API devolvió un perfil incompleto.');
      }
      return AppUserModel.fromJson(userJson);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await local.clearToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AppUser> becomeHost() async {
    final token = await local.readToken();
    if (token == null) throw const ApiException(
      statusCode: 401,
      code: 'SESSION_REQUIRED',
      message: 'Inicia sesión para activar tu perfil de anfitrión.',
    );
    final response = await remote.becomeHost(token);
    final userJson = response['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('La API devolvió un perfil de anfitrión incompleto.');
    }
    final newToken = response['token']?.toString();
    if (newToken != null && newToken.isNotEmpty) await local.saveToken(newToken);
    return AppUserModel.fromJson(userJson);
  }

  @override
  Future<void> signOut() => local.clearToken();
}
