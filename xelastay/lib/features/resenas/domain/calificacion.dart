import 'entities/resena.dart';

/// Promedio y cantidad de reseñas que se muestran en el detalle.
class Calificacion {
  const Calificacion({required this.promedio, required this.cantidad});

  /// Junta las reseñas que ya trae el catálogo (API) con las escritas en la
  /// app. El promedio se pondera por cantidad: 12 reseñas del catálogo pesan
  /// 12 veces, no una.
  factory Calificacion.combinar({
    required double promedioCatalogo,
    required int cantidadCatalogo,
    required List<Resena> locales,
  }) {
    final cantidad = cantidadCatalogo + locales.length;
    if (cantidad == 0) return const Calificacion(promedio: 0, cantidad: 0);
    final suma =
        promedioCatalogo * cantidadCatalogo +
        locales.fold<int>(0, (total, r) => total + r.estrellas);
    return Calificacion(promedio: suma / cantidad, cantidad: cantidad);
  }

  final double promedio;
  final int cantidad;

  bool get vacia => cantidad == 0;

  /// "4.8 · 13 reseñas". Sin reseñas no se inventa un promedio.
  String get texto => vacia
      ? 'Aún sin reseñas'
      : '${promedio.toStringAsFixed(1)} · '
            '${cantidad == 1 ? '1 reseña' : '$cantidad reseñas'}';
}
