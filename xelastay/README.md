# XelaStay Mobile

Aplicación Flutter para XelaStay, orientada a iOS y Android.

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
