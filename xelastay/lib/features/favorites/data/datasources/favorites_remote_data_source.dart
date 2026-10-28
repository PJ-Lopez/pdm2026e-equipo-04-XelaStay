import '../../../../core/network/api_client.dart';

class FavoritesRemoteDataSource {
  const FavoritesRemoteDataSource(this._apiClient, this._readToken);

  final ApiClient _apiClient;
  final Future<String?> Function() _readToken;

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final response = await _apiClient.get(
      '/favorites',
      token: await _readToken(),
    );
    final items = response['items'];
    if (items is! List) {
      throw const FormatException(
        'No pudimos leer tus alojamientos guardados.',
      );
    }
    return items.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<void> addFavorite(String stayId) async {
    await _apiClient.post('/favorites/$stayId', token: await _readToken());
  }

  Future<void> removeFavorite(String stayId) async {
    await _apiClient.delete('/favorites/$stayId', token: await _readToken());
  }
}
