import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../booking/domain/entities/reserva.dart';
import '../../domain/entities/resena.dart';

/// Único lugar donde se escribe SQL de la tabla `resenas`.
class ResenasLocalDataSource {
  ResenasLocalDataSource({AppDatabase? database, DateTime Function()? reloj})
    : _database = database ?? AppDatabase.instance,
      _reloj = reloj ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _reloj;

  Future<List<Resena>> deAlojamiento(String stayId) async {
    final db = await _database.database;
    final filas = await db.query(
      'resenas',
      where: 'stay_id = ?',
      whereArgs: [stayId],
      orderBy: 'creada_ms DESC, id DESC',
    );
    return [for (final f in filas) _desdeFila(f)];
  }

  Future<Resena?> deReserva(int reservaId) async {
    final db = await _database.database;
    final filas = await db.query(
      'resenas',
      where: 'reserva_id = ?',
      whereArgs: [reservaId],
    );
    return filas.isEmpty ? null : _desdeFila(filas.single);
  }

  /// En UNA transacción: revisa que la estadía esté completada y que no tenga
  /// reseña, y la guarda. El alojamiento y el autor salen de la reserva.
  Future<Resena> publicar({
    required int reservaId,
    required int estrellas,
    required String comentario,
  }) async {
    final db = await _database.database;
    try {
      final id = await db.transaction((txn) async {
        final filas = await txn.query(
          'reservas',
          columns: ['stay_id', 'huesped_nombre', 'estado'],
          where: 'id = ?',
          whereArgs: [reservaId],
        );
        if (filas.isEmpty) {
          throw const ResenaException('Esa reserva ya no existe.');
        }
        final r = filas.single;
        if (r['estado'] != EstadoReserva.completada.name) {
          throw const ResenaException(
            'Solo puedes reseñar una estadía completada.',
          );
        }
        final yaHay = Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COUNT(*) FROM resenas WHERE reserva_id = ?',
            [reservaId],
          ),
        );
        if ((yaHay ?? 0) > 0) {
          throw const ResenaException('Ya reseñaste esta estadía.');
        }
        return txn.insert('resenas', {
          'reserva_id': reservaId,
          'stay_id': r['stay_id'],
          'autor': r['huesped_nombre'],
          'estrellas': estrellas,
          'comentario': comentario,
          'creada_ms': _reloj().millisecondsSinceEpoch,
        });
      });
      final filas = await db.query('resenas', where: 'id = ?', whereArgs: [id]);
      return _desdeFila(filas.single);
    } on DatabaseException catch (e) {
      // UNIQUE(reserva_id): la base es la última defensa contra duplicados.
      if (e.isUniqueConstraintError()) {
        throw const ResenaException('Ya reseñaste esta estadía.');
      }
      rethrow;
    }
  }

  Resena _desdeFila(Map<String, Object?> f) => Resena(
    id: f['id']! as int,
    reservaId: f['reserva_id']! as int,
    stayId: f['stay_id']! as String,
    autor: f['autor']! as String,
    estrellas: f['estrellas']! as int,
    comentario: f['comentario']! as String,
    creadaEn: DateTime.fromMillisecondsSinceEpoch(f['creada_ms']! as int),
  );
}
