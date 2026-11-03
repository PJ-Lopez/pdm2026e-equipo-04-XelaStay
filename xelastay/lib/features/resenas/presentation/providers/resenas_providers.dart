import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../booking/presentation/providers/reservas_providers.dart';
import '../../data/datasources/resenas_local_data_source.dart';
import '../../data/repositories/resenas_repository_impl.dart';
import '../../domain/entities/resena.dart';
import '../../domain/repositories/resenas_repository.dart';

final resenasRepositoryProvider = Provider<ResenasRepository>(
  (ref) => ResenasRepositoryImpl(
    localDataSource: ResenasLocalDataSource(reloj: ref.watch(relojProvider)),
  ),
);

/// Reseñas de un alojamiento (para su detalle).
final resenasDeAlojamientoProvider =
    FutureProvider.family<List<Resena>, String>(
      (ref, stayId) =>
          ref.watch(resenasRepositoryProvider).deAlojamiento(stayId),
      retry: (_, _) => null,
    );

/// La reseña de una reserva (null si todavía no hay).
final resenaDeReservaProvider = FutureProvider.family<Resena?, int>(
  (ref, reservaId) => ref.watch(resenasRepositoryProvider).deReserva(reservaId),
  retry: (_, _) => null,
);

/// Después de publicar: el detalle de la reserva y el del alojamiento vuelven
/// a leer de la base.
void refrescarResenas(WidgetRef ref, Resena resena) {
  ref.invalidate(resenaDeReservaProvider(resena.reservaId));
  ref.invalidate(resenasDeAlojamientoProvider(resena.stayId));
}
