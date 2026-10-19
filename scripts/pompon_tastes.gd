class_name PomponTastes
extends RefCounted
## Gustos y personalidad que el Pompon va aprendiendo de como lo cuidas. Se guarda en `Pompon.tastes`.
##  - Color favorito: sale de los colores de las cosas que le compras y le pones.
##  - Comida favorita: los alimentos nuevos le dan desconfianza; de a poco, si se los das seguido, los va amando.
##  - Juego favorito (el que mas juegan) y habitacion favorita (donde mas tiempo pasa).
##  - Personalidad: cinco rasgos que se moldean con lo que viven juntos. Se forman de bebe y de niño
##    (plasticidad alta); de grande ya casi no cambian.
## Cada Pompon nace con una pequeña inclinacion propia (semilla = su ID): no hay dos iguales.

# Familias de color: clave -> [nombre, color de muestra]
const COLORS := {
	"rosa": ["rosa", Color("ff9ecb")], "rojo": ["rojo", Color("ee5b5b")], "naranja": ["naranja", Color("ffa24d")],
	"amarillo": ["amarillo", Color("ffd93d")], "verde": ["verde", Color("7bd389")], "menta": ["menta", Color("7fdcc8")],
	"celeste": ["celeste", Color("8ecae6")], "azul": ["azul", Color("5b8def")], "lila": ["lila", Color("b79df0")],
}

# Comidas. `tier`: 0 basica (gratis), 1 rica, 2 gourmet.
const FOODS := [
	{"id": "papilla", "name": "Papilla", "tier": 0, "price": 0, "alimentacion": 30.0, "felicidad": 0.0},
	{"id": "pan", "name": "Pan tostado", "tier": 0, "price": 0, "alimentacion": 30.0, "felicidad": 0.0},
	{"id": "arroz", "name": "Arroz con caldo", "tier": 0, "price": 0, "alimentacion": 30.0, "felicidad": 0.0},
	{"id": "manzana", "name": "Manzana", "tier": 1, "price": 5, "alimentacion": 40.0, "felicidad": 5.0},
	{"id": "banana", "name": "Banana", "tier": 1, "price": 5, "alimentacion": 40.0, "felicidad": 5.0},
	{"id": "zanahoria", "name": "Zanahoria", "tier": 1, "price": 5, "alimentacion": 40.0, "felicidad": 5.0},
	{"id": "galletitas", "name": "Galletitas", "tier": 1, "price": 5, "alimentacion": 40.0, "felicidad": 5.0},
	{"id": "pizza", "name": "Pizza", "tier": 2, "price": 12, "alimentacion": 50.0, "felicidad": 10.0},
	{"id": "helado", "name": "Helado", "tier": 2, "price": 12, "alimentacion": 50.0, "felicidad": 10.0},
	{"id": "torta", "name": "Torta de frutilla", "tier": 2, "price": 12, "alimentacion": 50.0, "felicidad": 10.0},
	{"id": "fideos", "name": "Fideos con salsa", "tier": 2, "price": 12, "alimentacion": 50.0, "felicidad": 10.0},
]
const GAMES := {"math": "Matemáticas", "simon": "Memoria", "pattern": "Patrones", "jump": "Salto al cielo", "paint": "Pintar", "music": "Hacer música"}
const TRAITS := ["Energico", "Timido", "Curioso", "Gloton", "Artistico"]
const TRAIT_STAT := {"Energico": "diversion", "Timido": "amor", "Curioso": "inteligencia", "Gloton": "alimentacion", "Artistico": "felicidad"}
const TRAIT_WORD := {"Energico": "enérgic{a}", "Timido": "tímid{a}", "Curioso": "curios{a}", "Gloton": "glot{on}", "Artistico": "artístic{a}"}
# Que tanto aprende segun la etapa: bebe y niño absorben todo; despues casi nada cambia.
const PLASTICITY := [0.0, 1.6, 1.3, 0.7, 0.4]
const FAV_COLOR_MIN := 3.0
const FAV_GAME_MIN := 3
const FAV_ROOM_SECONDS := 600.0


# ------------------------------------------------------------------ datos de cada Pompon

## Deja listos los gustos del Pompon (con su inclinacion propia, segun su ID) si todavia no existen.
static func ensure(p: Pompon) -> Dictionary:
	var t: Dictionary = p.tastes
	if t.has("traits") and t.has("innate_food"):
		return t
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(p.id)
	t["colors"] = t.get("colors", {})
	t["foods"] = t.get("foods", {})        # id -> puntaje (cuanto se lo dieron, ajustado por etapa)
	t["eaten"] = t.get("eaten", {})        # id -> veces
	t["games"] = t.get("games", {})
	t["rooms"] = t.get("rooms", {})        # numero de habitacion -> segundos
	t["fav"] = t.get("fav", {})            # favoritos ya anunciados
	t["innate_color"] = {}
	for fam in COLORS:
		t["innate_color"][fam] = snappedf(rng.randf_range(0.0, 1.0), 0.1)
	t["innate_food"] = {}
	for f in FOODS:
		t["innate_food"][f["id"]] = [-1, 0, 0, 0, 1][rng.randi() % 5]   # le cae mal / neutro / le cae bien
	t["traits"] = {}
	for tr in TRAITS:
		t["traits"][tr] = 20.0 + rng.randf_range(0.0, 8.0)
	if p.personality in TRAITS:
		t["traits"][p.personality] += 20.0
	p.tastes = t
	return t


static func plasticity(p: Pompon, now: int) -> float:
	return PLASTICITY[clampi(p.stage_index(now), 0, PLASTICITY.size() - 1)]


static func _vowel(p: Pompon) -> String:
	return "a" if p.sex == "Hembra" else "o"


static func _fmt(p: Pompon, text: String) -> String:
	return text.replace("{a}", _vowel(p)).replace("{on}", "ón" if p.sex != "Hembra" else "ona")


static func _news(p: Pompon, text: String, stat: String, key: String) -> Dictionary:
	return {"kind": "sentimiento", "text": _fmt(p, text), "stat": stat, "key": key}


# ------------------------------------------------------------------ colores

## A que familia de color pertenece (o "" si es gris, blanco o muy oscuro).
static func color_family(c: Color) -> String:
	if c.s < 0.18 or c.v < 0.35:
		return ""
	var h := c.h
	if h >= 0.93 or h < 0.02:
		return "rosa" if c.s < 0.55 else "rojo"
	if h < 0.11:
		return "naranja"
	if h < 0.19:
		return "amarillo"
	if h < 0.42:
		return "verde"
	if h < 0.52:
		return "menta"
	if h < 0.64:
		return "celeste" if c.s < 0.6 else "azul"
	if h < 0.77:
		return "lila"
	return "rosa"


static func color_name(fam: String) -> String:
	return COLORS[fam][0] if COLORS.has(fam) else ""


static func color_swatch(fam: String) -> Color:
	return COLORS[fam][1] if COLORS.has(fam) else Color.WHITE


## Puntaje de un color: lo que le compraron + su inclinacion de nacimiento.
static func color_score(p: Pompon, fam: String) -> float:
	var t := ensure(p)
	return float(t["colors"].get(fam, 0.0)) + float(t["innate_color"].get(fam, 0.0))


static func color_hearts(p: Pompon, fam: String) -> int:
	return clampi(int(float(ensure(p)["colors"].get(fam, 0.0)) * 0.7), 0, 5)


## Colores de mas a menos querido (solo los que ya tienen algun puntaje real).
static func colors_ranked(p: Pompon) -> Array:
	var t := ensure(p)
	var out: Array = []
	for fam in COLORS:
		if float(t["colors"].get(fam, 0.0)) > 0.0:
			out.append(fam)
	out.sort_custom(func(a, b): return color_score(p, a) > color_score(p, b))
	return out


static func favorite_color(p: Pompon) -> String:
	var r := colors_ranked(p)
	if r.is_empty() or float(ensure(p)["colors"][r[0]]) < FAV_COLOR_MIN:
		return ""
	if r.size() > 1 and color_score(p, r[0]) - color_score(p, r[1]) < 0.8:
		return ""
	return r[0]


## Compro algo ("hat", "shirt", muebles...): suma puntos al color de ese item.
static func on_item(p: Pompon, item_id: String, amount: float, now: int) -> void:
	if p == null or not p.hatched:
		return
	var item := Catalog.get_item(item_id)
	if item.is_empty():
		return
	var t := ensure(p)
	var fam := color_family(Color.html(item["color"]))
	if fam != "":
		t["colors"][fam] = float(t["colors"].get(fam, 0.0)) + amount * plasticity(p, now)
	bump(p, "Artistico", amount, now)


# ------------------------------------------------------------------ comidas

static func get_food(id: String) -> Dictionary:
	for f in FOODS:
		if f["id"] == id:
			return f
	return {}


static func times_eaten(p: Pompon, id: String) -> int:
	return int(ensure(p)["eaten"].get(id, 0))


static func food_score(p: Pompon, id: String) -> float:
	return float(ensure(p)["foods"].get(id, 0.0))


## Corazones (0 a 5) que le tiene a una comida. 0 y nunca comida = nueva; 0 y ya probada = todavia duda.
static func food_hearts(p: Pompon, id: String) -> int:
	return clampi(int(food_score(p, id) * 0.55), 0, 5)


static func is_new_food(p: Pompon, id: String) -> bool:
	return times_eaten(p, id) == 0


static func favorite_food(p: Pompon) -> String:
	var best := ""
	var best_score := 0.0
	var second := 0.0
	for f in FOODS:
		var s := food_score(p, f["id"])
		if s > best_score:
			second = best_score
			best_score = s
			best = f["id"]
		elif s > second:
			second = s
	if best == "" or food_hearts(p, best) < 3 or best_score - second < 1.0:
		return ""
	return best


## Le dan de comer `id`. Devuelve como lo vive: {"mult" (cuanta hambre le quita), "happy" (felicidad extra),
## "text", "kind", "stat", "force" (es un momento importante), "hearts"}.
static func eat(p: Pompon, id: String, now: int) -> Dictionary:
	var t := ensure(p)
	var before_hearts := food_hearts(p, id)
	var count := times_eaten(p, id)
	var innate := int(t["innate_food"].get(id, 0))
	var rate := plasticity(p, now) * (1.3 if innate > 0 else (0.75 if innate < 0 else 1.0))
	t["foods"][id] = food_score(p, id) + rate
	t["eaten"][id] = count + 1
	var after_hearts := food_hearts(p, id)
	var name := String(get_food(id).get("name", id)).to_lower()
	var baby := p.stage_index(now) <= 1
	var out := {"mult": 1.0, "happy": 0.0, "text": "", "kind": "frase", "stat": "alimentacion", "force": false, "hearts": after_hearts}
	if count == 0:
		out["mult"] = 0.7
		out["force"] = true
		out["text"] = "¿Mmm…? (lo prueba con cuidado)" if baby else "¿Qué es esto? Lo pruebo despacito…"
	elif before_hearts == 0 and after_hearts == 0:
		out["mult"] = 0.9
		out["text"] = "Mmm… (todavía no sabe si le gusta)" if baby else "Mmm… todavía no sé si me gusta"
	elif innate < 0 and after_hearts < 2:
		out["mult"] = 0.85
		out["text"] = "Mmm… (no le convence)" if baby else "No me convence mucho… pero lo intento"
	elif after_hearts >= 5:
		out["mult"] = 1.1
		out["happy"] = 4.0
		out["text"] = "¡Ñam ñam ñam! <3" if baby else "¡Mi comida favorita! %s es lo mejor" % name.capitalize()
	elif after_hearts >= 3:
		out["happy"] = 2.0
		out["text"] = "¡Ñam ñam!" if baby else "¡Me gusta mucho!"
	else:
		out["text"] = "¡Ñam!" if baby else "Está rico"
	if after_hearts > before_hearts and after_hearts >= 3 and before_hearts < 3:
		out["force"] = true
		if not baby:
			out["text"] = "¡Cada vez me gusta más: %s!" % name
	# comer variado y comer mucho moldean el caracter
	bump(p, "Gloton", 0.8, now)
	if count == 0:
		bump(p, "Curioso", 1.0, now)
	return out


# ------------------------------------------------------------------ juegos y habitaciones

static func on_game(p: Pompon, game: String, now: int) -> void:
	if p == null or not p.hatched:
		return
	var t := ensure(p)
	if GAMES.has(game):
		t["games"][game] = int(t["games"].get(game, 0)) + 1
	bump(p, "Curioso", 1.2, now)


static func favorite_game(p: Pompon) -> String:
	var t := ensure(p)
	var best := ""
	var best_n := 0
	var second := 0
	for g in GAMES:
		var n := int(t["games"].get(g, 0))
		if n > best_n:
			second = best_n
			best_n = n
			best = g
		elif n > second:
			second = n
	if best_n < FAV_GAME_MIN or best_n - second < 1:
		return ""
	return best


static func add_room_time(p: Pompon, room: int, seconds: float) -> void:
	var t := ensure(p)
	t["rooms"][str(room)] = float(t["rooms"].get(str(room), 0.0)) + seconds


static func favorite_room(p: Pompon) -> int:
	var t := ensure(p)
	var best := -1
	var best_s := FAV_ROOM_SECONDS
	for k in t["rooms"]:
		var s := float(t["rooms"][k])
		if s > best_s:
			best_s = s
			best = int(k)
	return best


## Primera vez que entra a una habitacion: curiosidad.
static func on_room(p: Pompon, room: int, now: int) -> void:
	if p == null or not p.hatched:
		return
	var t := ensure(p)
	var seen: Array = t.get("visited", [])
	if not seen.has(room):
		seen.append(room)
		t["visited"] = seen
		if room != 0:
			bump(p, "Curioso", 1.0, now)


# ------------------------------------------------------------------ personalidad

static func bump(p: Pompon, axis: String, amount: float, now: int) -> void:
	if p == null or not TRAITS.has(axis):
		return
	var t := ensure(p)
	t["traits"][axis] = clampf(float(t["traits"][axis]) + amount * plasticity(p, now), 0.0, 100.0)


static func trait_value(p: Pompon, axis: String) -> float:
	return float(ensure(p)["traits"].get(axis, 0.0))


## De bebe y de niño la personalidad puede cambiar si otro rasgo se impone. Devuelve la entrada del
## diario ({} si no cambio nada).
static func check_personality(p: Pompon, now: int) -> Dictionary:
	if p == null or not p.hatched or p.stage_index(now) > 2:
		return {}
	var top := p.personality
	for tr in TRAITS:
		if trait_value(p, tr) > trait_value(p, top):
			top = tr
	if top == p.personality or trait_value(p, top) < trait_value(p, p.personality) + 6.0:
		return {}
	p.personality = top
	return _news(p, "Siento que me estoy volviendo más %s" % TRAIT_WORD[top], TRAIT_STAT[top], "pers:" + top)


# ------------------------------------------------------------------ anuncios de favoritos

## Revisa si aparecio (o cambio) un favorito y devuelve las entradas del diario para contarlo.
static func new_favorites(p: Pompon, now: int) -> Array:
	var out: Array = []
	if p == null or not p.hatched or p.stage_index(now) == 0:
		return out
	var fav: Dictionary = ensure(p)["fav"]
	var color := favorite_color(p)
	if color != "" and fav.get("color", "") != color:
		var had: bool = fav.get("color", "") != ""
		fav["color"] = color
		out.append(_news(p, ("Ahora creo que mi color favorito es el %s" if had else "¡Me encantan las cosas de color %s! Creo que es mi color favorito") % color_name(color), "felicidad", "fav:color"))
	var food := favorite_food(p)
	if food != "" and fav.get("food", "") != food:
		var had2: bool = fav.get("food", "") != ""
		fav["food"] = food
		var fname := String(get_food(food)["name"]).to_lower()
		out.append(_news(p, ("Ahora mi comida favorita es: %s" if had2 else "¡Mi comida favorita es: %s!") % fname, "alimentacion", "fav:food"))
	var game := favorite_game(p)
	if game != "" and fav.get("game", "") != game:
		fav["game"] = game
		out.append(_news(p, "Mi juego favorito es %s" % GAMES[game], "diversion", "fav:game"))
	return out
