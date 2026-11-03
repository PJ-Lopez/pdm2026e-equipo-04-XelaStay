import '../../../../core/database/app_database.dart';
import '../../../booking/domain/entities/reserva.dart';
import '../../domain/entities/mensaje.dart';

/// Único lugar donde se escribe SQL de la tabla `mensajes`.
class ChatLocalDataSource {
  ChatLocalDataSource({AppDatabase? database, DateTime Function()? reloj})
    : _database = database ?? AppDatabase.instance,
      _reloj = reloj ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _reloj;

  Future<List<Mensaje>> mensajesDe(int reservaId) async {
    final db = await _database.database;
    final filas = await db.query(
      'mensajes',
      where: 'reserva_id = ?',
      whereArgs: [reservaId],
      orderBy: 'enviado_ms, id',
    );
    return [for (final f in filas) _desdeFila(f)];
  }

  /// Revisa que la reserva siga abierta y guarda el mensaje, en la misma
  /// transacción.
  Future<Mensaje> enviar({
    required int reservaId,
    required AutorMensaje autor,
    required String texto,
  }) async {
    final db = await _database.database;
    final id = await db.transaction((txn) async {
      final filas = await txn.query(
        'reservas',
        columns: ['estado'],
        where: 'id = ?',
        whereArgs: [reservaId],
      );
      if (filas.isEmpty) {
        throw const ChatException('Esa reserva ya no existe.');
      }
      final estado = filas.single['estado'];
      if (estado == EstadoReserva.cancelada.name ||
          estado == EstadoReserva.rechazada.name) {
        throw const ChatException(
          'Esta reserva se cerró; ya no se pueden enviar mensajes.',
        );
      }
      return txn.insert('mensajes', {
        'reserva_id': reservaId,
        'autor': autor.name,
        'texto': texto,
        'enviado_ms': _reloj().millisecondsSinceEpoch,
      });
    });
    final filas = await db.query('mensajes', where: 'id = ?', whereArgs: [id]);
    return _desdeFila(filas.single);
  }

  Mensaje _desdeFila(Map<String, Object?> f) => Mensaje(
    id: f['id']! as int,
    reservaId: f['reserva_id']! as int,
    autor: AutorMensaje.values.byName(f['autor']! as String),
    texto: f['texto']! as String,
    enviadoEn: DateTime.fromMillisecondsSinceEpoch(f['enviado_ms']! as int),
  );
}
