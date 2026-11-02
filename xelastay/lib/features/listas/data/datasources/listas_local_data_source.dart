import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/lista.dart';

/// Único lugar donde se escribe SQL de la tabla `listas`.
class ListasLocalDataSource {
  ListasLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Lista>> obtenerTodas() async {
    final db = await _database.database;
    // LEFT JOIN: las listas sin guardados también aparecen (con 0).
    final filas = await db.rawQuery('''
      SELECT l.id, l.nombre, l.descripcion, l.archivada,
             COUNT(g.stay_id) AS alojamientos
      FROM listas l
      LEFT JOIN guardados g ON g.lista_id = l.id
      GROUP BY l.id
      ORDER BY l.archivada, l.id
    ''');
    return [
      for (final f in filas)
        Lista(
          id: f['id']! as int,
          nombre: f['nombre']! as String,
          descripcion: f['descripcion']! as String,
          alojamientos: f['alojamientos']! as int,
          archivada: f['archivada'] == 1,
        ),
    ];
  }

  Future<void> guardar({
    int? id,
    required String nombre,
    required String descripcion,
  }) async {
    final db = await _database.database;
    try {
      if (id == null) {
        await db.insert('listas', {
          'nombre': nombre,
          'descripcion': descripcion,
          'creada_ms': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        // UPDATE de la misma fila: el id no cambia.
        final cambiadas = await db.update(
          'listas',
          {'nombre': nombre, 'descripcion': descripcion},
          where: 'id = ?',
          whereArgs: [id],
        );
        if (cambiadas == 0) {
          throw const ListaException('Esa lista ya no existe.');
        }
      }
    } on DatabaseException catch (e) {
      // El UNIQUE de la tabla es quien detecta el repetido; aquí solo se
      // traduce a algo que el usuario entienda.
      if (e.isUniqueConstraintError()) {
        throw ListaException(
          'Ya tienes una lista llamada "$nombre". Usa otro nombre.',
        );
      }
      rethrow;
    }
  }

  Future<void> archivar(int id, {required bool archivada}) async {
    final db = await _database.database;
    await db.update(
      'listas',
      {'archivada': archivada ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Regla de borrado: si algún alojamiento guardado apunta a la lista, NO se
  /// borra y se explica qué hacer. La revisión y el DELETE van en la misma
  /// transacción para que nadie guarde algo en medio de las dos.
  Future<void> eliminar(int id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final filas = await txn.rawQuery(
        '''
        SELECT l.archivada,
               (SELECT COUNT(*) FROM guardados g WHERE g.lista_id = l.id) AS n
        FROM listas l
        WHERE l.id = ?
        ''',
        [id],
      );
      if (filas.isEmpty) return; // ya no existe: nada que borrar
      final n = filas.single['n']! as int;
      if (n > 0) {
        final cuantos = n == 1
            ? 'Tiene 1 alojamiento guardado.'
            : 'Tiene $n alojamientos guardados.';
        throw ListaException(
          filas.single['archivada'] == 1
              ? '$cuantos Quítalos de la lista si quieres eliminarla.'
              : '$cuantos Archívala para dejar de verla.',
        );
      }
      await txn.delete('listas', where: 'id = ?', whereArgs: [id]);
    });
  }
}
