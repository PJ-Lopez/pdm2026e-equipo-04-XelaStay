# ADR-0001: Reservas, pagos, chat y reseñas en SQLite del teléfono

- **Estado:** aceptada
- **Fecha:** 2026-11-02
- **Autor:** @Emersonx257 (decisión del equipo)

## Contexto

XelaStay usa un API propio (`xela-stayAPI`) para el inicio de sesión, el catálogo y el registro de alojamientos. Para la exposición del 5 de noviembre necesitábamos reservas, pago, chat entre huésped y anfitrión y reseñas. El API no tiene esos endpoints, y agregarlos implicaba cambiar otro repositorio, desplegarlo y probarlo en menos de tres días.

## Decisión

Las reservas y todo lo que depende de ellas (pagos, mensajes y reseñas) se guardan en la base SQLite del teléfono (`AppDatabase`), en la **migración v3**. Las cuatro tablas van en una sola versión porque ninguna tiene sentido sin la reserva: `pagos`, `mensajes` y `resenas` tienen `FOREIGN KEY` a `reservas`.

Las reglas importantes viven en la base y en el repositorio, no en las pantallas:

- **Fechas que se empalman:** al solicitar, el datasource revisa en **la misma transacción** si hay una reserva aceptada o confirmada con `entrada < salida_nueva AND salida > entrada_nueva` antes del INSERT. Si dos solicitudes llegan a la vez, la segunda ya ve a la primera.
- Las fechas se guardan como texto `AAAA-MM-DD`, que ordena igual que las fechas, y el dinero en centavos (`int`).
- Los `CHECK` (salida después de la llegada, estrellas de 1 a 5, total = subtotal + servicio) son la última defensa aunque la app falle.

## Consecuencias

- ✅ Funciona sin conexión y no depende de cambiar el API para la demo.
- ✅ Todo se puede probar con `sqflite_common_ffi` en la computadora (pruebas de datos y de migración).
- ⚠️ **Los datos viven en un solo teléfono.** El anfitrión ve las solicitudes guardadas en ese teléfono, así que en la demo la misma persona hace de huésped y de anfitrión. El chat no llega a otro dispositivo.
- ⚠️ Si se borran los datos de la app, se pierden las reservas.

## Siguiente paso

Mover reservas, mensajes y reseñas al API (`/bookings`, `/bookings/{id}/messages`, `/stays/{id}/reviews`) manteniendo el mismo contrato `ReservasRepository`: solo cambiaría la implementación del repositorio (de SQLite a HTTP), no las pantallas.
