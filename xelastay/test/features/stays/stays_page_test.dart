import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/features/auth/domain/entities/app_user.dart';
import 'package:xelastay/features/stays/data/repositories/simulated_stays_repository.dart';
import 'package:xelastay/features/stays/domain/entities/stay.dart';
import 'package:xelastay/features/stays/domain/repositories/stays_repository.dart';
import 'package:xelastay/features/stays/domain/usecases/get_public_stays.dart';
import 'package:xelastay/features/stays/presentation/pages/stays_page.dart';

void main() {
  testWidgets('Muestra spinner con texto y luego los alojamientos', (
    tester,
  ) async {
    await _pumpPage(tester, const SimulatedStaysRepository());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando alojamientos'), findsOneWidget);
    expect(find.text('Apartamento en el centro de Xela'), findsNothing);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Apartamento en el centro de Xela'), findsOneWidget);
    expect(find.text('Cabaña con vista a las montañas'), findsOneWidget);
    expect(find.text('Q 250'), findsOneWidget);
    expect(find.text('Q 450'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Override con FakeErrorStaysRepository muestra error y reintenta',
    (tester) async {
      final repository = FakeErrorStaysRepository();
      await _pumpPage(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('No pudimos cargar los alojamientos'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(repository.attempts, 1);

      await tester.ensureVisible(find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(repository.attempts, 2);
      expect(find.text('No pudimos cargar los alojamientos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Reintentar pasa de error a carga y luego a datos', (
    tester,
  ) async {
    final repository = _ControlledStaysRepository();
    await _pumpPage(tester, repository);
    repository.requests.single.completeError(Exception('Sin conexión'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(repository.requests, hasLength(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.requests.last.complete(const [_stay]);
    await tester.pumpAndSettle();

    expect(find.text(_stay.title), findsOneWidget);
    expect(find.text('No pudimos cargar los alojamientos'), findsNothing);
  });

  testWidgets('El estado vacío permite actualizar y mostrar nuevos datos', (
    tester,
  ) async {
    final repository = _ControlledStaysRepository();
    await _pumpPage(tester, repository);
    repository.requests.single.complete(const []);
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay alojamientos publicados'), findsOneWidget);
    await tester.ensureVisible(find.text('Actualizar'));
    await tester.tap(find.text('Actualizar'));
    await tester.pump();

    expect(repository.requests, hasLength(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.requests.last.complete(const [_stay]);
    await tester.pumpAndSettle();

    expect(find.text(_stay.title), findsOneWidget);
    expect(find.text('Aún no hay alojamientos publicados'), findsNothing);
  });

  testWidgets('Una búsqueda sin resultados permite limpiar el filtro', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      const SimulatedStaysRepository(latency: Duration.zero),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'sin coincidencias');
    await tester.pumpAndSettle();

    expect(find.text('No encontramos resultados'), findsOneWidget);
    await tester.ensureVisible(find.text('Limpiar búsqueda'));
    await tester.tap(find.text('Limpiar búsqueda'));
    await tester.pumpAndSettle();

    expect(find.text('No encontramos resultados'), findsNothing);
    expect(find.text('Apartamento en el centro de Xela'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  test('El repositorio simulado expone los escenarios vacío y error', () async {
    expect(
      await const SimulatedStaysRepository(
        scenario: StaysScenario.empty,
        latency: Duration.zero,
      ).getPublicStays(),
      isEmpty,
    );
    await expectLater(
      const SimulatedStaysRepository(
        scenario: StaysScenario.error,
        latency: Duration.zero,
      ).getPublicStays(),
      throwsException,
    );
  });
}

Future<void> _pumpPage(WidgetTester tester, StaysRepository repository) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: StaysPage(
        user: const AppUser(
          id: 'guest',
          name: 'Visitante',
          email: 'guest@example.com',
          role: AppRole.guest,
        ),
        getPublicStays: GetPublicStays(repository),
        onOpenProfile: () {},
      ),
    ),
  );
}

class FakeErrorStaysRepository implements StaysRepository {
  int attempts = 0;

  @override
  Future<List<Stay>> getPublicStays() async {
    attempts++;
    throw Exception('Fallo interno que no debe mostrarse en la UI');
  }
}

class _ControlledStaysRepository implements StaysRepository {
  final requests = <Completer<List<Stay>>>[];

  @override
  Future<List<Stay>> getPublicStays() {
    final request = Completer<List<Stay>>();
    requests.add(request);
    return request.future;
  }
}

const _stay = Stay(
  id: 'stay-test',
  title: 'Alojamiento recuperado',
  propertyType: 'Apartamento',
  capacity: 2,
  priceAmount: 25000,
  currency: 'GTQ',
  ratingAverage: 0,
  ratingCount: 0,
  zone: 'Zona 1',
  reference: 'Parque Central',
  verificationStatus: 'verified',
);
