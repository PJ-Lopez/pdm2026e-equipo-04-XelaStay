/// Lista de viaje del huésped: "Fin de semana en Xela", "Con mis papás"...
class Lista {
  const Lista({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    this.alojamientos = 0,
  });

  static const largoMaximoNombre = 40;

  final int id;
  final String nombre;
  final String descripcion;

  /// Cuántos alojamientos guardados apuntan a esta lista.
  final int alojamientos;
}

/// Error con un mensaje listo para mostrarle al usuario (nunca SQL).
class ListaException implements Exception {
  const ListaException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}
