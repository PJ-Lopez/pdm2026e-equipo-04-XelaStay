# XelaStay 🏡📍

App Android en Flutter para encontrar, reservar y pagar alojamiento en Quetzaltenango, con ubicación verificada en el mapa, chat con el anfitrión y reseñas de huéspedes que de verdad se hospedaron.

> Proyecto del curso Programación de Dispositivos Móviles · UMES Quetzaltenango · Sección E · Equipo 4

---

## El problema y el usuario

**Usuario:** quien llega a Xela por unos días o unos meses (estudiantes de otros departamentos, viajeros, gente que viene por trabajo) y busca dónde quedarse. Del otro lado, el **anfitrión local** que renta un cuarto, un apartamento o una casa.

**Problema:** hoy ese alojamiento se busca en anuncios sueltos, sin ubicación verificada en un mapa. No se sabe si la dirección es real, las reseñas no se pueden comprobar y apartar un lugar es una cadena de mensajes: dos personas pueden creer que tienen las mismas fechas, y no queda constancia de lo que se pagó.

**Qué hace XelaStay:**

- Catálogo con **filtros** (verificados, hasta Q 300, para 3 o más) y **mapa** con la ubicación de cada lugar; los que la tienen revisada lo dicen.
- **Reservas que no se empalman:** al pedir y al aceptar se revisan las fechas dentro de una transacción.
- **Pago con comprobante** (simulado en esta versión, ver ADR-0003).
- **Chat por reserva** entre huésped y anfitrión.
- **Reseñas solo de estadías completadas**, marcadas como *Estadía verificada*.
- **Listas de viaje** para guardar alojamientos y decidir después.

## Capturas

| Explorar con filtros | Detalle | Mapa |
|---|---|---|
| ![Explorar](docs/capturas/explorar.png) | ![Detalle](docs/capturas/detalle.png) | ![Mapa](docs/capturas/mapa.png) |
| **Mis reservas** | **Pago y comprobante** | **Solicitudes del anfitrión** |
| ![Reservas](docs/capturas/reservas.png) | ![Pago](docs/capturas/pago.png) | ![Solicitudes](docs/capturas/solicitudes.png) |
| **Chat** | **Reseña** | **Listas de viaje** |
| ![Chat](docs/capturas/chat.png) | ![Reseña](docs/capturas/resena.png) | ![Listas](docs/capturas/listas.png) |

## Cómo correr la app

**Requisitos:** Flutter 3.47 (la misma versión del CI), Android Studio con un emulador Android y Docker para el API.

> La app es para **Android**. No funciona en Chrome: la base local (sqflite) no corre en Web.

**1. Levantar el API** (`xela-stayAPI`, en su propio repositorio). Da el inicio de sesión, el catálogo y el registro de alojamientos. Se levanta con Docker siguiendo su README: el API queda en el puerto 3000, con MySQL. **Todo el equipo debe usar la misma versión del API** (`git pull` en su carpeta antes de probar).

Para comprobarlo, abre `http://localhost:3000/api/v1/stays` en el navegador: debe mostrar los alojamientos.

**2. Correr la app** en el emulador:

```bash
cd xelastay
flutter pub get
flutter run
```

El emulador llega al API de la computadora por `http://10.0.2.2:3000/api/v1`. En un teléfono físico, usa la IP de la computadora en la red:

```bash
flutter run --dart-define=API_BASE_URL=http://IP-DE-LA-PC:3000/api/v1
```

**3. Recorrer el flujo completo.** Las reservas, el pago, el chat y las reseñas se guardan en el teléfono (ADR-0001), así que en la demo la misma persona hace de huésped y de anfitrión:

1. Crear cuenta → Explorar → elegir un alojamiento → *Solicitar reserva* con **llegada hoy**.
2. Reservas → la reserva → ícono de chat → escribir al anfitrión.
3. Perfil → *Conocer modo anfitrión* → *Quiero ser anfitrión* → *Solicitudes de reserva* → **Aceptar** (y contestar el chat).
4. Reservas → *Pagar y confirmar* → elegir método → comprobante.
5. Solicitudes → Aceptadas → **Marcar estadía completada**.
6. Reservas → **Escribir reseña** → el alojamiento la muestra con *Estadía verificada*.

## Pruebas y calidad

```bash
cd xelastay
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

- **Lógica:** filtros del catálogo, desglose del precio, centro del mapa, promedio de calificaciones.
- **Datos (SQLite real):** migraciones v1 → v2 → v3 con datos, reservas que se empalman, aceptar y rechazar en una transacción, pago único por reserva, chat y reseñas.
- **Pantallas:** cada pantalla con cargando, vacío y error con *Reintentar*, usando repositorios falsos.

El **CI** (GitHub Actions) corre formato, análisis y pruebas en cada PR y en `main`, y compila un APK de prueba. `main` está protegida: todo entra por PR revisado por otra persona.

## Arquitectura

Cada función vive en `xelastay/lib/features/<función>/` con tres capas, y las dependencias van hacia adentro:

```text
presentation/  pantallas y providers (Riverpod)  → solo llaman al repositorio
domain/        entidades, reglas y contratos      → Dart puro, sin Flutter ni SQL
data/          datasources (SQL o HTTP) y la implementación del repositorio
```

La pantalla nunca habla con la base: `pantalla → provider → repositorio → datasource → SQLite / API`. Funciones: `auth`, `stays` (catálogo, detalle, mapa), `listas`, `booking` (reservas), `pagos`, `hosts` (anfitrión), `chat` y `resenas`.

**Dónde se guardan los datos:**

- **API (Docker):** cuentas, sesión, catálogo de alojamientos y registro de alojamientos del anfitrión.
- **SQLite en el teléfono** (`xelastay.db`), con migraciones numeradas y probadas: v1 guardados · v2 listas de viaje · v3 reservas, pagos, mensajes y reseñas.

## Limitaciones conocidas

- **Datos en el teléfono, no en la cuenta** (ADR-0001). Reservas, pagos, chat y reseñas viven en el teléfono: el chat no llega a otro dispositivo, y en la demo la misma persona hace de huésped y de anfitrión. Las listas de viaje las comparten las cuentas que entren en el mismo teléfono.
- **No hay panel de administrador.** El rol admin ve lo mismo que un anfitrión. Los alojamientos que crea un anfitrión quedan pendientes de verificación y no hay pantalla para aprobarlos.
- **El anfitrión crea alojamientos, pero no los edita** desde la app.
- **El pago es simulado** (ADR-0003): no se cobra ni se piden datos de tarjeta.
- **Textos del API:** algunas palabras con acento se ven mal ("HistÃ³rico") porque el API no indica `charset=utf-8`, y el tipo de alojamiento aparece como lo manda el API ("apartment", "house").

## Decisiones (ADR)

- [ADR-0001](docs/adr/0001-reservas-en-sqlite-local.md) · Reservas, pagos, chat y reseñas en SQLite local.
- [ADR-0002](docs/adr/0002-mapa-con-openstreetmap.md) · Mapa con OpenStreetMap, sin llave de Google.
- [ADR-0003](docs/adr/0003-pago-simulado.md) · Pago simulado, sin pedir datos de tarjeta.

## Pruebas con usuarios

Qué intentaron las personas que probaron la app, qué falló y qué PR lo arregló: [docs/usuarios.md](docs/usuarios.md).

## Forma de trabajo

1. Cada tarea es un **issue** asignado.
2. Rama desde `main`: `feat/<#issue>-descripcion`.
3. **PR** con `Closes #<issue>`, el CI en verde y la **revisión de otra persona**.
4. Merge a `main`. Nadie hace push directo a `main`.

El uso de IA de cada PR queda en la [bitácora de IA](docs/bitacora-ia.md). Los roles de cada semana están en [docs/roles-semanales.md](docs/roles-semanales.md).

## Equipo

- **Emerson Basilio Tahay Menchú** — `202308012` — [@Emersonx257](https://github.com/Emersonx257)
- **Pedro Javier López López** — `202308038` — [@PJ-Lopez](https://github.com/PJ-Lopez)
- **Joshua David Flores Morales** — `202308056` — [@joshuaF14](https://github.com/joshuaF14)
- **Giovanni Fernando de León Coyoy** — `202308088` — [@gio-ld](https://github.com/gio-ld)
