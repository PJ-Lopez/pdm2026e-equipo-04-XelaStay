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

  // ---- Panel del anfitrión ----

  /// Todas las solicitudes guardadas en este teléfono (ver ADR-0001).
  Future<List<Reserva>> todas();

  /// Acepta una solicitud pendiente y rechaza las pendientes que se empalman
  /// con ella. Devuelve cuántas se rechazaron así.
  Future<int> aceptar(int id);

  Future<void> rechazar(int id);

  /// Cierra una estadía confirmada que ya empezó.
  Future<void> completar(int id);
}
