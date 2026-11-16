class_name Rooms
extends RefCounted
## Las habitaciones de la casa. Cada una es ancha (WORLD_SCREENS pantallas) y se recorre
## deslizando a izquierda y derecha. Se abren al subir de nivel el Pompon (maximo 6).

const WORLD_SCREENS := 3.0   # ancho de cada habitacion, en pantallas
## Version del dibujo del cuarto (se guarda como `room_layout`): 1 = una pantalla; 2 = dos pantallas y la
## pared hasta el 60 % del alto; 3 (16/11/2026) = tres pantallas y la pared hasta el 50 % (piso mas profundo).
const LAYOUT := 3
const FLOOR_START := 0.5   # fraccion del alto donde termina la pared y empieza el piso
const WALL_GAP := 12.0     # px que el pie de un mueble "contra la pared" queda por debajo de esa linea


## Altura (fraccion, centro del item) mas atras donde puede ir un mueble de piso: contra la pared, con el pie
## apoyado justo sobre la linea del piso. Las alfombras, en cambio, quedan enteras sobre el piso.
static func wall_y(id: String, h := 1280.0) -> float:
	var half := ItemArt.size_of(id).y * 0.5
	if Catalog.is_rug(id):
		return (FLOOR_START * h + half + 6.0) / h
	return (FLOOR_START * h + WALL_GAP - half) / h

const LIST := [
	{"id": "sala", "name": "Sala", "level": 1, "wall": "", "floor": "", "rug": "cfe8f3", "icon": "house"},
	{"id": "dormitorio", "name": "Dormitorio", "level": 6, "wall": "wall_lilac", "floor": "floor_pink", "rug": "ffc9dc", "icon": "heart"},
	{"id": "cocina", "name": "Cocina", "level": 14, "wall": "wall_mint", "floor": "floor_checker", "rug": "ffe6a8", "icon": "apple"},
	{"id": "biblioteca", "name": "Biblioteca", "level": 24, "wall": "wall_peach", "floor": "floor_wood", "rug": "c8dcf5", "icon": "bulb"},
	{"id": "jardin", "name": "Jardín", "level": 38, "wall": "wall_blue", "floor": "floor_grass", "rug": "fff1c9", "icon": "drop"},
	{"id": "terraza", "name": "Terraza estelar", "level": 52, "wall": "wall_space", "floor": "floor_carpet", "rug": "d9c8f5", "icon": "star"},
]


## Pasa un item colocado ({"id","x","y"}) de un cuarto dibujado con la version `from` a la actual: lo que ya
## estaba decorado queda en el medio del cuarto, a la misma distancia de la pared (los muebles quedan
## atras, contra la pared, y adelante queda piso libre).
static func migrate_entry(e: Dictionary, from: int) -> Dictionary:
	var x := float(e.get("x", 0.5))
	var y := float(e.get("y", 0.7))
	if from < 2:
		x = 0.25 + x * 0.5
	if from < 3:
		x = 1.0 / 6.0 + x * 2.0 / 3.0
		if Catalog.get_item(str(e.get("id", ""))).get("category", "") == "deco":
			y = 0.08 + (y - 0.09) * 0.32 / 0.41
		elif y - 0.1 <= 0.545:   # estaba lo mas atras posible: ahora queda contra la pared
			y = wall_y(str(e.get("id", "")))
		else:
			y -= 0.1
	var out := e.duplicate()
	out["x"] = clampf(x, 0.0, 1.0)
	out["y"] = clampf(y, 0.0, 1.0)
	return out


static func count() -> int:
	return LIST.size()


static func room_name(i: int) -> String:
	return T.label(LIST[clampi(i, 0, LIST.size() - 1)]["name"])


static func unlock_level(i: int) -> int:
	return int(LIST[clampi(i, 0, LIST.size() - 1)]["level"])


static func is_unlocked(i: int, level: int) -> bool:
	return i >= 0 and i < LIST.size() and level >= unlock_level(i)


## Cuantas habitaciones se pueden usar con ese nivel (siempre al menos la primera).
static func unlocked_count(level: int) -> int:
	var n := 0
	for i in LIST.size():
		if is_unlocked(i, level):
			n += 1
	return maxi(n, 1)


## Pared y piso con los que arranca la habitacion `i` (hasta que se cambien en la tienda o el vestidor).
static func default_style(i: int) -> Dictionary:
	var r: Dictionary = LIST[clampi(i, 0, LIST.size() - 1)]
	return {"wall": r["wall"], "floor": r["floor"]}


## "en la sala", "en el jardín"... para armar frases.
static func place_name(i: int) -> String:
	return T.s(["en la sala", "en el dormitorio", "en la cocina", "en la biblioteca", "en el jardín", "en la terraza estelar"][clampi(i, 0, 5)])


## Nombre corto para los botones de la barra de abajo.
static func short_name(i: int) -> String:
	return T.label("Terraza") if i == 5 else room_name(i)


static func rug_color(i: int) -> Color:
	return Color.html(LIST[clampi(i, 0, LIST.size() - 1)]["rug"])
