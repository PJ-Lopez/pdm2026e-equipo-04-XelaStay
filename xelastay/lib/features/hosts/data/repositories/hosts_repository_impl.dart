import '../../domain/entities/host_stay.dart';
import '../../domain/repositories/hosts_repository.dart';
import '../datasources/hosts_remote_data_source.dart';
import '../models/host_stay_model.dart';

class HostsRepositoryImpl implements HostsRepository {
  const HostsRepositoryImpl(this._remote);
  final HostsRemoteDataSource _remote;

  @override
  Future<HostStay> createStay(HostStayDraft draft) async {
    final response = await _remote.createStay(draft);
    final stayJson = response['stay'];
    if (stayJson is! Map<String, dynamic>) {
      throw const FormatException('La API no devolvió los datos del alojamiento creado.');
    }
    return HostStayModel.fromJson(stayJson);
  }
}
