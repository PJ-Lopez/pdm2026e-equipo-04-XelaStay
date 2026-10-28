import '../entities/guest_reservation.dart';

class ReservationListResult {
  const ReservationListResult({required this.items, required this.counts});

  final List<GuestReservation> items;
  final Map<ReservationGroup, int> counts;
}

abstract interface class ReservationsRepository {
  Future<ReservationListResult> getReservations(ReservationFilter filter);
  Future<void> deleteReservation(String id);
  Future<void> restoreReservation(GuestReservation reservation);
}
