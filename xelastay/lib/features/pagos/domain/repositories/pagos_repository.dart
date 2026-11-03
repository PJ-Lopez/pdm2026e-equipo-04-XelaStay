import '../entities/pago.dart';

abstract interface class PagosRepository {
  /// Paga una reserva aceptada y la deja confirmada. Lanza [PagoException]
  /// si no está aceptada o si ya se pagó.
  Future<Pago> pagar(int reservaId, MetodoPago metodo);

  /// El comprobante de una reserva, o null si todavía no se pagó.
  Future<Pago?> deReserva(int reservaId);
}
