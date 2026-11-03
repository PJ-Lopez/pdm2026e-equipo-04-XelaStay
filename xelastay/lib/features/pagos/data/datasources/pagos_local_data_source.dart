import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/formatos.dart';
import '../../../booking/domain/entities/reserva.dart';
import '../../domain/entities/pago.dart';

/// Único lugar donde se escribe SQL de la tabla `pagos`.
class PagosLocalDataSource {
  PagosLocalDataSource({AppDatabase? database, DateTime Function()? reloj})
    : _database = database ?? AppDatabase.instance,
      _reloj = reloj ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _reloj;

  /// Todo en UNA transacción: revisar el estado, guardar el pago y confirmar
  /// la reserva. Si algo falla, no queda un pago sin reserva confirmada ni
  /// una reserva confirmada sin pago.
  Future<Pago> pagar(int reservaId, MetodoPago metodo) async {
    final db = await _database.database;
    try {
      final pagoId = await db.transaction((txn) async {
        final filas = await txn.query(
          'reservas',
          columns: ['estado', 'precio_noche_centavos', 'entrada', 'salida'],
          where: 'id = ?',
          whereArgs: [reservaId],
        );
        if (filas.isEmpty) {
          throw const PagoException('Esa reserva ya no existe.');
        }
        final r = filas.single;
        final estado = r['estado']! as String;
        if (estado == EstadoReserva.confirmada.name ||
            estado == EstadoReserva.completada.name) {
          throw const PagoException('Esta reserva ya está pagada.');
        }
        if (estado != EstadoReserva.aceptada.name) {
          throw const PagoException(
            'Solo se paga una reserva que el anfitrión ya aceptó.',
          );
        }
        // El monto se calcula con lo guardado en la base, no con lo que
        // muestra la pantalla.
        final noches = desdeIso(
          r['salida']! as String,
        ).difference(desdeIso(r['entrada']! as String)).inDays;
        final desglose = Desglose.de(
          r['precio_noche_centavos']! as int,
          noches,
        );
        final id = await txn.insert('pagos', {
          'reserva_id': reservaId,
          'metodo': metodo.name,
          'subtotal_centavos': desglose.subtotalCentavos,
          'servicio_centavos': desglose.servicioCentavos,
          'total_centavos': desglose.totalCentavos,
          'referencia': 'XS-${reservaId.toString().padLeft(5, '0')}',
          'pagado_ms': _reloj().millisecondsSinceEpoch,
        });
        await txn.update(
          'reservas',
          {'estado': EstadoReserva.confirmada.name},
          where: 'id = ? AND estado = ?',
          whereArgs: [reservaId, EstadoReserva.aceptada.name],
        );
        return id;
      });
      return (await _porId(db, pagoId))!;
    } on DatabaseException catch (e) {
      // UNIQUE(reserva_id): dos toques casi al mismo tiempo.
      if (e.isUniqueConstraintError()) {
        throw const PagoException('Esta reserva ya está pagada.');
      }
      rethrow;
    }
  }

  Future<Pago?> deReserva(int reservaId) async {
    final db = await _database.database;
    final filas = await db.query(
      'pagos',
      where: 'reserva_id = ?',
      whereArgs: [reservaId],
    );
    return filas.isEmpty ? null : _desdeFila(filas.single);
  }

  Future<Pago?> _porId(Database db, int id) async {
    final filas = await db.query('pagos', where: 'id = ?', whereArgs: [id]);
    return filas.isEmpty ? null : _desdeFila(filas.single);
  }

  Pago _desdeFila(Map<String, Object?> f) => Pago(
    id: f['id']! as int,
    reservaId: f['reserva_id']! as int,
    metodo: MetodoPago.values.byName(f['metodo']! as String),
    subtotalCentavos: f['subtotal_centavos']! as int,
    servicioCentavos: f['servicio_centavos']! as int,
    totalCentavos: f['total_centavos']! as int,
    referencia: f['referencia']! as String,
    pagadoEn: DateTime.fromMillisecondsSinceEpoch(f['pagado_ms']! as int),
  );
}
