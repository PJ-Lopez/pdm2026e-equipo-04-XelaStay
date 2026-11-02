import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xelastay/core/database/app_database.dart';
import 'package:xelastay/features/listas/data/datasources/guardados_local_data_source.dart';
import 'package:xelastay/features/listas/data/datasources/listas_local_data_source.dart';
import 'package:xelastay/features/listas/data/repositories/listas_repository_impl.dart';
import 'package:xelastay/features/listas/domain/entities/alojamiento_guardado.dart';
import 'package:xelastay/features/listas/domain/entities/lista.dart';

void main() {
  sqfliteFfiInit();

  late Directory carpeta;
  late AppDatabase database;
  late ListasRepositoryImpl listas;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('xelastay_listas_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${carpeta.path}/xelastay.db',
    );
    listas = ListasRepositoryImpl(
      localDataSource: ListasLocalDataSource(database: database),
    );
  });

  tearDown(() async {
    await database.close();
    await carpeta.delete(recursive: true);
  });

  Future<Lista> buscar(String nombre) async =>
      (await listas.obtenerTodas()).singleWhere((l) => l.nombre == nombre);

  test('crear: la nueva lista aparece junto a Favoritos', () async {
    await listas.guardar(
      nombre: '  Fin de semana en Xela ',
      descripcion: 'Con mis papás',
    );

    final todas = await listas.obtenerTodas();
    expect(todas.map((l) => l.nombre), ['Favoritos', 'Fin de semana en Xela']);
    expect(todas.last.descripcion, 'Con mis papás');
    expect(todas.last.alojamientos, 0);
  });

  test('editar es un UPDATE de la misma fila: el id no cambia', () async {
    await listas.guardar(nombre: 'Fin de semna');
    final antes = await buscar('Fin de semna');

    // Un alojamiento guardado en la lista debe seguirla después de editarla.
    await GuardadosLocalDataSource(database: database).guardar(
      AlojamientoGuardado(
        stayId: 'demo-centro',
        titulo: 'Apartamento en el centro de Xela',
        zona: 'Zona 1',
        precioCentavos: 25000,
        guardadoEn: DateTime(2026, 11, 1),
        listaId: antes.id,
      ),
    );

    await listas.guardar(
      id: antes.id,
      nombre: 'Fin de semana',
      descripcion: 'Noviembre',
    );

    final despues = await buscar('Fin de semana');
    expect(despues.id, antes.id);
    expect(despues.descripcion, 'Noviembre');
    expect(despues.alojamientos, 1);
    expect(await listas.obtenerTodas(), hasLength(2)); // no se creó otra
  });

  test('nombre repetido da un mensaje humano, no un error de SQL', () async {
    await expectLater(
      listas.guardar(nombre: 'favoritos'),
      throwsA(
        isA<ListaException>().having(
          (e) => e.mensaje,
          'mensaje',
          'Ya tienes una lista llamada "favoritos". Usa otro nombre.',
        ),
      ),
    );

    // Editar otra lista para ponerle un nombre que ya existe, tampoco.
    await listas.guardar(nombre: 'Trabajo');
    final trabajo = await buscar('Trabajo');
    await expectLater(
      listas.guardar(id: trabajo.id, nombre: 'Favoritos'),
      throwsA(isA<ListaException>()),
    );

    // Guardar una lista con su mismo nombre sí se puede.
    await listas.guardar(id: trabajo.id, nombre: 'Trabajo', descripcion: 'x');
    expect((await buscar('Trabajo')).descripcion, 'x');
  });

  test('nombre vacío o muy largo no se guarda', () async {
    await expectLater(
      listas.guardar(nombre: '   '),
      throwsA(isA<ListaException>()),
    );
    await expectLater(
      listas.guardar(nombre: 'x' * (Lista.largoMaximoNombre + 1)),
      throwsA(isA<ListaException>()),
    );
    expect(await listas.obtenerTodas(), hasLength(1));
  });
}
