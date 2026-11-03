import '../entities/resena.dart';

abstract interface class ResenasRepository {
  /// Reseñas de un alojamiento, la más nueva primero.
  Future<List<Resena>> deAlojamiento(String stayId);

  /// La reseña de una reserva, o null si todavía no se escribió.
  Future<Resena?> deReserva(int reservaId);

  /// Publica la reseña de una estadía completada. Una por reserva.
  Future<Resena> publicar({
    required int reservaId,
    required int estrellas,
    String comentario = '',
  });
}
