# XelaStay Mobile

Aplicación Flutter para XelaStay, orientada a iOS y Android.

## Laboratorio: estados del catálogo

`StaysPage` recibe `GetPublicStays`, que depende del contrato
`StaysRepository`. La app normal mantiene el repositorio del API. La entrada
independiente de demostración usa `SimulatedStaysRepository` con 800 ms de
latencia, sin requerir inicio de sesión ni servidor:

```bash
flutter run -t lib/main_stays_demo.dart --dart-define=STAYS_SCENARIO=data
flutter run -t lib/main_stays_demo.dart --dart-define=STAYS_SCENARIO=error
flutter run -t lib/main_stays_demo.dart --dart-define=STAYS_SCENARIO=empty
```

En los tres casos se muestra primero un spinner con texto. `data` muestra dos
alojamientos; `error` muestra un mensaje y permite reintentar; `empty` permite
actualizar. Reintentar o actualizar conserva el escenario elegido; para cambiarlo
se debe ejecutar otro comando. Una búsqueda sin coincidencias permite limpiar
el filtro. El botón de perfil no navega en esta demostración aislada.

```bash
flutter test test/features/stays/stays_page_test.dart
```

Las pruebas sustituyen el repositorio mediante inyección de constructor, sin
HTTP ni almacenamiento real. Cubren carga, datos, error, reintento con recuperación,
vacío con actualización y limpieza de búsqueda.

## Módulos

Las features siguen Clean Architecture con dependencias hacia adentro:

    lib/
      core/                    # HTTP, tema y utilidades compartidas
      features/
        auth/
          domain/               # Usuario, contratos y casos de uso
          data/                 # API, almacenamiento seguro y repositorio
          presentation/         # Estado, páginas y widgets de acceso
        hosts/
          domain/               # Alojamiento del anfitrión y casos de uso
          data/                 # Integración con endpoints de anfitrión
          presentation/         # Activación y registro de alojamiento

La composición de repositorios y casos de uso vive en lib/main.dart. Los widgets dependen de casos de uso/controladores, no de HTTP ni de modelos de base de datos.

## Acceso a la API local

La configuración usa API_BASE_URL si se proporciona. En modo debug, por defecto conecta al API local en http://10.0.2.2:3000/api/v1 desde el emulador Android y http://127.0.0.1:3000/api/v1 desde Flutter Web y el simulador iOS.

    flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

Para un teléfono físico, define API_BASE_URL con la dirección LAN de la computadora que ejecuta la API. En builds de producción se debe configurar una URL HTTPS. El token de sesión se guarda con almacenamiento seguro del sistema.

El flujo actual cubre registro e inicio de sesión, restauración de sesión, activar modo anfitrión y registrar un alojamiento como pendiente de verificación. La selección de coordenadas aún es manual; el formulario recoge dirección, zona, referencia y coordenadas para alinearse con la API.
