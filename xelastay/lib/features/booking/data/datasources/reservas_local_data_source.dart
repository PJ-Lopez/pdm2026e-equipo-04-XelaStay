import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/formatos.dart';
import '../../domain/entities/reserva.dart';

/// Único lugar donde se escribe SQL de la tabla `reservas`.
class ReservasLocalDataSource {
  ReservasLocalDataSource({AppDatabase? database, DateTime Function()? reloj})
    : _database = database ?? AppDatabase.instance,
      _reloj = reloj ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _reloj;

  Future<List<Reserva>> delHuesped(String huespedId) async {
    final db = await _database.database;
    final filas = await db.query(
      'reservas',
      where: 'huesped_id = ?',
      whereArgs: [huespedId],
      orderBy: 'creada_ms DESC, id DESC',
    );
    return [for (final f in filas) desdeFila(f)];
  }

  Future<Reserva> porId(int id) async {
    final db = await _database.database;
    final filas = await db.query('reservas', where: 'id = ?', whereArgs: [id]);
    if (filas.isEmpty) {
      throw const ReservaException('Esa reserva ya no existe.');
    }
    return desdeFila(filas.single);
  }

  /// La revisión de disponibilidad y el INSERT van en la MISMA transacción:
  /// si dos solicitudes llegan a la vez, la segunda ya ve a la primera.
  Future<Reserva> solicitar(SolicitudReserva s) async {
    final db = await _database.database;
    final entrada = fechaIso(s.entrada);
    final salida = fechaIso(s.salida);
    final id = await db.transaction((txn) async {
      // Fechas tomadas: una reserva aceptada o confirmada que se empalma.
      final tomadas = Sqflite.firstIntValue(
        await txn.rawQuery(
          '''
          SELECT COUNT(*) FROM reservas
          WHERE stay_id = ? AND estado IN ('aceptada', 'confirmada')
            AND entrada < ? AND salida > ?
          ''',
          [s.stayId, salida, entrada],
        ),
      )!;
      if (tomadas > 0) {
        throw const ReservaException(
          'Esas fechas ya no están disponibles. Prueba con otras.',
        );
      }
      // La misma persona no manda dos veces la misma solicitud.
      final repetidas = Sqflite.firstIntValue(
        await txn.rawQuery(
          '''
          SELECT COUNT(*) FROM reservas
          WHERE stay_id = ? AND huesped_id = ? AND estado = 'pendiente'
            AND entrada < ? AND salida > ?
          ''',
          [s.stayId, s.huespedId, salida, entrada],
        ),
      )!;
      if (repetidas > 0) {
        throw const ReservaException(
          'Ya enviaste una solicitud para esas fechas.',
        );
      }
      return txn.insert('reservas', {
        'stay_id': s.stayId,
        'titulo': s.titulo,
        'zona': s.zona,
        'precio_noche_centavos': s.precioNocheCentavos,
        'entrada': entrada,
        'salida': salida,
        'huespedes': s.huespedes,
        'huesped_id': s.huespedId,
        'huesped_nombre': s.huespedNombre,
        'estado': EstadoReserva.pendiente.name,
        'creada_ms': _reloj().millisecondsSinceEpoch,
      });
    });
    return porId(id);
  }

  /// UPDATE condicionado: solo cambia si sigue en un estado cancelable.
  Future<void> cancelar(int id) async {
    final db = await _database.database;
    final cambiadas = await db.update(
      'reservas',
      {'estado': EstadoReserva.cancelada.name},
      where: "id = ? AND estado IN ('pendiente', 'aceptada')",
      whereArgs: [id],
    );
    if (cambiadas == 0) {
      throw const ReservaException(
        'Esta reserva ya no se puede cancelar desde la app.',
      );
    }
  }

  /// Las más próximas primero.
  Future<List<Reserva>> todas() async {
    final db = await _database.database;
    final filas = await db.query('reservas', orderBy: 'entrada, id');
    return [for (final f in filas) desdeFila(f)];
  }

  /// Aceptar es la otra mitad de las reservas concurrentes: en UNA
  /// transacción se acepta esta solicitud y se rechazan las pendientes que se
  /// empalman, para que no queden dos estadías en las mismas fechas.
  Future<int> aceptar(int id) async {
    final db = await _database.database;
    return db.transaction((txn) async {
      final filas = await txn.query(
        'reservas',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (filas.isEmpty) {
        throw const ReservaException('Esa solicitud ya no existe.');
      }
      final r = filas.single;
      if (r['estado'] != EstadoReserva.pendiente.name) {
        throw const ReservaException('Esta solicitud ya fue atendida.');
      }
      final ocupadas = Sqflite.firstIntValue(
        await txn.rawQuery(
          '''
          SELECT COUNT(*) FROM reservas
          WHERE stay_id = ? AND id <> ? AND estado IN ('aceptada', 'confirmada')
            AND entrada < ? AND salida > ?
          ''',
          [r['stay_id'], id, r['salida'], r['entrada']],
        ),
      )!;
      if (ocupadas > 0) {
        throw const ReservaException(
          'Ya aceptaste otra reserva en esas fechas.',
        );
      }
      await txn.update(
        'reservas',
        {'estado': EstadoReserva.aceptada.name},
        where: 'id = ?',
        whereArgs: [id],
      );
      // Las demás solicitudes de esas fechas quedan rechazadas.
      return txn.update(
        'reservas',
        {'estado': EstadoReserva.rechazada.name},
        where:
            "stay_id = ? AND id <> ? AND estado = 'pendiente' "
            'AND entrada < ? AND salida > ?',
        whereArgs: [r['stay_id'], id, r['salida'], r['entrada']],
      );
    });
  }

  Future<void> rechazar(int id) async {
    final db = await _database.database;
    final cambiadas = await db.update(
      'reservas',
      {'estado': EstadoReserva.rechazada.name},
      where: "id = ? AND estado = 'pendiente'",
      whereArgs: [id],
    );
    if (cambiadas == 0) {
      throw const ReservaException('Esta solicitud ya fue atendida.');
    }
  }

  /// Solo una estadía confirmada cuya llegada ya pasó (o es hoy).
  Future<void> completar(int id, DateTime hoy) async {
    final db = await _database.database;
    final cambiadas = await db.update(
      'reservas',
      {'estado': EstadoReserva.completada.name},
      where: "id = ? AND estado = 'confirmada' AND entrada <= ?",
      whereArgs: [id, fechaIso(hoy)],
    );
    if (cambiadas == 0) {
      throw const ReservaException(
        'Solo se completa una estadía confirmada que ya empezó.',
      );
    }
  }

  static Reserva desdeFila(Map<String, Object?> f) => Reserva(
    id: f['id']! as int,
    stayId: f['stay_id']! as String,
    titulo: f['titulo']! as String,
    zona: f['zona']! as String,
    precioNocheCentavos: f['precio_noche_centavos']! as int,
    entrada: desdeIso(f['entrada']! as String),
    salida: desdeIso(f['salida']! as String),
    huespedes: f['huespedes']! as int,
    huespedId: f['huesped_id']! as String,
    huespedNombre: f['huesped_nombre']! as String,
    estado: EstadoReserva.values.byName(f['estado']! as String),
    creadaEn: DateTime.fromMillisecondsSinceEpoch(f['creada_ms']! as int),
  );
}
