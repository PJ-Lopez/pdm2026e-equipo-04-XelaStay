import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/theme/app_theme.dart';
import 'package:xelastay/features/listas/domain/entities/alojamiento_guardado.dart';
import 'package:xelastay/features/listas/domain/entities/lista.dart';
import 'package:xelastay/features/listas/domain/repositories/guardados_repository.dart';
import 'package:xelastay/features/listas/presentation/pages/lista_detalle_page.dart';
import 'package:xelastay/features/listas/presentation/providers/guardados_providers.dart';
import 'package:xelastay/features/stays/data/repositories/simulated_stays_repository.dart';
import 'package:xelastay/features/stays/domain/usecases/get_public_stays.dart';

void main() {
  testWidgets('agregar un alojamiento del catálogo y quitarlo de la lista', (
    tester,
  ) async {
    final guardados = GuardadosFalsos();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guardadosRepositoryProvider.overrideWithValue(guardados),
          getPublicStaysProvider.overrideWithValue(
            GetPublicStays(
              const SimulatedStaysRepository(latency: Duration.zero),
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ListaDetallePage(
            lista: Lista(id: 1, nombre: 'Favoritos'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Esta lista está vacía. Agrega alojamientos del catálogo.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Agregar alojamiento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apartamento en el centro de Xela'));
    await tester.pumpAndSettle();

    expect(find.text('Apartamento en el centro de Xela'), findsOneWidget);
    expect(find.text('Zona 1 · Q 250 / noche'), findsOneWidget);
    expect(find.text('Guardado en "Favoritos"'), findsOneWidget);
    expect(guardados.datos.single.listaId, 1);
    expect(guardados.datos.single.precioCentavos, 25000);

    await tester.tap(find.byTooltip('Quitar de la lista'));
    await tester.pumpAndSettle();

    expect(guardados.datos, isEmpty);
    expect(find.text('Apartamento en el centro de Xela'), findsNothing);
  });

  testWidgets('un fallo al guardar muestra un mensaje amigable', (
    tester,
  ) async {
    final guardados = GuardadosFalsos()..fallarAlGuardar = true;
    await _abrirDetalle(tester, guardados);

    await tester.tap(find.text('Agregar alojamiento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apartamento en el centro de Xela'));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos guardar el alojamiento. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(guardados.datos, isEmpty);
  });

  testWidgets('un fallo al quitar muestra un mensaje amigable', (tester) async {
    final guardados = GuardadosFalsos()..fallarAlQuitar = true;
    guardados.datos.add(
      AlojamientoGuardado(
        stayId: 'stay-1',
        titulo: 'Alojamiento de prueba',
        zona: 'Zona 1',
        precioCentavos: 25000,
        guardadoEn: DateTime(2026, 11, 1),
        listaId: 1,
      ),
    );
    await _abrirDetalle(tester, guardados);

    await tester.tap(find.byTooltip('Quitar de la lista'));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos quitar el alojamiento. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(guardados.datos, hasLength(1));
  });
}

Future<void> _abrirDetalle(
  WidgetTester tester,
  GuardadosFalsos guardados,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        guardadosRepositoryProvider.overrideWithValue(guardados),
        getPublicStaysProvider.overrideWithValue(
          GetPublicStays(
            const SimulatedStaysRepository(latency: Duration.zero),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const ListaDetallePage(lista: Lista(id: 1, nombre: 'Favoritos')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class GuardadosFalsos implements GuardadosRepository {
  final datos = <AlojamientoGuardado>[];
  bool fallarAlGuardar = false;
  bool fallarAlQuitar = false;

  @override
  Future<List<AlojamientoGuardado>> deLista(int listaId) async =>
      datos.where((g) => g.listaId == listaId).toList();

  @override
  Future<void> guardar(AlojamientoGuardado alojamiento) async {
    if (fallarAlGuardar) throw StateError('fallo de base de datos');
    datos
      ..removeWhere((g) => g.stayId == alojamiento.stayId)
      ..add(alojamiento);
  }

  @override
  Future<void> quitar(String stayId) async {
    if (fallarAlQuitar) throw StateError('fallo de base de datos');
    datos.removeWhere((g) => g.stayId == stayId);
  }
}
