class_name Rooms
extends RefCounted
## Las habitaciones de la casa. Cada una es ancha (WORLD_SCREENS pantallas) y se recorre
## deslizando a izquierda y derecha. Se abren al subir de nivel el Pompon (maximo 6).

const WORLD_SCREENS := 2.0   # ancho de cada habitacion, en pantallas

const LIST := [
	{"id": "sala", "name": "Sala", "level": 1, "wall": "", "floor": "", "rug": "cfe8f3", "icon": "house"},
	{"id": "dormitorio", "name": "Dormitorio", "level": 6, "wall": "wall_lilac", "floor": "floor_pink", "rug": "ffc9dc", "icon": "heart"},
	{"id": "cocina", "name": "Cocina", "level": 14, "wall": "wall_mint", "floor": "floor_checker", "rug": "ffe6a8", "icon": "apple"},
	{"id": "biblioteca", "name": "Biblioteca", "level": 24, "wall": "wall_peach", "floor": "floor_wood", "rug": "c8dcf5", "icon": "bulb"},
	{"id": "jardin", "name": "Jardín", "level": 38, "wall": "wall_blue", "floor": "floor_grass", "rug": "fff1c9", "icon": "drop"},
	{"id": "terraza", "name": "Terraza estelar", "level": 52, "wall": "wall_space", "floor": "floor_carpet", "rug": "d9c8f5", "icon": "star"},
]


static func count() -> int:
	return LIST.size()


static func room_name(i: int) -> String:
	return LIST[clampi(i, 0, LIST.size() - 1)]["name"]


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
	return ["en la sala", "en el dormitorio", "en la cocina", "en la biblioteca", "en el jardín", "en la terraza estelar"][clampi(i, 0, 5)]


## Nombre corto para los botones de la barra de abajo.
static func short_name(i: int) -> String:
	return "Terraza" if i == 5 else room_name(i)


static func rug_color(i: int) -> Color:
	return Color.html(LIST[clampi(i, 0, LIST.size() - 1)]["rug"])
