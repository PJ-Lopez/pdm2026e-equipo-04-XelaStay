import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xelastay/core/database/app_database.dart';
import 'package:xelastay/features/listas/data/datasources/guardados_local_data_source.dart';
import 'package:xelastay/features/listas/domain/entities/alojamiento_guardado.dart';

void main() {
  // SQLite real en la computadora (FFI): no hace falta teléfono.
  sqfliteFfiInit();

  late Directory carpeta;
  late AppDatabase database;
  late GuardadosLocalDataSource guardados;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('xelastay_db_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${carpeta.path}/xelastay.db',
    );
    guardados = GuardadosLocalDataSource(database: database);
  });

  tearDown(() async {
    await database.close();
    await carpeta.delete(recursive: true);
  });

  AlojamientoGuardado cabana({int precioCentavos = 45000}) =>
      AlojamientoGuardado(
        stayId: 'demo-cabana',
        titulo: 'Cabaña con vista a las montañas',
        zona: 'Las afueras de Xela',
        precioCentavos: precioCentavos,
        guardadoEn: DateTime(2026, 11, 1, 18, 30),
      );

  test('los guardados siguen ahí al cerrar y abrir la base', () async {
    await guardados.guardar(cabana());
    await database.close();

    final todos = await guardados.obtenerTodos();
    expect(todos, hasLength(1));
    expect(todos.single.titulo, 'Cabaña con vista a las montañas');
    expect(todos.single.precioCentavos, 45000);
    expect(todos.single.guardadoEn, DateTime(2026, 11, 1, 18, 30));

    final db = await database.database;
    expect(await db.getVersion(), AppDatabase.versionActual);
  });

  test('guardar dos veces el mismo alojamiento no lo duplica', () async {
    await guardados.guardar(cabana());
    await guardados.guardar(cabana(precioCentavos: 50000));

    final todos = await guardados.obtenerTodos();
    expect(todos, hasLength(1));
    expect(todos.single.precioCentavos, 50000);

    await guardados.quitar('demo-cabana');
    expect(await guardados.obtenerTodos(), isEmpty);
  });

  test('la base rechaza un precio negativo aunque la app falle', () async {
    await expectLater(
      guardados.guardar(cabana(precioCentavos: -1)),
      throwsA(isA<DatabaseException>()),
    );
  });
}
