import '../entities/reserva.dart';

abstract interface class ReservasRepository {
  /// Reservas que hizo esta persona, las más nuevas primero.
  Future<List<Reserva>> delHuesped(String huespedId);

  Future<Reserva> porId(int id);

  /// Crea la solicitud en estado `pendiente`. Lanza [ReservaException] si
  /// las fechas no son válidas o ya están tomadas.
  Future<Reserva> solicitar(SolicitudReserva solicitud);

  /// Solo se cancela si está pendiente o aceptada.
  Future<void> cancelar(int id);
}
