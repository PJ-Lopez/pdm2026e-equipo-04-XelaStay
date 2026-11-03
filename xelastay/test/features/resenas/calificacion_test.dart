import 'package:flutter_test/flutter_test.dart';
import 'package:xelastay/features/resenas/domain/calificacion.dart';
import 'package:xelastay/features/resenas/domain/entities/resena.dart';

Resena _resena(int estrellas) => Resena(
  id: estrellas,
  reservaId: estrellas,
  stayId: 'centro',
  autor: 'Ana López',
  estrellas: estrellas,
  comentario: '',
  creadaEn: DateTime(2026, 11, 17),
);

void main() {
  test('sin reseñas no inventa un promedio', () {
    final c = Calificacion.combinar(
      promedioCatalogo: 0,
      cantidadCatalogo: 0,
      locales: const [],
    );
    expect(c.vacia, isTrue);
    expect(c.texto, 'Aún sin reseñas');
  });

  test('solo con reseñas de la app', () {
    final c = Calificacion.combinar(
      promedioCatalogo: 0,
      cantidadCatalogo: 0,
      locales: [_resena(5), _resena(4)],
    );
    expect(c.promedio, 4.5);
    expect(c.texto, '4.5 · 2 reseñas');
  });

  test('el promedio pesa cada reseña del catálogo, no lo cuenta como una', () {
    // 3 del catálogo con 4.0 (suma 12) + una de 1 estrella = 13 / 4.
    final c = Calificacion.combinar(
      promedioCatalogo: 4,
      cantidadCatalogo: 3,
      locales: [_resena(1)],
    );
    expect(c.cantidad, 4);
    expect(c.promedio, 3.25);
    expect(c.texto, '3.3 · 4 reseñas');
  });

  test('una sola reseña se dice en singular', () {
    final c = Calificacion.combinar(
      promedioCatalogo: 0,
      cantidadCatalogo: 0,
      locales: [_resena(3)],
    );
    expect(c.texto, '3.0 · 1 reseña');
  });

  test('cada número de estrellas tiene su palabra', () {
    expect(
      [for (var i = 1; i <= 5; i++) etiquetaEstrellas(i)],
      ['Mala', 'Regular', 'Buena', 'Muy buena', 'Excelente'],
    );
  });
}
