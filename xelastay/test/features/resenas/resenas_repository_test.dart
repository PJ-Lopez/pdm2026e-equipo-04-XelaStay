import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xelastay/core/database/app_database.dart';
import 'package:xelastay/features/resenas/data/datasources/resenas_local_data_source.dart';
import 'package:xelastay/features/resenas/data/repositories/resenas_repository_impl.dart';
import 'package:xelastay/features/resenas/domain/entities/resena.dart';

void main() {
  sqfliteFfiInit();

  late Directory carpeta;
  late AppDatabase database;
  late ResenasRepositoryImpl resenas;
  late DateTime ahora;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('xelastay_resenas_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${carpeta.path}/xelastay.db',
    );
    ahora = DateTime(2026, 11, 17, 12);
    resenas = ResenasRepositoryImpl(
      localDataSource: ResenasLocalDataSource(
        database: database,
        reloj: () => ahora,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    await carpeta.delete(recursive: true);
  });

  Future<int> reserva(
    String estado, {
    String stayId = 'centro',
    String huesped = 'Ana López',
  }) async {
    final db = await database.database;
    return db.insert('reservas', {
      'stay_id': stayId,
      'titulo': 'Apartamento en el centro de Xela',
      'zona': 'Zona 1',
      'precio_noche_centavos': 25000,
      'entrada': '2026-11-14',
      'salida': '2026-11-16',
      'huespedes': 2,
      'huesped_id': 'ana',
      'huesped_nombre': huesped,
      'estado': estado,
      'creada_ms': 0,
    });
  }

  Matcher error(String mensaje) => throwsA(
    isA<ResenaException>().having((e) => e.mensaje, 'mensaje', mensaje),
  );

  test(
    'reseñar una estadía completada la guarda con datos de la reserva',
    () async {
      final id = await reserva('completada');

      final r = await resenas.publicar(
        reservaId: id,
        estrellas: 5,
        comentario: '  Muy limpio y cerca del parque.  ',
      );

      // El alojamiento y el autor salen de la reserva, no de la pantalla.
      expect(r.stayId, 'centro');
      expect(r.autor, 'Ana López');
      expect(r.estrellas, 5);
      expect(r.comentario, 'Muy limpio y cerca del parque.');
      expect(r.creadaEn, DateTime(2026, 11, 17, 12));

      await database.close(); // como cerrar y abrir la app
      expect((await resenas.deReserva(id))!.estrellas, 5);
      expect(await resenas.deAlojamiento('centro'), hasLength(1));
    },
  );

  test('solo se reseña una estadía completada', () async {
    for (final estado in [
      'pendiente',
      'aceptada',
      'confirmada',
      'rechazada',
      'cancelada',
    ]) {
      final id = await reserva(estado);
      await expectLater(
        resenas.publicar(reservaId: id, estrellas: 4),
        error('Solo puedes reseñar una estadía completada.'),
        reason: estado,
      );
    }
    expect(await resenas.deAlojamiento('centro'), isEmpty);
  });

  test('una reseña por reserva, aunque se intente dos veces', () async {
    final id = await reserva('completada');
    await resenas.publicar(reservaId: id, estrellas: 4);

    await expectLater(
      resenas.publicar(reservaId: id, estrellas: 1),
      error('Ya reseñaste esta estadía.'),
    );
    expect((await resenas.deReserva(id))!.estrellas, 4);
  });

  test('la base también impide la segunda reseña (UNIQUE)', () async {
    final id = await reserva('completada');
    await resenas.publicar(reservaId: id, estrellas: 4);
    final db = await database.database;

    await expectLater(
      db.insert('resenas', {
        'reserva_id': id,
        'stay_id': 'centro',
        'autor': 'Otra persona',
        'estrellas': 5,
        'comentario': '',
        'creada_ms': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('las estrellas van de 1 a 5, en el repositorio y en la base', () async {
    final id = await reserva('completada');

    await expectLater(
      resenas.publicar(reservaId: id, estrellas: 0),
      error('Elige de 1 a 5 estrellas.'),
    );
    await expectLater(
      resenas.publicar(reservaId: id, estrellas: 6),
      error('Elige de 1 a 5 estrellas.'),
    );
    final db = await database.database;
    await expectLater(
      db.insert('resenas', {
        'reserva_id': id,
        'stay_id': 'centro',
        'autor': 'Ana López',
        'estrellas': 9,
        'comentario': '',
        'creada_ms': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('el comentario es opcional pero tiene un máximo', () async {
    final id = await reserva('completada');

    await expectLater(
      resenas.publicar(
        reservaId: id,
        estrellas: 3,
        comentario: 'a' * (ResenasRepositoryImpl.largoMaximo + 1),
      ),
      error('La reseña puede tener hasta 500 caracteres.'),
    );
    final r = await resenas.publicar(reservaId: id, estrellas: 3);
    expect(r.comentario, '');
  });

  test('cada alojamiento ve solo sus reseñas, la más nueva primero', () async {
    final primera = await reserva('completada', huesped: 'Ana López');
    final segunda = await reserva('completada', huesped: 'Luis Pérez');
    final otra = await reserva('completada', stayId: 'cabana');

    await resenas.publicar(reservaId: primera, estrellas: 4);
    ahora = DateTime(2026, 11, 18, 9);
    await resenas.publicar(reservaId: segunda, estrellas: 5);
    await resenas.publicar(reservaId: otra, estrellas: 2);

    final delCentro = await resenas.deAlojamiento('centro');
    expect(delCentro.map((r) => r.autor), ['Luis Pérez', 'Ana López']);
    expect(await resenas.deAlojamiento('cabana'), hasLength(1));
    expect(await resenas.deReserva(999), isNull);
  });

  test('avisa si la reserva ya no existe', () async {
    await expectLater(
      resenas.publicar(reservaId: 999, estrellas: 5),
      error('Esa reserva ya no existe.'),
    );
  });
}
