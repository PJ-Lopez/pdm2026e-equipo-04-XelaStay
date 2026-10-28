import '../../../stays/domain/entities/stay.dart';

abstract interface class FavoritesRepository {
  Future<List<Stay>> getFavorites();
  Future<void> addFavorite(String stayId);
  Future<void> removeFavorite(String stayId);
}
