import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/reservas_repository_impl.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/repositories/reservas_repository.dart';

/// Reloj inyectable: en las pruebas "hoy" es una fecha fija.
final relojProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final reservasRepositoryProvider = Provider<ReservasRepository>(
  (ref) => ReservasRepositoryImpl(reloj: ref.watch(relojProvider)),
);

/// Reservas de una persona. Después de solicitar o cancelar se invalida.
final reservasDelHuespedProvider = FutureProvider.family<List<Reserva>, String>(
  (ref, huespedId) =>
      ref.watch(reservasRepositoryProvider).delHuesped(huespedId),
  retry: (_, _) => null,
);

/// Una reserva fresca de la base (el detalle la vuelve a leer tras cada acción).
final reservaPorIdProvider = FutureProvider.family<Reserva, int>(
  (ref, id) => ref.watch(reservasRepositoryProvider).porId(id),
  retry: (_, _) => null,
);

/// Panel del anfitrión: todas las solicitudes guardadas en el teléfono.
final solicitudesProvider = FutureProvider<List<Reserva>>(
  (ref) => ref.watch(reservasRepositoryProvider).todas(),
  retry: (_, _) => null,
);

/// Después de cualquier cambio en una reserva: Reservas, su detalle y el panel
/// del anfitrión se vuelven a leer de la base, no se cambian a mano.
void refrescarReservas(WidgetRef ref) {
  ref.invalidate(reservasDelHuespedProvider);
  ref.invalidate(reservaPorIdProvider);
  ref.invalidate(solicitudesProvider);
}
