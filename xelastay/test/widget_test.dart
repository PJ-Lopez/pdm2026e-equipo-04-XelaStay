import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/app.dart';
import 'package:xelastay/features/auth/domain/entities/app_user.dart';
import 'package:xelastay/features/auth/domain/repositories/auth_repository.dart';
import 'package:xelastay/features/auth/domain/usecases/become_host.dart';
import 'package:xelastay/features/auth/domain/usecases/register_account.dart';
import 'package:xelastay/features/auth/domain/usecases/restore_session.dart';
import 'package:xelastay/features/auth/domain/usecases/sign_in.dart';
import 'package:xelastay/features/auth/domain/usecases/sign_out.dart';
import 'package:xelastay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:xelastay/features/auth/presentation/pages/sign_in_page.dart';
import 'package:xelastay/features/hosts/domain/entities/host_stay.dart';
import 'package:xelastay/features/hosts/domain/repositories/hosts_repository.dart';
import 'package:xelastay/features/hosts/domain/usecases/create_host_stay.dart';
import 'package:xelastay/features/stays/domain/entities/stay.dart';
import 'package:xelastay/features/stays/domain/repositories/stays_repository.dart';
import 'package:xelastay/features/stays/domain/usecases/get_public_stays.dart';

void main() {
  testWidgets('Muestra carga y luego acceso cuando no hay sesión', (
    tester,
  ) async {
    final repository = _AuthRepository();
    final controller = AuthController(
      signIn: SignIn(repository),
      register: RegisterAccount(repository),
      restoreSession: RestoreSession(repository),
      becomeHost: BecomeHost(repository),
      signOut: SignOut(repository),
    );

    await tester.pumpWidget(
      XelaStayApp(
        authController: controller,
        createHostStay: CreateHostStay(_HostsRepository()),
        getPublicStays: GetPublicStays(_StaysRepository()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(SignInPage), findsNothing);

    repository.session.complete(null);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SignInPage), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _AuthRepository implements AuthRepository {
  final session = Completer<AppUser?>();

  @override
  Future<AppUser?> restoreSession() => session.future;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError('El arranque no debe iniciar sesión.');

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) => throw UnimplementedError('El arranque no debe registrar cuentas.');

  @override
  Future<AppUser> becomeHost() =>
      throw UnimplementedError('El arranque no debe activar anfitriones.');

  @override
  Future<void> signOut() =>
      throw UnimplementedError('El arranque no debe cerrar sesión.');
}

class _HostsRepository implements HostsRepository {
  @override
  Future<HostStay> createStay(HostStayDraft draft) =>
      throw UnimplementedError('El arranque no debe crear alojamientos.');
}

class _StaysRepository implements StaysRepository {
  @override
  Future<List<Stay>> getPublicStays() =>
      throw UnimplementedError('Sin sesión no debe consultar alojamientos.');
}
