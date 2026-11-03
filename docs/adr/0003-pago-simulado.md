# ADR-0003: Pago simulado, sin datos de tarjeta

- **Estado:** aceptada
- **Fecha:** 2026-11-02
- **Autor:** @gio-ld (decisión del equipo)

## Contexto

El flujo de reserva necesita un paso de pago para que una reserva aceptada quede confirmada. Integrar una pasarela real (por ejemplo, un procesador de tarjetas) exige una cuenta de comercio, llaves secretas que no pueden ir al repositorio y cumplir normas de seguridad para manejar datos de tarjeta. Nada de eso cabe en el alcance del curso.

## Decisión

El pago es **simulado** y la pantalla lo dice:

- la persona elige un método (tarjeta, transferencia o efectivo al llegar) y **no se piden ni guardan datos de tarjeta**;
- en **una sola transacción** se revisa que la reserva esté `aceptada`, se calcula el monto con los datos guardados en la base (no con lo que muestra la pantalla), se inserta el pago y la reserva pasa a `confirmada`;
- la tabla `pagos` tiene `UNIQUE(reserva_id)` (no se puede pagar dos veces) y `CHECK(total = subtotal + servicio)`;
- el comprobante se muestra en el detalle de la reserva con su referencia (`XS-00012`) y la leyenda "Pago simulado: no se hizo ningún cobro real".

## Consecuencias

- ✅ El flujo completo (solicitar → aceptar → pagar → confirmada) se puede demostrar y probar sin cuentas externas ni secretos.
- ✅ Si falla cualquier paso, la transacción no deja un pago sin confirmar la reserva, ni al revés.
- ⚠️ No hay cobro real. Una pasarela de verdad tendría que procesar el pago en el servidor; la app solo recibiría la confirmación. Como `PagosRepository` es un contrato, solo cambiaría su implementación.
