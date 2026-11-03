/// Quién escribió el mensaje. En esta versión el chat vive en el teléfono
/// (ADR-0001): la misma persona puede escribir como huésped o como anfitrión.
enum AutorMensaje {
  huesped('Huésped'),
  anfitrion('Anfitrión');

  const AutorMensaje(this.etiqueta);

  final String etiqueta;
}

class Mensaje {
  const Mensaje({
    required this.id,
    required this.reservaId,
    required this.autor,
    required this.texto,
    required this.enviadoEn,
  });

  final int id;
  final int reservaId;
  final AutorMensaje autor;
  final String texto;
  final DateTime enviadoEn;
}

/// Error con un mensaje listo para mostrarle al usuario (nunca SQL).
class ChatException implements Exception {
  const ChatException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
