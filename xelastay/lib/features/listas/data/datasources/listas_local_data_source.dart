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
      SELECT l.id, l.nombre, l.descripcion,
             COUNT(g.stay_id) AS alojamientos
      FROM listas l
      LEFT JOIN guardados g ON g.lista_id = l.id
      GROUP BY l.id
      ORDER BY l.id
    ''');
    return [
      for (final f in filas)
        Lista(
          id: f['id']! as int,
          nombre: f['nombre']! as String,
          descripcion: f['descripcion']! as String,
          alojamientos: f['alojamientos']! as int,
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
}
