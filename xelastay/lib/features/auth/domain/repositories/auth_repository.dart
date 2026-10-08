import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  });

  Future<AppUser?> restoreSession();

  Future<AppUser> becomeHost();

  Future<void> signOut();
}
