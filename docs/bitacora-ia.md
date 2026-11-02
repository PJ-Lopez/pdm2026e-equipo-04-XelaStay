# Bitácora de uso de IA

## 2026-11-01 · Codex · Revisión e integración local de S16 parte 4

- **Qué se solicitó:** traer los cambios de `main` y trabajar la entrega de
  Emerson cuando la parte 3 estuviera integrada.
- **Qué se aceptó:** aplicar el parche de Emerson sobre la rama creada desde
  `origin/main`, y mostrar mensajes amigables si falla agregar o quitar un
  alojamiento.
- **Qué se descartó:** dejar las excepciones del repositorio sin manejar ni
  mostrar mensajes técnicos al usuario.
- **Qué se corrigió:** las escrituras desde `ListaDetallePage` no manejaban
  fallos del repositorio; ahora el usuario recibe un mensaje y la vista evita
  usar el estado después de desmontarse. Se añadieron pruebas widget para ambos
  errores.
- **Verificación automatizada:** `flutter pub get`, `dart format lib test`,
  `flutter analyze` sin observaciones y `flutter test` con 30 pruebas aprobadas.
- **Validación humana:** pendiente; este entorno no tiene un emulador Android
  disponible para ejecutar los pasos manuales del laboratorio.

## 2026-11-01 · @Emersonx257 · S16 parte 4: regla de borrado, archivar y alojamientos

- **Herramienta:** Claude (asistente de código).
- **Qué pedí:** que una lista con alojamientos no se pueda borrar (mensaje
  claro y ofrecer archivar), archivar/restaurar, sección "Archivadas" y una
  pantalla para agregar alojamientos del catálogo a una lista y quitarlos,
  todo refrescando con `ref.invalidate`. Pruebas de las reglas con SQLite real
  y de widget.
- **Qué acepté:** `eliminar` que cuenta los guardados y borra en una sola
  transacción, `archivar`, los botones "Archivar/Restaurar" y "Eliminar" en el
  mismo formulario, `ListaDetallePage` con el catálogo vía
  `getPublicStaysProvider` (configurado en `main.dart`) y las pruebas.
- **Qué rechacé o corregí:**
  - El SnackBar usaba el `context` de la fila tocada. Al archivar, la fila
    cambia de sección y ese `context` se desmonta, así que el aviso no salía.
    Se toma el `ScaffoldMessenger` antes de abrir el formulario.
  - Confiar solo en la llave foránea para no borrar: el usuario vería un error
    de SQLite. Se revisa antes, en la misma transacción que el `DELETE`, y se
    lanza `ListaException` con un mensaje para el usuario.
  - Sugerir "Archívala" a una lista que ya está archivada no tiene sentido: en
    ese caso el mensaje pide quitar sus alojamientos.
  - Que `getPublicStaysProvider` devolviera datos simulados por defecto: en
    producción ocultaría que falta configurarlo. Por defecto lanza un error y
    `main.dart` lo sobreescribe con el API.
- **Verificación:** pruebas de reglas con SQLite real (en uso no se borra,
  archivar sobrevive a cerrar y abrir), pruebas de widget del formulario y del
  detalle, `flutter test` local y CI en verde; prueba manual en emulador
  (borrar una lista con alojamientos, archivarla, cerrar y abrir la app).

## 2026-11-01 · @gio-ld · S16 parte 3: CRUD de listas de viaje

- **Herramienta:** Claude (asistente de código).
- **Qué pedí:** CRUD de la entidad `Lista` con capas (entidad, contrato del
  repositorio, datasource SQLite, implementación, providers), una pantalla con
  la lista y un solo formulario que crea y edita. El formulario recibe el
  registro inicial y la función para guardar, sin SQL ni providers. Después de
  guardar, refrescar invalidando el provider. Entrada desde "Mi perfil".
- **Qué acepté:** `ListaForm` con `DatosLista`, `abrirFormularioLista` que
  invalida `listasProvider`, el `LEFT JOIN` para contar alojamientos, la
  traducción del error UNIQUE a un mensaje para el usuario y las pruebas con
  repositorio falso (`overrideWithValue`) y con SQLite real.
- **Qué rechacé o corregí:**
  - Agregar la lista nueva a mano al estado de la pantalla después de guardar:
    se rechazó, se invalida el provider para que lo visible sea lo guardado.
    La prueba lo comprueba contando las lecturas del repositorio.
  - Abrir la lista desde una pestaña nueva del menú inferior: se dejó en "Mi
    perfil" para no tocar la navegación que cambia `feat/filtro-reservas`.
  - Copiar la validación de inkash tal cual (un `throw` en un método sin
    `async` lanza el error antes de devolver el `Future`). Se hizo `async`
    para que el formulario y `expectLater(..., throwsA(...))` lo reciban
    siempre como un `Future` con error.
- **Verificación:** prueba de widget (tocar una lista abre el formulario lleno
  y "Guardar cambios" la actualiza conservando el id), pruebas del repositorio
  con SQLite, `flutter test` local y CI en verde; prueba manual en emulador
  (crear, editar, cerrar y volver a abrir la app).

## 2026-11-01 · @joshuaF14 · S16 parte 2: migración v2 (listas de viaje)

- **Herramienta:** Claude (asistente de código).
- **Qué pedí:** agregar la versión 2 de la base con la tabla `listas` y la
  columna `guardados.lista_id`, sin tocar la migración 1 que ya está en
  `main`, más la prueba que abre una base v1 con datos usando la versión
  nueva (como `app_database_test` de inkash).
- **Qué acepté:** `_v2Listas` con `COLLATE NOCASE UNIQUE` en el nombre, la
  columna `archivada`, la lista "Favoritos" creada por la migración, el
  `UPDATE` que mete ahí los guardados viejos y las pruebas de migración y de
  "mismo esquema en instalación nueva y actualizada".
- **Qué rechacé o corregí:**
  - Agregar `lista_id` como `NOT NULL`: `ALTER TABLE ... ADD COLUMN` con
    `REFERENCES` no lo permite sin un `DEFAULT`, y no hay un id fijo que poner.
    Se dejó nullable y se llenó con el `UPDATE` en la misma migración.
  - Insertar "Favoritos" usando una constante de la app: la migración debe ser
    una foto fija del pasado, así que el nombre va escrito en el SQL.
  - La prueba de migración no inserta los datos v1 con el datasource (que ya
    escribe `lista_id`), sino con las columnas exactas de la versión 1.
- **Verificación:** las reglas de la base (UNIQUE sin importar mayúsculas,
  `CHECK`, llave foránea) se probaron en SQLite real con `sqflite_common_ffi`;
  `flutter test` local y CI en verde.

## 2026-11-01 · @PJ-Lopez · S16 parte 1: base local SQLite (v1)

- **Herramienta:** Claude (asistente de código).
- **Qué pedí:** base de datos local con `sqflite` siguiendo el patrón de inkash
  (`s16-01`): migraciones numeradas, `onCreate` y `onUpgrade` con el mismo
  código, `PRAGMA foreign_keys = ON` y una primera tabla `guardados` para
  tener alojamientos a mano sin conexión. SQL solo en el datasource y pruebas
  con `sqflite_common_ffi`.
- **Qué acepté:** `AppDatabase` con el mapa `migraciones`, la fábrica
  inyectable para pruebas, la tabla `guardados` con precio en centavos y los
  `CHECK` como última defensa.
- **Qué rechacé o corregí:**
  - Para no duplicar un guardado se descartó `INSERT ... ON CONFLICT DO
    UPDATE` (UPSERT) y se usó `ConflictAlgorithm.replace`: el `minSdk` es 23 y
    hasta Android 10 el SQLite del sistema es anterior a 3.24, la versión que
    trajo UPSERT.
  - Las dependencias se agregaron sin mover las líneas que ya existían en
    `pubspec.yaml`, para no chocar con la rama `feat/filtro-reservas`.
- **Verificación:** `dart format`, `flutter analyze` y `flutter test` antes del
  PR; CI en verde.

## 2026-10-15 · Estados del catálogo de alojamientos

- **Qué pedí:** implementar la guía de Pareja 1: `StaysPage` con carga, error,
  vacío y datos, repositorio simulado, pruebas con `FakeErrorStaysRepository`
  y PR para revisión de la Pareja 2.
- **Qué acepté:** conservar el contrato `StaysRepository` y el caso de uso
  `GetPublicStays`; renombrar el catálogo existente a `StaysPage`; añadir
  spinner con texto, acciones funcionales y repositorio simulado con latencia;
  aislar la demostración en una entrada independiente; cubrir estados y
  transiciones con pruebas automatizadas.
- **Qué rechacé:** no se descartaron propuestas de implementación durante esta
  tarea. Se aclaró que no hay un issue asociado ni preguntas de reflexión,
  por lo que el PR no debe inventar esas referencias.
- **Validación humana pendiente:** ejecutar la demostración en un dispositivo
  o emulador y revisar los cambios antes de aprobar el PR.
