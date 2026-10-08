enum AppRole { guest, host, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final AppRole role;
  final String? phone;

  bool get canManageStays => role == AppRole.host || role == AppRole.admin;
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final AppUser user;
}
