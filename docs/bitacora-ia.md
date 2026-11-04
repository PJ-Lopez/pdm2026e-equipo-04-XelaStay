# Bitácora de uso de IA

## 2026-11-04 · @gio-ld · Documentación: README, limitaciones y ajustes de la bitácora

- **Herramienta:** Claude (asistente de código), en la sesión que coordinó
  @gio-ld para el equipo; esta parte la revisó y subió su autor.
- **Qué se pidió:** un README que explique el problema y el usuario, cómo
  correr el API y la app, el flujo de la demo, las pruebas, la arquitectura,
  las decisiones y las limitaciones, con capturas reales de la app.
- **Qué acepté:** el README nuevo, con una sección de limitaciones conocidas,
  y mover la tabla de roles por semana a `docs/roles-semanales.md`.
- **Qué rechacé o corregí:**
  - El README anterior describía colas con RabbitMQ o Kafka y un chat en
    tiempo real que la app no tiene. Se quitó: el README solo cuenta lo que
    está en `main`.
  - Se descartó esconder lo que falta. En lugar de eso, "Limitaciones
    conocidas" dice lo que la app todavía no hace (panel de administrador,
    editar alojamientos, datos por cuenta) y los textos del API con acentos
    rotos.
  - En la entrada de la parte A decía "la app fallaba" por usar `ref`
    después de un `await`. Fue una precaución, no un fallo que haya pasado:
    se corrigió a "podría fallar".
  - La entrada de S16 parte 4 decía que se probó en emulador, pero ese día no
    había uno disponible (lo dice también la entrada de Codex). Se corrigió.
- **Verificación:** se revisó cada afirmación del README contra el código de
  `main`, y las capturas salen de la app corriendo en el emulador.

## 2026-11-02 · @gio-ld · Sprint 3: chat entre huésped y anfitrión

- **Herramienta:** Claude (asistente de código), en una sesión que coordinó
  @gio-ld para el equipo; esta parte la revisó, probó y subió su autor.
- **Qué se pidió:** un chat por reserva para que huésped y anfitrión se pongan
  de acuerdo (hora de llegada, llaves, dudas). El huésped lo abre desde el
  detalle de su reserva y el anfitrión desde Solicitudes de reserva.
- **Qué acepté:** la tabla `mensajes` que ya traía la migración v3;
  `ChatLocalDataSource.enviar` en una transacción que revisa que la reserva
  exista y siga abierta; `ChatRepositoryImpl` que recorta espacios y pone un
  máximo de 500 caracteres; `ChatPage` con el autor y la hora en cada mensaje,
  y vacío, error con *Reintentar* y modo solo lectura.
- **Qué rechacé o corregí:**
  - Se descartó un chat en tiempo real con servidor (WebSocket o Firebase):
    necesita backend y llaves que no van en el repo. Por ADR-0001 los
    mensajes viven en SQLite del teléfono, y así se explica en la demo.
  - Se descartó borrar el texto al tocar *Enviar*: si falla, el mensaje se
    perdería. Se borra solo cuando ya se guardó.
  - Bloquear el chat de una reserva cancelada o rechazada no se dejó solo en
    la pantalla: la base también lo revisa dentro de la transacción.
  - Se ordena por `enviado_ms, id` para que dos mensajes del mismo
    milisegundo no cambien de lugar.
- **Verificación:** pruebas de datos con SQLite (orden y persistencia al
  reabrir, una conversación por reserva, vacío y largo máximo, reservas
  cerradas, reserva inexistente), pruebas de widget (abrir desde la reserva y
  enviar, vista del anfitrión, el borrador se queda si falla, solo lectura,
  reintentar), `flutter analyze` y CI en verde.

## 2026-11-02 · @gio-ld · Sprint 3: pago simulado de la reserva y ADR-0003

- **Herramienta:** Claude (asistente de código), en una sesión que coordinó
  @gio-ld para el equipo; esta parte la revisó, probó y subió su autor.
- **Qué se pidió:** que una reserva aceptada por el anfitrión se pueda pagar
  eligiendo un método y que quede confirmada, con un comprobante en el
  detalle. Que quede claro que es un pago simulado.
- **Qué acepté:** `PagosLocalDataSource.pagar` en una sola transacción
  (revisar estado, insertar pago, confirmar reserva); el monto calculado con
  los datos de la base; `UNIQUE(reserva_id)` traducido a "Esta reserva ya está
  pagada."; `PagoPage` sin campos de tarjeta y `ComprobanteCard`.
- **Qué rechacé o corregí:**
  - Se descartó pedir número de tarjeta "para que se vea real": una app no
    debe recolectar datos de pago que no va a procesar. Solo se elige el
    método y la pantalla dice que es simulado.
  - Se descartó guardar el total que muestra la pantalla: si tuviera un dato
    viejo, se guardaría mal. El datasource lo recalcula con lo guardado.
  - Se evitó `Radio` con `groupValue` porque está marcado como obsoleto en
    Flutter reciente; se usó `ListTile` con un ícono de selección.
- **Verificación:** pruebas de datos con SQLite (paga y confirma, no paga una
  pendiente, no paga dos veces, `CHECK` del total), pruebas de widget (elegir
  método, pagar, error sin cerrar, comprobante), `flutter analyze` y CI en
  verde.

## 2026-11-02 · @Emersonx257 · Sprint 3: reseñas de estadías completadas

- **Herramienta:** Claude (asistente de código), en una sesión que coordinó
  @gio-ld para el equipo; esta parte la revisó, probó y subió su autor.
- **Qué se pidió:** que el huésped pueda reseñar (1 a 5 estrellas y un
  comentario opcional) una estadía que ya se completó, y que el detalle del
  alojamiento muestre esas reseñas y su promedio.
- **Qué acepté:** la tabla `resenas` que ya traía la migración v3;
  `ResenasLocalDataSource.publicar` en una transacción que revisa que la
  reserva esté completada y sin reseña; el alojamiento y el autor tomados de
  la reserva; `Calificacion.combinar` como lógica pura; `ResenaPage`,
  `AccionResena` en el detalle de la reserva y las reseñas en el detalle del
  alojamiento con la marca "Estadía verificada".
- **Qué rechacé o corregí:**
  - Se descartó dejar reseñar cualquier alojamiento desde su detalle: se
    podría opinar sin haber ido. Solo se reseña desde una reserva completada.
  - Se descartó escribir el nombre del autor en el formulario: sale de la
    reserva, para que nadie firme con otro nombre.
  - Se descartó promediar "promedio del catálogo + promedio local" como si
    fueran dos datos iguales: 12 reseñas del catálogo pesan 12 veces.
  - Se quitó `ReviewsPage` de ejemplo (datos fijos y sin conectar a ninguna
    pantalla) para no dejar código muerto junto a las reseñas reales.
- **Verificación:** pruebas de lógica (`Calificacion.combinar`), pruebas de
  datos con SQLite (solo completadas, una por reserva, `UNIQUE` y `CHECK` de
  estrellas en la base, orden y persistencia al reabrir), pruebas de widget
  (reseñar desde la reserva, error sin cerrar, promedio y lista en el
  alojamiento, reintentar), `flutter analyze` y CI en verde.

## 2026-11-02 · @joshuaF14 · Sprint 3: mapa de alojamientos con OpenStreetMap y ADR-0002

- **Herramienta:** Claude (asistente de código), en una sesión que coordinó
  @gio-ld para el equipo; esta parte la revisó, probó y subió su autor.
- **Qué se pidió:** ver los alojamientos de Explorar en un mapa de Xela con pines
  de precio; al tocar un pin, una tarjeta con el alojamiento y un botón al
  detalle. Sin llave de Google, porque la rúbrica prohíbe subir claves.
- **Qué acepté:** `flutter_map` con teselas de OpenStreetMap y su crédito;
  coordenadas opcionales en `Stay` (`latitud` y `longitud`); `StayModel`
  que acepta varias formas de mandar las coordenadas desde el API;
  `centroDelMapa` como lógica pura; la capa de teselas reemplazable para las
  pruebas.
- **Qué rechacé o corregí:**
  - Se descartó poner en el centro de Xela los alojamientos que no traen
    coordenadas: sería mostrar una ubicación inventada. No tienen pin y el
    mapa avisa.
  - Se descartó meter el mapa dentro del `ListView` de Explorar: el arrastre
    del mapa competiría con el scroll de la lista. Se abre como pantalla
    aparte con la lista ya filtrada.
  - Se descartó probar el mapa con las teselas reales: en las pruebas de
    Flutter no hay internet. La prueba pasa `capaDeMapa: SizedBox.shrink()`.
- **Verificación:** pruebas de lógica (centro del mapa, lectura de
  coordenadas del API), prueba de widget (pines, tarjeta, detalle y aviso de
  alojamientos sin ubicación), `flutter analyze` y CI en verde.

## 2026-11-02 · @Emersonx257 · Sprint 3: reservas, migración v3 y ADR-0001

- **Herramienta:** Claude (asistente de código), en una sesión que coordinó
  @gio-ld para el equipo; esta parte la revisó, probó y subió su autor.
- **Qué se pidió:** solicitar una reserva desde el detalle del alojamiento con
  fechas, huéspedes y desglose de precio; que no se acepten fechas que se
  empalman; una pestaña Reservas con filtro (Pendientes, Próximas,
  Anteriores) y el detalle de cada reserva con la opción de cancelar. La
  migración v3 con las tablas de reservas, pagos, mensajes y reseñas, su
  prueba y un ADR con la decisión de guardarlas en el teléfono.
- **Qué acepté:** la revisión de fechas tomadas y el INSERT en una sola
  transacción; `Desglose` como lógica pura en centavos; el reloj inyectable
  (`relojProvider`) para que las pruebas no dependan del día; el `UPDATE`
  condicionado para cancelar.
- **Qué rechacé o corregí:**
  - Se descartó calcular la tarifa de servicio con `double`
    (`subtotal * 0.1`): se usan enteros con redondeo,
    `(subtotal * 10 + 50) ~/ 100`.
  - Se descartó bloquear también las solicitudes pendientes de otras
    personas: nadie más podría pedir fechas que el anfitrión todavía no
    aceptó. Quedan "en cola" y solo bloquean las aceptadas o confirmadas.
  - Se descartó guardar las fechas como milisegundos: con la hora incluida,
    una estadía de "dos noches" podría contar una o tres. Se guardan como
    `AAAA-MM-DD`.
  - Se cierra el PR #20 (`feat/filtro-reservas`): sus reservas venían de un
    repositorio con datos escritos a mano; esta parte las reemplaza por datos
    reales en SQLite.
- **Verificación:** pruebas de lógica (desglose, pestañas por estado,
  formatos), de datos con SQLite (empalmes, cola, reglas, cancelar, `CHECK`) y
  de migración v2→v3; pruebas de widget del formulario y de la pestaña;
  `flutter analyze` y CI en verde.

## 2026-11-02 · @PJ-Lopez · Sprint 3: panel del anfitrión con solicitudes de reserva

- **Herramienta:** Claude (asistente de código), en una sesión que coordinó
  @gio-ld para el equipo; esta parte la revisó, probó y subió su autor.
- **Qué se pidió:** que el anfitrión vea las solicitudes de reserva con filtro
  (Por atender, Aceptadas, Cerradas), pueda aceptarlas o rechazarlas y marcar
  como completada una estadía confirmada que ya empezó.
- **Qué acepté:** `aceptar` en una sola transacción que también rechaza las
  pendientes que se empalman (la otra mitad de las reservas concurrentes);
  `UPDATE` condicionados para rechazar y completar; `SolicitudesPage` con
  botones bloqueados mientras se guarda; `refrescarReservas` también refresca
  el panel.
- **Qué rechacé o corregí:**
  - Se descartó dejar las otras solicitudes pendientes al aceptar una: dos
    huéspedes podrían terminar con las mismas fechas aceptadas.
  - Se descartó permitir "completar" cualquier reserva: solo una confirmada
    cuya llegada ya pasó, para que la reseña venga de una estadía real.
  - Se mostró un solo aviso al aceptar ("se rechazaron N"), en vez de dos
    avisos seguidos.
- **Verificación:** pruebas de datos con SQLite (aceptar y rechazar las que se
  empalman, no aceptar fechas ocupadas, rechazar una vez, reglas de completar,
  orden), pruebas de widget del panel (aceptar, completar, mensaje de regla),
  `flutter analyze` y CI en verde.

## 2026-11-02 · @PJ-Lopez · Sprint 3: detalle del alojamiento y filtros en Explorar

- **Herramienta:** Claude (asistente de código).
- **Qué pedí:** que las tarjetas de Explorar abran un detalle del alojamiento
  con verificación explicada, calificación sin inventar promedios y un botón
  para guardarlo en una lista de viaje. Además, chips de filtro en el listado
  (verificados, hasta Q 300, para 3 o más) combinados con la búsqueda.
- **Qué acepté:** `FiltrosCatalogo` como lógica pura fuera del widget (se
  prueba sin Flutter), `StayDetailPage` con la hoja "Guardar en…" que solo
  ofrece listas activas, y `StayPhoto` como widget compartido.
- **Qué rechacé o corregí:**
  - Filtrar dentro de `build` con condiciones sueltas: se movió a
    `FiltrosCatalogo` para probar las reglas con pruebas de lógica.
  - Mostrar "0.0" cuando no hay reseñas: se cambió por "Aún sin reseñas".
  - Se descartó usar `ref` después del `await` sin revisar `context.mounted`:
    si el usuario sale antes de que termine el guardado, podría fallar.
- **Verificación:** pruebas de lógica de filtros, pruebas de widget (chips,
  "Quitar filtros", tocar tarjeta abre el detalle, guardar en lista y error al
  guardar), `flutter analyze` y CI en verde.

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

## 2026-11-02 · @joshuaF14 · Sprint 3: pestañas y Guardados con las listas locales

- **Herramienta:** Claude (asistente de código).
- **Qué pedí:** barra inferior con Explorar, Guardados y Perfil, donde
  Guardados muestre las listas de viaje guardadas en SQLite, y quitar la
  pantalla vieja de guardados que no estaba conectada a la navegación.
- **Qué acepté:** `ListasPage` como pestaña dentro del `IndexedStack` (conserva
  su estado al cambiar de pestaña) y una prueba de widget que recorre las tres
  pestañas con un repositorio en memoria.
- **Qué rechacé o corregí:**
  - Conservar `guardados_screen.dart`: hacía la llamada HTTP desde el provider
    (sin pasar por repositorio) y rellenaba con datos escritos a mano cuando
    el API no traía un campo. Se eliminó junto con `SavedStay`.
  - Se eliminó también `StaysStatePage` con su repositorio de datos fijos: era
    una pantalla de práctica que la app ya no usa (Explorar cubre los estados
    de carga, vacío y error con el API).
  - Usar el índice `1` escrito a mano para abrir Perfil: con una pestaña nueva
    apuntaba a Guardados. Ahora es la constante `_perfil`.
- **Verificación:** prueba de navegación entre pestañas, `flutter analyze` y
  `flutter test` en verde.

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
  detalle, `flutter test` local y CI en verde. La prueba manual en emulador
  (borrar una lista con alojamientos, archivarla, cerrar y abrir la app)
  quedó pendiente al cerrar S16: no había emulador disponible.

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
