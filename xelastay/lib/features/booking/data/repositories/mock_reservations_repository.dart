import '../../domain/entities/guest_reservation.dart';
import '../../domain/repositories/reservations_repository.dart';

class MockReservationsRepository implements ReservationsRepository {
  MockReservationsRepository() : _reservations = List.of(_mockReservations);

  final List<GuestReservation> _reservations;

  @override
  Future<ReservationListResult> getReservations(
    ReservationFilter filter,
  ) async {
    final counts = <ReservationGroup, int>{
      for (final group in ReservationGroup.values)
        group: _reservations
            .where((reservation) => reservation.group == group)
            .length,
    };
    final query = filter.query.trim().toLowerCase();
    final items = _reservations.where((reservation) {
      if (reservation.group != filter.group) return false;
      if (query.isEmpty) return true;
      return '${reservation.stayName} ${reservation.location} ${reservation.statusMessage}'
          .toLowerCase()
          .contains(query);
    }).toList();
    return ReservationListResult(items: items, counts: counts);
  }

  @override
  Future<void> deleteReservation(String id) async {
    final index = _reservations.indexWhere(
      (reservation) => reservation.id == id,
    );
    if (index < 0) throw StateError('La reserva ya no existe.');
    _reservations.removeAt(index);
  }

  @override
  Future<void> restoreReservation(GuestReservation reservation) async {
    if (_reservations.any((item) => item.id == reservation.id)) return;
    _reservations.add(reservation);
    _reservations.sort((a, b) {
      final groupOrder = a.group.index.compareTo(b.group.index);
      if (groupOrder != 0) return groupOrder;
      return b.checkIn.compareTo(a.checkIn);
    });
  }
}

final _mockReservations = [
  GuestReservation(
    id: 'reservation-pending',
    stayName: 'Cabaña Mirador Santa María',
    location: 'Valle de Palajunoj, Quetzaltenango',
    checkIn: DateTime(2026, 11, 14),
    checkOut: DateTime(2026, 11, 17),
    guestCount: 2,
    group: ReservationGroup.pending,
    status: 'awaiting_host',
    statusMessage: 'Tu solicitud está con el anfitrión',
    statusDetail:
        'Doña Carmen suele responder en menos de 3 horas. Te notificaremos en cuanto confirme.',
    createdLabel: 'Ayer a las 18:42 hrs · Mensaje de cortesía incluido',
    responseDeadline:
        'Tiene hasta hoy a las 18:42 para aceptar o sugerir ajuste',
    verified: true,
  ),
  GuestReservation(
    id: 'reservation-upcoming',
    stayName: 'Casa de Adobe en el Centro',
    location: 'Zona 1, Quetzaltenango',
    checkIn: DateTime(2026, 12, 3),
    checkOut: DateTime(2026, 12, 6),
    guestCount: 3,
    group: ReservationGroup.upcoming,
    status: 'confirmed',
    statusMessage: 'Reserva confirmada',
    statusDetail:
        'Tu llegada está lista. Consulta los detalles antes de viajar.',
    createdLabel: 'Confirmada por el anfitrión',
    responseDeadline: 'Código de acceso e instrucciones disponibles',
    verified: true,
  ),
  GuestReservation(
    id: 'reservation-past-1',
    stayName: 'Loft Vista al Volcán',
    location: 'Zona 3, Quetzaltenango',
    checkIn: DateTime(2026, 9, 8),
    checkOut: DateTime(2026, 9, 10),
    guestCount: 2,
    group: ReservationGroup.past,
    status: 'completed',
    statusMessage: 'Estadía completada',
    statusDetail:
        'Gracias por hospedarte. Cuéntale a la comunidad cómo te fue.',
    createdLabel: 'Estadía finalizada',
    responseDeadline: 'Puedes dejar una reseña',
    verified: true,
  ),
  GuestReservation(
    id: 'reservation-past-2',
    stayName: 'Habitación Jardín de Xela',
    location: 'Zona 9, Quetzaltenango',
    checkIn: DateTime(2026, 7, 2),
    checkOut: DateTime(2026, 7, 4),
    guestCount: 1,
    group: ReservationGroup.past,
    status: 'cancelled',
    statusMessage: 'Solicitud cancelada',
    statusDetail: 'Esta solicitud ya no está activa.',
    createdLabel: 'Cancelada',
    responseDeadline: 'Ver detalle de la solicitud',
    verified: false,
  ),
];
