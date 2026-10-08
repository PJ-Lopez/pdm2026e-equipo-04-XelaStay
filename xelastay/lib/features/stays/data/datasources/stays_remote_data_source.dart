import '../../../../core/network/api_client.dart';

class StaysRemoteDataSource {
  const StaysRemoteDataSource(this._apiClient, this._readToken);

  final ApiClient _apiClient;
  final Future<String?> Function() _readToken;

  Future<List<Map<String, dynamic>>> getPublicStays() async {
    final token = await _readToken();
    final response = await _apiClient.get('/stays', token: token);
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('No pudimos cargar los alojamientos.');
    }
    return items.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
