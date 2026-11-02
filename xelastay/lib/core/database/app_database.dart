import 'package:sqflite/sqflite.dart';

/// Base de datos local de XelaStay (SQLite).
///
/// Guarda en el teléfono lo que el huésped quiere tener a mano aunque no haya
/// conexión: sus listas de viaje y los alojamientos que guardó en ellas.
/// Desde la versión 3 también guarda reservas, pagos, mensajes y reseñas
/// (ver docs/adr/0001-reservas-en-sqlite-local.md).
class AppDatabase {
  AppDatabase({this.factory, this.path = 'xelastay.db'});

  /// Instancia compartida por toda la aplicación.
  static final AppDatabase instance = AppDatabase();

  /// El esquema es una LISTA de migraciones numeradas.
  /// - Instalación nueva (onCreate): se aplican todas, de la 1 a la última.
  /// - Teléfono que ya tenía la app (onUpgrade): solo las que le faltan.
  /// Así un teléfono nuevo y uno actualizado terminan con el MISMO esquema.
  ///
  /// Regla de oro: una migración publicada NO se edita; se agrega otra.
  static final Map<int, Future<void> Function(Database db)> migraciones = {
    1: _v1Guardados,
    2: _v2Listas,
    3: _v3Reservas,
  };

  static int get versionActual => migraciones.length;

  /// En pruebas se inyecta `databaseFactoryFfi`; en el teléfono es null y se
  /// usa la de sqflite. Se resuelve al ABRIR, no al construir, para que crear
  /// un datasource en una prueba de widget no exija sqflite inicializado.
  final DatabaseFactory? factory;
  final String path;
  Future<Database>? _database;

  Future<Database> get database => _database ??= _abrir();

  Future<Database> _abrir() async {
    try {
      return await (factory ?? databaseFactory).openDatabase(
        path,
        options: OpenDatabaseOptions(
          // Subir la versión es la ÚNICA forma de cambiar el esquema en
          // teléfonos que ya tienen la app (onCreate no se vuelve a ejecutar).
          version: versionActual,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          // sqflite corre onCreate/onUpgrade dentro de una transacción:
          // si una migración falla, no queda un esquema a medias.
          onCreate: (db, version) => _migrar(db, desde: 0, hasta: version),
          onUpgrade: (db, desde, hasta) =>
              _migrar(db, desde: desde, hasta: hasta),
        ),
      );
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  static Future<void> _migrar(
    Database db, {
    required int desde,
    required int hasta,
  }) async {
    for (var v = desde + 1; v <= hasta; v++) {
      await migraciones[v]!(db);
    }
  }

  // v1 (S16): alojamientos guardados por el huésped.
  // Se guarda una copia de lo necesario para mostrarlos sin conexión.
  // El precio va en centavos (int), igual que en el API.
  static Future<void> _v1Guardados(Database db) async {
    await db.execute('''
      CREATE TABLE guardados (
        stay_id TEXT NOT NULL PRIMARY KEY,
        titulo TEXT NOT NULL CHECK (length(trim(titulo)) > 0),
        zona TEXT NOT NULL,
        precio_centavos INTEGER NOT NULL CHECK (precio_centavos >= 0),
        guardado_ms INTEGER NOT NULL
      )
    ''');
  }

  // v2 (S16): listas de viaje ("Fin de semana en Xela", "Con mis papás"...).
  // Cada guardado pasa a pertenecer a una lista.
  static Future<void> _v2Listas(Database db) async {
    // COLLATE NOCASE: "Favoritos" y "favoritos" cuentan como el mismo nombre.
    // archivada: una lista en uso no se borra, se archiva para dejar de verla.
    await db.execute('''
      CREATE TABLE listas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL COLLATE NOCASE UNIQUE
          CHECK (length(trim(nombre)) > 0),
        descripcion TEXT NOT NULL DEFAULT '',
        archivada INTEGER NOT NULL DEFAULT 0 CHECK (archivada IN (0, 1)),
        creada_ms INTEGER NOT NULL
      )
    ''');
    // El nombre va ESCRITO AQUÍ y no importado de la app: una migración es
    // una foto del pasado y no debe cambiar si el código cambia.
    await db.execute('''
      INSERT INTO listas (nombre, creada_ms)
      VALUES ('Favoritos', CAST(strftime('%s', 'now') AS INTEGER) * 1000)
    ''');
    // ALTER TABLE solo puede AGREGAR columnas, y con llave foránea la nueva
    // tiene que aceptar NULL: los guardados viejos todavía no tienen lista.
    // Sin ON DELETE: la base no deja borrar una lista que tiene guardados.
    await db.execute('''
      ALTER TABLE guardados
      ADD COLUMN lista_id INTEGER REFERENCES listas (id)
    ''');
    // Los guardados que el usuario ya tenía quedan en "Favoritos": no se
    // pierden ni quedan huérfanos.
    await db.execute('''
      UPDATE guardados
      SET lista_id = (SELECT id FROM listas WHERE nombre = 'Favoritos')
    ''');
    await db.execute(
      'CREATE INDEX idx_guardados_lista_id ON guardados (lista_id)',
    );
  }

  // v3 (Sprint 3): reservas y todo lo que cuelga de una reserva.
  // Van juntas en una sola versión porque ninguna tiene sentido sin la reserva
  // (FOREIGN KEY): pago, mensajes del chat y reseña.
  static Future<void> _v3Reservas(Database db) async {
    // Las fechas van como texto 'AAAA-MM-DD': ordenan igual que las fechas,
    // así que "se empalman" es entrada < otra_salida AND salida > otra_entrada.
    await db.execute('''
      CREATE TABLE reservas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stay_id TEXT NOT NULL,
        titulo TEXT NOT NULL,
        zona TEXT NOT NULL,
        precio_noche_centavos INTEGER NOT NULL
          CHECK (precio_noche_centavos >= 0),
        entrada TEXT NOT NULL,
        salida TEXT NOT NULL,
        huespedes INTEGER NOT NULL CHECK (huespedes > 0),
        huesped_id TEXT NOT NULL,
        huesped_nombre TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN (
          'pendiente', 'aceptada', 'confirmada',
          'rechazada', 'cancelada', 'completada'
        )),
        creada_ms INTEGER NOT NULL,
        CHECK (salida > entrada)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_reservas_stay ON reservas (stay_id, entrada, salida)',
    );
    await db.execute(
      'CREATE INDEX idx_reservas_huesped ON reservas (huesped_id)',
    );
    // Un pago por reserva (UNIQUE). El total se comprueba en la base.
    await db.execute('''
      CREATE TABLE pagos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reserva_id INTEGER NOT NULL UNIQUE REFERENCES reservas (id),
        metodo TEXT NOT NULL
          CHECK (metodo IN ('tarjeta', 'transferencia', 'efectivo')),
        subtotal_centavos INTEGER NOT NULL CHECK (subtotal_centavos >= 0),
        servicio_centavos INTEGER NOT NULL CHECK (servicio_centavos >= 0),
        total_centavos INTEGER NOT NULL
          CHECK (total_centavos = subtotal_centavos + servicio_centavos),
        referencia TEXT NOT NULL UNIQUE,
        pagado_ms INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE mensajes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reserva_id INTEGER NOT NULL REFERENCES reservas (id),
        autor TEXT NOT NULL CHECK (autor IN ('huesped', 'anfitrion')),
        texto TEXT NOT NULL CHECK (length(trim(texto)) > 0),
        enviado_ms INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_mensajes_reserva ON mensajes (reserva_id, enviado_ms)',
    );
    // Una reseña por reserva: solo opina quien se hospedó (UNIQUE + FK).
    await db.execute('''
      CREATE TABLE resenas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reserva_id INTEGER NOT NULL UNIQUE REFERENCES reservas (id),
        stay_id TEXT NOT NULL,
        autor TEXT NOT NULL,
        estrellas INTEGER NOT NULL CHECK (estrellas BETWEEN 1 AND 5),
        comentario TEXT NOT NULL DEFAULT '',
        creada_ms INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_resenas_stay ON resenas (stay_id)');
  }

  Future<void> close() async {
    final pendiente = _database;
    if (pendiente == null) return;
    final db = await pendiente;
    await db.close();
    _database = null;
  }
}
