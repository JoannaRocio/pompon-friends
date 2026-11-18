class_name PomponAlbum
extends RefCounted
## Album de recuerdos: figuritas que el Pompon gana con sus primeras veces y al crecer. Cada figurita
## tiene un hueco con "?" y una pista hasta que se gana; ganada muestra el dia de vida en que la consiguio.
## Todo sale de lo que el juego ya guarda (primeras veces, gustos, edad, amigos): no hay datos aparte,
## salvo `tastes["album_seen"]` (las que ya se festejaron con el aviso de "¡Figurita nueva!").

const PAGES := ["Primeras veces", "Comidas", "Lugares y amigos", "Creciendo"]
const FOOD_TINT := [Color("e0b48f"), Color("ffa94d"), Color("ff7aa8")]


## Todas las figuritas: {"id", "page", "title", "hint", "icon", "color"}.
static func stickers() -> Array:
	var out: Array = [
		_s("bath", 0, "Primer baño", "Báñalo", "bubbles", Color("3cc9b0")),
		_s("drink", 0, "Primer trago de agua", "Dale de beber", "drop", Color("5bb8f5")),
		_s("pet", 0, "Primer mimo", "Hazle una caricia", "heart", Color("ff7aa8")),
		_s("sleep", 0, "Primera noche en su camita", "Que duerma de noche", "moon", Color("7b8ce0")),
		_s("wear", 0, "Estrenó ropa", "Ponle ropa en el vestidor", "shirt", Color("a98bea")),
		_s("game:math", 0, "Jugó a Matemáticas", "Juega a Matemáticas", "calc", Color("5bb8f5")),
		_s("game:simon", 0, "Jugó a Simón Dice", "Juega a Simón Dice", "note", Color("a98bea")),
		_s("game:pattern", 0, "Jugó a Patrones", "Juega a Patrones", "puzzle", Color("3cc9b0")),
		_s("game:jump", 0, "Saltó al cielo", "Juega a Salto al cielo", "star", Color("5bb8f5")),
		_s("game:paint", 0, "Pintó su primer dibujo", "Juega a Pintar", "heart", Color("ff7aa8")),
		_s("game:music", 0, "Hizo su primera canción", "Juega a Hacer música", "note", Color("a98bea")),
	]
	for f in PomponTastes.FOODS:
		out.append(_s("food:" + f["id"], 1, PomponTastes.food_name(f["id"]), T.s("Dale de comer %s") % PomponTastes.food_name(f["id"]).to_lower(), "apple", FOOD_TINT[int(f["tier"])]))
	for i in range(1, Rooms.count()):
		out.append(_s("room:%d" % i, 2, Rooms.room_name(i), "Ábrela al subir de nivel", Rooms.LIST[i]["icon"], Color("a98bea")))
	out.append_array([
		_s("neighbor", 2, "Primer vecino", "Visita a un vecino", "house", Color("5fc77f")),
		_s("real_friend", 2, "Primer amigo de verdad", "Agrega a un amigo con su código", "people", Color("ff7aa8")),
		_s("best_friend", 2, "Mejores amigos", "Llega a 75 de amistad con alguien", "heart", Color("f2566f")),
		_s("born", 3, "¡Nació!", "", "star", Color("ffcf3f")),
		_s("stage:2", 3, "Ya es niño", "Crece hasta el día 8", "sprout", Color("5fc77f")),
		_s("stage:3", 3, "Ya es adolescente", "Crece hasta el día 22", "sprout", Color("3cc9b0")),
		_s("stage:4", 3, "Ya es grande", "Crece hasta el día 52", "sprout", Color("5bb8f5")),
		_s("word", 3, "Su primera palabra", "Cuídalo bien de bebé", "book", Color("ffa94d")),
		_s("skill", 3, "Aprendió una habilidad", "Juega y usa sus juguetes", "bulb", Color("6c7ff0")),
	])
	return out


static func _s(id: String, page: int, title: String, hint: String, icon: String, color: Color) -> Dictionary:
	return {"id": id, "page": page, "title": T.s(title), "hint": T.s(hint), "icon": icon, "color": color}


## Veces que hizo algo segun PomponFirsts (las primeras veces que se cuentan desde que existe el album).
static func _firsts(p: Pompon) -> Dictionary:
	return p.tastes.get("firsts", {})


static func _any_first(p: Pompon, prefix: String) -> bool:
	for k in _firsts(p):
		if String(k).begins_with(prefix):
			return true
	return false


## ¿Ya la gano? (tambien mira lo que el juego guardaba antes del album, para partidas viejas)
static func unlocked(p: Pompon, id: String, now: int) -> bool:
	if p == null or not p.hatched:
		return false
	var firsts := _firsts(p)
	var t: Dictionary = p.tastes
	match id:
		"bath", "drink", "pet", "sleep":
			return firsts.has(id + ":")
		"wear":
			return _any_first(p, "wear:")
		"neighbor":
			for k in firsts:
				if String(k).begins_with("friend:") and not String(k).begins_with("friend:f:"):
					return true
			for k in GameState.friend_points:
				if not String(k).begins_with("f:") and int(GameState.friend_points[k]) > 0:
					return true
			return false
		"real_friend":
			return _any_first(p, "friend:f:") or not GameState.friends.is_empty()
		"best_friend":
			for k in GameState.friend_points:
				if int(GameState.friend_points[k]) >= 75:
					return true
			return false
		"born":
			return true
		"word":
			return not PomponGrowth.known_words(p, now).is_empty()
		"skill":
			for s in PomponSkills.ORDER:
				if PomponSkills.level(p, s) >= 1:
					return true
			return false
	if id.begins_with("game:"):
		var g := id.substr(5)
		return firsts.has("game:" + g) or int(t.get("games", {}).get(g, 0)) > 0
	if id.begins_with("food:"):
		var f := id.substr(5)
		return firsts.has("food:" + f) or PomponTastes.times_eaten(p, f) > 0
	if id.begins_with("room:"):
		var r := int(id.substr(5))
		return firsts.has("room:%d" % r) or t.get("visited", []).has(r)
	if id.begins_with("stage:"):
		return p.stage_index(now) >= int(id.substr(6))
	return false


## Dia de vida en que la gano (0 si no se sabe: partidas de antes del album).
static func day_won(p: Pompon, id: String) -> int:
	var at := 0
	var dates: Dictionary = p.tastes.get("firsts_at", {})
	if id.begins_with("stage:"):
		at = PomponGrowth.stage_start(p, int(id.substr(6)))
	elif id == "born":
		at = p.born_at
	else:
		for k in dates:
			var key := String(k)
			if key == id + ":" or key == id or (id == "wear" and key.begins_with("wear:")) \
					or (id == "neighbor" and key.begins_with("friend:") and not key.begins_with("friend:f:")) \
					or (id == "real_friend" and key.begins_with("friend:f:")):
				at = int(dates[k]) if at == 0 else mini(at, int(dates[k]))
	if at <= 0 or p.born_at <= 0:
		return 0
	return maxi(1, (at - p.born_at) / 86400 + 1)


## {"won", "total"}
static func progress(p: Pompon, now: int) -> Dictionary:
	var won := 0
	var all := stickers()
	for s in all:
		if unlocked(p, s["id"], now):
			won += 1
	return {"won": won, "total": all.size()}


## Figuritas ganadas que todavia no se festejaron. La primera vez (partidas viejas) se marcan todas
## como vistas sin avisar, para no llenar la pantalla de avisos.
static func new_ones(p: Pompon, now: int) -> Array:
	if p == null or not p.hatched:
		return []
	var won: Array = []
	for s in stickers():
		if unlocked(p, s["id"], now):
			won.append(s)
	if not p.tastes.has("album_seen"):
		p.tastes["album_seen"] = won.map(func(s): return s["id"])
		return []
	var seen: Array = p.tastes["album_seen"]
	var out: Array = won.filter(func(s): return not seen.has(s["id"]))
	for s in out:
		seen.append(s["id"])
	return out
