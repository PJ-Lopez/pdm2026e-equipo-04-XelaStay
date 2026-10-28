import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../stays/domain/entities/stay.dart';
import '../../domain/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => throw StateError('FavoritesRepository no está configurado.'),
);

final favoritesProvider = FutureProvider<List<Stay>>(
  (ref) => ref.watch(favoritesRepositoryProvider).getFavorites(),
  retry: (_, _) => null,
);
