import '../entities/lista.dart';

abstract interface class ListasRepository {
  Future<List<Lista>> obtenerTodas();

  /// Crea una lista (`id == null`) o edita una existente. Editar es un UPDATE
  /// de la MISMA fila: el id no cambia y sus alojamientos la siguen.
  /// Lanza [ListaException] con un mensaje para el usuario.
  Future<void> guardar({
    int? id,
    required String nombre,
    String descripcion = '',
  });
}
