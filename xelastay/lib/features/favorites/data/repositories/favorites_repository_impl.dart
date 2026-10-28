import '../../../stays/data/models/stay_model.dart';
import '../../../stays/domain/entities/stay.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_data_source.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._remote);

  final FavoritesRemoteDataSource _remote;

  @override
  Future<List<Stay>> getFavorites() async => (await _remote.getFavorites())
      .map(StayModel.fromJson)
      .toList(growable: false);

  @override
  Future<void> addFavorite(String stayId) => _remote.addFavorite(stayId);

  @override
  Future<void> removeFavorite(String stayId) => _remote.removeFavorite(stayId);
}
