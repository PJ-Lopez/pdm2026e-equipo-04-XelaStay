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
  DateTime reloj() => DateTime(2026, 11, 10, 9);

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('xelastay_anfitrion_');
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

  Future<Reserva> pedir(String huesped, int entrada, int salida) =>
      reservas.solicitar(
        SolicitudReserva(
          stayId: 'centro',
          titulo: 'Apartamento en el centro de Xela',
          zona: 'Zona 1',
          precioNocheCentavos: 25000,
          capacidad: 2,
          entrada: DateTime(2026, 11, entrada),
          salida: DateTime(2026, 11, salida),
          huespedes: 1,
          huespedId: huesped,
          huespedNombre: huesped,
        ),
      );

  Future<EstadoReserva> estado(int id) async =>
      (await reservas.porId(id)).estado;

  // Pone el estado directo en la base (lo que haría el pago).
  Future<void> marcar(int id, EstadoReserva e) async {
    final db = await database.database;
    await db.update(
      'reservas',
      {'estado': e.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Matcher error(String mensaje) => throwsA(
    isA<ReservaException>().having((e) => e.mensaje, 'mensaje', mensaje),
  );

  test('aceptar rechaza en la misma transacción las que se empalman', () async {
    final ana = await pedir('ana', 14, 16);
    final luis = await pedir('luis', 15, 17); // se empalma con Ana
    final marta = await pedir('marta', 16, 18); // llega cuando Ana sale

    expect(await reservas.aceptar(ana.id), 1);

    expect(await estado(ana.id), EstadoReserva.aceptada);
    expect(await estado(luis.id), EstadoReserva.rechazada);
    expect(await estado(marta.id), EstadoReserva.pendiente);

    await expectLater(
      reservas.aceptar(ana.id),
      error('Esta solicitud ya fue atendida.'),
    );
  });

  test('no se acepta si ya hay otra aceptada en esas fechas', () async {
    final ana = await pedir('ana', 14, 16);
    await reservas.aceptar(ana.id);
    // Una pendiente que se coló con fechas ocupadas (insertada directo).
    final db = await database.database;
    final colada = await db.insert('reservas', {
      'stay_id': 'centro',
      'titulo': 'Apartamento en el centro de Xela',
      'zona': 'Zona 1',
      'precio_noche_centavos': 25000,
      'entrada': '2026-11-15',
      'salida': '2026-11-17',
      'huespedes': 1,
      'huesped_id': 'luis',
      'huesped_nombre': 'luis',
      'estado': 'pendiente',
      'creada_ms': 0,
    });
    await expectLater(
      reservas.aceptar(colada),
      error('Ya aceptaste otra reserva en esas fechas.'),
    );
    expect(await estado(colada), EstadoReserva.pendiente);
  });

  test('rechazar solo una vez', () async {
    final ana = await pedir('ana', 14, 16);
    await reservas.rechazar(ana.id);
    expect(await estado(ana.id), EstadoReserva.rechazada);
    await expectLater(
      reservas.rechazar(ana.id),
      error('Esta solicitud ya fue atendida.'),
    );
  });

  test('completar solo una confirmada que ya empezó', () async {
    final hoy = await pedir('ana', 10, 12); // llega hoy
    final futura = await pedir('luis', 20, 22);
    await marcar(hoy.id, EstadoReserva.confirmada);
    await marcar(futura.id, EstadoReserva.confirmada);
    final pendiente = await pedir('marta', 24, 25);

    await reservas.completar(hoy.id);
    expect(await estado(hoy.id), EstadoReserva.completada);

    const mensaje = 'Solo se completa una estadía confirmada que ya empezó.';
    await expectLater(reservas.completar(futura.id), error(mensaje));
    await expectLater(reservas.completar(pendiente.id), error(mensaje));
  });

  test(
    'todas devuelve las solicitudes de todos, la más próxima primero',
    () async {
      await pedir('luis', 20, 22);
      await pedir('ana', 14, 16);
      final todas = await reservas.todas();
      expect(todas.map((r) => r.huespedId), ['ana', 'luis']);
    },
  );
}
