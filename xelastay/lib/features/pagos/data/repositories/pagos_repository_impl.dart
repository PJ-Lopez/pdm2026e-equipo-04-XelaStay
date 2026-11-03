import '../../domain/entities/pago.dart';
import '../../domain/repositories/pagos_repository.dart';
import '../datasources/pagos_local_data_source.dart';

class PagosRepositoryImpl implements PagosRepository {
  PagosRepositoryImpl({PagosLocalDataSource? localDataSource})
    : _local = localDataSource ?? PagosLocalDataSource();

  final PagosLocalDataSource _local;

  @override
  Future<Pago> pagar(int reservaId, MetodoPago metodo) =>
      _local.pagar(reservaId, metodo);

  @override
  Future<Pago?> deReserva(int reservaId) => _local.deReserva(reservaId);
}
