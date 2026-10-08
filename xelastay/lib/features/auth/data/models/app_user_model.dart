import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.phone,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    final role = switch (json['role']?.toString()) {
      'host' => AppRole.host,
      'admin' => AppRole.admin,
      _ => AppRole.guest,
    };
    return AppUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Usuario XelaStay',
      email: json['email']?.toString() ?? '',
      role: role,
      phone: json['phone']?.toString(),
    );
  }
}

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.accessToken, required super.user});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic> || json['token'] == null) {
      throw const FormatException('La API devolvió una sesión incompleta.');
    }
    return AuthSessionModel(
      accessToken: json['token'].toString(),
      user: AppUserModel.fromJson(userJson),
    );
  }
}
