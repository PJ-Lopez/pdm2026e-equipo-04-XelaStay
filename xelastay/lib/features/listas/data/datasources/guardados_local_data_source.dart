import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/alojamiento_guardado.dart';

/// Único lugar donde se escribe SQL de la tabla `guardados`.
class GuardadosLocalDataSource {
  GuardadosLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  /// Los más recientes primero.
  Future<List<AlojamientoGuardado>> obtenerTodos() async {
    final db = await _database.database;
    final filas = await db.query('guardados', orderBy: 'guardado_ms DESC');
    return [for (final f in filas) _desdeFila(f)];
  }

  /// Guardar dos veces el mismo alojamiento no lo duplica: `stay_id` es la
  /// llave primaria y la segunda vez reemplaza a la primera.
  Future<void> guardar(AlojamientoGuardado alojamiento) async {
    final db = await _database.database;
    await db.insert('guardados', {
      'stay_id': alojamiento.stayId,
      'titulo': alojamiento.titulo,
      'zona': alojamiento.zona,
      'precio_centavos': alojamiento.precioCentavos,
      'guardado_ms': alojamiento.guardadoEn.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> quitar(String stayId) async {
    final db = await _database.database;
    await db.delete('guardados', where: 'stay_id = ?', whereArgs: [stayId]);
  }

  AlojamientoGuardado _desdeFila(Map<String, Object?> f) => AlojamientoGuardado(
    stayId: f['stay_id']! as String,
    titulo: f['titulo']! as String,
    zona: f['zona']! as String,
    precioCentavos: f['precio_centavos']! as int,
    guardadoEn: DateTime.fromMillisecondsSinceEpoch(f['guardado_ms']! as int),
  );
}
