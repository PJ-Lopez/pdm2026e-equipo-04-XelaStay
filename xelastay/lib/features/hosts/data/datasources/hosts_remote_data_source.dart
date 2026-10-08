import '../../../../core/network/api_client.dart';
import '../../domain/entities/host_stay.dart';

class HostsRemoteDataSource {
  const HostsRemoteDataSource(this._apiClient, this._readToken);

  final ApiClient _apiClient;
  final Future<String?> Function() _readToken;

  Future<Map<String, dynamic>> createStay(HostStayDraft draft) async {
    final token = await _readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_REQUIRED',
        message: 'Inicia sesión para registrar un alojamiento.',
      );
    }
    return _apiClient.post(
      '/stays/host/stays',
      token: token,
      body: {
        'title': draft.title,
        'description': draft.description,
        'propertyType': draft.propertyType,
        'capacity': draft.capacity,
        'bedrooms': draft.bedrooms,
        'beds': draft.beds,
        'bathrooms': draft.bathrooms,
        'priceAmount': (draft.priceInQuetzales * 100).round(),
        'currency': 'GTQ',
        'rules': draft.rules,
        'latitude': draft.latitude,
        'longitude': draft.longitude,
        'address': draft.address,
        'zoneNeighborhood': draft.zone,
        'localReference': draft.localReference,
      },
    );
  }
}
