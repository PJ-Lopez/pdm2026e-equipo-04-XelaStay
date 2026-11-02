import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/theme/app_theme.dart';
import 'package:xelastay/features/auth/domain/entities/app_user.dart';
import 'package:xelastay/features/listas/domain/entities/alojamiento_guardado.dart';
import 'package:xelastay/features/listas/domain/entities/lista.dart';
import 'package:xelastay/features/listas/domain/repositories/guardados_repository.dart';
import 'package:xelastay/features/listas/domain/repositories/listas_repository.dart';
import 'package:xelastay/features/listas/presentation/providers/guardados_providers.dart';
import 'package:xelastay/features/listas/presentation/providers/listas_providers.dart';
import 'package:xelastay/features/stays/domain/entities/stay.dart';
import 'package:xelastay/features/stays/presentation/pages/stay_detail_page.dart';

void main() {
  testWidgets('muestra el alojamiento y explica la verificación', (
    tester,
  ) async {
    await _abrir(tester, _GuardadosFalsos());

    expect(find.text('Apartamento en el centro de Xela'), findsOneWidget);
    expect(find.text('Zona 1 · Cerca del Parque Central'), findsOneWidget);
    expect(find.text('Ubicación revisada por XelaStay'), findsOneWidget);
    expect(find.text('4.8 · 12 reseñas'), findsOneWidget);
    expect(find.text('Hasta 2 huéspedes'), findsOneWidget);
  });

  testWidgets('guardar ofrece solo listas activas y guarda en la elegida', (
    tester,
  ) async {
    final guardados = _GuardadosFalsos();
    await _abrir(tester, guardados);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Guardar en…'), findsOneWidget);
    expect(find.text('Fin de semana'), findsOneWidget);
    expect(find.text('Viaje viejo'), findsNothing); // archivada

    await tester.tap(find.text('Fin de semana'));
    await tester.pumpAndSettle();

    expect(find.text('Guardado en "Fin de semana"'), findsOneWidget);
    expect(guardados.datos.single.stayId, 'centro');
    expect(guardados.datos.single.listaId, 2);
    expect(guardados.datos.single.precioCentavos, 25000);
  });

  testWidgets('"Solicitar reserva" abre el formulario de la reserva', (
    tester,
  ) async {
    await _abrir(tester, _GuardadosFalsos());

    await tester.tap(find.text('Solicitar reserva'));
    await tester.pumpAndSettle();

    expect(find.text('Elegir fechas'), findsOneWidget);
    expect(find.text('Máximo 2'), findsOneWidget);
  });

  testWidgets('si falla al guardar muestra un mensaje amigable', (
    tester,
  ) async {
    final guardados = _GuardadosFalsos()..fallar = true;
    await _abrir(tester, guardados);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos guardar el alojamiento. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(guardados.datos, isEmpty);
  });
}

const _stay = Stay(
  id: 'centro',
  title: 'Apartamento en el centro de Xela',
  propertyType: 'Apartamento',
  capacity: 2,
  priceAmount: 25000,
  currency: 'GTQ',
  ratingAverage: 4.8,
  ratingCount: 12,
  zone: 'Zona 1',
  reference: 'Cerca del Parque Central',
  verificationStatus: 'verified',
);

const _usuario = AppUser(
  id: 'u1',
  name: 'Ana López',
  email: 'ana@example.com',
  role: AppRole.guest,
);

Future<void> _abrir(WidgetTester tester, _GuardadosFalsos guardados) async {
  // Pantalla de teléfono: así toda la ficha cabe y se construye.
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        listasRepositoryProvider.overrideWithValue(_ListasFalsas()),
        guardadosRepositoryProvider.overrideWithValue(guardados),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const StayDetailPage(stay: _stay, usuario: _usuario),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ListasFalsas implements ListasRepository {
  @override
  Future<List<Lista>> obtenerTodas() async => const [
    Lista(id: 1, nombre: 'Favoritos'),
    Lista(id: 2, nombre: 'Fin de semana'),
    Lista(id: 3, nombre: 'Viaje viejo', archivada: true),
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

class _GuardadosFalsos implements GuardadosRepository {
  final datos = <AlojamientoGuardado>[];
  bool fallar = false;

  @override
  Future<List<AlojamientoGuardado>> deLista(int listaId) async =>
      datos.where((g) => g.listaId == listaId).toList();

  @override
  Future<void> guardar(AlojamientoGuardado alojamiento) async {
    if (fallar) throw StateError('fallo de base de datos');
    datos.add(alojamiento);
  }

  @override
  Future<void> quitar(String stayId) async =>
      datos.removeWhere((g) => g.stayId == stayId);
}
