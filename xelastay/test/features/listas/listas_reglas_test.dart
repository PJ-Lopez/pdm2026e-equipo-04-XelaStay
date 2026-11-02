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
    carpeta = await Directory.systemTemp.createTemp('xelastay_reglas_');
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

  Future<void> guardarEn(int listaId, String stayId) =>
      GuardadosLocalDataSource(database: database).guardar(
        AlojamientoGuardado(
          stayId: stayId,
          titulo: 'Alojamiento $stayId',
          zona: 'Zona 1',
          precioCentavos: 25000,
          guardadoEn: DateTime(2026, 11, 1),
          listaId: listaId,
        ),
      );

  test('una lista en uso no se borra: mensaje claro y sigue ahí', () async {
    final favoritos = await buscar('Favoritos');
    await guardarEn(favoritos.id, 'demo-centro');
    await guardarEn(favoritos.id, 'demo-cabana');

    await expectLater(
      listas.eliminar(favoritos.id),
      throwsA(
        isA<ListaException>().having(
          (e) => e.mensaje,
          'mensaje',
          'Tiene 2 alojamientos guardados. Archívala para dejar de verla.',
        ),
      ),
    );
    final sigue = await buscar('Favoritos');
    expect(sigue.alojamientos, 2);
    expect(sigue.enUso, isTrue);
  });

  test('una lista sin alojamientos sí se elimina', () async {
    await listas.guardar(nombre: 'Trabajo');
    await listas.eliminar((await buscar('Trabajo')).id);

    expect((await listas.obtenerTodas()).map((l) => l.nombre), ['Favoritos']);
  });

  test('archivar conserva los alojamientos y sobrevive al reabrir', () async {
    await listas.guardar(nombre: 'Viejo viaje');
    final viejo = await buscar('Viejo viaje');
    await guardarEn(viejo.id, 'demo-cabana');

    await listas.archivar(viejo.id, archivada: true);
    await database.close(); // como cerrar y abrir la app

    final todas = await listas.obtenerTodas();
    expect(todas.last.nombre, 'Viejo viaje'); // las archivadas van al final
    expect(todas.last.archivada, isTrue);
    expect(todas.last.alojamientos, 1);

    // Archivada y en uso: el mensaje ya no sugiere archivar otra vez.
    await expectLater(
      listas.eliminar(viejo.id),
      throwsA(
        isA<ListaException>().having(
          (e) => e.mensaje,
          'mensaje',
          'Tiene 1 alojamiento guardado. '
              'Quítalos de la lista si quieres eliminarla.',
        ),
      ),
    );

    await listas.archivar(viejo.id, archivada: false);
    expect((await buscar('Viejo viaje')).archivada, isFalse);
  });
}
