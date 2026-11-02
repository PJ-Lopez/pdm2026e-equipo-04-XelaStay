import '../../../../core/utils/formatos.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/repositories/reservas_repository.dart';
import '../datasources/reservas_local_data_source.dart';

class ReservasRepositoryImpl implements ReservasRepository {
  ReservasRepositoryImpl({
    ReservasLocalDataSource? localDataSource,
    DateTime Function()? reloj,
  }) : _local = localDataSource ?? ReservasLocalDataSource(reloj: reloj),
       _reloj = reloj ?? DateTime.now;

  final ReservasLocalDataSource _local;
  final DateTime Function() _reloj;

  @override
  Future<List<Reserva>> delHuesped(String huespedId) =>
      _local.delHuesped(huespedId);

  @override
  Future<Reserva> porId(int id) => _local.porId(id);

  /// Reglas que se revisan antes de tocar la base, con mensajes humanos.
  @override
  Future<Reserva> solicitar(SolicitudReserva s) async {
    final hoy = soloFecha(_reloj());
    final entrada = soloFecha(s.entrada);
    final salida = soloFecha(s.salida);
    if (entrada.isBefore(hoy)) {
      throw const ReservaException('La fecha de llegada ya pasó.');
    }
    if (!salida.isAfter(entrada)) {
      throw const ReservaException('Elige al menos una noche.');
    }
    if (s.huespedes < 1 || s.huespedes > s.capacidad) {
      throw ReservaException(
        'Este alojamiento recibe hasta ${s.capacidad} huéspedes.',
      );
    }
    return _local.solicitar(s);
  }

  @override
  Future<void> cancelar(int id) => _local.cancelar(id);
}
