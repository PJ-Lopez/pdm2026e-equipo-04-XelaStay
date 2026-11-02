import 'package:sqflite/sqflite.dart';

/// Base de datos local de XelaStay (SQLite).
///
/// Guarda en el teléfono lo que el huésped quiere tener a mano aunque no haya
/// conexión: sus listas de viaje y los alojamientos que guardó en ellas.
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

  Future<void> close() async {
    final pendiente = _database;
    if (pendiente == null) return;
    final db = await pendiente;
    await db.close();
    _database = null;
  }
}
