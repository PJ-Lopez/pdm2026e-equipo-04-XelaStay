import 'package:latlong2/latlong.dart';

import 'entities/stay.dart';

/// Parque Centro América, Quetzaltenango: centro por defecto del mapa.
const centroDeXela = LatLng(14.8346, -91.5181);

/// Dónde centrar el mapa: el promedio de los alojamientos con coordenadas, o
/// el centro de Xela si ninguno tiene.
LatLng centroDelMapa(List<Stay> stays) {
  final conUbicacion = stays.where((s) => s.tieneUbicacion).toList();
  if (conUbicacion.isEmpty) return centroDeXela;
  final lat =
      conUbicacion.map((s) => s.latitud!).reduce((a, b) => a + b) /
      conUbicacion.length;
  final lng =
      conUbicacion.map((s) => s.longitud!).reduce((a, b) => a + b) /
      conUbicacion.length;
  return LatLng(lat, lng);
}
