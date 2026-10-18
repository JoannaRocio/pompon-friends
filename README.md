# Pompon Friends

Juego de mascotas virtuales para Android que **enseña matemáticas**, hecho con **Godot 4.7** (GDScript). Estilo acogedor tipo Pet Society: eliges la especie y el sexo de tu Pompon, trabajas en el periódico resolviendo cuentas (sumas, restas, multiplicaciones y divisiones) para ganar monedas y comprarle una cuna al huevo; después lo cuidas, lo vistes, decoras su casa y visitas a tus vecinos. Todo el arte, la música y los sonidos se generan por código.

## Cómo empieza una partida

1. Una bienvenida saluda al jugador por su nombre ("Hoy es el día en que adoptas a tu primer Pompon"). Se elige la **especie** (solo se ven sombras: el diseño es sorpresa) y el **sexo**, y una **cigüeña** trae el huevo. Colores, carita y personalidad son sorpresa. Se empieza con **0 monedas**.
2. El huevo **no nace solo**: necesita una **cuna** (50 monedas). El tutorial lo explica con frases sencillas.
3. El jugador va al botón **Trabajo**: se abren las **ofertas de empleo del periódico**. Hoy hay un puesto disponible, **profesor/a de Matemáticas** (la primera vez que se juega se pregunta el **nombre y los pronombres** (con botón para inventar nombres tiernos), así dice *Profesora Ana* o *Profesor Leo*), y dos bloqueados que llegarán pronto (**profesor/a de Inglés** y de **Geografía**). Dentro del aula elige qué mejorar: **sumas y restas**, **multiplicaciones** o **divisiones** (10 niveles cada uno, el primero muy sencillo). La **paga no depende de la nota** (se premia intentarlo, no saber) sino del **nivel de profesor/a**: se asciende con los turnos terminados (nivel 2 a los 5, 3 a los 10, 4 a los 20 y después uno cada 10, hasta el 100) y la paga por turno sube de 50 a 500. Al final un cartel muestra la **nota (0-10)** y, si hubo errores, la respuesta correcta con explicación. Si el jugador responde bien y rápido varias veces, el juego decide que **dominó el nivel**, aparece un cartel de avance y gana un premio fijo de 30 monedas. Ver `docs/aprendizaje.md`.
4. Con las monedas se compra la cuna en la **Tienda**; el huevo nace y se le **pone nombre**.

## Abrir y probar

- Abre `project.godot` con Godot 4.7 (o usa el acceso directo del escritorio) y presiona **F5**.
- Escena principal: `scenes/intro.tscn` (animación del logo de Jojo Games a pantalla completa) → menú → casa.

## Estructura

| Carpeta | Contenido |
|---|---|
| `scenes/` | Escenas (`.tscn`): casi todas solo cargan un script y arman la interfaz en código |
| `scripts/` | Lógica del juego (ver abajo) |
| `assets/` | Íconos, fuente Fredoka (licencia OFL), música y sonidos, logo de Jojo Games |
| `tools/` | Herramientas de desarrollo: generar audio, íconos, imágenes de la tienda, capturas |
| `tests/` | Pruebas automáticas (`tests/run_all.ps1`) |
| `docs/store/` | Textos de la ficha de Play Store, política de privacidad, guía de publicación e imágenes |
| `android/` | Plantilla de compilación Gradle (necesaria para generar el AAB) |

### Scripts principales

- `game_state.gd` (autoload): partida, monedas, guardado seguro con respaldo, tiempo transcurrido, misiones, vecinos, regalo diario.
- `pompon.gd`: genética, estadísticas (0-100), etapas de vida y abandono a los 30 días.
- `pompon_view.gd`: dibuja a cada Pompon y su ropa (7 especies) y lo anima.
- `math_problems.gd`: 3 caminos × 10 niveles, generación de cuentas, repaso de errores, explicaciones por partes, lecciones, nota y la regla que decide cuándo se domina un nivel.
- **Niveles:** el Pompon sube un nivel por día de vida (Bebé 1-7, Niño 8-21, Adolescente 22-51, Adulto 52+). Los items de la tienda se desbloquean por nivel (`Catalog.UNLOCK` en `catalog.gd`); la tienda (`shop.gd`) muestra tarjetas, filtros por categoría y los próximos items con candado.
- `bowl_art.gd`: los tazones de comida y de agua (el de siempre es feo a propósito; en la tienda hay 8 lindos que se usan al comer y beber).
- `hud.gd`, `stat_bar.gd`, `action_button.gd`, `ambient_fx.gd`: interfaz de la casa (tarjetas, iconos dibujados, barras con iconos, botones redondos y motitas de luz).
- `welcome.gd`, `stork_view.gd`: bienvenida, elección de especie y sexo y animación de la cigüeña con el huevo.
- `profile_dialog.gd`: pregunta nombre y pronombres del jugador (primer "Jugar"; se cambia desde las ofertas).
- `jobs.gd`, `job_board.gd`: los trabajos que ofrece el periódico (uno disponible y dos bloqueados) y la pantalla de ofertas.
- `classroom_view.gd`, `sort_field.gd`, `intro_demo.gd`: el salón con sus alumnos, el juego de ordenar objetos y la mini animación que explica el trabajo.
- `job_menu.gd`, `job_game.gd`, `math_hint.gd`, `lesson_view.gd`, `mastery_dots.gd`: aula de matemáticas, el turno de trabajo en un salón de clase (dos alumnos Pompon levantan la mano, se corrige su examen resolviendo la cuenta medida en tiempo, mientras se ordena en un juego tranquilo), lecciones, cartel de avance, cartel final y los dibujitos de ayuda.
- `catalog.gd`, `item_art.gd`, `item_icon.gd`: catálogo de 53 ítems (incluye la cuna) y su arte.
- `room_view.gd`: el cuarto (pared, piso, muebles, día y noche, modo decorar con arrastre).
- `home.gd`: pantalla principal (mascota que camina, acciones, panel de estado, guías de primer uso).
- `audio.gd` (autoload): música y efectos. `look.gd` (autoload): tema visual y zonas seguras de Android.
- `neighbors.gd`, `missions.gd`, `pompon_speech.gd`: vecinos, misiones y Pase, y frases.

## Pruebas

```
powershell -ExecutionPolicy Bypass -File tests/run_all.ps1
```

Respalda y restaura tu partida guardada. Para ver la interfaz sin abrir el editor hay herramientas de captura en `tools/` (ver el comentario de cada archivo).

## Exportar

El proyecto tiene dos presets en `export_presets.cfg`:

- **Android APK (prueba)**: `build/PomponFriends.apk`, para instalar directo en tu celular.
- **Android** (AAB, Gradle, API 36): `build/PomponFriends.aab`, para subir a Google Play.

```
godot --headless --path . --export-debug "Android APK (prueba)" build/PomponFriends.apk
godot --headless --path . --export-debug "Android" build/PomponFriends.aab
```

Para publicar, sigue `docs/store/publicar.md` (clave de firma propia, política de privacidad, etc.).

## Regenerar audio, íconos e imágenes

```
python tools/gen_audio.py <carpeta>            # música y sonidos (WAV; la música se pasa a OGG con ffmpeg)
godot --path . --rendering-method gl_compatibility --resolution 512x512 --script tools/make_icon.gd
godot --path . --rendering-method gl_compatibility --resolution 540x960 --script tools/store_images.gd -- docs/store/images
```

## Pendiente conocido

- Compras dentro de la app (Google Play Billing).
- Visitas entre jugadores reales (requiere servidor); hoy hay vecinos sin conexión.
- Soporte iOS (requiere una Mac con Xcode y cuenta de Apple Developer).
