/// Cómo pagó el huésped. Es un pago SIMULADO: la app no cobra ni pide datos
/// de tarjeta; solo registra la elección (ver docs/adr/0003-pago-simulado.md).
enum MetodoPago {
  tarjeta('Tarjeta (simulado)'),
  transferencia('Transferencia bancaria'),
  efectivo('Efectivo al llegar');

  const MetodoPago(this.etiqueta);

  final String etiqueta;
}

class Pago {
  const Pago({
    required this.id,
    required this.reservaId,
    required this.metodo,
    required this.subtotalCentavos,
    required this.servicioCentavos,
    required this.totalCentavos,
    required this.referencia,
    required this.pagadoEn,
  });

  final int id;
  final int reservaId;
  final MetodoPago metodo;
  final int subtotalCentavos;
  final int servicioCentavos;
  final int totalCentavos;

  /// Código del comprobante, por ejemplo "XS-00012".
  final String referencia;
  final DateTime pagadoEn;
}

/// Error con un mensaje listo para mostrarle al usuario (nunca SQL).
class PagoException implements Exception {
  const PagoException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
