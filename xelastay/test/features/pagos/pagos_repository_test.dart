import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xelastay/core/database/app_database.dart';
import 'package:xelastay/features/pagos/data/datasources/pagos_local_data_source.dart';
import 'package:xelastay/features/pagos/data/repositories/pagos_repository_impl.dart';
import 'package:xelastay/features/pagos/domain/entities/pago.dart';

void main() {
  sqfliteFfiInit();

  late Directory carpeta;
  late AppDatabase database;
  late PagosRepositoryImpl pagos;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('xelastay_pagos_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${carpeta.path}/xelastay.db',
    );
    pagos = PagosRepositoryImpl(
      localDataSource: PagosLocalDataSource(
        database: database,
        reloj: () => DateTime(2026, 11, 10, 18, 5),
      ),
    );
  });

  tearDown(() async {
    await database.close();
    await carpeta.delete(recursive: true);
  });

  // Una reserva de 2 noches a Q 250 en el estado indicado.
  Future<int> reserva(String estado) async {
    final db = await database.database;
    return db.insert('reservas', {
      'stay_id': 'centro',
      'titulo': 'Apartamento en el centro de Xela',
      'zona': 'Zona 1',
      'precio_noche_centavos': 25000,
      'entrada': '2026-11-14',
      'salida': '2026-11-16',
      'huespedes': 2,
      'huesped_id': 'ana',
      'huesped_nombre': 'Ana López',
      'estado': estado,
      'creada_ms': 0,
    });
  }

  Future<String> estadoDe(int id) async {
    final db = await database.database;
    final filas = await db.query('reservas', where: 'id = ?', whereArgs: [id]);
    return filas.single['estado']! as String;
  }

  Matcher error(String mensaje) => throwsA(
    isA<PagoException>().having((e) => e.mensaje, 'mensaje', mensaje),
  );

  test('pagar una reserva aceptada guarda el pago y la confirma', () async {
    final id = await reserva('aceptada');

    final pago = await pagos.pagar(id, MetodoPago.transferencia);

    // El monto sale de la base: 2 noches × Q 250 + 10 %.
    expect(pago.subtotalCentavos, 50000);
    expect(pago.servicioCentavos, 5000);
    expect(pago.totalCentavos, 55000);
    expect(pago.referencia, 'XS-${id.toString().padLeft(5, '0')}');
    expect(pago.metodo, MetodoPago.transferencia);
    expect(pago.pagadoEn, DateTime(2026, 11, 10, 18, 5));
    expect(await estadoDe(id), 'confirmada');

    await database.close(); // como cerrar y abrir la app
    final comprobante = await pagos.deReserva(id);
    expect(comprobante!.totalCentavos, 55000);
  });

  test('no se paga lo que el anfitrión no ha aceptado', () async {
    final id = await reserva('pendiente');
    await expectLater(
      pagos.pagar(id, MetodoPago.efectivo),
      error('Solo se paga una reserva que el anfitrión ya aceptó.'),
    );
    expect(await pagos.deReserva(id), isNull);
    expect(await estadoDe(id), 'pendiente');
  });

  test('pagar dos veces da un mensaje humano y no duplica', () async {
    final id = await reserva('aceptada');
    await pagos.pagar(id, MetodoPago.tarjeta);
    await expectLater(
      pagos.pagar(id, MetodoPago.tarjeta),
      error('Esta reserva ya está pagada.'),
    );
    final db = await database.database;
    expect(await db.query('pagos'), hasLength(1));
  });

  test('la base rechaza un total que no cuadra aunque la app falle', () async {
    final id = await reserva('aceptada');
    final db = await database.database;
    await expectLater(
      db.insert('pagos', {
        'reserva_id': id,
        'metodo': 'efectivo',
        'subtotal_centavos': 50000,
        'servicio_centavos': 5000,
        'total_centavos': 1,
        'referencia': 'XS-X',
        'pagado_ms': 0,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });
}
