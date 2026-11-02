import 'entities/stay.dart';

/// Filtros del catálogo de Explorar. Es lógica pura: no sabe de widgets ni
/// del API, así que se prueba sin Flutter.
class FiltrosCatalogo {
  const FiltrosCatalogo({
    this.busqueda = '',
    this.soloVerificados = false,
    this.precioMaximoCentavos,
    this.huespedesMinimos,
  });

  /// Precio tope del chip "Hasta Q 300" (en centavos, como el API).
  static const topeEconomico = 30000;

  /// Capacidad mínima del chip "Para 3 o más".
  static const grupo = 3;

  final String busqueda;
  final bool soloVerificados;
  final int? precioMaximoCentavos;
  final int? huespedesMinimos;

  /// Hay algún chip encendido (la búsqueda de texto se cuenta aparte).
  bool get tieneChips =>
      soloVerificados ||
      precioMaximoCentavos != null ||
      huespedesMinimos != null;

  bool coincide(Stay stay) {
    if (soloVerificados && !stay.isVerified) return false;
    final tope = precioMaximoCentavos;
    if (tope != null && stay.priceAmount > tope) return false;
    final minimo = huespedesMinimos;
    if (minimo != null && stay.capacity < minimo) return false;
    final texto = busqueda.trim().toLowerCase();
    if (texto.isEmpty) return true;
    return '${stay.title} ${stay.zone} ${stay.reference} ${stay.propertyType}'
        .toLowerCase()
        .contains(texto);
  }

  List<Stay> aplicar(List<Stay> stays) => stays.where(coincide).toList();

  FiltrosCatalogo conBusqueda(String valor) => FiltrosCatalogo(
    busqueda: valor,
    soloVerificados: soloVerificados,
    precioMaximoCentavos: precioMaximoCentavos,
    huespedesMinimos: huespedesMinimos,
  );

  FiltrosCatalogo alternarVerificados() => FiltrosCatalogo(
    busqueda: busqueda,
    soloVerificados: !soloVerificados,
    precioMaximoCentavos: precioMaximoCentavos,
    huespedesMinimos: huespedesMinimos,
  );

  FiltrosCatalogo alternarEconomico() => FiltrosCatalogo(
    busqueda: busqueda,
    soloVerificados: soloVerificados,
    precioMaximoCentavos: precioMaximoCentavos == null ? topeEconomico : null,
    huespedesMinimos: huespedesMinimos,
  );

  FiltrosCatalogo alternarGrupo() => FiltrosCatalogo(
    busqueda: busqueda,
    soloVerificados: soloVerificados,
    precioMaximoCentavos: precioMaximoCentavos,
    huespedesMinimos: huespedesMinimos == null ? grupo : null,
  );
}
