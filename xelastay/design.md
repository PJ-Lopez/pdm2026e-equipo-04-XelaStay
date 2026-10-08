# XelaStay — Diseño de la app móvil

> Guía de experiencia, interfaz e implementación visual para iOS y Android. La app ayuda a encontrar alojamientos locales en Quetzaltenango con información útil, ubicación comprensible y señales claras de confianza.

## 1. Visión del producto

XelaStay debe sentirse como una guía de viaje local, cálida y cuidada, con la rapidez de una app de reservas. No es solo un catálogo: orienta a la persona para entender **dónde queda** un alojamiento, **qué tiene cerca**, **por qué podría convenirle** y **qué tan confiable es la información**.

### Principios de experiencia

1. **Primero el lugar, después el formulario.** Permitir explorar antes de exigir cuenta o permisos de ubicación.
2. **Mapa y tarjetas se complementan.** Una persona puede empezar por la zona o por las características; cambiar de vista conserva búsqueda, fechas y filtros.
3. **Explicar la relevancia.** Cada recomendación indica motivos concretos, como “a 6 min del parque”, “espacio para trabajar” o “vista hacia Santa María” (solo si está verificado).
4. **La confianza se puede comprobar.** Diferenciar ubicación verificada, reseña de una estadía completada y disponibilidad consultada de una promesa de reserva.
5. **La reserva siempre comunica su estado.** Una solicitud en proceso no debe parecer confirmada; mostrar qué pasó y cuál es el siguiente paso.
6. **Local sin estereotipos.** Usar Xela, sus paisajes, clima, barrios, referencias y arquitectura con fotografías y lenguaje propios. Los elementos culturales deben tener contexto y respeto.

## 2. Identidad visual

### Idea creativa: “Xela entre volcanes”

Una identidad editorial de viaje construida alrededor del perfil del volcán Santa María, el cielo frío de altura y los acentos urbanos de Xela. El volcán puede aparecer como línea de horizonte, marca de sección o ilustración sutil; las fotos reales de alojamientos y lugares siguen siendo protagonistas.

Usar curvas de nivel y líneas de mapa como textura muy tenue en fondos o transiciones. El patrón no debe competir con texto, pines ni controles del mapa. Evitar usar símbolos mayas o textiles como decoración genérica: cualquier referencia textil debe partir de una fuente local identificable y acreditada.

### Paleta

El blanco y los tonos claros dominan para que las fotos se vean amplias y la lectura sea cómoda. Azul comunica orientación y confianza; rojo añade energía para acciones y detalles de marca.

| Token | Color | Uso |
| --- | --- | --- |
| `canvas` | `#F7F8FA` | Fondo general, superficies detrás de tarjetas. |
| `surface` | `#FFFFFF` | Tarjetas, hojas modales y barras. |
| `ink` | `#17233B` | Texto principal azul noche. |
| `blue` | `#244D82` | Navegación, enlaces, selección y elementos de mapa. |
| `blue-soft` | `#EAF1F8` | Chips seleccionados, filtros y paneles informativos. |
| `red` | `#B83C45` | Acción principal, favoritos activos y acentos. |
| `red-soft` | `#F8E9EA` | Fondo suave de avisos o etiquetas relacionadas con marca. |
| `muted` | `#687486` | Texto secundario e iconografía secundaria. |
| `line` | `#E2E7ED` | Bordes y separadores. |
| `success` | `#24745B` | Confirmaciones y estados completados. |
| `warning` | `#946318` | Atención y estados que requieren respuesta. |

Usar rojo para acciones primarias puntuales, no para grandes áreas ni textos largos. El azul será el color de navegación y orientación. Revisar contraste de cada combinación, sobre todo texto blanco sobre rojo y texto secundario sobre `canvas`; no comunicar estados solo con color.

### Tipografía “con carácter de Xela”

- **Titulares editoriales:** una serif legible y expresiva, por ejemplo `Lora` o `Merriweather`, para títulos de bienvenida, nombres de colecciones y frases locales.
- **Interfaz y lectura:** una sans-serif clara como `Inter` o la familia de sistema para etiquetas, botones, precios, formularios y textos extensos.
- La sensación quetzalteca viene de la composición, el vocabulario local, la fotografía y el perfil del volcán, no de imitar letras de idiomas originarios ni de una fuente ornamental difícil de leer.
- Verificar licencia y disponibilidad offline de las fuentes antes de incluir archivos en Flutter. Mantener cifras y precios en sans-serif para facilitar comparación.

Escala orientativa: título de pantalla 28–32 px, encabezado de sección 20–24 px, título de tarjeta 16–18 px, cuerpo 14–16 px, metadatos 12–13 px. Son puntos de partida; respetar el escalado de texto del sistema y permitir que el contenido crezca.

### Fotografía y gráficos

- Fotografía cálida y natural, luz real, interiores completos y referencias reconocibles; mostrar escala y contexto, no solo detalles decorativos.
- En el detalle, mezclar fotos del alojamiento con ubicación/referencias locales claramente identificadas. No presentar fotos de la zona como fotos del alojamiento.
- No usar imágenes generadas como prueba del estado de un lugar. Fotos verificadas y fotos ilustrativas deben distinguirse.
- Iconos simples y consistentes. El símbolo de XelaStay puede combinar una ubicación y una línea de horizonte volcánico, sin sobrecargarlo.

## 3. Navegación y arquitectura de información

Usar una barra inferior persistente con cuatro destinos principales:

1. **Explorar** — mapa/lista, búsqueda y filtros.
2. **Guardados** — alojamientos guardados.
3. **Reservas** — solicitudes y estadías con su estado.
4. **Perfil** — cuenta, preferencias y ayuda.

El **chat** se abre desde la reserva o desde la conversación relacionada con una solicitud. Así la persona entiende de qué alojamiento y fechas está hablando. Acciones secundarias usan hojas modales o páginas apiladas; evitar llenar la navegación principal de opciones.

```text
Explorar → Resultados (mapa/lista) → Detalle → Solicitar reserva → Estado de solicitud
                                      ├→ Guardar
                                      ├→ Ver reseñas
                                      └→ Preguntar al anfitrión → Chat
Reservas → Solicitud/estadía → Detalle de estado → Chat / Reseña cuando aplique
```

### Reglas de navegación

- Mantener búsqueda, filtros y posición del mapa al entrar a un detalle y volver.
- Android: respetar botón/gesto Atrás y navegación del sistema; no interceptarlos de forma inesperada.
- iOS: usar áreas seguras, gestos de navegación y presentación de hojas familiar a iOS.
- Evitar pantallas sin salida. Toda hoja modal ofrece cerrar/cancelar claramente.
- El usuario puede consultar el catálogo sin autenticación; pedir iniciar sesión cuando guarde en cuenta, envíe mensajes o solicite una reserva.

## 4. Flujos y pantallas

### A. Explorar — punto de entrada

**Encabezado:** saludo discreto y contexto “Quetzaltenango, Guatemala”, con un pequeño perfil o acceso a cuenta. Debajo, una barra de búsqueda prominente: **“¿Qué te gustaría tener cerca?”**

La búsqueda permite indicar lugar/referencia, fechas y huéspedes sin ocupar toda la pantalla. Sugerencias de interés en chips horizontales, de selección opcional:

- Cerca del centro
- Vista al volcán
- Cocina
- Parqueo
- Para trabajar
- Familiar
- Económico
- Pet friendly

Mostrar solo chips que el catálogo pueda respaldar; no fingir características. Una franja editorial opcional, por ejemplo **“Despierta con Santa María”**, lleva a una colección de alojamientos cuya vista esté verificada. Si no hay inventario curado, reemplazar por recomendaciones calculadas y explicar el motivo.

La lista inicial puede combinar:

- **Tu búsqueda** con fechas/huéspedes editables.
- **Alojamientos verificados cerca de…** con contexto local.
- **Por qué aparece aquí:** etiqueta breve y concreta basada en preferencias o proximidad.

No bloquear la primera vista con un onboarding largo ni pedir ubicación del teléfono de inmediato.

### B. Resultados — mapa y lista

- Control visible **Mapa / Lista** que conserva criterios y resultados.
- En mapa, pines con precio, pines agrupados al alejar el zoom y una tarjeta inferior compacta al seleccionar un pin.
- En lista, tarjetas grandes con foto, precio por noche, puntuación y número de reseñas, zona/referencia, indicador de verificación y 1–2 atributos relevantes.
- Filtros en hoja inferior: presupuesto, fechas, huéspedes, habitaciones, servicios, zona/referencia, puntuación y opciones de accesibilidad cuando haya datos fiables.
- Botón para ordenar: recomendados, precio más bajo, mejor calificados y más cercanos a una referencia.
- La ubicación precisa del teléfono es optativa. Si se niega el permiso, permitir buscar por zona, dirección o punto conocido.
- Mostrar cuándo no hay resultados y permitir quitar el filtro más restrictivo; nunca dejar un mapa vacío sin explicación.

**Tarjeta recomendada:** foto 4:3 con esquinas redondeadas; favorito en esquina con área táctil amplia; verificación fuera de la foto; título de una línea o dos; zona y referencia; calificación con conteo; precio nocturno y, tras elegir fechas, total estimado si ya está disponible.

### C. Detalle del alojamiento

1. Galería con fotos, contador y botón de guardar.
2. Nombre, zona/referencia física y estado de verificación explicado al tocar.
3. Puntuación y cantidad de reseñas, sin mostrar promedios sin respaldo.
4. Precio por noche y resumen de fechas/huéspedes seleccionados.
5. Bloque **“Lo que te puede interesar”** con etiquetas razonadas y datos comprobables.
6. Descripción, capacidad, habitaciones y servicios.
7. Ubicación en mapa con referencias locales; indicar si el pin es aproximado.
8. Reseñas con indicador **“Estadía verificada”**, fecha y paginación.
9. Perfil/resumen del anfitrión y acción para preguntar.
10. Barra inferior fija: precio orientativo y **“Consultar disponibilidad”** / **“Solicitar reserva”** según el estado real.

No mostrar dirección exacta ni información personal sensible si la política del producto reserva esos datos para después de aceptar la reserva. Los detalles de verificación explican cuándo se revisó y qué significa, sin publicar evidencia privada.

### D. Fechas, huéspedes y filtros

- Calendario mensual con entrada y salida claramente diferenciadas; usar intervalos locales, no horas.
- Resumen persistente de noches y huéspedes.
- Personas y edades si las reglas del alojamiento lo requieren; controles `+ / −` accesibles y con límites explícitos.
- Validar fechas antes de enviar, pero volver a verificar disponibilidad en servidor al solicitar.
- En filtros, mostrar **Aplicar** y **Limpiar**. Conservar valores al cerrar la hoja.

### E. Solicitar reserva y estados

Mostrar un resumen de alojamiento, fechas, huéspedes y desglose de precio antes de confirmar. Aclarar si es solicitud sujeta a aprobación del anfitrión o reserva instantánea.

Después del envío, la pantalla muestra el progreso recibido de la API:

| Estado | Texto para la persona | Acción/expectativa |
| --- | --- | --- |
| `queued` / `processing` | “Estamos comprobando las fechas” | Mantener el estado visible; permitir volver a Explorar. |
| `awaiting_host` | “Tu solicitud está con el anfitrión” | Mostrar vencimiento/respuesta esperada solo si la API informa ese dato. |
| `confirmed` | “Tu estadía está confirmada” | Acceso a instrucciones y chat permitido. |
| `unavailable` | “Esas fechas ya no están disponibles” | Sugerir fechas o alojamientos cercanos. |
| `rejected` / `expired` | Explicar que no se confirmó | Mostrar alternativas y opción de intentar de nuevo. |
| `cancelled` | “Solicitud cancelada” | Mostrar detalle y próxima acción permitida. |

Una solicitud con estado pendiente no se presenta como reserva confirmada. Nunca vaciar formulario si ocurrió un error recuperable; conservar lo que la persona ya escribió.

### F. Reservas, chat y reseñas

- En Reservas, separar **Pendientes**, **Próximas** y **Anteriores**; cada fila muestra estado, alojamiento y fechas.
- El chat presenta el contexto del alojamiento/solicitud, fecha del último mensaje y estados de envío/lectura si existen.
- Permitir reintentar un mensaje fallido y conservar borrador local durante navegación temporal.
- Los mensajes muestran autor, hora y contenido con jerarquía legible; no depender solo de burbujas de color.
- La acción para dejar reseña aparece cuando el servidor informa que la estadía se completó; señalar que la reseña está ligada a una reserva real.

### G. Guardados y perfil

- Guardados puede funcionar localmente sin cuenta; al iniciar sesión, ofrecer sincronizarlos.
- Perfil reúne datos propios, preferencias, idioma, ayuda, privacidad y cerrar sesión.
- No esconder ayuda de reserva o contacto en varios niveles de navegación.

## 5. Sistema de componentes Flutter

Construir primero widgets pequeños con tokens de tema; las mismas piezas deben funcionar en Android y iOS.

```text
core/theme/
  app_colors.dart
  app_typography.dart
  app_theme.dart
features/
  explore/presentation/widgets/
    search_summary_bar.dart
    interest_chip.dart
    stay_card.dart
    verification_badge.dart
    stay_map_pin.dart
    map_list_switch.dart
    filter_sheet.dart
  stay_detail/presentation/widgets/
    photo_gallery.dart
    rating_summary.dart
    local_context_card.dart
    review_card.dart
    booking_action_bar.dart
  booking/presentation/widgets/
    booking_status_timeline.dart
    price_summary.dart
  shared/presentation/widgets/
    async_content.dart
    empty_state.dart
    app_error_view.dart
```

Widgets compartidos deben recibir datos y callbacks, no acceder directamente a HTTP. Mantener carga/error/vacío como componentes repetibles y adaptar solo los controles de plataforma que ganen claridad real (por ejemplo, calendarios, diálogos del sistema, permiso de ubicación y navegación atrás).

Usar `SafeArea`, `MediaQuery` y layouts flexibles; evitar anchos/altos fijos basados en un solo teléfono. El mapa debe ser un adaptador reemplazable para que la selección del proveedor no fuerce rediseñar tarjetas y búsqueda.

### Estados de carga y conexión

- **Carga inicial:** placeholders de tarjetas con medidas parecidas al contenido final para reducir saltos.
- **Carga adicional:** indicador al final de lista; no bloquear controles de mapa/filtros.
- **Error de catálogo:** conservar filtros y ofrecer reintento.
- **Sin conexión:** indicar que puede haber información desactualizada; no permitir asumir disponibilidad vigente.
- **Sin resultados:** sugerir ampliar radio, quitar filtros o cambiar fechas.
- **Imagen fallida:** mantener proporción y mostrar fondo/ícono de marca; el texto siempre existe fuera de la imagen.

## 6. Compatibilidad iOS y Android

Sí: al estar construida en Flutter, la app puede compartir la mayoría del código y publicar en ambas plataformas. El diseño se adapta al sistema en lugar de forzar una apariencia idéntica en controles nativos.

- Definir una experiencia consistente con `MaterialApp` y `ThemeData`, usando componentes adaptativos donde la convención de plataforma importe.
- Respetar barra de estado, notch/cámara, áreas seguras, teclado, orientación y navegación de cada sistema.
- Solicitar permisos contextualmente: explicar por qué se necesita ubicación antes del diálogo del sistema; ofrecer alternativa manual y funcionar si el permiso se rechaza.
- Usar plugins compatibles con ambas plataformas para mapa, ubicación, almacenamiento seguro, imágenes y notificaciones. Confirmar versiones y configuración iOS/Android al elegirlos.
- Probar en tamaños pequeños y grandes, simulador/emulador y al menos un dispositivo real por plataforma antes del lanzamiento.
- La documentación de interfaz no garantiza por sí sola compatibilidad de plugins: revisar permisos, configuración de plataforma, políticas de tienda y APIs mínimas durante implementación.

## 7. Accesibilidad y calidad de interacción

- Objetivos táctiles recomendados de al menos 48 dp en Android y 44 pt en iOS; separar controles próximos.
- Etiquetas semánticas para pin, favorito, puntuación, estado y botones solo con icono.
- Contraste suficiente, foco visible y orden de lectura lógico para lectores de pantalla.
- Soportar texto ampliado, orientación y contenido traducible; no truncar precios ni estados importantes.
- No usar solo rojo/azul para distinguir estados; acompañar con icono y texto.
- Animaciones breves y funcionales (selección de pin, cambio mapa/lista); respetar “reducir movimiento” y no usar movimiento como única señal.
- Formularios con errores junto al campo, explicación accionable y foco accesible.

## 8. Voz y microcopy

Español claro, cercano y guatemalteco sin exagerar modismos. Usar “alojamiento”, “anfitrión”, “fechas”, “huéspedes” y “solicitud”. Evitar prometer “reservado” hasta recibir confirmación del servidor.

Ejemplos:

- Búsqueda: **“¿Qué te gustaría tener cerca?”**
- Referencia: **“A 8 minutos caminando del Parque Central”** (si se calcula con fuente adecuada y se etiqueta como estimación).
- Verificación: **“Ubicación revisada por XelaStay”** con explicación de qué fue revisado.
- Recomendación: **“Te puede interesar: tiene cocina y espacio para trabajar”**.
- Error: **“No pudimos actualizar la disponibilidad. Tus fechas siguen aquí; intenta de nuevo.”**

No afirmar que un lugar está cerca, tiene vista al volcán, es accesible o fue verificado sin datos que sustenten esa afirmación.

## 9. Entregables y orden de diseño

1. Definir tokens, tipografía y componentes base.
2. Prototipar Explorar, resultados mapa/lista y tarjeta de alojamiento.
3. Prototipar detalle, fechas/filtros y solicitud de reserva/estados.
4. Completar reservas, chat, reseñas, guardados y perfil.
5. Revisar flujos con datos reales de alojamientos y referencias de Xela; comprobar que etiquetas editoriales se puedan respaldar desde la API.
6. Implementar en widgets reusables, validar accesibilidad y revisar en iOS y Android.

## 10. Criterios de aceptación visual y funcional

- Una persona llega al catálogo y ve opciones útiles sin registrarse ni conceder ubicación.
- Puede buscar por fechas/huéspedes, alternar mapa/lista y volver desde el detalle sin perder los filtros.
- Las tarjetas comunican precio, zona, calificación, referencia y verificación con lectura rápida.
- Cada recomendación y distintivo se apoya en datos de la API y explica lo que significa.
- La persona distingue solicitud pendiente de reserva confirmada y puede recuperar el estado.
- Los flujos principales funcionan con lector de pantalla, texto ampliado y navegación del sistema.
- Componentes y pantallas se adaptan a iOS y Android con diseño responsivo y convenciones propias de cada sistema.

## 11. Decisiones pendientes

- Fuente serif/sans definitiva y licencias.
- Proveedor de mapa/geocodificación y definición de rutas a pie vs. distancia aproximada.
- Política de precisión de ubicaciones antes y después de una reserva.
- Campos que tendrá la verificación física y quién puede aprobarla.
- Criterios transparentes para ordenar y recomendar alojamientos.
- Identidad gráfica final y fuentes locales/fotografía con permiso de uso.
- Política de fechas, cancelaciones, reserva instantánea o aprobación del anfitrión.
