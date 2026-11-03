import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../booking/presentation/providers/reservas_providers.dart';
import '../../data/datasources/chat_local_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/mensaje.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(
    localDataSource: ChatLocalDataSource(reloj: ref.watch(relojProvider)),
  ),
);

/// Mensajes de una reserva. Después de enviar se invalida para releer.
final mensajesProvider = FutureProvider.family<List<Mensaje>, int>(
  (ref, reservaId) => ref.watch(chatRepositoryProvider).mensajesDe(reservaId),
  retry: (_, _) => null,
);
