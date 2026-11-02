import '../../domain/entities/lista.dart';
import '../../domain/repositories/listas_repository.dart';
import '../datasources/listas_local_data_source.dart';

class ListasRepositoryImpl implements ListasRepository {
  ListasRepositoryImpl({ListasLocalDataSource? localDataSource})
    : _local = localDataSource ?? ListasLocalDataSource();

  final ListasLocalDataSource _local;

  @override
  Future<List<Lista>> obtenerTodas() => _local.obtenerTodas();

  @override
  Future<void> guardar({
    int? id,
    required String nombre,
    String descripcion = '',
  }) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) {
      throw const ListaException('Ponle un nombre a la lista.');
    }
    if (limpio.length > Lista.largoMaximoNombre) {
      throw const ListaException(
        'El nombre puede tener hasta ${Lista.largoMaximoNombre} caracteres.',
      );
    }
    await _local.guardar(
      id: id,
      nombre: limpio,
      descripcion: descripcion.trim(),
    );
  }

  @override
  Future<void> archivar(int id, {required bool archivada}) =>
      _local.archivar(id, archivada: archivada);

  @override
  Future<void> eliminar(int id) => _local.eliminar(id);
}
