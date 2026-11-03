import '../../domain/entities/resena.dart';
import '../../domain/repositories/resenas_repository.dart';
import '../datasources/resenas_local_data_source.dart';

class ResenasRepositoryImpl implements ResenasRepository {
  ResenasRepositoryImpl({ResenasLocalDataSource? localDataSource})
    : _local = localDataSource ?? ResenasLocalDataSource();

  static const largoMaximo = 500;

  final ResenasLocalDataSource _local;

  @override
  Future<List<Resena>> deAlojamiento(String stayId) =>
      _local.deAlojamiento(stayId);

  @override
  Future<Resena?> deReserva(int reservaId) => _local.deReserva(reservaId);

  @override
  Future<Resena> publicar({
    required int reservaId,
    required int estrellas,
    String comentario = '',
  }) async {
    if (estrellas < Resena.estrellasMinimas ||
        estrellas > Resena.estrellasMaximas) {
      throw const ResenaException('Elige de 1 a 5 estrellas.');
    }
    final limpio = comentario.trim();
    if (limpio.length > largoMaximo) {
      throw const ResenaException(
        'La reseña puede tener hasta $largoMaximo caracteres.',
      );
    }
    return _local.publicar(
      reservaId: reservaId,
      estrellas: estrellas,
      comentario: limpio,
    );
  }
}
