import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/theme/app_theme.dart';
import 'package:xelastay/features/booking/domain/entities/reserva.dart';
import 'package:xelastay/features/booking/domain/repositories/reservas_repository.dart';
import 'package:xelastay/features/booking/presentation/providers/reservas_providers.dart';
import 'package:xelastay/features/hosts/presentation/pages/solicitudes_page.dart';

void main() {
  test('cada estado cae en su pestaña del panel', () {
    expect(filtroDe(EstadoReserva.pendiente), FiltroSolicitudes.porAtender);
    expect(filtroDe(EstadoReserva.aceptada), FiltroSolicitudes.aceptadas);
    expect(filtroDe(EstadoReserva.confirmada), FiltroSolicitudes.aceptadas);
    expect(filtroDe(EstadoReserva.cancelada), FiltroSolicitudes.cerradas);
  });

  testWidgets('aceptar avisa cuántas se rechazaron y la pasa a Aceptadas', (
    tester,
  ) async {
    final repo = _Solicitudes()..rechazadasAlAceptar = 2;
    await _abrir(tester, repo);

    expect(find.text('Casa de Ana'), findsOneWidget);
    expect(find.text('Casa de Luis'), findsNothing); // está en Aceptadas

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(repo.aceptadas, [1]);
    expect(
      find.text('Aceptada. Se rechazaron 2 solicitudes de las mismas fechas.'),
      findsOneWidget,
    );
    expect(find.text('No hay solicitudes por atender.'), findsOneWidget);

    await tester.tap(find.text('Aceptadas'));
    await tester.pumpAndSettle();
    expect(find.text('Casa de Ana'), findsOneWidget);
    expect(find.text('Esperando el pago del huésped.'), findsOneWidget);
  });

  testWidgets('una estadía confirmada que ya empezó se puede completar', (
    tester,
  ) async {
    final repo = _Solicitudes();
    await _abrir(tester, repo);

    await tester.tap(find.text('Aceptadas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar estadía completada'));
    await tester.pumpAndSettle();

    expect(repo.completadas, [2]);
    expect(find.text('Estadía completada'), findsOneWidget);
  });

  testWidgets('si la regla no deja, se muestra el motivo', (tester) async {
    final repo = _Solicitudes()..yaAtendida = true;
    await _abrir(tester, repo);

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();

    expect(find.text('Esta solicitud ya fue atendida.'), findsOneWidget);
    expect(find.text('Casa de Ana'), findsOneWidget);
  });
}

Future<void> _abrir(WidgetTester tester, _Solicitudes repo) async {
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
      child: MaterialApp(theme: buildAppTheme(), home: const SolicitudesPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Reserva _reserva(int id, String titulo, EstadoReserva estado, int entrada) =>
    Reserva(
      id: id,
      stayId: 'stay-$id',
      titulo: titulo,
      zona: 'Zona 1',
      precioNocheCentavos: 25000,
      entrada: DateTime(2026, 11, entrada),
      salida: DateTime(2026, 11, entrada + 2),
      huespedes: 2,
      huespedId: 'h$id',
      huespedNombre: 'Huésped $id',
      estado: estado,
      creadaEn: DateTime(2026, 11, 2),
    );

/// Solicitudes en memoria: Ana pendiente y Luis confirmada desde ayer.
class _Solicitudes implements ReservasRepository {
  final lista = <Reserva>[
    _reserva(1, 'Casa de Ana', EstadoReserva.pendiente, 14),
    _reserva(2, 'Casa de Luis', EstadoReserva.confirmada, 9),
  ];
  final aceptadas = <int>[];
  final completadas = <int>[];
  int rechazadasAlAceptar = 0;
  bool yaAtendida = false;

  void _cambiar(int id, EstadoReserva estado) {
    final i = lista.indexWhere((r) => r.id == id);
    final r = lista[i];
    lista[i] = _reserva(r.id, r.titulo, estado, r.entrada.day);
  }

  @override
  Future<List<Reserva>> todas() async => [...lista];

  @override
  Future<int> aceptar(int id) async {
    aceptadas.add(id);
    _cambiar(id, EstadoReserva.aceptada);
    return rechazadasAlAceptar;
  }

  @override
  Future<void> rechazar(int id) async {
    if (yaAtendida) {
      throw const ReservaException('Esta solicitud ya fue atendida.');
    }
    _cambiar(id, EstadoReserva.rechazada);
  }

  @override
  Future<void> completar(int id) async {
    completadas.add(id);
    _cambiar(id, EstadoReserva.completada);
  }

  @override
  Future<List<Reserva>> delHuesped(String huespedId) async => const [];

  @override
  Future<Reserva> porId(int id) async => lista.firstWhere((r) => r.id == id);

  @override
  Future<Reserva> solicitar(SolicitudReserva solicitud) =>
      throw UnimplementedError();

  @override
  Future<void> cancelar(int id) async {}
}
