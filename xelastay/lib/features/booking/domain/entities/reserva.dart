import '../../../../core/utils/formatos.dart';

/// Estados de una reserva. Una solicitud pendiente nunca se presenta como
/// confirmada: cada estado dice qué pasó y cuál es el siguiente paso.
enum EstadoReserva {
  pendiente('Esperando al anfitrión', 'Tu solicitud está con el anfitrión.'),
  aceptada(
    'Falta el pago',
    'El anfitrión aceptó. Paga para confirmar la estadía.',
  ),
  confirmada('Confirmada', 'Tu estadía está confirmada.'),
  rechazada(
    'No se confirmó',
    'El anfitrión no aceptó o las fechas ya no estaban disponibles.',
  ),
  cancelada('Cancelada', 'Cancelaste esta solicitud.'),
  completada('Completada', 'La estadía terminó.');

  const EstadoReserva(this.etiqueta, this.descripcion);

  final String etiqueta;
  final String descripcion;

  /// Mientras está así, la solicitud se puede cancelar.
  bool get cancelable =>
      this == EstadoReserva.pendiente || this == EstadoReserva.aceptada;
}

/// Pestañas de Reservas.
enum GrupoReserva { pendientes, proximas, anteriores }

class Reserva {
  const Reserva({
    required this.id,
    required this.stayId,
    required this.titulo,
    required this.zona,
    required this.precioNocheCentavos,
    required this.entrada,
    required this.salida,
    required this.huespedes,
    required this.huespedId,
    required this.huespedNombre,
    required this.estado,
    required this.creadaEn,
  });

  final int id;
  final String stayId;
  final String titulo;
  final String zona;
  final int precioNocheCentavos;

  /// Día de llegada y día de salida (sin hora).
  final DateTime entrada;
  final DateTime salida;
  final int huespedes;
  final String huespedId;
  final String huespedNombre;
  final EstadoReserva estado;
  final DateTime creadaEn;

  int get noches => salida.difference(entrada).inDays;

  Desglose get desglose => Desglose.de(precioNocheCentavos, noches);

  /// En qué pestaña de Reservas aparece, según el estado y la fecha de hoy.
  GrupoReserva grupo(DateTime hoy) {
    switch (estado) {
      case EstadoReserva.pendiente:
      case EstadoReserva.aceptada:
        return GrupoReserva.pendientes;
      case EstadoReserva.confirmada:
        return salida.isAfter(soloFecha(hoy))
            ? GrupoReserva.proximas
            : GrupoReserva.anteriores;
      case EstadoReserva.rechazada:
      case EstadoReserva.cancelada:
      case EstadoReserva.completada:
        return GrupoReserva.anteriores;
    }
  }
}

/// Cuánto cuesta una estadía. Todo en centavos (`int`), nunca `double`.
class Desglose {
  const Desglose({
    required this.noches,
    required this.subtotalCentavos,
    required this.servicioCentavos,
  });

  /// Tarifa de servicio de XelaStay, en porcentaje del subtotal.
  static const porcentajeServicio = 10;

  factory Desglose.de(int precioNocheCentavos, int noches) {
    final subtotal = precioNocheCentavos * noches;
    // Redondeo al centavo más cercano, sin pasar por double.
    final servicio = (subtotal * porcentajeServicio + 50) ~/ 100;
    return Desglose(
      noches: noches,
      subtotalCentavos: subtotal,
      servicioCentavos: servicio,
    );
  }

  final int noches;
  final int subtotalCentavos;
  final int servicioCentavos;

  int get totalCentavos => subtotalCentavos + servicioCentavos;
}

/// Datos para pedir una reserva nueva.
class SolicitudReserva {
  const SolicitudReserva({
    required this.stayId,
    required this.titulo,
    required this.zona,
    required this.precioNocheCentavos,
    required this.capacidad,
    required this.entrada,
    required this.salida,
    required this.huespedes,
    required this.huespedId,
    required this.huespedNombre,
  });

  final String stayId;
  final String titulo;
  final String zona;
  final int precioNocheCentavos;
  final int capacidad;
  final DateTime entrada;
  final DateTime salida;
  final int huespedes;
  final String huespedId;
  final String huespedNombre;
}

/// Error con un mensaje listo para mostrarle al usuario (nunca SQL).
class ReservaException implements Exception {
  const ReservaException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
