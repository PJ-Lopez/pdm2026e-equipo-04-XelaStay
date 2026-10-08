import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class RegisterAccount {
  const RegisterAccount(this._repository);
  final AuthRepository _repository;

  Future<AuthSession> call({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) => _repository.register(
    name: name.trim(),
    email: email.trim(),
    password: password,
    phone: phone?.trim(),
  );
}
