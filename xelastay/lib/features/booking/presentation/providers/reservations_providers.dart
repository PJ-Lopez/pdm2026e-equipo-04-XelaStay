import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_reservations_repository.dart';
import '../../domain/entities/guest_reservation.dart';
import '../../domain/repositories/reservations_repository.dart';

final reservationsRepositoryProvider = Provider<ReservationsRepository>(
  (ref) => MockReservationsRepository(),
);

class ReservationFilterNotifier extends Notifier<ReservationFilter> {
  @override
  ReservationFilter build() => const ReservationFilter();

  void selectGroup(ReservationGroup group) {
    state = state.copyWith(group: group);
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }
}

final reservationFilterProvider =
    NotifierProvider<ReservationFilterNotifier, ReservationFilter>(
      ReservationFilterNotifier.new,
    );

final reservationsProvider = FutureProvider<ReservationListResult>((ref) {
  final filter = ref.watch(reservationFilterProvider);
  final repository = ref.watch(reservationsRepositoryProvider);
  return repository.getReservations(filter);
}, retry: (_, _) => null);
