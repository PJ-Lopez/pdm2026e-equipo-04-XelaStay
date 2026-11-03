import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xelastay/core/database/app_database.dart';
import 'package:xelastay/features/chat/data/datasources/chat_local_data_source.dart';
import 'package:xelastay/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:xelastay/features/chat/domain/entities/mensaje.dart';

void main() {
  sqfliteFfiInit();

  late Directory carpeta;
  late AppDatabase database;
  late ChatRepositoryImpl chat;
  late DateTime ahora;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('xelastay_chat_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${carpeta.path}/xelastay.db',
    );
    ahora = DateTime(2026, 11, 10, 9, 30);
    chat = ChatRepositoryImpl(
      localDataSource: ChatLocalDataSource(
        database: database,
        reloj: () => ahora,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    await carpeta.delete(recursive: true);
  });

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

  Matcher error(String mensaje) => throwsA(
    isA<ChatException>().having((e) => e.mensaje, 'mensaje', mensaje),
  );

  test('guarda la conversación en orden y sobrevive a cerrar la app', () async {
    final id = await reserva('pendiente');

    await chat.enviar(
      reservaId: id,
      autor: AutorMensaje.huesped,
      texto: '  ¿Puedo llegar a las 10 de la noche?  ',
    );
    ahora = DateTime(2026, 11, 10, 9, 45);
    await chat.enviar(
      reservaId: id,
      autor: AutorMensaje.anfitrion,
      texto: 'Claro, la llave está en recepción.',
    );

    await database.close(); // como cerrar y abrir la app
    final mensajes = await chat.mensajesDe(id);

    expect(mensajes.map((m) => m.autor), [
      AutorMensaje.huesped,
      AutorMensaje.anfitrion,
    ]);
    // Se guarda sin los espacios de los extremos.
    expect(mensajes.first.texto, '¿Puedo llegar a las 10 de la noche?');
    expect(mensajes.first.enviadoEn, DateTime(2026, 11, 10, 9, 30));
    expect(mensajes.last.enviadoEn, DateTime(2026, 11, 10, 9, 45));
  });

  test('cada reserva tiene su propia conversación', () async {
    final primera = await reserva('aceptada');
    final segunda = await reserva('confirmada');

    await chat.enviar(
      reservaId: primera,
      autor: AutorMensaje.huesped,
      texto: 'Hola',
    );

    expect(await chat.mensajesDe(primera), hasLength(1));
    expect(await chat.mensajesDe(segunda), isEmpty);
  });

  test('no guarda mensajes vacíos ni demasiado largos', () async {
    final id = await reserva('aceptada');

    await expectLater(
      chat.enviar(reservaId: id, autor: AutorMensaje.huesped, texto: '   '),
      error('Escribe un mensaje antes de enviarlo.'),
    );
    await expectLater(
      chat.enviar(
        reservaId: id,
        autor: AutorMensaje.huesped,
        texto: 'a' * (ChatRepositoryImpl.largoMaximo + 1),
      ),
      error('El mensaje puede tener hasta 500 caracteres.'),
    );
    expect(await chat.mensajesDe(id), isEmpty);
  });

  test('una reserva cancelada o rechazada ya no recibe mensajes', () async {
    for (final estado in ['cancelada', 'rechazada']) {
      final id = await reserva(estado);
      await expectLater(
        chat.enviar(
          reservaId: id,
          autor: AutorMensaje.anfitrion,
          texto: 'Hola',
        ),
        error('Esta reserva se cerró; ya no se pueden enviar mensajes.'),
        reason: estado,
      );
      expect(await chat.mensajesDe(id), isEmpty, reason: estado);
    }
  });

  test('una estadía completada todavía puede conversar', () async {
    final id = await reserva('completada');

    final mensaje = await chat.enviar(
      reservaId: id,
      autor: AutorMensaje.huesped,
      texto: 'Olvidé un cargador en el cuarto.',
    );

    expect(mensaje.reservaId, id);
    expect(await chat.mensajesDe(id), hasLength(1));
  });

  test('avisa si la reserva ya no existe', () async {
    await expectLater(
      chat.enviar(reservaId: 999, autor: AutorMensaje.huesped, texto: 'Hola'),
      error('Esa reserva ya no existe.'),
    );
  });
}
