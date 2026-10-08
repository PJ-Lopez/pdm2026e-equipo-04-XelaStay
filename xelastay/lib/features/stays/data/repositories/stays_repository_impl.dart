import '../../domain/entities/stay.dart';
import '../../domain/repositories/stays_repository.dart';
import '../datasources/stays_remote_data_source.dart';
import '../models/stay_model.dart';

class StaysRepositoryImpl implements StaysRepository {
  const StaysRepositoryImpl(this._remote);

  final StaysRemoteDataSource _remote;

  @override
  Future<List<Stay>> getPublicStays() async => (await _remote.getPublicStays())
      .map(StayModel.fromJson)
      .toList(growable: false);
}
