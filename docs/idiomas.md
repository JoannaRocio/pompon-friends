# Idiomas (español e inglés)

Desde el 14/11/2026 el juego tiene una base para varios idiomas. Por ahora solo están traducidas las
pantallas de entrada; el resto sigue en español y se migra de a poco (lista abajo).

## Cómo funciona
- **Textos**: `locale/textos.csv`, con columnas `keys,es,en` (una fila por texto). Godot lo importa solo y
  genera `locale/textos.es.translation` y `locale/textos.en.translation`, registradas en `project.godot`
  (`[internationalization]`, idioma de respaldo `es`).
- **En el código**, con la clase `T` (`scripts/t.gd`):
  - `T.t("menu.play")` → "¡Jugar!" / "Play!"
  - `T.t("home.egg_of", {"species": "conejo"})` → reemplaza `{species}`. Para frases armadas por partes,
    usar **una sola clave con marcadores** (`{name}`, `{n}`...), nunca pegar pedazos traducidos: el orden de
    las palabras cambia entre idiomas ("Tu huevo de conejo" / "Your bunny egg").
  - `T.g("menu.reset_sure", GameState.player_title)` → variante por género: busca `menu.reset_sure.f`,
    `.m` o `.n` y, si no está, `menu.reset_sure`. En inglés casi siempre alcanza con la clave sin género
    (o con las tres iguales).
  - `T.n("home.in_days", dias)` → `home.in_days.one` (1) o `home.in_days.many` (resto), con `{n}`.
  - `T.s("Tienda")` → **lo más simple para textos nuevos**: el español es la clave (`s:Tienda` en el CSV).
    Con marcadores: `T.s("Te faltan %d") % n` o `T.s("{stage} en {n} {d}", {...})`.
  - `T.data("item", id, nombre)` → nombres de datos por id (`item.hat_bow`, `food.pizza`...).
  - `T.label("Comer")` → para **botones cuyo texto en español es también su identificador**
    (`ActionButton.caption`, solapas, especies, etapas, sexo, pronombres). Busca `ui.Comer`; si no existe,
    deja el texto igual. Así el tutorial y las pruebas siguen encontrando los botones por su nombre en
    español, pero en pantalla se ve "Eat". `ActionButton` ya lo hace solo con su `caption`.
- **Idioma**: `GameState.language` ("es", "en" o vacío = el del celular). `T.device_lang()`: si el celular
  está en español, español; cualquier otro idioma, inglés. Se aplica al cargar (`GameState._ready`) y con
  `GameState.set_language()`. Botón "ES/EN" en el menú, junto a música y sonido (vuelve a cargar el menú).
  Se guarda en la partida, y "Empezar de nuevo" lo conserva (como la música). Una partida vieja sin idioma
  usa el del celular.
- **Pruebas**: `run_all.ps1` fija `POMPON_LANG=es` (así no dependen del idioma de la PC). `test_locale`
  cambia de idioma a mano y revisa que no se vea ninguna clave sin traducir; además busca en todos los
  `.gd` los `T.s("...")`, `T.t("...")` y `T.label("...")` y avisa si alguno no tiene inglés ("codigo: ... sin
  ingles: []"), y en cada pantalla migrada lista lo que se ve en español ("sigue en español: []").

## Cómo agregar un texto
1. Agregar una fila a `locale/textos.csv`: `clave,texto en español,texto en inglés`. Si el texto tiene
   comas, saltos de línea o comillas, va entre comillas dobles (`"Hola, {name}"`; una comilla adentro se
   escribe `""`). Las claves van por pantalla: `menu.*`, `home.*`, `tip.*`, `tut.*`, `welcome.*`...
2. En el código, `T.t("clave")` (o `T.g`, `T.n`, `T.label`). No usar `tr()` con el texto en español.
3. Abrir el editor (o correr `godot --headless --path . --import --quit`) para que se regeneren los
   `.translation`. Correr `tests/test_locale.gd`: avisa si a una clave le falta un idioma.
4. Inglés simple y cálido, para chicos: frases cortas, "you", sin palabras difíciles.

Cuidado:
- Lo que se **guarda** en la partida (diario, despedida, nombres de cosas) se guarda ya traducido en el
  idioma de ese momento. Para migrar el diario conviene guardar la clave y los datos, no el texto.
- Las comparaciones en el código deben usar ids, nunca el texto que se muestra (`caption`, especie...).
- Los nombres prefabricados (`ProfileDialog.NAME_IDEAS`, `Pompon.NAME_IDEAS`) quedan iguales en los dos
  idiomas.

## Ya migrado
Intro (no tiene texto), menú (con "Empezar de nuevo"), bienvenida (especie, sexo, cigüeña), pregunta de
edad (`FriendSafety.ask_age`), `ProfileDialog`, `NamePicker`, y en la casa: tarjeta del Pompon (título,
especie, personalidad, barras, crecimiento, cuna), botones de arriba y de abajo, solapas, avisos de la
primera vez (`TIPS`, huevo que se mueve), regalo del día, nombre del Pompon al nacer, "¿Te avisamos?",
cartel de nombres nuevos, la despedida (solo los botones) y el tutorial guiado completo
(`TutorialSteps`, `TutorialOverlay`).
- Tienda, vestidor, decorar, menú de comida, nombres de los 119 objetos (`Catalog.item_name`, claves
  `item.<id>`), comidas (`PomponTastes.food_name`, `food.<id>`), habitaciones (`Rooms.room_name`) y el
  aviso de nivel nuevo.
- Trabajo: periódico, ficha de profe, aula, lecciones, turno y carteles finales; Matemáticas (nombres de
  niveles, lecciones, explicaciones, nota) y Geografía: los 51 países y capitales en inglés (`geo.c.<id>`,
  `geo.k.<id>`) y listas propias de otras capitales y países del mundo para las opciones con pista
  (`EXTRA_CAPITALS_EN`, `EXTRA_COUNTRIES_EN`). La pista ("B…") solo sale si las tres opciones empiezan con
  esa letra; si no hay suficientes (Quito y Ottawa en español, Quito y Jakarta en inglés), esa pregunta va
  sin pista. `test_locale` lo revisa en los dos idiomas.

## Falta migrar (de más texto a menos)
Cantidad aproximada de textos en español que quedan en cada archivo:

| Archivo | Textos | Qué es |
|---|---|---|
| `english_problems.gd` | ~250 | Clase de Inglés (ver nota de diseño) |
| `pompon_thoughts.gd` | ~115 | Diario: pensamientos y sentimientos |
| `pompon_play.gd` | ~100 | Lo que hace con los muebles y sus comentarios |
| `geography_problems.gd` | ~95 | Países, capitales, regiones |
| `pompon_firsts.gd` | ~95 | Primeras veces (diario) |
| `catalog.gd` | ~90 | Nombres de los objetos de la tienda |
| `math_problems.gd` | ~60 | Clase de Matemáticas |
| `pompon_activity.gd` | ~60 | Cajita "qué está haciendo" |
| `movies.gd` | ~40 | Películas del cine |
| `home.gd` | ~40 | Diario, comida, decorar, noche, figuritas |
| `pompon_growth.gd` | ~35 | Rasgos y palabras al crecer |
| `profile_panel.gd` | ~30 | Ficha del Pompon |
| `pompon_tastes.gd` | ~30 | Gustos |
| `pompon_speech.gd` | ~30 | Lo que dice en el globo |
| `neighbors_screen.gd` | ~27 | Vecinos y amigos |
| `pompon_mood.gd` | ~25 | Ánimo |
| `progress.gd` | ~23 | Logros y sello semanal |
| `job_game.gd`, `game_state.gd`, `paint_game.gd`, `jobs.gd`, `cloud_panel.gd` | ~20 c/u | Turno de trabajo, avisos guardados, pintar, puestos, nube |
| `friend_safety.gd` (salvo la edad), `job_board.gd`, `visit_screen.gd`, `pompon_skills.gd`, `pompon.gd`, `notifier.gd` | 12–16 | Seguridad, periódico, visitas, habilidades, aviso semanal |
| `cinema.gd`, `town.gd`, `shop.gd`, `friends.gd`, `rooms.gd`, `job_menu.gd`, `missions_screen.gd`, `teacher_card.gd`, `neighbors.gd`, `missions.gd` | 5–11 | |
| minijuegos (`simon`, `music`, `math`, `pattern`, `jump`, `minigames`, `minigame_base`), `wardrobe.gd`, `pixel_art.gd`, `lesson_view.gd`, `cloud.gd`, `album_panel.gd`, `pompon_album.gd`, `town_building.gd` | 1–4 | |

(Cuenta hecha a ojo con un script: textos entre comillas con espacios o acentos.) También falta la ficha de
la tienda en inglés (`docs/store/store-listing.md`) y las capturas para la tienda en inglés.

## Clase de Español (hecho el 14/11/2026)
Cuando se juega en inglés, la materia de idiomas (id `english`) es **clase de Español**
(`SpanishProblems`, "Spanish Teacher"): usa las mismas palabras y frases de `EnglishProblems` al revés.
"Words" muestra la palabra en inglés (con su dibujo) y se elige en español; "What does it mean?" muestra la
palabra en español y se elige en inglés; "Sentences" muestra la frase en inglés y se elige en español. La
voz del teléfono dice el español (`Speech.say(texto, "es")`, si el teléfono tiene una voz en español); la
pronunciación escrita no se muestra. El progreso va en caminos propios `es_words`, `es_meaning`,
`es_phrases` (no se mezcla con `en_*`). `Jobs.problems("english")` elige según el idioma y
`Jobs.problems_of_track(camino)` siempre devuelve el de ese camino. Los textos de esa clase están escritos
directamente en inglés en `spanish_problems.gd` (solo se ven en inglés).
