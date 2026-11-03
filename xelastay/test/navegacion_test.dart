import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:xelastay/features/booking/domain/entities/reserva.dart';
import 'package:xelastay/features/booking/domain/repositories/reservas_repository.dart';
import 'package:xelastay/features/booking/presentation/providers/reservas_providers.dart';
import 'package:xelastay/features/hosts/domain/entities/host_stay.dart';
import 'package:xelastay/features/hosts/domain/repositories/hosts_repository.dart';
import 'package:xelastay/features/hosts/domain/usecases/create_host_stay.dart';
import 'package:xelastay/features/listas/domain/entities/lista.dart';
import 'package:xelastay/features/listas/domain/repositories/listas_repository.dart';
import 'package:xelastay/features/listas/presentation/providers/listas_providers.dart';
import 'package:xelastay/features/stays/domain/entities/stay.dart';
import 'package:xelastay/features/stays/domain/repositories/stays_repository.dart';
import 'package:xelastay/features/stays/domain/usecases/get_public_stays.dart';

void main() {
  testWidgets('las pestañas llevan a Explorar, Guardados, Reservas y Perfil', (
    tester,
  ) async {
    final auth = _AuthRepository();
    final controller = AuthController(
      signIn: SignIn(auth),
      register: RegisterAccount(auth),
      restoreSession: RestoreSession(auth),
      becomeHost: BecomeHost(auth),
      signOut: SignOut(auth),
    );

    await tester.pumpWidget(
      ProviderScope(
        // Guardados y Reservas usan repositorios en memoria: la prueba no
        // abre SQLite.
        overrides: [
          listasRepositoryProvider.overrideWithValue(_Listas()),
          reservasRepositoryProvider.overrideWithValue(_Reservas()),
        ],
        child: XelaStayApp(
          authController: controller,
          createHostStay: CreateHostStay(_HostsRepository()),
          getPublicStays: GetPublicStays(_StaysRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Arranca en Explorar.
    expect(find.text('Tu próxima historia empieza en Xela.'), findsOneWidget);
    expect(find.text('Mis listas de viaje'), findsNothing);

    await tester.tap(find.text('Guardados'));
    await tester.pumpAndSettle();
    expect(find.text('Mis listas de viaje'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);

    await tester.tap(find.text('Reservas'));
    await tester.pumpAndSettle();
    expect(find.text('Mis reservas'), findsOneWidget);
    expect(find.text('No tienes solicitudes pendientes'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);

    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    expect(find.text('Tu próxima historia empieza en Xela.'), findsOneWidget);
  });
}

class _AuthRepository implements AuthRepository {
  @override
  Future<AppUser?> restoreSession() async => const AppUser(
    id: 'u1',
    name: 'Ana López',
    email: 'ana@example.com',
    role: AppRole.guest,
  );

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) => throw UnimplementedError();

  @override
  Future<AppUser> becomeHost() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

class _HostsRepository implements HostsRepository {
  @override
  Future<HostStay> createStay(HostStayDraft draft) =>
      throw UnimplementedError();
}

class _StaysRepository implements StaysRepository {
  @override
  Future<List<Stay>> getPublicStays() async => const [];
}

class _Reservas implements ReservasRepository {
  @override
  Future<List<Reserva>> delHuesped(String huespedId) async => const [];

  @override
  Future<Reserva> porId(int id) => throw UnimplementedError();

  @override
  Future<Reserva> solicitar(SolicitudReserva solicitud) =>
      throw UnimplementedError();

  @override
  Future<void> cancelar(int id) async {}

  @override
  Future<List<Reserva>> todas() async => const [];

  @override
  Future<int> aceptar(int id) async => 0;

  @override
  Future<void> rechazar(int id) async {}

  @override
  Future<void> completar(int id) async {}
}

class _Listas implements ListasRepository {
  @override
  Future<List<Lista>> obtenerTodas() async => const [
    Lista(id: 1, nombre: 'Favoritos'),
  ];

  @override
  Future<void> guardar({
    int? id,
    required String nombre,
    String descripcion = '',
  }) async {}

  @override
  Future<void> archivar(int id, {required bool archivada}) async {}

  @override
  Future<void> eliminar(int id) async {}
}
