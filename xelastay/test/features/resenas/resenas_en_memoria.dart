import 'package:xelastay/features/resenas/domain/entities/resena.dart';
import 'package:xelastay/features/resenas/domain/repositories/resenas_repository.dart';

/// Reseñas en memoria para las pruebas de pantallas: no abre SQLite.
class ResenasEnMemoria implements ResenasRepository {
  ResenasEnMemoria([List<Resena>? iniciales]) : datos = [...?iniciales];

  final List<Resena> datos;
  bool fallarAlLeer = false;

  /// Si no es null, publicar lanza este error de la regla.
  String? reglaQueFalla;

  @override
  Future<List<Resena>> deAlojamiento(String stayId) async {
    if (fallarAlLeer) throw Exception('sin base');
    return datos.where((r) => r.stayId == stayId).toList();
  }

  @override
  Future<Resena?> deReserva(int reservaId) async {
    for (final r in datos) {
      if (r.reservaId == reservaId) return r;
    }
    return null;
  }

  @override
  Future<Resena> publicar({
    required int reservaId,
    required int estrellas,
    String comentario = '',
  }) async {
    final regla = reglaQueFalla;
    if (regla != null) throw ResenaException(regla);
    final resena = Resena(
      id: datos.length + 1,
      reservaId: reservaId,
      stayId: 'centro',
      autor: 'Ana López',
      estrellas: estrellas,
      comentario: comentario.trim(),
      creadaEn: DateTime(2026, 11, 17),
    );
    datos.add(resena);
    return resena;
  }
}
