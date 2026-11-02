import '../../domain/entities/alojamiento_guardado.dart';
import '../../domain/repositories/guardados_repository.dart';
import '../datasources/guardados_local_data_source.dart';

class GuardadosRepositoryImpl implements GuardadosRepository {
  GuardadosRepositoryImpl({GuardadosLocalDataSource? localDataSource})
    : _local = localDataSource ?? GuardadosLocalDataSource();

  final GuardadosLocalDataSource _local;

  @override
  Future<List<AlojamientoGuardado>> deLista(int listaId) =>
      _local.deLista(listaId);

  @override
  Future<void> guardar(AlojamientoGuardado alojamiento) =>
      _local.guardar(alojamiento);

  @override
  Future<void> quitar(String stayId) => _local.quitar(stayId);
}
