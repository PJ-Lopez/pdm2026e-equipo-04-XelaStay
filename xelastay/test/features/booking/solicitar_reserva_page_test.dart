import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/theme/app_theme.dart';
import 'package:xelastay/features/auth/domain/entities/app_user.dart';
import 'package:xelastay/features/booking/domain/entities/reserva.dart';
import 'package:xelastay/features/booking/domain/repositories/reservas_repository.dart';
import 'package:xelastay/features/booking/presentation/pages/solicitar_reserva_page.dart';
import 'package:xelastay/features/booking/presentation/providers/reservas_providers.dart';
import 'package:xelastay/features/stays/domain/entities/stay.dart';

void main() {
  testWidgets('muestra el desglose y envía la solicitud', (tester) async {
    final repo = _Reservas();
    await _abrir(tester, repo);

    // 2 noches × Q 250 + 10 % de servicio.
    expect(find.text('Q 250.00 × 2 noches'), findsOneWidget);
    expect(find.text('Q 500.00'), findsOneWidget);
    expect(find.text('Q 50.00'), findsOneWidget);
    expect(find.text('Q 550.00'), findsOneWidget);

    // No deja pasar de la capacidad (2).
    await tester.tap(find.byTooltip('Más huéspedes'));
    await tester.tap(find.byTooltip('Más huéspedes'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.ensureVisible(find.text('Enviar solicitud'));
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    expect(repo.recibidas.single.huespedes, 2);
    expect(repo.recibidas.single.huespedId, 'ana');
    expect(repo.recibidas.single.entrada, DateTime(2026, 11, 14));
    expect(find.text('enviada: true'), findsOneWidget); // hizo pop(true)
  });

  testWidgets('si las fechas ya no están, explica y conserva el formulario', (
    tester,
  ) async {
    final repo = _Reservas()..fechasTomadas = true;
    await _abrir(tester, repo);

    await tester.ensureVisible(find.text('Enviar solicitud'));
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();

    expect(
      find.text('Esas fechas ya no están disponibles. Prueba con otras.'),
      findsOneWidget,
    );
    expect(find.text('Q 550.00'), findsOneWidget); // no se borró nada
    expect(find.text('enviada: true'), findsNothing);
  });
}

const _stay = Stay(
  id: 'centro',
  title: 'Apartamento en el centro de Xela',
  propertyType: 'Apartamento',
  capacity: 2,
  priceAmount: 25000,
  currency: 'GTQ',
  ratingAverage: 0,
  ratingCount: 0,
  zone: 'Zona 1',
  reference: 'Cerca del Parque Central',
  verificationStatus: 'verified',
);

/// Abre el formulario desde un botón, como lo hace el detalle, para poder
/// comprobar el valor con el que cierra.
Future<void> _abrir(WidgetTester tester, _Reservas repo) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reservasRepositoryProvider.overrideWithValue(repo),
        relojProvider.overrideWithValue(() => DateTime(2026, 11, 10)),
      ],
      child: MaterialApp(theme: buildAppTheme(), home: const _Inicio()),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

class _Inicio extends StatefulWidget {
  const _Inicio();

  @override
  State<_Inicio> createState() => _InicioState();
}

class _InicioState extends State<_Inicio> {
  bool? _enviada;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () async {
            final r = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => SolicitarReservaPage(
                  stay: _stay,
                  usuario: const AppUser(
                    id: 'ana',
                    name: 'Ana López',
                    email: 'ana@example.com',
                    role: AppRole.guest,
                  ),
                  fechasIniciales: DateTimeRange(
                    start: DateTime(2026, 11, 14),
                    end: DateTime(2026, 11, 16),
                  ),
                ),
              ),
            );
            setState(() => _enviada = r);
          },
          child: const Text('abrir'),
        ),
        if (_enviada != null) Text('enviada: $_enviada'),
      ],
    ),
  );
}

class _Reservas implements ReservasRepository {
  final recibidas = <SolicitudReserva>[];
  bool fechasTomadas = false;

  @override
  Future<Reserva> solicitar(SolicitudReserva s) async {
    if (fechasTomadas) {
      throw const ReservaException(
        'Esas fechas ya no están disponibles. Prueba con otras.',
      );
    }
    recibidas.add(s);
    return Reserva(
      id: 1,
      stayId: s.stayId,
      titulo: s.titulo,
      zona: s.zona,
      precioNocheCentavos: s.precioNocheCentavos,
      entrada: s.entrada,
      salida: s.salida,
      huespedes: s.huespedes,
      huespedId: s.huespedId,
      huespedNombre: s.huespedNombre,
      estado: EstadoReserva.pendiente,
      creadaEn: DateTime(2026, 11, 10),
    );
  }

  @override
  Future<List<Reserva>> delHuesped(String huespedId) async => const [];

  @override
  Future<Reserva> porId(int id) => throw UnimplementedError();

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
