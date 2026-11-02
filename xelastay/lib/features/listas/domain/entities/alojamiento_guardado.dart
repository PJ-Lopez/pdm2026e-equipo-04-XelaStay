/// Copia local de un alojamiento que el huésped guardó para verlo después,
/// incluso sin conexión.
class AlojamientoGuardado {
  const AlojamientoGuardado({
    required this.stayId,
    required this.titulo,
    required this.zona,
    required this.precioCentavos,
    required this.guardadoEn,
  });

  /// Id del alojamiento en el API (`Stay.id`).
  final String stayId;
  final String titulo;
  final String zona;

  /// Precio por noche en centavos, como lo entrega el API.
  final int precioCentavos;
  final DateTime guardadoEn;
}
