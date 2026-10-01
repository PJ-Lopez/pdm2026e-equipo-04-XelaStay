# pdm2026e-equipo-04-xelastay
# XelaStay 🏡📍

> Plataforma móvil construida en Flutter para la exploración, reserva y contacto directo de alojamientos con ubicaciones físicas reales en Quetzaltenango, respaldada por un sistema de resolución de reservas concurrentes mediante colas asíncronas.

---

## 1. Problema Observable
Las personas que buscan alojamiento o alquiler en Quetzaltenango se enfrentan a anuncios sin validación física en mapas reales, reseñas poco confiables y el riesgo constante de sobreventa o cancelaciones de última hora cuando dos o más personas intentan reservar el mismo espacio simultáneamente.

---

## 2. Alcance del MVP (Milestone M1: Arquitectura y Datos)
1. **Exploración Geográfica y Catálogo:** Visualización de alojamientos mediante mapa interactivo con pines y lista de tarjetas con referencias físicas verificadas.
2. **Detalle de Alojamiento y Reseñas:** Vista con especificaciones del lugar, calificación promedio, comentarios de huéspedes previos y acción de reserva.
3. **Gestión de Reservas y Chat:** Flujo de solicitud para apartar lugar (preparado para resolución asíncrona de colas) y canal de chat bidireccional entre huésped y anfitrión.

---

## 3. Integrantes del Equipo

* **Emerson Basilio Tahay Menchú** — Carnet: `202308012` — [@Emersonx257](https://github.com/Emersonx257)
* **Pedro Javier López López** — Carnet: `202308038` — [@PJ-Lopez](https://github.com/PJ-Lopez)
* **Joshua David Flores Morales** — Carnet: `202308056` — [@joshuaF14](https://github.com/joshuaF14)
* **Giovanni Fernando de León Coyoy** — Carnet: `202308088` — [@gio-ld](https://github.com/gio-ld)

---

## 4. Historial y Matriz de Roles Semanales

De acuerdo con la metodología del curso, los roles rotan periódicamente para garantizar la participación equitativa en la toma de decisiones, arquitectura, desarrollo y calidad:

### Semana 1 (Laboratorio S08 — Definición, Setup y Backlog M1)
| Integrante | Rol Semana 1 | Responsabilidad Desempeñada |
| :--- | :--- | :--- |
| `@PJ-Lopez` | **Arquitectura** | Creación y configuración inicial del repositorio, ramas base y `.gitignore`. |
| `@Emersonx257` | **Producto / PM** | Delimitación del alcance del MVP y redacción de criterios de aceptación iniciales. |
| `@joshuaF14` | **UX / Investigación** | Mapeo del flujo principal de navegación y análisis de interacción del usuario. |
| `@gio-ld` | **QA / Release** | Configuración de reglas de protección en `main`, revisión del primer Pull Request y merge. |

### Semana 2 (Semana Actual — Implementación M1: Arquitectura y Modelos)
| Integrante | Rol Semana 2 | Responsabilidad y Entregables |
| :--- | :--- | :--- |
| `@PJ-Lopez` | **Producto / PM** | Priorización de backlog en M1, auditoría de criterios de aceptación y alineación con backend comercial. |
| `@joshuaF14` | **Arquitectura** | Estructuración de Clean Architecture y creación de modelos de datos Dart (`Stay`, `BookingRequest`, `Review`, `ChatMessage`). |
| `@gio-ld` | **UX / Investigación** | Maquetación de vistas de exploración (mapa/lista), detalle de estancia y catálogo de ubicaciones. |
| `@Emersonx257` | **QA / Release** | Revisión de Pull Requests, validación de criterios en ramas `issue-*` y control de merges hacia `main`. |

---

## 5. Arquitectura de Software: Clean Architecture

El proyecto organiza su código fuente bajo una estructura modular en capas para desacoplar las reglas de negocio de la interfaz gráfica y de las fuentes de datos externas:

```text
lib/
├── main.dart                          # Punto de arranque de la aplicación
│
├── core/                              # Recursos comunes compartidos
│   ├── theme/                         # Paleta de colores, tipografía y ThemeData
│   ├── network/                       # Configuración HTTP y clientes de mensajería/colas
│   └── utils/                         # Formateadores de moneda (Q) y helpers
│
└── features/                          # Módulos por capacidad funcional
    ├── stays/                         # Módulo de exploración y catálogo de lugares
    │   ├── domain/                    # Entidades puras (Stay, Location, Review) y contratos
    │   ├── data/                      # Modelos con serialización y fuentes de datos
    │   └── presentation/              # Páginas (ExploraPage, DetallePage) y widgets
    │
    ├── booking/                       # Módulo de solicitud y resolución de reservas
    │   ├── domain/                    # Entidad BookingRequest y lógica de estados
    │   ├── data/                      # Repositorios y conexión a endpoints / colas
    │   └── presentation/              # Páginas de confirmación y estado de reserva
    │
    └── chat/                          # Módulo de mensajería huésped-anfitrión
        ├── domain/                    # Entidad ChatMessage y contratos
        ├── data/                      # Datasources en tiempo real
        └── presentation/              # ChatPage y componentes de conversación
```

---

## 6. Regla de Trabajo y Flujo Git

> ⚠️ **Regla estricta:** Nadie hace push directo a `main`. Todo cambio en el proyecto debe pasar por revisión antes de integrarse.

El ciclo de desarrollo obligatorio es:

```text
[Issue asignado en M1] ──> [Rama local: issue-<#>-descripcion] ──> [Pull Request con 'Closes #<#>'] ──> [Revisión y Aprobación QA] ──> [Merge a main]
```