# pdm2026e-equipo-04-gymtrack
# GymTrack 

> Aplicación móvil construida en Flutter para el registro ágil de entrenamientos de pesas, control de sobrecarga progresiva y temporización de descansos guiados.

---

## 1. Problema Observable
Las personas que entrenan fuerza o hipertrofia en salas de pesas suelen olvidar las cargas y repeticiones ejecutadas en sesiones anteriores, recurren a blocs de notas desestructurados que generan fricción durante el entrenamiento y extienden innecesariamente sus descansos por distracción con el teléfono móvil.

---

## 2. Alcance del MVP (Milestone M1: Arquitectura y Datos)
1. **Catálogo de Rutinas Base:** Selector de 3 rutinas fijas predeterminadas (Empuje, Tracción, Pierna).
2. **Registro de Series Interactivo:** Entrada rápida de peso (kg/lbs) y repeticiones con validación de serie completada.
3. **Temporizador de Descanso:** Contador regresivo configurable (60s / 90s / 120s) con alerta de descanso finalizado y pantalla de resumen con volumen total levantado.

---

## 3. Integrantes del Equipo

* **Emerson Basilio Tahay Menchú** — Carnet: `202308012` — [@Emersonx257](https://github.com/Emersonx257)
* **Pedro Javier López López** — Carnet: `202308038` — [@PJ-Lopez](https://github.com/PJ-Lopez)
* **Joshua David Flores Morales** — Carnet: `202308056` — [@joshuaF14](https://github.com/joshuaF14)
* **Giovanni Fernando de León Coyoy** — Carnet: `202308088` — [@gio-ld](https://github.com/gio-ld)

---

## 4. Historial y Matriz de Roles Semanales

De acuerdo con la metodología de trabajo del curso, los roles rotan periódicamente asegurando que todos los integrantes participen en la toma de decisiones, arquitectura, diseño y control de calidad:

### Semana 1 (Laboratorio S08 — Definición, Setup y Backlog M1)
| Integrante | Rol Semana 1 | Responsabilidad Desempeñada |
| :--- | :--- | :--- |
| `@Emersonx257` | **Producto / PM** | Definición del alcance del MVP, delimitación de funciones y redacción de criterios de aceptación. |
| `@PJ-Lopez` | **Arquitectura** | Creación y configuración inicial del repositorio, ramas base y archivo `.gitignore`. |
| `@joshuaF14` | **UX / Investigación** | Mapeo del flujo principal de 3 pasos y validación de la experiencia en sala de pesas. |
| `@gio-ld` | **QA / Release** | Configuración de reglas de protección en `main`, revisión del primer Pull Request y merge inicial. |

### Semana 2 (Semana Actual — Implementación M1: Arquitectura y Modelos)
| Integrante | Rol Semana 2 | Responsabilidad y Entregables |
| :--- | :--- | :--- |
| `@PJ-Lopez` | **Producto / PM** | Priorización y refinamiento de issues en Milestone M1; auditoría de criterios de aceptación. |
| `@joshuaF14` | **Arquitectura** | Definición del estándar de Clean Architecture y creación de modelos de datos Dart (`Routine`, `Exercise`, `WorkoutSet`). |
| `@gio-ld` | **UX / Investigación** | Maquetación del flujo de navegación entre pantallas y validación del catálogo de rutinas. |
| `@Emersonx257` | **QA / Release** | Revisión de Pull Requests, ejecución de checklist de pruebas y control de merges hacia `main`. |

---

## 5. Arquitectura de Software: Clean Architecture

El proyecto organiza su código fuente bajo una estructura modular en capas para desacoplar la interfaz de usuario de las reglas de negocio y fuentes de datos:

```text
lib/
├── main.dart                          # Punto de entrada y arranque
│
├── core/                              # Recursos globales compartidos
│   ├── theme/                         # Paleta de colores y ThemeData
│   └── utils/                         # Formateadores y helpers
│
└── features/                          # Módulos funcionales
    └── workout/                       # Feature principal de entrenamiento
        ├── domain/                    # Lógica pura (sin dependencias de UI)
        │   ├── entities/              # Routine, Exercise, WorkoutSet
        │   └── repositories/          # Contratos e interfaces abstractas
        │
        ├── data/                      # Persistencia e implementación
        │   ├── datasources/           # Catálogo local / persistencia
        │   ├── models/                # Modelos y serialización
        │   └── repositories/          # Implementación de los repositorios
        │
        └── presentation/              # Capa visual y estado
            ├── controllers/           # Gestores de estado y timer
            ├── pages/                 # RutinasPage, TrainingPage, SummaryPage
            └── widgets/               # SetRowTile, TimerCard, etc.
```

---

## 6. Regla de Trabajo y Flujo Git

>  **Regla estricta:** Nadie hace push directo a `main`. Todo cambio en el proyecto debe pasar por revisión antes de integrarse.

El ciclo de desarrollo obligatorio es:

[Issue asignado en M1] ──> [Rama local: issue-<#>-descripcion] ──> [Pull Request con 'Closes #<#>'] ──> [Revisión y Aprobación QA] ──> [Merge a main]