# Pompon Friends — traspaso para otro Claude

Juego de mascota virtual kawaii ("Pompon"), en español, sin anuncios, que enseña matemáticas.
Godot 4.7.2 + GDScript. Retrato 720x1280 (stretch canvas_items/expand). Android primero, iOS después. Aún no publicado.
Todo el arte se dibuja por código (`_draw`). No hay imágenes de personajes ni muebles.

## Reglas de trabajo con el usuario
- Habla español. Prefiere que se rediseñe pantalla por pantalla, con **poco texto** y UX intuitiva para niños.
- Antes de dar algo por hecho: tests + capturas. Si algo falla, decirlo.
- No matar el editor de Godot del usuario (hay un proceso abierto). Al lanzar Godot para pruebas, matar solo los procesos propios.
- El que **trabaja y gana habilidades matemáticas es el cuidador (el jugador)**, no el Pompon. El Pompon tiene sus propias habilidades (ver más abajo).

## Git
- Repositorio privado en GitHub: https://github.com/JoannaRocio/pompon-friends (rama `main`, desde el 18/10/2026). Hacer un commit por cada mejora terminada y con los tests en verde, y subirlo (`git push`).
- `.gitignore` deja afuera `.godot/`, `build/` (APK/AAB/web) y `android/` (plantilla de 1,2 GB: se reinstala con Proyecto > Instalar plantilla de compilación de Android). Las claves de firma (`*.keystore`, `*.jks`) nunca van al repositorio.
- Finales de línea LF forzados (`.gitattributes` + `core.autocrlf=false` en este repo): con CRLF los textos de varias líneas del juego muestran una línea vacía de más.

## Cómo correr y probar
- Tests (sin ventana): `powershell -ExecutionPolicy Bypass -File tests/run_all.ps1` (respalda y restaura la partida guardada). Hoy pasan todos (~35; `test_neighbors_screen` tarda ~25 s porque espera las animaciones).
- Cada test es `tests/test_*.gd` y **imprime** resultados; el script solo falla si hay `SCRIPT ERROR`/`Parse Error`. Hay que mirar la salida para validar.
- Los tests `--script` no resuelven autoloads (`GameState`, `Audio`) al compilar: cargar scripts en runtime (`load(...)`) y no referenciar clases que usen `GameState` desde el cuerpo del test (p. ej. `RoomView.CONST` rompe la compilación; usar `instancia.CONST`).
- Un `Control` nuevo en un test se achica a 0 tras un frame: darle `custom_minimum_size`.
- Capturas: script con `SubViewport` 720x1280, ejecutar Godot **con ventana** (`Godot_*win64.exe`, no la consola) con `--script`, `--resolution 720x1280 -- <carpeta>`. Respaldar y restaurar `%APPDATA%\Godot\app_userdata\Pompon Friends\save.json*` porque los scripts guardan.
- Palabra reservada en GDScript 4.7: `trait` (no usar como nombre de parámetro).
- Los `Label` con autowrap dentro de contenedores sin ancho se parten letra por letra: darles `custom_minimum_size.x` o `AUTOWRAP_OFF`.

## Exportar
- `export_presets.cfg`: Android AAB, Android APK (prueba) y Web "Web (Netlify)" (`variant/thread_support=false`).
- `exclude_filter` incluye `assets/art/*`: **lo que se necesite en runtime NO va en `assets/art`** (el logo está en `assets/jojo_logo.png`).
- Builds hechos antes de las últimas funciones: `build/PomponFriends.apk|aab`, `build/web`, `build/PomponFriends-web.zip` → **hay que regenerarlos**.
- AAB/APK están firmados con clave de debug. Falta keystore de release para Play Store.

## Estructura (scripts/)
- **Autoloads**: `GameState` (guardado, monedas, muebles, habitaciones, diario, vecino, hooks), `Audio`, `Look`.
- **Pantallas**: intro, menú, bienvenida (elige especie y sexo + cigüeña), `home.gd` (casa), tienda, vestidor, trabajo (`job_*`), minijuegos (`math/simon/pattern_game`, base `minigame_base.gd`), misiones, vecinos/visita.
- **UI compartida**: `Hud` (tarjetas, íconos dibujados, botones), `StatBar` (`warn_low = false` para barras que no son necesidades), `PomponView.portrait_zoom` (foto redonda), `ActionButton`, `HomeDock` (barra de abajo con solapas), `HeartsRow`, `ProfilePanel`, `GuideArrow`.
- **Casa**: `RoomView` (cuarto ancho de 2 pantallas con scroll, edición, estantes), `Rooms` (6 habitaciones por nivel), `ItemArt`/`Catalog` (arte y catálogo).
- **Pompon**: `Pompon` (datos + `tastes` + `growth`), `PomponView` (dibujo/animación; `_has_point` limita el toque al personaje).
- **Sistemas del Pompon** (todos estáticos, guardados dentro de `Pompon`): `PomponTastes` (gustos y personalidad), `PomponSkills` (habilidades), `PomponGrowth` (calidad de crecimiento), `PomponThoughts` (diario), `PomponActivity` (qué está haciendo), `PomponMood`/`PomponSpeech` (anteriores, aún usados parcialmente).
- Guardado: `user://save.json` + `.bak` (escritura segura). `SAVE_VERSION := 2`, `room_layout: 2` (migra cuartos viejos de 1 pantalla).

## Reglas de diseño acordadas (números clave)
**Niveles**: nivel del Pompon = día de vida. Etapas: Bebé 1–7, Niño 8–21, Adolescente 22–51, Adulto 52+. Los ítems de la tienda se desbloquean por nivel (`Catalog.UNLOCK`).

**Habitaciones**: 6, abren en niveles 1, 6, 14, 24, 38, 52 (Sala, Dormitorio, Cocina, Biblioteca, Jardín, Terraza estelar). Cada una ancha (2 pantallas), con su propia pared/piso. Muebles con superficie (`Catalog.SURFACES`) y adornos chicos (`Catalog.SMALL`) que se apoyan encima (`"on"`, `"ox"` en `placed`). Cambiar de habitación: solapa "Casa" del dock.

**Barra de abajo** (solo cosas del Pompon y la casa): solapa "Pompon" (comer, beber, bañar, caricia, juegos; una fila) y "Casa" (tienda, vestidor, decorar, habitaciones). Huevo: solo Tienda. **Arriba a la izquierda**, las cosas del cuidador: Menú, Misiones, Vecinos, Trabajo y Diario (la flecha guía apunta hacia arriba cuando el botón está pegado al borde).

**Barras**: Amor → se muestra "Confianza"; Amistad → "Social" (la mitad solo con el cuidador, la otra mitad solo con otros Pompons: `Pompon.add_social`). Inteligencia ya no se muestra (stat interno). La barra principal es **Crecimiento**.

**Calidad de crecimiento** (`PomponGrowth`): por etapa (bebé 7 días, niño 14, adolescente 30). Cada día vale hasta 1/N: entrar 15%, necesidades bien 20%, comer x2 15%, agua 5%, baño 5%, cariño x2 10%, 2 minijuegos 15%, rato juntos 7,5%, visitar a otro Pompon 7,5%. Al cerrar la etapa: ≥90 rasgo muy positivo (Muy amable / Súper confiado / Muy generoso por regalos) + 5 palabras; 50–89 rasgos normales (Curioso/Alegre/Amable) + 2 palabras; <50 Tímido/Miedoso/Solitario + 0 palabras. Palabras por umbrales de calidad 25/40/55/70/85 (el bebé no habla hasta ganarlo; al nacer solo hace sonidos).

**Vecino NPC**: `Neighbors.buddy` se crea con el primer Pompon, misma edad, primero en la lista (`GameState.buddy`). Amigos por ID: **pendiente**.

**Amistad con vecinos** (`Neighbors`, `GameState.friend_*`, `visit_screen.gd`, efectos en `VisitFx`): 0–100 puntos por vecino. Suma **1 punto por día** por entrar a su casa y 1 por cada actividad (acariciar, jugar, regalo); repetirlas es gratis y solo muestra la animación; cada acción descansa 5 s después de usarla (las otras siguen disponibles). El regalo cuesta 5 monedas solo la primera vez del día. Jugar sube **Lógica** (1 vez/día). Niveles: Conocidos 0, Compañeros 25, Amigos 50 (regala 20 monedas), Mejores amigos 75. La barra "Socializando" del panel de arriba se llena en 20 s: al completarse, Social de tu Pompon queda al máximo y caen 20 monedas (1 vez/día por vecino). La primera vez que se conocen (`neighbors_met`) hay una presentación tímida con una de 3 variantes al azar: se huelen, se hacen mimos o se saludan. Cuando no haces nada, los Pompons hacen cositas solos.

**Gustos** (`PomponTastes`): color favorito (por compras/equipar), comida favorita (11 comidas; lo nuevo da desconfianza y de a poco se ama; aprende más rápido de bebé/niño: plasticidad 1.6/1.3/0.7/0.4), juego y habitación favoritos, 5 rasgos de personalidad que se moldean de bebé/niño. Cada Pompon nace con inclinaciones propias (semilla = su ID).

**Habilidades del Pompon** (`PomponSkills`): Físico, Creatividad, Música, Matemáticas, Lógica (nivel 0–10). Suben con minijuegos (math→Matemáticas, pattern→Lógica, simon→Música+Lógica), con objetos comprados (y practicando con ellos en su cuarto) y el Físico caminando **hasta nivel 3** (después hacen falta objetos).

**Diario** (`PomponThoughts`): pensamientos/sentimientos/frases con coherencia al juego (necesidades, hora, habitación, muebles, ropa, eventos recientes). Espontáneo cada 4–7 min, mín. 45 s entre entradas, urgencias cada 20 min. "Dijo" sale en el globo; "pensó/sintió" en la píldora. Guarda 120 entradas.

**Primeras veces** (`PomponFirsts`, cuenta en `tastes["firsts"]`): la primera vez que prueba una comida, se baña, toma agua, recibe un mimo, juega un minijuego, usa un objeto de práctica, estrena ropa, conoce una habitación o un vecino, se anota SIEMPRE en el diario con una reacción al azar. Las repeticiones se anotan con 45 % / 30 % / 12 % / 4 % (2.ª, 3.ª, 4.ª–6.ª, 7.ª en adelante) y como mucho una cada 8 min; las habitaciones solo la primera vez. Lo que pasa fuera de la casa va a `pending_thoughts`.

**Actividad actual** (`PomponActivity`): cuadro bajo la tarjeta, cambia cada 8–14 s.

**Tutorial**: avisos cortos que desaparecen solos (8 s); al nacer, un aviso explica que los días siguientes definen cómo crece.
**Antes de nacer** (`home.gd`, `_prehatch`): al volver a casa con la cuna recién comprada, el huevo se mueve solo con "toc toc" (cada 1,3–2,1 s), aviso "¡Algo se mueve! Tócalo para ayudarlo a salir." y flecha al huevo. Cada toque abre una rajadura (`PomponView.egg_cracks`); al tercero, o a los 12 s, empieza `HatchAnimation`. Mientras tanto la casa se ve como con el huevo (`_is_born()` y `PomponView.show_egg`), aunque `pompon.hatched` ya sea true.

**Carrera de profesor/a** (`Jobs.career_level/shifts_for_level/pay_for_level`, `GameState.career_level/job_pay`): nivel por turnos terminados en total (2 a los 5, 3 a los 10, 4 a los 20, luego cada 10; nivel 100 a los 980). Paga por turno lineal de 50 a 500 (ojo: la tienda cuesta 8–60, revisar precios). `TeacherCard` = ficha (nombre, nivel en estrella, paga, turnos para ascender) en las ofertas cuando ya trabaja. Tutorial del trabajo con `BigNotice` (cartel grande): 1) primera vez en ofertas "Para cuidar a tu Pompon necesitas monedas"; 2) primer "Aplicar": "¡Conseguiste tu primer trabajo!" + ficha; 3) fin del primer turno: "¡Perfecto! … compremos una cuna" con botón a la Tienda. Al ascender sale "¡Ascendiste!" con la ficha nueva. Ids en `tips_seen`: `job_intro`, `job_hired`, `job_first_shift`.

**Empezar de nuevo**: botón redondo (flecha en círculo) junto a música y sonido en el menú, solo si hay partida. Pide confirmar dos veces (en la segunda, el botón grande es "No, me quedo"). `GameState.reset_game()` borra `save.json`, `.bak` y `.tmp` (si Windows no deja borrar, los vacía) y vuelve todas las variables a sus valores iniciales. Los ajustes de música y sonido se conservan. Después va a la intro.

**Partida en la nube** (autoload `Cloud`, `CloudCode`, `CloudPanel`, `server/supabase.sql`, datos en `CloudConfig`): sin cuentas ni emails. "Guardar en la nube" (botón de nube del menú) crea un código al azar de 12 caracteres (`ABCD-EFGH-JKLM`, sin I/O/0/1). Desde ahí se sube sola cada 3 min si hubo cambios y al pausar o cerrar la app. "Recuperar con un código" baja la partida y reemplaza la del dispositivo. Si la misma partida se siguió jugando en otro dispositivo, la subida se rechaza (`conflict`, comparando `cloud_synced_at` con el `updated_at` del servidor) y el jugador elige cuál se queda; el botón de nube muestra un punto rojo. Proyecto de Supabase creado (`zbdtwbrkcqljlslwxjeu`); la URL y la clave pública ya están en `CloudConfig`. La contraseña de la base NO se guarda en el proyecto (la tiene el dueño). Si `CloudConfig` está vacío, la nube se apaga ("muy pronto"). Prueba real contra el servidor: `tools/cloud_check.gd` (borra la partida local: respaldar `save.json*` antes). Los tests usan `Cloud.fake_server` (en memoria) y `Cloud.enabled = false`: nunca tocan el servidor real. Android: `permissions/internet=true` y `user_data_backup/allow=true` (copia automática de Android en la cuenta de Google). Política de privacidad actualizada (borrador, revisar).

**Amigos de verdad** (autoload `Friends`, funciones `pompon_friend_*` en `server/supabase.sql`, pantalla de Vecinos): "Activar amigos" registra al jugador con una clave secreta propia (`GameState.friend_secret`; en el servidor solo su hash) y da un código de amigo de 8 caracteres. La "tarjeta" (Pompon, habitación actual y nombre del jugador) se publica y se actualiza cada 5 min si hubo cambios. Agregar amigo = solicitud con el código; el otro acepta o rechaza (punto rojo en el botón Vecinos). Hasta que acepta, el que pidió ve solo el código, no la tarjeta. Los amigos aparecen en Vecinos (`Neighbors.friends`, id `f:CODIGO`, chip "de Ana", botón Quitar) y se visitan con su cuarto entero (2 pantallas). Cada visita, caricia, juego o regalo que suma le llega como aviso (una por tipo cada 20 h): va a su diario y suma Social. Sin chat ni texto libre. La identidad de amigos viaja en la partida de la nube. Tests: `test_friends` (servidor de mentira con dos jugadores).

**Finales de línea**: los `.gd` deben quedar en LF. Si se edita con Python en Windows, leer/escribir en binario: con CRLF los textos multilínea muestran una línea vacía de más.

**Flechas guía** (`GuideArrow`, con `set_targets` recorre varios botones): mientras `GameState.job_guide_on()` (nunca trabajó, o el huevo espera cuna y no alcanzan las monedas) señalan Trabajo en la casa, "Aplicar" en las ofertas y los tres "Trabajar" del aula (o "Ir a la Tienda" si ya alcanza). En el turno: si pasan 6 s sin ordenar, un dedito muestra cómo arrastrar un objeto (`SortField`); si un alumno levanta la mano y no lo tocás en 4 s, la flecha señala su examen; si no respondés en 8 s, recorre las respuestas (sin marcar la correcta). Una ayuda por vez.

## Estado y pendientes
- Todo lo anterior implementado y con tests. Falta probar en celular real (Android e iPhone/Safari: sonido, guardado, rendimiento).
- Regenerar APK/AAB/web con lo último.
- Keystore de release para Play Store; iOS nativo requiere Mac + cuenta Apple.
- Amigos de verdad: funcionando contra Supabase (18/10/2026: `tools/friends_check.gd` pasó registro, solicitud, aceptar, avisos, límite de visitas, clave falsa y quitar; tablas cerradas al acceso directo). Quedaron dos perfiles de prueba (`LRLD-VLKW` y `BV5V-PJVQ`, se pueden borrar en Table Editor > friend_profiles). Falta probarlo en dos celulares.
- Nube: funcionando contra Supabase (18/10/2026: `tools/cloud_check.gd` pasó subir, recuperar, conflicto y código inexistente; la tabla no se puede leer ni escribir directo). Quedó una partida de prueba con el código `FYEL-DDEN-9FAU` (se puede borrar en Table Editor). Falta: probar en el celular y actualizar "Seguridad de los datos" en Google Play (se envían el nombre del jugador y el progreso, opcional).
- Pantallas rediseñadas al estilo nuevo: tienda, vestidor (mini cuarto + solapas Ropa/Cuarto/Tazones), misiones (botón "Ir" + camino del Pase), vecinos y visita (botones redondos).
- Revisar el equilibrio de números (puntaje diario, precios, niveles de desbloqueo) jugando de verdad.
