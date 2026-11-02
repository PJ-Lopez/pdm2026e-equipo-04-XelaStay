import '../entities/alojamiento_guardado.dart';

abstract interface class GuardadosRepository {
  Future<List<AlojamientoGuardado>> deLista(int listaId);

  /// Si el alojamiento ya estaba en otra lista, lo mueve a la nueva.
  Future<void> guardar(AlojamientoGuardado alojamiento);

  Future<void> quitar(String stayId);
}
