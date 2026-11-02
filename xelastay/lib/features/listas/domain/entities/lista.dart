/// Lista de viaje del huésped: "Fin de semana en Xela", "Con mis papás"...
class Lista {
  const Lista({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    this.alojamientos = 0,
    this.archivada = false,
  });

  static const largoMaximoNombre = 40;

  final int id;
  final String nombre;
  final String descripcion;

  /// Cuántos alojamientos guardados apuntan a esta lista.
  final int alojamientos;

  /// Archivada: ya no aparece entre las activas, pero conserva sus
  /// alojamientos. Es la salida cuando una lista en uso no se puede borrar.
  final bool archivada;

  bool get enUso => alojamientos > 0;
}

/// Error con un mensaje listo para mostrarle al usuario (nunca SQL).
class ListaException implements Exception {
  const ListaException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
