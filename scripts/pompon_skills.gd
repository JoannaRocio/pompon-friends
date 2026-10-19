class_name PomponSkills
extends RefCounted
## Habilidades del Pompon (como en Los Sims): fisico, creatividad, musica, matematicas y logica.
## Suben de 0 a 10 con los minijuegos, con los objetos que le compras (los practica solo en su cuarto)
## y, el fisico, explorando la casa. Se guardan en `Pompon.tastes["skills"]` (puntos de experiencia).

const SKILLS := {
	"fisico": {"name": "Físico", "icon": "bolt", "color": Color("ff7a59"), "stat": "diversion",
		"hint": "Explorar la casa (hasta el nivel 3), y después la rueda, el columpio, el túnel y el rascador"},
	"creatividad": {"name": "Creatividad", "icon": "palette", "color": Color("ff7aa8"), "stat": "felicidad",
		"hint": "Cuadros, bloques, arcoíris y adornos"},
	"musica": {"name": "Música", "icon": "note", "color": Color("a98bea"), "stat": "felicidad",
		"hint": "El juego de Memoria, el piano y la caja musical"},
	"matematicas": {"name": "Matemáticas", "icon": "calc", "color": Color("5bb8f5"), "stat": "inteligencia",
		"hint": "El juego de Matemáticas, el reloj y el escritorio"},
	"logica": {"name": "Lógica", "icon": "puzzle", "color": Color("3cc9b0"), "stat": "inteligencia",
		"hint": "El juego de Patrones, los libros, la biblioteca y el robot"},
}
const ORDER := ["fisico", "creatividad", "musica", "matematicas", "logica"]
# Experiencia acumulada que hace falta para cada nivel (0 a 10).
const THRESHOLDS := [0.0, 6.0, 15.0, 28.0, 45.0, 66.0, 91.0, 120.0, 153.0, 190.0, 231.0]
const MAX_LEVEL := 10

# Objetos que entrenan una habilidad.
const ITEM_SKILL := {
	"furn_wheel": "fisico", "furn_swing": "fisico", "furn_tunnel": "fisico", "furn_scratcher": "fisico",
	"toy_blocks": "creatividad", "deco_picture": "creatividad", "toy_frame": "creatividad", "deco_rainbow": "creatividad",
	"toy_vase": "creatividad",
	"furn_piano": "musica", "toy_musicbox": "musica",
	"deco_clock": "matematicas", "furn_desk": "matematicas",
	"toy_books": "logica", "furn_bookshelf": "logica", "toy_robot": "logica", "furn_globe": "logica",
}
# Que habilidades da cada minijuego: [habilidad, peso]
const GAME_SKILL := {
	"math": [["matematicas", 1.0]],
	"pattern": [["logica", 1.0]],
	"simon": [["musica", 0.75], ["logica", 0.25]],
	"jump": [["fisico", 1.0]],
	"paint": [["creatividad", 1.0]],
	"music": [["musica", 1.0]],
}
const GAME_BASE_XP := 4.0
const BUY_XP := 2.0
const PRACTICE_XP := 1.0
const WALK_PIXELS_PER_XP := 42000.0   # explorar: un punto de fisico cada ~10 minutos caminando

const PRACTICE_TEXT := {
	"fisico": "hace ejercicio con %s", "creatividad": "crea algo con %s", "musica": "hace música con %s",
	"matematicas": "practica cuentas con %s", "logica": "resuelve acertijos con %s",
}


static func _skills(p: Pompon) -> Dictionary:
	if not p.tastes.has("skills"):
		p.tastes["skills"] = {}
	return p.tastes["skills"]


static func xp(p: Pompon, skill: String) -> float:
	return float(_skills(p).get(skill, 0.0))


static func level_for_xp(points: float) -> int:
	var lv := 0
	for i in THRESHOLDS.size():
		if points >= THRESHOLDS[i]:
			lv = i
	return lv


static func level(p: Pompon, skill: String) -> int:
	return level_for_xp(xp(p, skill))


## Cuanto falta (0 a 1) para el proximo nivel.
static func progress(p: Pompon, skill: String) -> float:
	var lv := level(p, skill)
	if lv >= MAX_LEVEL:
		return 1.0
	var lo: float = THRESHOLDS[lv]
	var hi: float = THRESHOLDS[lv + 1]
	return clampf((xp(p, skill) - lo) / (hi - lo), 0.0, 1.0)


## Explorar la casa solo entrena el fisico hasta el nivel 3; despues hacen falta objetos (rueda, columpio...).
const WALK_MAX_LEVEL := 3


static func add_walk_xp(p: Pompon, amount: float) -> Dictionary:
	if p == null or level(p, "fisico") >= WALK_MAX_LEVEL:
		return {}
	return add_xp(p, "fisico", amount)


static func item_skill(item_id: String) -> String:
	return ITEM_SKILL.get(item_id, "")


## Suma experiencia. Devuelve la entrada del diario si subio de nivel ({} si no).
static func add_xp(p: Pompon, skill: String, amount: float) -> Dictionary:
	if p == null or not p.hatched or not SKILLS.has(skill) or amount <= 0.0:
		return {}
	var before := level(p, skill)
	_skills(p)[skill] = xp(p, skill) + amount
	var after := level(p, skill)
	if after > before:
		var info: Dictionary = SKILLS[skill]
		var vowel := "a" if p.sex == "Hembra" else "o"
		var text := "¡Mejoré mi %s! Ahora estoy en nivel %d" % [String(info["name"]).to_lower(), after]
		if after >= MAX_LEVEL:
			text = "¡Llegué al nivel máximo de %s!" % String(info["name"]).to_lower()
		return {"kind": "sentimiento", "text": text.replace("{a}", vowel), "stat": info["stat"], "key": "skill:%s:%d" % [skill, after]}
	return {}


## Termino un minijuego (`ratio` = aciertos / rondas). Devuelve las entradas de nivel que haya.
static func on_game(p: Pompon, game: String, ratio: float) -> Array:
	var out: Array = []
	for pair in GAME_SKILL.get(game, []):
		var e := add_xp(p, pair[0], GAME_BASE_XP * float(pair[1]) * (0.4 + 0.6 * clampf(ratio, 0.0, 1.0)))
		if not e.is_empty():
			out.append(e)
	return out


## Compro un objeto que entrena una habilidad: un empujoncito inicial.
static func on_buy(p: Pompon, item_id: String) -> Array:
	var skill := item_skill(item_id)
	if skill == "":
		return []
	var e := add_xp(p, skill, BUY_XP)
	return [] if e.is_empty() else [e]


## Objetos de la habitacion `room_items` (ids) que entrenan algo.
static func trainers(room_items: Array) -> Array:
	return room_items.filter(func(id): return ITEM_SKILL.has(id))


## "hace ejercicio con su rueda de ejercicio" (para el cuadro de actividad).
static func practice_text(item_id: String) -> String:
	var name: String = Catalog.get_item(item_id).get("name", item_id).to_lower()
	var poss := "sus " if name.split(" ")[0] in ["cubos"] else "su "
	return PRACTICE_TEXT[ITEM_SKILL[item_id]] % (poss + name)
