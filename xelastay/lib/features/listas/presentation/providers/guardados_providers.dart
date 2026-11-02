import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../stays/domain/entities/stay.dart';
import '../../../stays/domain/usecases/get_public_stays.dart';
import '../../data/repositories/guardados_repository_impl.dart';
import '../../domain/entities/alojamiento_guardado.dart';
import '../../domain/repositories/guardados_repository.dart';

final guardadosRepositoryProvider = Provider<GuardadosRepository>(
  (ref) => GuardadosRepositoryImpl(),
);

/// Alojamientos de UNA lista. Al agregar o quitar se invalida para releer.
final guardadosDeListaProvider =
    FutureProvider.family<List<AlojamientoGuardado>, int>(
      (ref, listaId) => ref.watch(guardadosRepositoryProvider).deLista(listaId),
      retry: (_, _) => null,
    );

/// El catálogo viene del API. `main.dart` lo configura con
/// `overrideWithValue`; las pruebas usan un repositorio simulado.
final getPublicStaysProvider = Provider<GetPublicStays>(
  (ref) => throw UnimplementedError(
    'Configura getPublicStaysProvider en el ProviderScope de main.dart.',
  ),
);

/// Alojamientos del catálogo para agregarlos a una lista.
final catalogoProvider = FutureProvider<List<Stay>>(
  (ref) => ref.watch(getPublicStaysProvider)(),
  retry: (_, _) => null,
);
