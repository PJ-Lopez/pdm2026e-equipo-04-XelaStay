import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xelastay/core/database/app_database.dart';
import 'package:xelastay/features/booking/data/datasources/reservas_local_data_source.dart';
import 'package:xelastay/features/booking/data/repositories/reservas_repository_impl.dart';
import 'package:xelastay/features/booking/domain/entities/reserva.dart';

void main() {
  sqfliteFfiInit();

  late Directory carpeta;
  late AppDatabase database;
  late ReservasRepositoryImpl reservas;
  // "Hoy" fijo: las pruebas no dependen del día en que se corren.
  DateTime reloj() => DateTime(2026, 11, 10, 9);

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('xelastay_reservas_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${carpeta.path}/xelastay.db',
    );
    reservas = ReservasRepositoryImpl(
      localDataSource: ReservasLocalDataSource(
        database: database,
        reloj: reloj,
      ),
      reloj: reloj,
    );
  });

  tearDown(() async {
    await database.close();
    await carpeta.delete(recursive: true);
  });

  SolicitudReserva solicitud({
    String huesped = 'ana',
    int entrada = 14,
    int salida = 16,
    int huespedes = 2,
  }) => SolicitudReserva(
    stayId: 'centro',
    titulo: 'Apartamento en el centro de Xela',
    zona: 'Zona 1',
    precioNocheCentavos: 25000,
    capacidad: 2,
    entrada: DateTime(2026, 11, entrada),
    salida: DateTime(2026, 11, salida),
    huespedes: huespedes,
    huespedId: huesped,
    huespedNombre: huesped == 'ana' ? 'Ana López' : 'Luis Pérez',
  );

  // Simula que el anfitrión ya aceptó (eso lo hace el panel del anfitrión).
  Future<void> marcar(int id, EstadoReserva estado) async {
    final db = await database.database;
    await db.update(
      'reservas',
      {'estado': estado.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Matcher error(String mensaje) => throwsA(
    isA<ReservaException>().having((e) => e.mensaje, 'mensaje', mensaje),
  );

  test(
    'solicitar guarda una reserva pendiente que sobrevive al reabrir',
    () async {
      final r = await reservas.solicitar(solicitud());
      expect(r.estado, EstadoReserva.pendiente);
      expect(r.noches, 2);
      expect(r.entrada, DateTime(2026, 11, 14));

      await database.close(); // como cerrar y abrir la app
      final otra = await reservas.porId(r.id);
      expect(otra.titulo, 'Apartamento en el centro de Xela');
      expect(otra.huespedNombre, 'Ana López');
      expect(await reservas.delHuesped('ana'), hasLength(1));
      expect(await reservas.delHuesped('luis'), isEmpty);
    },
  );

  test('fechas tomadas: no se empalma con una reserva aceptada', () async {
    final ana = await reservas.solicitar(solicitud());
    await marcar(ana.id, EstadoReserva.aceptada);

    // 15–17 se empalma con 14–16.
    await expectLater(
      reservas.solicitar(solicitud(huesped: 'luis', entrada: 15, salida: 17)),
      error('Esas fechas ya no están disponibles. Prueba con otras.'),
    );
    // Llegar el día que Ana sale sí se puede.
    final luis = await reservas.solicitar(
      solicitud(huesped: 'luis', entrada: 16, salida: 18),
    );
    expect(luis.estado, EstadoReserva.pendiente);
  });

  test(
    'dos personas pueden pedir las mismas fechas (quedan en cola)',
    () async {
      await reservas.solicitar(solicitud());
      final luis = await reservas.solicitar(solicitud(huesped: 'luis'));
      expect(luis.estado, EstadoReserva.pendiente);

      // Pero la misma persona no manda dos veces la misma solicitud.
      await expectLater(
        reservas.solicitar(solicitud()),
        error('Ya enviaste una solicitud para esas fechas.'),
      );
    },
  );

  test('reglas con mensaje humano antes de tocar la base', () async {
    await expectLater(
      reservas.solicitar(solicitud(entrada: 5, salida: 7)),
      error('La fecha de llegada ya pasó.'),
    );
    await expectLater(
      reservas.solicitar(solicitud(entrada: 14, salida: 14)),
      error('Elige al menos una noche.'),
    );
    await expectLater(
      reservas.solicitar(solicitud(huespedes: 3)),
      error('Este alojamiento recibe hasta 2 huéspedes.'),
    );
    expect(await reservas.delHuesped('ana'), isEmpty);
  });

  test('cancelar solo una vez y solo si está pendiente o aceptada', () async {
    final r = await reservas.solicitar(solicitud());
    await reservas.cancelar(r.id);
    expect((await reservas.porId(r.id)).estado, EstadoReserva.cancelada);
    await expectLater(
      reservas.cancelar(r.id),
      error('Esta reserva ya no se puede cancelar desde la app.'),
    );

    final confirmada = await reservas.solicitar(
      solicitud(entrada: 20, salida: 22),
    );
    await marcar(confirmada.id, EstadoReserva.confirmada);
    await expectLater(
      reservas.cancelar(confirmada.id),
      error('Esta reserva ya no se puede cancelar desde la app.'),
    );
  });

  test(
    'la base rechaza una salida antes de la llegada aunque la app falle',
    () async {
      final db = await database.database;
      await expectLater(
        db.insert('reservas', {
          'stay_id': 'x',
          'titulo': 'x',
          'zona': 'x',
          'precio_noche_centavos': 1,
          'entrada': '2026-11-16',
          'salida': '2026-11-14',
          'huespedes': 1,
          'huesped_id': 'x',
          'huesped_nombre': 'x',
          'creada_ms': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );
}
