import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/theme/app_theme.dart';
import 'package:xelastay/features/auth/domain/entities/app_user.dart';
import 'package:xelastay/features/booking/domain/entities/reserva.dart';
import 'package:xelastay/features/booking/domain/repositories/reservas_repository.dart';
import 'package:xelastay/features/booking/presentation/pages/reservas_page.dart';
import 'package:xelastay/features/booking/presentation/providers/reservas_providers.dart';

void main() {
  testWidgets('el filtro separa pendientes, próximas y anteriores', (
    tester,
  ) async {
    await _abrir(tester, ReservasFalsas());

    // Arranca en Pendientes.
    expect(find.text('Casa Pendiente'), findsOneWidget);
    expect(find.text('Esperando al anfitrión'), findsOneWidget);
    expect(find.text('Casa Confirmada'), findsNothing);

    await tester.tap(find.text('Próximas'));
    await tester.pumpAndSettle();
    expect(find.text('Casa Confirmada'), findsOneWidget);
    expect(find.text('Casa Pendiente'), findsNothing);

    await tester.tap(find.text('Anteriores'));
    await tester.pumpAndSettle();
    expect(find.text('Casa Cancelada'), findsOneWidget);
    expect(find.text('Cancelada'), findsOneWidget); // estado con texto
  });

  testWidgets('tocar una reserva abre su detalle y se puede cancelar', (
    tester,
  ) async {
    final repo = ReservasFalsas();
    await _abrir(tester, repo);

    await tester.tap(find.text('Casa Pendiente'));
    await tester.pumpAndSettle();
    expect(find.text('Tu solicitud está con el anfitrión.'), findsOneWidget);
    expect(find.text('Q 550.00'), findsOneWidget); // total del desglose

    await tester.ensureVisible(find.text('Cancelar solicitud'));
    await tester.tap(find.text('Cancelar solicitud'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, cancelar'));
    await tester.pumpAndSettle();

    expect(repo.canceladas, [1]);
    expect(find.text('Solicitud cancelada'), findsOneWidget);
    // El detalle volvió a leer la base: ya no ofrece cancelar.
    expect(find.text('Cancelar solicitud'), findsNothing);
  });

  testWidgets('vacío y error con reintentar', (tester) async {
    final repo = ReservasFalsas()
      ..reservas.clear()
      ..fallar = true;
    await _abrir(tester, repo);

    expect(find.text('No pudimos leer tus reservas'), findsOneWidget);
    repo.fallar = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No tienes solicitudes pendientes'), findsOneWidget);
  });
}

Future<void> _abrir(WidgetTester tester, ReservasFalsas repo) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reservasRepositoryProvider.overrideWithValue(repo),
        relojProvider.overrideWithValue(() => DateTime(2026, 11, 10)),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const ReservasPage(
          usuario: AppUser(
            id: 'ana',
            name: 'Ana López',
            email: 'ana@example.com',
            role: AppRole.guest,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Reserva _reserva(int id, String titulo, EstadoReserva estado) => Reserva(
  id: id,
  stayId: 'stay-$id',
  titulo: titulo,
  zona: 'Zona 1',
  precioNocheCentavos: 25000,
  entrada: DateTime(2026, 11, 14),
  salida: DateTime(2026, 11, 16),
  huespedes: 2,
  huespedId: 'ana',
  huespedNombre: 'Ana López',
  estado: estado,
  creadaEn: DateTime(2026, 11, 2),
);

/// Repositorio en memoria con la misma regla de cancelar que el real.
class ReservasFalsas implements ReservasRepository {
  final reservas = <Reserva>[
    _reserva(1, 'Casa Pendiente', EstadoReserva.pendiente),
    _reserva(2, 'Casa Confirmada', EstadoReserva.confirmada),
    _reserva(3, 'Casa Cancelada', EstadoReserva.cancelada),
  ];
  final canceladas = <int>[];
  bool fallar = false;

  @override
  Future<List<Reserva>> delHuesped(String huespedId) async {
    if (fallar) throw StateError('fallo de base de datos');
    return [...reservas];
  }

  @override
  Future<Reserva> porId(int id) async => reservas.firstWhere((r) => r.id == id);

  @override
  Future<Reserva> solicitar(SolicitudReserva solicitud) =>
      throw UnimplementedError();

  @override
  Future<void> cancelar(int id) async {
    final i = reservas.indexWhere((r) => r.id == id);
    final r = reservas[i];
    canceladas.add(id);
    reservas[i] = _reserva(r.id, r.titulo, EstadoReserva.cancelada);
  }

  @override
  Future<List<Reserva>> todas() async => const [];

  @override
  Future<int> aceptar(int id) async => 0;

  @override
  Future<void> rechazar(int id) async {}

  @override
  Future<void> completar(int id) async {}
}
