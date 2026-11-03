import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../booking/presentation/providers/reservas_providers.dart';
import '../../data/datasources/pagos_local_data_source.dart';
import '../../data/repositories/pagos_repository_impl.dart';
import '../../domain/entities/pago.dart';
import '../../domain/repositories/pagos_repository.dart';

final pagosRepositoryProvider = Provider<PagosRepository>(
  (ref) => PagosRepositoryImpl(
    localDataSource: PagosLocalDataSource(reloj: ref.watch(relojProvider)),
  ),
);

/// Comprobante de una reserva (null si todavía no se pagó).
final pagoDeReservaProvider = FutureProvider.family<Pago?, int>(
  (ref, reservaId) => ref.watch(pagosRepositoryProvider).deReserva(reservaId),
  retry: (_, _) => null,
);
