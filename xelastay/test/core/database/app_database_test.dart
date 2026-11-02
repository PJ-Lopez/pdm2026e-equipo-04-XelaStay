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

  Future<int> idDeLista(Database db, String nombre) async {
    final filas = await db.query(
      'listas',
      columns: ['id'],
      where: 'nombre = ?',
      whereArgs: [nombre],
    );
    return filas.single['id']! as int;
  }

  AlojamientoGuardado cabana({required int listaId, int precio = 45000}) =>
      AlojamientoGuardado(
        stayId: 'demo-cabana',
        titulo: 'Cabaña con vista a las montañas',
        zona: 'Las afueras de Xela',
        precioCentavos: precio,
        guardadoEn: DateTime(2026, 11, 1, 18, 30),
        listaId: listaId,
      );

  test('los guardados siguen ahí al cerrar y abrir la base', () async {
    final favoritos = await idDeLista(await database.database, 'Favoritos');
    await guardados.guardar(cabana(listaId: favoritos));
    await database.close();

    final todos = await guardados.obtenerTodos();
    expect(todos, hasLength(1));
    expect(todos.single.titulo, 'Cabaña con vista a las montañas');
    expect(todos.single.precioCentavos, 45000);
    expect(todos.single.guardadoEn, DateTime(2026, 11, 1, 18, 30));
    expect(todos.single.listaId, favoritos);

    final db = await database.database;
    expect(await db.getVersion(), AppDatabase.versionActual);
  });

  test('guardar dos veces el mismo alojamiento no lo duplica', () async {
    final favoritos = await idDeLista(await database.database, 'Favoritos');
    await guardados.guardar(cabana(listaId: favoritos));
    await guardados.guardar(cabana(listaId: favoritos, precio: 50000));

    final todos = await guardados.obtenerTodos();
    expect(todos, hasLength(1));
    expect(todos.single.precioCentavos, 50000);

    await guardados.quitar('demo-cabana');
    expect(await guardados.obtenerTodos(), isEmpty);
  });

  test('la base rechaza un precio negativo aunque la app falle', () async {
    final favoritos = await idDeLista(await database.database, 'Favoritos');
    await expectLater(
      guardados.guardar(cabana(listaId: favoritos, precio: -1)),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('la base protege las listas: nombre único y no borrar en uso', () async {
    final db = await database.database;
    await db.insert('listas', {'nombre': 'Fin de semana', 'creada_ms': 0});

    // Mayúsculas distintas cuentan como el mismo nombre (COLLATE NOCASE).
    await expectLater(
      db.insert('listas', {'nombre': 'fin de semana', 'creada_ms': 0}),
      throwsA(
        isA<DatabaseException>().having(
          (e) => e.isUniqueConstraintError(),
          'es UNIQUE',
          isTrue,
        ),
      ),
    );

    // Lista con guardados: la llave foránea no deja borrarla.
    final finde = await idDeLista(db, 'Fin de semana');
    await guardados.guardar(cabana(listaId: finde));
    await expectLater(
      db.delete('listas', where: 'id = ?', whereArgs: [finde]),
      throwsA(isA<DatabaseException>()),
    );
  });

  // Crea una base EXACTAMENTE como la dejaba la app en la versión 1:
  // la tabla guardados sin listas, con datos de un usuario real.
  Future<String> crearBaseV1() async {
    final ruta = '${carpeta.path}/v1.db';
    final v1 = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => AppDatabase.migraciones[1]!(db),
      ),
    );
    await v1.insert('guardados', {
      'stay_id': 'demo-centro',
      'titulo': 'Apartamento en el centro de Xela',
      'zona': 'Zona 1',
      'precio_centavos': 25000,
      'guardado_ms': DateTime(2026, 10, 30).millisecondsSinceEpoch,
    });
    await v1.insert('guardados', {
      'stay_id': 'demo-cabana',
      'titulo': 'Cabaña con vista a las montañas',
      'zona': 'Las afueras de Xela',
      'precio_centavos': 45000,
      'guardado_ms': DateTime(2026, 10, 31).millisecondsSinceEpoch,
    });
    await v1.close();
    return ruta;
  }

  // La prueba más importante de una migración: el usuario que ya tenía la
  // app (versión 1) actualiza y NO pierde lo que había guardado.
  test('migra de la versión 1 a la actual sin perder los guardados', () async {
    final actualizada = AppDatabase(
      factory: databaseFactoryFfi,
      path: await crearBaseV1(),
    );
    final db = await actualizada.database;

    expect(await db.getVersion(), AppDatabase.versionActual);

    // Lo nuevo existe: la tabla listas con "Favoritos" activa.
    final listas = await db.query('listas');
    expect(listas, hasLength(1));
    expect(listas.single['nombre'], 'Favoritos');
    expect(listas.single['archivada'], 0);

    // Lo viejo sigue: los dos guardados, ahora dentro de "Favoritos".
    final favoritos = listas.single['id']! as int;
    final migrados = await GuardadosLocalDataSource(
      database: actualizada,
    ).deLista(favoritos);
    expect(migrados.map((g) => g.titulo), [
      'Cabaña con vista a las montañas',
      'Apartamento en el centro de Xela',
    ]);
    expect(migrados.map((g) => g.precioCentavos), [45000, 25000]);
    await actualizada.close();
  });

  // Base EXACTAMENTE como la dejaba la versión 2 (lab S16), con una lista
  // creada por el usuario y un alojamiento guardado en ella.
  Future<String> crearBaseV2() async {
    final ruta = '${carpeta.path}/v2.db';
    final v2 = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await AppDatabase.migraciones[1]!(db);
          await AppDatabase.migraciones[2]!(db);
        },
      ),
    );
    final finde = await v2.insert('listas', {
      'nombre': 'Fin de semana',
      'creada_ms': 0,
    });
    await v2.insert('guardados', {
      'stay_id': 'demo-cabana',
      'titulo': 'Cabaña con vista a las montañas',
      'zona': 'Las afueras de Xela',
      'precio_centavos': 45000,
      'guardado_ms': 0,
      'lista_id': finde,
    });
    await v2.close();
    return ruta;
  }

  test(
    'migra de la versión 2 a la 3: listas intactas y reservas nuevas',
    () async {
      final actualizada = AppDatabase(
        factory: databaseFactoryFfi,
        path: await crearBaseV2(),
      );
      final db = await actualizada.database;
      expect(await db.getVersion(), AppDatabase.versionActual);

      // Lo viejo sigue.
      final filas = await db.rawQuery('''
      SELECT l.nombre, g.titulo FROM guardados g
      JOIN listas l ON l.id = g.lista_id
    ''');
      expect(filas, [
        {
          'nombre': 'Fin de semana',
          'titulo': 'Cabaña con vista a las montañas',
        },
      ]);
      // Lo nuevo existe y está vacío.
      for (final tabla in ['reservas', 'pagos', 'mensajes', 'resenas']) {
        expect(await db.query(tabla), isEmpty, reason: tabla);
      }
      await actualizada.close();
    },
  );

  // Si onCreate y onUpgrade divergen, un usuario nuevo y uno actualizado
  // tendrían bases distintas. Esta prueba lo detecta comparando el esquema.
  test('instalación nueva y actualizada tienen el mismo esquema', () async {
    Future<List<Object?>> esquema(AppDatabase base) async {
      final db = await base.database;
      final objetos = await db.rawQuery(
        "SELECT type, name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' "
        'ORDER BY type, name',
      );
      final columnas = [
        for (final t in objetos.where((o) => o['type'] == 'table'))
          for (final c in await db.rawQuery('PRAGMA table_info(${t['name']})'))
            '${t['name']}.${c['name']} ${c['type']} ${c['notnull']}',
      ];
      return [...objetos, ...columnas];
    }

    final nueva = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${carpeta.path}/nueva.db',
    );
    final actualizada = AppDatabase(
      factory: databaseFactoryFfi,
      path: await crearBaseV1(),
    );
    expect(await esquema(actualizada), await esquema(nueva));
    await nueva.close();
    await actualizada.close();
  });
}
