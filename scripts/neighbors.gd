class_name Neighbors
extends RefCounted
## Vecinos del barrio (sin conexion): Pompons con su propia casa que puedes visitar.
## Suben la estadistica Amistad. Mas adelante se podrian reemplazar por amigos reales en linea.

const ROSTER := [
	{"id": "luna", "name": "Luna", "species": "Felino", "seed": 11},
	{"id": "nube", "name": "Nube", "species": "Conejo", "seed": 23},
	{"id": "bruno", "name": "Bruno", "species": "Canino", "seed": 37},
	{"id": "pipo", "name": "Pipo", "species": "Ave", "seed": 41},
	{"id": "chispa", "name": "Chispa", "species": "Dragon", "seed": 53},
]

# Cada una suma 1 punto de amistad la primera vez del dia (repetirla solo muestra la animacion).
# `short`, `icon` y `color` son para los botones redondos; `skill` sube una habilidad del Pompon.
const ACTIONS := [
	{"key": "pet", "label": "Acariciar", "short": "Acariciar", "icon": "heart", "color": "ff7aa8",
		"cost": 0, "amistad": 6.0, "diversion": 0.0, "sfx": "pet"},
	{"key": "play", "label": "Jugar juntos", "short": "Jugar", "icon": "game", "color": "a98bea",
		"cost": 0, "amistad": 10.0, "diversion": 15.0, "sfx": "success", "skill": "logica"},
	{"key": "gift", "label": "Dejar un regalo (5)", "short": "Regalo", "icon": "gift", "color": "ffb938",
		"cost": 5, "amistad": 6.0, "diversion": 0.0, "sfx": "coin"},
]
const MAX_POINTS := 100
const MILESTONE := 50          # a esta amistad el vecino te regala monedas (una sola vez)
const MILESTONE_COINS := 20
const SKILL_XP := 3.0          # experiencia de habilidad por la primera actividad del dia
const WATCH_SECONDS := 20.0    # quedarse socializando (barra "Socializando")...
const WATCH_COINS := 20        # ...hace caer monedas y llena Social (una vez por dia con cada vecino)
const REST_SECONDS := 5.0      # descanso entre actividades: los Pompons se cansan
# Lo que suma un punto por dia: entrar y cada actividad.
const DAILY_KEYS := ["visit", "pet", "play", "gift"]
# Niveles de amistad: [puntos desde, nombre]
const LEVELS := [[0, "Conocidos"], [25, "Compañeros"], [50, "Amigos"], [75, "Mejores amigos"]]

const FLOOR_SPOTS := [
	Vector2(0.16, 0.70), Vector2(0.84, 0.70), Vector2(0.16, 0.78), Vector2(0.84, 0.78),
	Vector2(0.36, 0.67), Vector2(0.64, 0.67), Vector2(0.36, 0.78), Vector2(0.64, 0.78),
]
const WALL_SPOTS := [Vector2(0.22, 0.34), Vector2(0.78, 0.34), Vector2(0.50, 0.28), Vector2(0.50, 0.46)]

static var current := ""   # vecino que se esta visitando
static var buddy := {}     # el vecino que se crea solo, de la misma edad que tu Pompon (NPC)
static var friends: Array = []   # amigos de verdad (Friends): {"id": "f:CODIGO", "name", "player", "real", "code", "snapshot"}

const BUDDY_NAMES := ["Tobi", "Bimba", "Fresa", "Mota", "Pipa", "Canelo", "Rulo", "Lunita", "Chicle", "Maní"]


## Todos los vecinos: primero el de tu edad (si existe), despues tus amigos de verdad y los del barrio.
static func all() -> Array:
	return ([buddy] if not buddy.is_empty() else []) + friends + ROSTER


## Pone los amigos de verdad (lista de GameState.friends: {"code", "snapshot"}).
static func set_friends(list: Array) -> void:
	friends = []
	for f in list:
		friends.append(friend_entry(f))


## La entrada de vecino de un amigo de verdad ({"code", "snapshot"}).
static func friend_entry(f: Dictionary) -> Dictionary:
	var snap: Dictionary = f.get("snapshot", {})
	var pompon = snap.get("pompon", {})
	var name := str(pompon.get("nickname", "")).strip_edges().left(14) if typeof(pompon) == TYPE_DICTIONARY else ""
	return {"id": "f:" + str(f["code"]), "name": name if name != "" else "Pompon", "real": true,
		"player": str(snap.get("player", "")).strip_edges().left(14), "code": str(f["code"]), "snapshot": snap}


## Crea los datos de un vecino NPC (nombre, especie y semilla al azar).
static func new_buddy() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return {"id": "buddy", "name": BUDDY_NAMES[rng.randi() % BUDDY_NAMES.size()],
		"species": Pompon.SPECIES[rng.randi() % Pompon.SPECIES.size()], "seed": rng.randi_range(100, 9999), "same_age": true}


## Icono y color de lo que suma por dia ("visit" o una actividad): [icono, Color].
static func daily_look(key: String) -> Array:
	if key == "visit":
		return ["house", Color("5fc77f")]
	var a := get_action(key)
	return [a.get("icon", "star"), Color(a.get("color", "ffb938"))]


## Nivel de amistad (0 a 3) segun los puntos.
static func level_index(points: int) -> int:
	var idx := 0
	for i in LEVELS.size():
		if points >= int(LEVELS[i][0]):
			idx = i
	return idx


static func level_name(points: int) -> String:
	return LEVELS[level_index(points)][1]


static func get_entry(id: String) -> Dictionary:
	for e in all():
		if e["id"] == id:
			return e
	return {}


static func get_action(key: String) -> Dictionary:
	for a in ACTIONS:
		if a["key"] == key:
			return a
	return {}


## Un amigo de verdad: su Pompon y su habitacion salen de su tarjeta (validando todo: viene de otro juego).
static func _build_real(entry: Dictionary) -> Dictionary:
	var snap: Dictionary = entry.get("snapshot", {})
	var d = snap.get("pompon", {})
	if typeof(d) != TYPE_DICTIONARY:
		d = {}
	var color := func(key: String, fallback: String) -> Color:
		var text := str(d.get(key, ""))
		return Color.html(text) if Color.html_is_valid(text) else Color(fallback)
	var p := PomponView.make_sample(
		str(d.get("species", "")) if str(d.get("species", "")) in Pompon.SPECIES else "Felino",
		color.call("color_primary", "ffb3cc"), color.call("color_secondary", "fff0f5"),
		str(d.get("eyes", "")) if str(d.get("eyes", "")) in Pompon.EYE_SHAPES else "redondos",
		str(d.get("mouth", "")) if str(d.get("mouth", "")) in Pompon.MOUTH_SHAPES else Pompon.MOUTH_SHAPES[0],
		str(d.get("face", "")) if str(d.get("face", "")) in Pompon.FACE_SHAPES else Pompon.FACE_SHAPES[0])
	p.nickname = entry["name"]
	p.sex = str(d.get("sex", "")) if str(d.get("sex", "")) in Pompon.SEX else Pompon.SEX[0]
	p.personality = str(d.get("personality", "")) if str(d.get("personality", "")) in Pompon.PERSONALITIES else Pompon.PERSONALITIES[0]
	p.hatched = true
	var born := int(d.get("born_at", 0))
	if born > 0:
		p.born_at = born   # crece de verdad: se ve bebe, niño o adulto como en el juego de tu amigo
	var equipped := {}
	var wear = snap.get("equipped", {})
	if typeof(wear) == TYPE_DICTIONARY:
		for cat in Catalog.WEARABLE:
			var id := str(wear.get(cat, ""))
			if Catalog.get_item(id).get("category", "") == cat:
				equipped[cat] = id
	var wall := str(snap.get("wall", ""))
	var floor_item := str(snap.get("floor", ""))
	var placed := []
	var items = snap.get("placed", [])
	if typeof(items) == TYPE_ARRAY:
		for it in items.slice(0, 60):
			if typeof(it) == TYPE_DICTIONARY and Catalog.is_placeable(str(it.get("id", ""))):
				var e := {"id": str(it["id"]), "x": clampf(float(it.get("x", 0.5)), 0.0, 1.0), "y": clampf(float(it.get("y", 0.7)), 0.0, 1.0)}
				if str(it.get("on", "")) != "":
					e["on"] = str(it["on"])
					e["ox"] = float(it.get("ox", 0.0))
				if bool(it.get("flip", false)):
					e["flip"] = true
				placed.append(e)
	return {"name": entry["name"], "pompon": p, "equipped": equipped,
		"wall": wall if Catalog.get_item(wall).get("category", "") == "wall" else "",
		"floor": floor_item if Catalog.get_item(floor_item).get("category", "") == "floor" else "",
		"placed": placed, "screens": Rooms.WORLD_SCREENS, "player": entry.get("player", ""), "real": true}


## Genera (siempre igual para el mismo vecino) su Pompon, su ropa y su casa.
static func build(entry: Dictionary) -> Dictionary:
	if entry.get("real", false):
		return _build_real(entry)
	var rng := RandomNumberGenerator.new()
	rng.seed = entry["seed"]
	var c1 := Color.from_hsv(rng.randf(), rng.randf_range(0.25, 0.5), rng.randf_range(0.88, 1.0))
	var c2 := Color.from_hsv(rng.randf(), rng.randf_range(0.08, 0.25), rng.randf_range(0.94, 1.0))
	var p := PomponView.make_sample(entry["species"], c1, c2,
		Pompon.EYE_SHAPES[rng.randi() % Pompon.EYE_SHAPES.size()],
		Pompon.MOUTH_SHAPES[rng.randi() % Pompon.MOUTH_SHAPES.size()],
		Pompon.FACE_SHAPES[rng.randi() % Pompon.FACE_SHAPES.size()])
	p.id = "#POMPON-%04d" % (entry["seed"] * 137 % 10000)
	p.sex = Pompon.SEX[rng.randi() % 2]
	p.personality = Pompon.PERSONALITIES[rng.randi() % Pompon.PERSONALITIES.size()]
	p.stats["inteligencia"] = float(rng.randi_range(4, 20))
	if entry.get("same_age", false):  # crece al mismo tiempo que tu Pompon
		p.hatched = true
		p.born_at = int(entry.get("born_at", p.born_at))

	var equipped := {}
	for cat in Catalog.WEARABLE:
		if rng.randf() < 0.7:
			var options := Catalog.ITEMS.filter(func(i): return i["category"] == cat)
			equipped[cat] = options[rng.randi() % options.size()]["id"]
	var walls := Catalog.ITEMS.filter(func(i): return i["category"] == "wall")
	var floors := Catalog.ITEMS.filter(func(i): return i["category"] == "floor")
	var wall: String = walls[rng.randi() % walls.size()]["id"]
	var floor_item: String = floors[rng.randi() % floors.size()]["id"]

	# su mueble clave + unos cuantos muebles y cuadros
	var floor_pool := Catalog.ITEMS.filter(func(i): return i["category"] == "furniture" and not i.has("species"))
	var wall_pool := Catalog.ITEMS.filter(func(i): return i["category"] == "deco")
	var floor_ids: Array = [Catalog.required_furniture(entry["species"])["id"]]
	while floor_ids.size() < 4:
		var pick: String = floor_pool[rng.randi() % floor_pool.size()]["id"]
		if not floor_ids.has(pick):
			floor_ids.append(pick)
	var wall_ids: Array = []
	while wall_ids.size() < 2:
		var pick2: String = wall_pool[rng.randi() % wall_pool.size()]["id"]
		if not wall_ids.has(pick2):
			wall_ids.append(pick2)
	var placed := []
	for id in floor_ids:
		var s: Vector2 = ItemArt.best_spot(id, FLOOR_SPOTS, placed)
		var half := ItemArt.size_of(id).x * 0.5 / 720.0 + 0.02
		placed.append({"id": id, "x": clampf(s.x, half, 1.0 - half), "y": s.y})
	var wall_placed := []
	for id in wall_ids:
		var s2: Vector2 = ItemArt.best_spot(id, WALL_SPOTS, wall_placed)
		wall_placed.append({"id": id, "x": s2.x, "y": s2.y})
	placed.append_array(wall_placed)
	return {"name": entry["name"], "pompon": p, "equipped": equipped, "wall": wall, "floor": floor_item, "placed": placed}
