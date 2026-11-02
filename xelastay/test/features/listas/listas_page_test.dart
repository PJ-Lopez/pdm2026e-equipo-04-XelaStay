import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/core/theme/app_theme.dart';
import 'package:xelastay/features/listas/domain/entities/lista.dart';
import 'package:xelastay/features/listas/domain/repositories/listas_repository.dart';
import 'package:xelastay/features/listas/presentation/pages/listas_page.dart';
import 'package:xelastay/features/listas/presentation/providers/listas_providers.dart';

void main() {
  testWidgets('crear una lista: aparece sin recargar a mano', (tester) async {
    final repositorio = await abrirPantalla(tester);
    expect(find.text('Favoritos'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Crear lista'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Fin de semana en Xela',
    );
    await tester.pump();
    await tester.tap(find.text('Crear lista'));
    await tester.pumpAndSettle();

    expect(find.text('Fin de semana en Xela'), findsOneWidget);
    expect(find.text('Lista creada'), findsOneWidget);
    // La lista se volvió a leer (provider invalidado), no se agregó a mano.
    expect(repositorio.lecturas, 2);
  });

  testWidgets(
    'tocar una lista abre el formulario lleno y "Guardar cambios" la actualiza',
    (tester) async {
      final repositorio = await abrirPantalla(tester);

      await tester.tap(find.text('Favoritos'));
      await tester.pumpAndSettle();

      // El formulario abre lleno con los datos del registro.
      expect(find.text('Editar lista'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Favoritos'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Lo que quiero visitar'),
        findsOneWidget,
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Favoritos'),
        'Favoritos de Xela',
      );
      await tester.pump();
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('Editar lista'), findsNothing);
      expect(find.text('Favoritos de Xela'), findsOneWidget);
      expect(find.text('Cambios guardados'), findsOneWidget);
      // Mismo registro (mismo id), no uno nuevo.
      expect(repositorio.listas, hasLength(1));
      expect(repositorio.listas.single.id, 1);
      expect(repositorio.listas.single.nombre, 'Favoritos de Xela');
      expect(repositorio.listas.single.alojamientos, 2);
    },
  );

  testWidgets('nombre repetido muestra un mensaje y no cierra el formulario', (
    tester,
  ) async {
    final repositorio = await abrirPantalla(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'favoritos',
    );
    await tester.pump();
    await tester.tap(find.text('Crear lista'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ya tienes una lista llamada "favoritos". Usa otro nombre.'),
      findsOneWidget,
    );
    expect(find.text('Crear lista'), findsOneWidget);
    expect(repositorio.listas, hasLength(1));
  });

  testWidgets('borrar una lista en uso: mensaje claro y se ofrece archivar', (
    tester,
  ) async {
    final repositorio = await abrirPantalla(tester);

    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    // No se borra: el mensaje explica por qué y el formulario sigue abierto.
    expect(
      find.text(
        'Tiene 2 alojamientos guardados. Archívala para dejar de verla.',
      ),
      findsOneWidget,
    );
    expect(find.text('Editar lista'), findsOneWidget);
    expect(repositorio.listas, hasLength(1));

    // La otra salida: archivarla.
    await tester.tap(find.text('Archivar'));
    await tester.pumpAndSettle();

    expect(find.text('Lista archivada'), findsOneWidget);
    expect(find.text('Archivadas'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
    expect(repositorio.listas.single.archivada, isTrue);
    expect(repositorio.listas.single.alojamientos, 2);
  });

  testWidgets('una lista sin alojamientos sí se elimina', (tester) async {
    final repositorio = await abrirPantalla(
      tester,
      otras: [const Lista(id: 2, nombre: 'Trabajo')],
    );

    await tester.tap(find.text('Trabajo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Trabajo'), findsNothing);
    expect(find.text('Lista eliminada'), findsOneWidget);
    expect(repositorio.listas.map((l) => l.nombre), ['Favoritos']);
  });
}

Future<ListasFalsas> abrirPantalla(
  WidgetTester tester, {
  List<Lista> otras = const [],
}) async {
  final repositorio = ListasFalsas([
    const Lista(
      id: 1,
      nombre: 'Favoritos',
      descripcion: 'Lo que quiero visitar',
      alojamientos: 2,
    ),
    ...otras,
  ]);
  await tester.pumpWidget(
    ProviderScope(
      // Override: la pantalla usa el repositorio falso, sin base de datos.
      overrides: [listasRepositoryProvider.overrideWithValue(repositorio)],
      child: MaterialApp(theme: buildAppTheme(), home: const ListasPage()),
    ),
  );
  await tester.pumpAndSettle();
  return repositorio;
}

/// Repositorio en memoria con las mismas reglas que el real.
class ListasFalsas implements ListasRepository {
  ListasFalsas(this.listas);

  final List<Lista> listas;
  int lecturas = 0;
  int _siguienteId = 100;

  @override
  Future<List<Lista>> obtenerTodas() async {
    lecturas++;
    return [...listas];
  }

  @override
  Future<void> guardar({
    int? id,
    required String nombre,
    String descripcion = '',
  }) async {
    final limpio = nombre.trim();
    final repetido = listas.any(
      (l) => l.id != id && l.nombre.toLowerCase() == limpio.toLowerCase(),
    );
    if (repetido) {
      throw ListaException(
        'Ya tienes una lista llamada "$limpio". Usa otro nombre.',
      );
    }
    if (id == null) {
      listas.add(
        Lista(id: _siguienteId++, nombre: limpio, descripcion: descripcion),
      );
      return;
    }
    final i = listas.indexWhere((l) => l.id == id);
    listas[i] = Lista(
      id: id,
      nombre: limpio,
      descripcion: descripcion,
      alojamientos: listas[i].alojamientos,
      archivada: listas[i].archivada,
    );
  }

  @override
  Future<void> archivar(int id, {required bool archivada}) async {
    final i = listas.indexWhere((l) => l.id == id);
    final l = listas[i];
    listas[i] = Lista(
      id: l.id,
      nombre: l.nombre,
      descripcion: l.descripcion,
      alojamientos: l.alojamientos,
      archivada: archivada,
    );
  }

  @override
  Future<void> eliminar(int id) async {
    final lista = listas.singleWhere((l) => l.id == id);
    if (lista.enUso) {
      throw ListaException(
        'Tiene ${lista.alojamientos} alojamientos guardados. '
        'Archívala para dejar de verla.',
      );
    }
    listas.remove(lista);
  }
}
