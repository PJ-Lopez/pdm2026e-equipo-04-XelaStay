import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/listas_repository_impl.dart';
import '../../domain/entities/lista.dart';
import '../../domain/repositories/listas_repository.dart';

/// En las pruebas se reemplaza con `overrideWithValue` por uno falso.
final listasRepositoryProvider = Provider<ListasRepository>(
  (ref) => ListasRepositoryImpl(),
);

/// Después de crear, editar o borrar se hace `ref.invalidate(listasProvider)`:
/// la pantalla vuelve a leer de la base en vez de cambiar la lista a mano.
final listasProvider = FutureProvider<List<Lista>>(
  (ref) => ref.watch(listasRepositoryProvider).obtenerTodas(),
  // Riverpod 3 reintenta solo los errores; aquí se muestra el error y el
  // usuario decide reintentar.
  retry: (_, _) => null,
);
