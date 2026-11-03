import '../entities/mensaje.dart';

abstract interface class ChatRepository {
  /// Mensajes de una reserva, del más viejo al más nuevo.
  Future<List<Mensaje>> mensajesDe(int reservaId);

  /// Lanza [ChatException] si el texto está vacío o la reserva ya se cerró.
  Future<Mensaje> enviar({
    required int reservaId,
    required AutorMensaje autor,
    required String texto,
  });
}
