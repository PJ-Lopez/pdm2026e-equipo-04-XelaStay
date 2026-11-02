# Bitácora de uso de IA

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
