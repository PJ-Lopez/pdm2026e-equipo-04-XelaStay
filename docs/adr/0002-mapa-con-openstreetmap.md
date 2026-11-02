# ADR-0002: Mapa con OpenStreetMap (flutter_map) en lugar de Google Maps

- **Estado:** aceptada
- **Fecha:** 2026-11-02
- **Autor:** @joshuaF14 (decisión del equipo)

## Contexto

La app necesita mostrar los alojamientos en un mapa de Xela para que la persona entienda dónde quedan. La opción conocida era Google Maps (`google_maps_flutter`), pero:

- pide una llave de API de Google Cloud con una tarjeta de crédito asociada;
- la llave va en `AndroidManifest.xml`, y la rúbrica del curso prohíbe subir claves al repositorio;
- cada integrante tendría que configurar su propia llave para correr la app.

## Decisión

Usamos **`flutter_map`** con las teselas públicas de **OpenStreetMap** (`https://tile.openstreetmap.org/{z}/{x}/{y}.png`):

- no necesita llave ni cuenta, así que cualquiera clona el repo y corre la app;
- mostramos el crédito "OpenStreetMap contributors", que pide la licencia ODbL, y enviamos un `userAgentPackageName` como piden sus reglas de uso;
- el mapa recibe la lista **ya filtrada** de Explorar (`MapaAlojamientosPage(stays: ...)`), así que conserva la búsqueda y los chips;
- un alojamiento sin coordenadas **no** se pone en el centro de Xela "por si acaso": sale solo en la lista y el mapa avisa cuántos no tienen ubicación;
- la capa de teselas se puede reemplazar (`capaDeMapa`). Las pruebas usan una capa vacía para no depender de internet.

## Consecuencias

- ✅ Sin secretos en el repo y sin costo.
- ✅ Las pruebas de widget del mapa corren sin red.
- ⚠️ Las teselas públicas de OSM no son para tráfico grande. Si la app se publicara, habría que usar un proveedor de teselas (o un servidor propio) y cambiar solo `urlTemplate`.
- ⚠️ No hay búsqueda de direcciones (geocodificación). Las coordenadas las pone el anfitrión al registrar su alojamiento.
