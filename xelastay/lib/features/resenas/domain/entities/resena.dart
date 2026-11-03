/// Reseña de una estadía. Solo existe si la reserva se completó, así que
/// siempre viene de alguien que de verdad se hospedó.
class Resena {
  const Resena({
    required this.id,
    required this.reservaId,
    required this.stayId,
    required this.autor,
    required this.estrellas,
    required this.comentario,
    required this.creadaEn,
  });

  static const estrellasMinimas = 1;
  static const estrellasMaximas = 5;

  final int id;
  final int reservaId;
  final String stayId;

  /// Nombre del huésped, tomado de la reserva (no se escribe a mano).
  final String autor;
  final int estrellas;
  final String comentario;
  final DateTime creadaEn;
}

/// Palabra que acompaña a las estrellas, para no depender solo del dibujo.
String etiquetaEstrellas(int estrellas) => switch (estrellas) {
  1 => 'Mala',
  2 => 'Regular',
  3 => 'Buena',
  4 => 'Muy buena',
  5 => 'Excelente',
  _ => '',
};

/// Error con un mensaje listo para mostrarle al usuario (nunca SQL).
class ResenaException implements Exception {
  const ResenaException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
