extends Node
## Autoload "GameState": guarda la partida y aplica el tiempo transcurrido.

signal pompon_left(farewell: String)

const SAVE_PATH := "user://save.json"

var pompon: Pompon = null
var coins := 0
var gems := 0
var last_saved := 0
var owned: Array = []        # ids de items comprados
var equipped := {}           # categoria -> id (hat, glasses, shirt, floor, wall)
var placed: Array = []       # muebles/decoracion en el cuarto: {"id", "x", "y"} (x,y de 0 a 1)

# Lugares por defecto (fraccion del cuarto) para lo que se compra.
const FLOOR_SPOTS := [
	Vector2(0.16, 0.70), Vector2(0.84, 0.70), Vector2(0.16, 0.78), Vector2(0.84, 0.78),
	Vector2(0.36, 0.67), Vector2(0.64, 0.67), Vector2(0.36, 0.78), Vector2(0.64, 0.78), Vector2(0.50, 0.66),
]
const WALL_SPOTS := [
	Vector2(0.22, 0.34), Vector2(0.78, 0.34), Vector2(0.50, 0.28), Vector2(0.30, 0.48), Vector2(0.70, 0.48),
	Vector2(0.50, 0.46), Vector2(0.14, 0.20), Vector2(0.86, 0.20),
]
const ROOM_REF_WIDTH := 720.0   # ancho de referencia para que los items anchos no se salgan
const ROOM_REF_WORLD := Vector2(720.0 * 2.0, 1280.0)   # habitacion completa (2 pantallas) de referencia


func _ready() -> void:
	coins = 0  # se empieza sin monedas: hay que trabajar en el periodico
	load_game()


func buy(item_id: String) -> bool:
	var item := Catalog.get_item(item_id)
	if item.is_empty() or owned.has(item_id) or coins < item["price"]:
		return false
	coins -= item["price"]
	owned.append(item_id)
	Audio.play("coin")
	track("buy")
	note_event("bought")
	PomponTastes.on_item(pompon, item_id, 1.5, int(Time.get_unix_time_from_system()))
	if pompon != null:
		for e in PomponSkills.on_buy(pompon, item_id):
			pending_thoughts.append(e)
	_taste_check()
	if Catalog.is_placeable(item_id):
		place_item(item_id)  # se coloca solo; despues lo puedes mover en "Decorar"
	if Catalog.get_item(item_id)["category"] in Catalog.BOWLS:
		equipped[Catalog.get_item(item_id)["category"]] = item_id  # el tazon nuevo se usa enseguida
	if item_id == CRIB_ID and hatch_now():  # con la cuna lista, el huevo puede nacer
		hatch_anim_pending = true  # y en la casa se ve la animacion del nacimiento
	save_game()
	return true


# --- Decoracion del cuarto ---
func placed_ids() -> Array:
	return placed.map(func(p): return p["id"])


func is_placed(item_id: String) -> bool:
	return placed_ids().has(item_id)


## Coloca un item comprado en la habitacion actual: en `at` (fraccion del ancho/alto de la habitacion)
## o, si no se indica, en el primer lugar libre mas cercano a `near_x` (los adornos chicos
## prefieren apoyarse sobre un mueble o estante libre).
func place_item(item_id: String, at := Vector2(-1.0, -1.0), near_x := 0.5) -> void:
	if not owned.has(item_id) or is_placed(item_id) or not Catalog.is_placeable(item_id):
		return
	var entry := {"id": item_id, "room": current_room}
	var in_room := placed.filter(func(p): return int(p.get("room", 0)) == current_room)
	if at.x < 0.0 and Catalog.is_small(item_id):
		var spot := _free_surface(item_id, in_room, near_x)
		if not spot.is_empty():
			entry["on"] = spot["support"]
			entry["ox"] = spot["ox"]
			at = spot["at"]
	if at.x < 0.0:
		var is_wall: bool = Catalog.get_item(item_id)["category"] == "deco"
		var spots := _world_spots(WALL_SPOTS if is_wall else FLOOR_SPOTS, near_x)
		# solo cuentan los items de la misma zona (pared o piso): no chocan entre si
		var same_zone := in_room.filter(func(p): return (Catalog.get_item(p["id"])["category"] == "deco") == is_wall)
		at = ItemArt.best_spot(item_id, spots, same_zone, ROOM_REF_WORLD)
	var half := ItemArt.size_of(item_id).x * 0.5 / (ROOM_REF_WIDTH * Rooms.WORLD_SCREENS) + 0.02
	entry["x"] = clampf(at.x, half, 1.0 - half)
	entry["y"] = at.y
	placed.append(entry)


## Los lugares de siempre (pensados para una pantalla) repetidos en cada pantalla de la habitacion,
## empezando por la pantalla mas cercana a `near_x`.
func _world_spots(spots: Array, near_x: float) -> Array:
	var keyed := []
	var screens := int(round(Rooms.WORLD_SCREENS))
	for s in screens:
		var centre := (s + 0.5) / Rooms.WORLD_SCREENS
		for i in spots.size():
			var sp: Vector2 = spots[i]
			keyed.append([absf(centre - near_x) * 10.0 + i * 0.001, Vector2((s + sp.x) / Rooms.WORLD_SCREENS, sp.y)])
	keyed.sort_custom(func(a, b): return a[0] < b[0])
	return keyed.map(func(k): return k[1])


## Un lugar libre sobre algun mueble o estante de la habitacion para un adorno chico (o {} si no hay).
func _free_surface(item_id: String, in_room: Array, near_x: float) -> Dictionary:
	var isz := ItemArt.size_of(item_id)
	var supports := in_room.filter(func(p): return not Catalog.surface_of(p["id"]).is_empty() and str(p.get("on", "")) == "")
	supports.sort_custom(func(a, b): return absf(float(a["x"]) - near_x) < absf(float(b["x"]) - near_x))
	for sup in supports:
		var surf := Catalog.surface_of(sup["id"])
		var hw: float = surf["hw"]
		if isz.x > hw * 2.0 + 70.0:
			continue
		var lim := maxf(hw - isz.x * 0.3, 0.0)
		var others := in_room.filter(func(p): return str(p.get("on", "")) == sup["id"])
		for f in [0.0, -0.6, 0.6, -1.0, 1.0]:
			var ox: float = lim * f
			var free := true
			for o in others:
				if absf(ox - float(o.get("ox", 0.0))) < (isz.x + ItemArt.size_of(o["id"]).x) * 0.32:
					free = false
					break
			if free:
				var cx: float = float(sup["x"]) + ox / (ROOM_REF_WIDTH * Rooms.WORLD_SCREENS)
				var cy: float = float(sup["y"]) + (float(surf["dy"]) - isz.y * 0.5 + 3.0) / ROOM_REF_WORLD.y
				return {"support": sup["id"], "ox": ox, "at": Vector2(cx, cy)}
	return {}


## Guarda un mueble (y lo que tenga apoyado encima) de vuelta en la bandeja.
func store_item(item_id: String) -> void:
	placed = placed.filter(func(p): return p["id"] != item_id and str(p.get("on", "")) != item_id)
	save_game()


## Apoya el adorno `item_id` sobre el mueble `support`, `ox` px a un lado de su centro.
func attach_item(item_id: String, support: String, ox: float) -> void:
	for p in placed:
		if p["id"] == item_id:
			p["on"] = support
			p["ox"] = ox


func detach_item(item_id: String) -> void:
	for p in placed:
		if p["id"] == item_id:
			p.erase("on")
			p.erase("ox")


# --- El vecino NPC de la misma edad ---
var buddy := {}   # {"id": "buddy", "name", "species", "seed", "same_age"}: se crea con el primer Pompon


func _ensure_buddy() -> void:
	if buddy.is_empty():
		buddy = Neighbors.new_buddy()
	_sync_buddy()


## El vecino crece al mismo tiempo que tu Pompon (misma fecha de nacimiento).
func _sync_buddy() -> void:
	if buddy.is_empty():
		Neighbors.buddy = {}
		return
	buddy["born_at"] = pompon.born_at if pompon != null else int(Time.get_unix_time_from_system())
	Neighbors.buddy = buddy


# --- Gustos: lo que el Pompon va aprendiendo (ver PomponTastes) ---
var pending_thoughts: Array = []   # anuncios para el diario ("mi color favorito es...") que la casa muestra


## Revisa si aparecio un favorito nuevo o cambio la personalidad; lo deja anotado para la casa.
func _taste_check() -> void:
	if pompon == null or not pompon.hatched:
		return
	var now := int(Time.get_unix_time_from_system())
	for e in PomponTastes.new_favorites(pompon, now):
		pending_thoughts.append(e)
	var pe := PomponTastes.check_personality(pompon, now)
	if not pe.is_empty():
		pending_thoughts.append(pe)


# --- Diario del Pompon: lo que piensa, siente y dice (ver PomponThoughts) ---
const JOURNAL_MAX := 120
var journal: Array = []     # {"t": unix, "kind": pensamiento|sentimiento|frase, "text", "stat"}
var events := {}            # suceso ("fed", "worked"...) -> ultima vez (unix); lo usa el Pompon para recordar
var offline_seconds := 0    # cuanto estuvo cerrada la app antes de abrirla (se avisa una sola vez)


## Primera vez (o, cada tanto, otra vez) que el Pompon hace algo: va al diario cuando vuelve a casa.
func _first(kind: String, subject: String, label: String) -> void:
	if pompon == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var e := PomponFirsts.experience(pompon, kind, subject, label, int(Time.get_unix_time_from_system()), rng)
	if not e.is_empty():
		pending_thoughts.append(e)


func add_journal(entry: Dictionary) -> void:
	if entry.is_empty() or str(entry.get("text", "")) == "":
		return
	journal.append({"t": int(Time.get_unix_time_from_system()), "kind": str(entry["kind"]), "text": str(entry["text"]), "stat": str(entry.get("stat", ""))})
	while journal.size() > JOURNAL_MAX:
		journal.pop_front()


func last_journal_time() -> int:
	return 0 if journal.is_empty() else int(journal[journal.size() - 1]["t"])


## Los ultimos `n` textos del diario (para que el Pompon no se repita).
func recent_journal_texts(n := 12) -> Array:
	return journal.slice(maxi(0, journal.size() - n)).map(func(e): return e["text"])


func note_event(kind: String) -> void:
	events[kind] = int(Time.get_unix_time_from_system())
	if pompon != null and pompon.hatched:
		PomponGrowth.record_event(pompon, kind, int(Time.get_unix_time_from_system()))


# --- Habitaciones ---
var current_room := 0
var room_styles := {}   # "0".."5" -> {"wall": id, "floor": id} (pared y piso de cada habitacion)


## Cuantas habitaciones puede usar el jugador con el nivel de su Pompon.
func rooms_unlocked() -> int:
	return Rooms.unlocked_count(pompon_level())


## Cambia de habitacion (solo las que ya se abrieron). Cada una guarda su propia pared y piso.
func set_room(i: int) -> bool:
	if i < 0 or i >= Rooms.count() or not Rooms.is_unlocked(i, pompon_level()):
		return false
	if i == current_room:
		return true
	_store_style()
	current_room = i
	_apply_style()
	note_event("room_changed")
	_first("room", str(i), PomponFirsts.room_label(i))
	PomponTastes.on_room(pompon, i, int(Time.get_unix_time_from_system()))
	_taste_check()
	save_game()
	return true


func _store_style() -> void:
	room_styles[str(current_room)] = {"wall": str(equipped.get("wall", "")), "floor": str(equipped.get("floor", ""))}


## Pone en `equipped` la pared y el piso de la habitacion actual (los de fabrica si nunca se cambiaron).
func _apply_style() -> void:
	var style: Dictionary = room_styles.get(str(current_room), Rooms.default_style(current_room))
	for cat in ["wall", "floor"]:
		var id := str(style.get(cat, ""))
		if id == "":
			equipped.erase(cat)
		else:
			equipped[cat] = id


func move_item(item_id: String, x: float, y: float) -> void:
	for p in placed:
		if p["id"] == item_id:
			p["x"] = x
			p["y"] = y


# --- Misiones diarias y Pase Pompon ---
var missions_day := 0
var mission_progress := {}   # id -> cantidad hoy
var missions_claimed: Array = []
var pass_xp := 0
var pass_claimed: Array = []  # indices de nivel ya reclamados


func _refresh_missions() -> void:
	var day := Missions.today(int(Time.get_unix_time_from_system()))
	if day != missions_day:
		missions_day = day
		mission_progress = {}
		missions_claimed = []


func track(event: String, amount := 1) -> void:
	_refresh_missions()
	mission_progress[event] = int(mission_progress.get(event, 0)) + amount


func mission_done(id: String) -> bool:
	_refresh_missions()
	var def := Missions.get_def(id)
	return not def.is_empty() and int(mission_progress.get(id, 0)) >= def["goal"]


func claim_mission(id: String) -> bool:
	if not mission_done(id) or missions_claimed.has(id):
		return false
	var def := Missions.get_def(id)
	coins += def["coins"]
	Audio.play("success")
	pass_xp += def["xp"]
	missions_claimed.append(id)
	save_game()
	return true


func pass_tier_unlocked(tier: int) -> bool:
	return pass_xp >= (tier + 1) * Missions.PASS_XP_PER_TIER


func claim_pass_tier(tier: int) -> bool:
	if tier < 0 or tier >= Missions.PASS_TIERS.size():
		return false
	if not pass_tier_unlocked(tier) or pass_claimed.has(tier):
		return false
	var reward: Dictionary = Missions.PASS_TIERS[tier]
	coins += reward["coins"]
	Audio.play("success")
	if reward["item"] != "" and not owned.has(reward["item"]):
		owned.append(reward["item"])
	pass_claimed.append(tier)
	save_game()
	return true


# --- Trabajo en el periodico (profesor/a de matematicas e ingles) ---
var jobs_done := 0
var player_title := ""     # sexo / como quiere que lo llamen: "f", "m" o "n" (vacio = todavia no eligio)
var player_name := ""      # nombre del jugador (se pregunta la primera vez que juega)
const PLAYER_NAME_MAX := 14


## Primera vez que se juega: ya dijo como se llama y su sexo?
func has_profile() -> bool:
	return player_name != "" and player_title in ["f", "m", "n"]


static func clean_player_name(text: String) -> String:
	return text.strip_edges().left(PLAYER_NAME_MAX).strip_edges()


## Guiar con flechas el camino al trabajo: la primera vez que se trabaja, o mientras el huevo espera
## su cuna y todavia no alcanzan las monedas.
func job_guide_on() -> bool:
	if jobs_done == 0:
		return true
	return egg_waiting() and not owns_crib() and coins < int(Catalog.get_item(CRIB_ID)["price"])


func set_profile(new_name: String, gender: String) -> void:
	player_name = clean_player_name(new_name)
	player_title = gender if gender in ["f", "m", "n"] else "n"
	save_game()
# camino -> {"level", "history": [{"c": acierto, "t": segundos}], "answered", "correct", "completed", "lessons": [niveles]}
# (los caminos de ingles, "en_...", se guardan aca tambien)
var math_progress := {}
# camino -> lo fallado para repasar: cuentas [{"op","a","b","streak"}] o palabras de ingles [{"key","streak"}]
var math_weak := {}


func math_state(camino: String) -> Dictionary:
	if not math_progress.has(camino):
		math_progress[camino] = {"level": 1, "history": [], "answered": 0, "correct": 0, "completed": false, "lessons": []}
	return math_progress[camino]


func math_level(camino: String) -> int:
	return clampi(int(math_state(camino)["level"]), 1, Jobs.problems(Jobs.subject_of(camino)).MAX_LEVEL)


## ¿Ya dio alguna clase de esa materia ("math" o "english")?
func taught(subject: String) -> bool:
	for camino in Jobs.problems(subject).TRACKS:
		if int(math_progress.get(camino, {}).get("answered", 0)) > 0:
			return true
	return false


func weak_facts(camino: String) -> Array:
	return math_weak.get(camino, [])


func lesson_seen(camino: String, level: int) -> bool:
	return math_state(camino)["lessons"].has(level)


func mark_lesson_seen(camino: String, level: int) -> void:
	var lessons: Array = math_state(camino)["lessons"]
	if not lessons.has(level):
		lessons.append(level)
		save_game()


## Anota una respuesta (acierto y tiempo) y recuerda las cuentas falladas: vuelven a salir
## mas adelante hasta que se aciertan dos veces seguidas.
func record_answer(camino: String, problem: Dictionary, was_correct: bool, seconds: float) -> void:
	var st := math_state(camino)
	var history: Array = st["history"]
	history.append({"c": was_correct, "t": snappedf(seconds, 0.01)})
	while history.size() > MathProblems.HISTORY_KEEP:
		history.pop_front()
	st["answered"] = int(st["answered"]) + 1
	if was_correct:
		st["correct"] = int(st["correct"]) + 1
	var weak: Array = math_weak.get(camino, [])
	var found := -1
	for i in weak.size():
		var w: Dictionary = weak[i]
		if (w["key"] if w.has("key") else MathProblems.fact_key(w["op"], w["a"], w["b"])) == problem["key"]:
			found = i
	if was_correct:
		if found >= 0:
			weak[found]["streak"] = int(weak[found]["streak"]) + 1
			if weak[found]["streak"] >= 2:
				weak.remove_at(found)
	elif found >= 0:
		weak[found]["streak"] = 0
	elif problem.has("op"):
		weak.append({"op": problem["op"], "a": problem["a"], "b": problem["b"], "streak": 0})
	else:
		weak.append({"key": problem["key"], "streak": 0})
		while weak.size() > 12:
			weak.pop_front()
	math_weak[camino] = weak


## Cierra un turno de trabajo. La paga es SIEMPRE la misma (se premia intentarlo, no saber); el juego
## mira las ultimas respuestas y decide si el nivel ya se domina (premio fijo por subir de nivel).
## Devuelve {"pay","bonus","note","title","message","action","reason","level_before","level_after","history"}.
## `full` = se llego al final del turno (si se cobra antes, solo se lleva la paga de siempre).
func finish_job(camino: String, correct: int, total: int, full := false) -> Dictionary:
	note_event("worked")
	PomponTastes.bump(pompon, "Timido", 0.5, int(Time.get_unix_time_from_system()))   # se queda solito en casa mientras el cuidador trabaja
	var problems := Jobs.problems(Jobs.subject_of(camino))
	var st := math_state(camino)
	var before := math_level(camino)
	var snapshot: Array = st["history"].duplicate(true)
	var decision: Dictionary = problems.evaluate(camino, before, st["history"])
	var action: String = decision["action"]
	var after := before
	var bonus := 0
	match action:
		"up", "jump":
			after = mini(problems.MAX_LEVEL, before + int(decision["levels"]))
			bonus = problems.LEVEL_UP_BONUS
		"down":
			after = maxi(1, before - 1)
		"complete":
			if st["completed"]:
				action = "none"
			else:
				st["completed"] = true
				bonus = problems.LEVEL_UP_BONUS
				st["history"] = []
	if after != before:
		st["level"] = after
		st["history"] = []  # en el nivel nuevo se junta evidencia nueva
	var career_before := career_level()
	var pay := job_pay()   # la paga depende del nivel de profesor/a, no de la nota
	var extra: int = problems.FULL_SHIFT_BONUS if full else 0
	coins += pay + bonus + extra
	jobs_done += 1
	var career_after := career_level()
	track("job")
	Audio.play("success" if bonus > 0 or extra > 0 else "coin")
	var grade: Dictionary = problems.grade(correct, total)
	save_game()
	return {"pay": pay, "bonus": bonus, "extra": extra, "full": full, "note": grade["note"], "title": grade["title"], "message": grade["message"],
		"action": action, "reason": decision["reason"], "level_before": before, "level_after": after, "history": snapshot,
		"career_before": career_before, "career_after": career_after, "promoted": career_after > career_before}


## Nivel de profesor/a (sube con los turnos terminados) y lo que paga cada turno ahora.
func career_level() -> int:
	return Jobs.career_level(jobs_done)


func job_pay() -> int:
	return Jobs.pay_for_level(career_level())


# --- Vecinos y regalo diario ---
var friend_points := {}      # id del vecino -> puntos de amistad (0-100)
var friend_actions := {}     # "vecino:accion" -> dia en que se hizo por ultima vez (acciones, "visit" y "watch")
var neighbors_met: Array = []  # vecinos que tu Pompon ya conocio (la presentacion se ve una vez)
var daily_gift_day := 0
var gift_streak := 0


func friend_done_today(neighbor_id: String, key: String) -> bool:
	var today := Missions.today(int(Time.get_unix_time_from_system()))
	return int(friend_actions.get("%s:%s" % [neighbor_id, key], 0)) == today


## Por que no se puede visitar ("" si se puede).
func _visit_blocker(neighbor_id: String) -> String:
	if pompon == null:
		return "Necesitas un Pompon para visitar a tus vecinos."
	if not pompon.hatched:
		return "Tu huevo todavía no nació. ¡Cómprale una cuna primero!"
	if Neighbors.get_entry(neighbor_id).is_empty():
		return "?"
	return ""


## Suma 1 punto de amistad (tope MAX_POINTS). Al cruzar el hito el vecino regala monedas.
## Devuelve las monedas regaladas (0 si no hubo hito).
func _add_friend_point(neighbor_id: String) -> int:
	var before := int(friend_points.get(neighbor_id, 0))
	var after := mini(Neighbors.MAX_POINTS, before + 1)
	friend_points[neighbor_id] = after
	if before < Neighbors.MILESTONE and after >= Neighbors.MILESTONE:
		coins += Neighbors.MILESTONE_COINS
		return Neighbors.MILESTONE_COINS
	return 0


## Entrar a la casa de un vecino: la primera visita del dia suma 1 punto de amistad.
func friend_visit(neighbor_id: String) -> Dictionary:
	if _visit_blocker(neighbor_id) != "" or friend_done_today(neighbor_id, "visit"):
		return {"ok": false, "pts": 0}
	friend_actions["%s:visit" % neighbor_id] = Missions.today(int(Time.get_unix_time_from_system()))
	note_event("visited")
	pompon.add_social(4.0, false)
	track("visit")
	_first("friend", neighbor_id, str(Neighbors.get_entry(neighbor_id).get("name", "")))
	var bonus := _add_friend_point(neighbor_id)
	save_game()
	return {"ok": true, "pts": 1, "bonus": bonus}


## Una actividad con un vecino. La primera del dia de cada tipo suma 1 punto de amistad (y el regalo
## cuesta monedas); repetirla es gratis y solo se ve la animacion.
## Devuelve {"ok", "msg", "pts" (0 o 1), "bonus" (monedas del hito)}.
func friend_action(neighbor_id: String, key: String) -> Dictionary:
	var act := Neighbors.get_action(key)
	var blocker := _visit_blocker(neighbor_id)
	if blocker != "" or act.is_empty():
		return {"ok": false, "msg": blocker if blocker != "?" else "", "pts": 0}
	if friend_done_today(neighbor_id, key):
		return {"ok": true, "msg": "¡Otra vez!", "pts": 0}
	if coins < act["cost"]:
		return {"ok": false, "msg": "No te alcanzan las monedas.", "pts": 0}
	coins -= act["cost"]
	var now := int(Time.get_unix_time_from_system())
	friend_actions["%s:%s" % [neighbor_id, key]] = Missions.today(now)
	if key == "gift":
		note_event("gifted")
	PomponTastes.bump(pompon, "Energico", 1.5, now)
	PomponTastes.bump(pompon, "Timido", -0.8, now)
	_taste_check()
	pompon.add_social(float(act["amistad"]), false)   # socializar con otro Pompon llena la barra completa
	if act["diversion"] > 0.0:
		pompon.add_stat("diversion", act["diversion"])
	var skill: String = act.get("skill", "")
	if skill != "":
		var news := PomponSkills.add_xp(pompon, skill, Neighbors.SKILL_XP)
		if not news.is_empty():
			pending_thoughts.append(news)
	var bonus := _add_friend_point(neighbor_id)
	var msg := "¡+1 de amistad!"
	if bonus > 0:
		msg += " Tu amigo te regaló %d monedas." % bonus
	save_game()
	return {"ok": true, "msg": msg, "pts": 1, "bonus": bonus}


## Completar la barra "Socializando" (quedarse un rato con el vecino): una vez por dia con cada
## vecino llena al maximo la barra Social de tu Pompon y caen monedas.
func friend_watch_reward(neighbor_id: String) -> int:
	if _visit_blocker(neighbor_id) != "" or friend_done_today(neighbor_id, "watch"):
		return 0
	friend_actions["%s:watch" % neighbor_id] = Missions.today(int(Time.get_unix_time_from_system()))
	pompon.add_social(100.0, false)
	coins += Neighbors.WATCH_COINS
	save_game()
	return Neighbors.WATCH_COINS


## La primera vez que tu Pompon conoce a un vecino hay una presentacion (una sola vez).
func has_met(neighbor_id: String) -> bool:
	return neighbors_met.has(neighbor_id)


func mark_met(neighbor_id: String) -> void:
	if not neighbors_met.has(neighbor_id):
		neighbors_met.append(neighbor_id)
		save_game()


func daily_gift_available() -> bool:
	return pompon != null and Missions.today(int(Time.get_unix_time_from_system())) != daily_gift_day


## Regalo de monedas una vez por dia: 10, y +5 por cada dia seguido (hasta 30). Sin castigo si faltas.
func claim_daily_gift() -> int:
	if not daily_gift_available():
		return 0
	var day := Missions.today(int(Time.get_unix_time_from_system()))
	gift_streak = gift_streak + 1 if day == daily_gift_day + 1 else 1
	daily_gift_day = day
	var amount := 10 + 5 * mini(gift_streak - 1, 4)
	coins += amount
	Audio.play("coin")
	save_game()
	return amount


## Recompensa comun de los minijuegos de inteligencia (+1 Inteligencia y Diversion).
func reward_minigame(earned_coins: int, game := "", ratio := 1.0) -> void:
	var growth_before := PomponGrowth.quality(pompon, int(Time.get_unix_time_from_system())) if pompon != null else 0.0
	coins += earned_coins
	Audio.play("success" if earned_coins > 0 else "fail")
	track("minigame")
	note_event("played")
	PomponTastes.on_game(pompon, game, int(Time.get_unix_time_from_system()))
	if pompon != null:
		for e in PomponSkills.on_game(pompon, game, ratio):
			pending_thoughts.append(e)
		if PomponTastes.GAMES.has(game):  # primera vez que juega a esto (o, cada tanto, otra vez)
			_first("game", game, PomponTastes.GAMES[game])
	_taste_check()
	if pompon != null:
		pompon.add_stat("inteligencia", 1.0)
		var now := int(Time.get_unix_time_from_system())
		last_minigame_gain = PomponGrowth.quality(pompon, now) - growth_before
		minigame_gain_pending = true  # el menu de minijuegos muestra cuanto subio el crecimiento
		pompon.add_stat("diversion", 15.0)
		pompon.add_stat("amor", 3.0)
		pompon.add_social(2.0, true)
	save_game()


func equip(item_id: String) -> void:
	var item := Catalog.get_item(item_id)
	if item.is_empty() or not owned.has(item_id):
		return
	var cat: String = item["category"]
	if Catalog.is_placeable(item_id):
		return  # los muebles se colocan con place_item (Decorar)
	if equipped.get(cat, "") == item_id:
		equipped.erase(cat)  # tocar de nuevo lo quita
	else:
		equipped[cat] = item_id
		PomponTastes.on_item(pompon, item_id, 0.4, int(Time.get_unix_time_from_system()))
		if cat in Catalog.WEARABLE:
			_first("wear", item_id, PomponThoughts._poss(item_id))
		_taste_check()
	save_game()


func has_pompon() -> bool:
	return pompon != null


const CRIB_ID := "furn_crib"


func owns_crib() -> bool:
	return owned.has(CRIB_ID)


## El Pompon sigue siendo un huevo y espera que le compren la cuna.
func egg_waiting() -> bool:
	return pompon != null and not pompon.hatched


## Hace nacer al huevo (al comprarle la cuna). Devuelve false si ya habia nacido.
func hatch_now() -> bool:
	if pompon == null or pompon.hatched:
		return false
	pompon.hatch(int(Time.get_unix_time_from_system()))
	_sync_buddy()
	stage_news = "¡Tu huevo eclosionó!"
	last_stage = 1
	Audio.play("hatch")
	save_game()
	return true


func new_pompon(species := "", sex := "") -> Pompon:
	pompon = Pompon.generate(species, sex)
	last_stage = 0
	farewell = ""
	_ensure_buddy()
	save_game()
	return pompon


# Avisos pendientes para la pantalla de la casa (se consumen al mostrarse).
var farewell := ""      # nota de despedida cuando el Pompon se va
var level_seen := 0   # ultimo nivel del Pompon que ya se festejo (para avisar los items nuevos)


## Nivel del Pompon (un nivel por dia de vida). Sin Pompon o con huevo cuenta como nivel 1.
func pompon_level() -> int:
	if pompon == null or not pompon.hatched:
		return 1
	return maxi(1, pompon.level(int(Time.get_unix_time_from_system())))


var last_minigame_gain := 0.0
var minigame_gain_pending := false   # falta mostrar el "+1 inteligencia" en el menu de minijuegos
var hatch_anim_pending := false   # falta mostrar la animacion del nacimiento (solo en memoria)
var stage_news := ""    # "¡Tu huevo eclosionó!", "Ahora es un Nino!"...
var last_stage := -1
var _paused_at := 0
var _autosave := 20.0
var _stage_check := 0.0


func _process(delta: float) -> void:
	if pompon == null:
		return
	if pompon.advance(delta, Catalog.has_required_furniture(pompon.species, placed_ids())):
		_pompon_abandons()
		return
	_check_stage(delta)
	_autosave -= delta  # la app puede cerrarse en cualquier momento en el celular
	if _autosave <= 0.0:
		_autosave = 20.0
		save_game()


func _check_stage(delta: float) -> void:
	_stage_check -= delta
	if _stage_check > 0.0:
		return
	_stage_check = 1.0
	var idx := pompon.stage_index(int(Time.get_unix_time_from_system()))
	if last_stage >= 0 and idx > last_stage:
		stage_news = "¡Tu huevo eclosionó!" if idx == 1 else "¡Tu Pompon ahora es %s!" % Pompon.STAGES[idx]
		for done_stage in range(maxi(last_stage, 1), idx):  # termina la etapa: palabras y rasgo segun como lo cuidaste
			for e in PomponGrowth.finish_stage(pompon, done_stage, int(Time.get_unix_time_from_system())):
				pending_thoughts.append(e)
	last_stage = idx


func _pompon_abandons() -> void:
	var name := pompon.display_name()
	var species := pompon.species
	pompon = null  # Se conservan monedas, gemas, muebles y ropa.
	farewell = "%s, tu %s, se fue de casa.\n\nDejó una nota:\n\"Gracias por cuidarme. Te quiero mucho. Nos vemos pronto...\"\n\nTe quedan tus monedas, tu ropa y tus muebles." % [name, Pompon.species_label(species).to_lower()]
	save_game()
	pompon_left.emit(farewell)


const BACKUP_PATH := "user://save.json.bak"
const SAVE_VERSION := 2
var tips_seen: Array = []     # guias de primer uso ya mostradas
var cloud_code := ""          # codigo de la partida en la nube ("" = nunca se guardo en la nube)
var cloud_synced_at := ""     # fecha (del servidor) de la ultima vez que se subio o bajo
var save_count := 0           # cuantas veces se guardo en esta sesion (la nube sabe si hubo cambios)
var friend_code := ""         # codigo de amigo (Friends); "" = amigos sin activar
var friend_secret := ""       # clave secreta de este jugador para el servidor de amigos
var friends: Array = []       # amigos aceptados: {"code", "snapshot"} (ultima tarjeta vista)
var friend_requests: Array = []   # solicitudes recibidas que esperan respuesta
var friend_sent: Array = []   # solicitudes enviadas que el otro todavia no acepto


## Guardado seguro: se escribe a un archivo temporal y se conserva una copia de respaldo,
## asi un corte de bateria justo al guardar no deja la partida a medias.
func save_game() -> void:
	save_count += 1
	var data := save_dict()
	var tmp_path := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar la partida.")
		return
	f.store_string(JSON.stringify(data))
	f.close()
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if FileAccess.file_exists(SAVE_PATH):
		dir.copy(SAVE_PATH, BACKUP_PATH)
		dir.remove(SAVE_PATH)
	dir.rename(tmp_path, SAVE_PATH)


## Toda la partida como diccionario (lo que se escribe en el archivo y lo que se sube a la nube).
func save_dict() -> Dictionary:
	last_saved = int(Time.get_unix_time_from_system())
	_store_style()
	return {
		"version": SAVE_VERSION,
		"coins": coins, "gems": gems, "last_saved": last_saved,
		"owned": owned, "equipped": equipped, "placed": placed,
		"room_layout": 2, "current_room": current_room, "room_styles": room_styles, "journal": journal, "events": events, "buddy": buddy,
		"missions_day": missions_day, "mission_progress": mission_progress,
		"missions_claimed": missions_claimed, "pass_xp": pass_xp, "pass_claimed": pass_claimed,
		"farewell": farewell, "last_stage": last_stage, "tips_seen": tips_seen,
		"friend_points": friend_points, "friend_actions": friend_actions, "neighbors_met": neighbors_met,
		"daily_gift_day": daily_gift_day, "gift_streak": gift_streak,
		"jobs_done": jobs_done, "level_seen": level_seen, "player_title": player_title, "player_name": player_name, "math_progress": math_progress, "math_weak": math_weak,
		"cloud_code": cloud_code, "cloud_synced_at": cloud_synced_at,
		"friend_code": friend_code, "friend_secret": friend_secret, "friends": friends,
		"friend_requests": friend_requests, "friend_sent": friend_sent,
		"pompon": pompon.to_dict() if pompon else null,
	}


## Empezar de nuevo: borra la partida guardada (y su respaldo) y deja todo como al instalar el juego.
## La musica y el sonido (ajustes, no progreso) se conservan.
func reset_game() -> void:
	for path in [SAVE_PATH, BACKUP_PATH, SAVE_PATH + ".tmp"]:
		_erase_file(path)
	# los valores iniciales salen de una copia nueva de este script (asi no se olvida ninguna variable)
	var fresh: Node = get_script().new()
	for prop in get_script().get_script_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value = fresh.get(prop["name"])
			set(prop["name"], value.duplicate(true) if value is Array or value is Dictionary else value)
	fresh.free()
	Neighbors.buddy = {}
	Neighbors.current = ""
	Neighbors.set_friends([])
	MathProblems.current_track = "addsub"
	EnglishProblems.current_track = "en_words"
	Jobs.current = "math"


## Lista de amigos guardada: solo entradas con codigo valido y tarjeta.
func _friend_list(list) -> Array:
	var out := []
	if typeof(list) == TYPE_ARRAY:
		for e in list:
			if typeof(e) == TYPE_DICTIONARY and CloudCode.clean_friend(str(e.get("code", ""))) != "":
				var snap = e.get("snapshot", {})
				out.append({"code": str(e["code"]), "snapshot": snap if typeof(snap) == TYPE_DICTIONARY else {}})
	return out


## Borra un archivo de la partida. Si el sistema no deja borrarlo (por ejemplo, un antivirus lo tiene
## abierto), se vacia: un guardado vacio cuenta como "sin partida", asi nunca vuelve la partida vieja.
func _erase_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	DirAccess.remove_absolute(path)
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string("{}")
			f.close()


func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}  # archivo danado: se usara el respaldo
	return json.data if typeof(json.data) == TYPE_DICTIONARY else {}


func load_game() -> void:
	var parsed := _read_save(SAVE_PATH)
	if parsed.is_empty():
		parsed = _read_save(BACKUP_PATH)  # el guardado principal falta o esta danado
	if parsed.is_empty():
		return
	apply_save(parsed)


## Pone en el juego una partida leida (del archivo o bajada de la nube), descartando lo invalido.
func apply_save(parsed: Dictionary) -> void:
	coins = maxi(0, int(parsed.get("coins", 0)))
	gems = maxi(0, int(parsed.get("gems", 0)))
	last_saved = int(parsed.get("last_saved", 0))
	# Se descartan datos invalidos (items que ya no existen, entradas incompletas).
	owned = []
	for id in parsed.get("owned", []):
		if typeof(id) == TYPE_STRING and not Catalog.get_item(id).is_empty() and not owned.has(id):
			owned.append(id)
	equipped = {}
	var saved_equipped = parsed.get("equipped", {})
	if typeof(saved_equipped) == TYPE_DICTIONARY:
		for cat in saved_equipped:
			var id: String = str(saved_equipped[cat])
			if owned.has(id) and not Catalog.is_placeable(id):
				equipped[cat] = id
	placed = []
	journal = []
	for e in parsed.get("journal", []):
		if typeof(e) == TYPE_DICTIONARY and e.has("t") and str(e.get("text", "")) != "" 				and str(e.get("kind", "")) in ["pensamiento", "sentimiento", "frase"]:
			journal.append({"t": int(e["t"]), "kind": str(e["kind"]), "text": str(e["text"]), "stat": str(e.get("stat", ""))})
	while journal.size() > JOURNAL_MAX:
		journal.pop_front()
	events = {}
	var saved_events = parsed.get("events", {})
	if typeof(saved_events) == TYPE_DICTIONARY:
		for k in saved_events:
			events[str(k)] = int(saved_events[k])
	current_room = clampi(int(parsed.get("current_room", 0)), 0, Rooms.count() - 1)
	room_styles = {}
	var saved_styles = parsed.get("room_styles", {})
	if typeof(saved_styles) == TYPE_DICTIONARY:
		for key in saved_styles:
			var st = saved_styles[key]
			if typeof(st) == TYPE_DICTIONARY and str(key).is_valid_int():
				var clean := {}
				for cat in ["wall", "floor"]:
					var sid := str(st.get(cat, ""))
					clean[cat] = sid if sid == "" or Catalog.get_item(sid).get("category", "") == cat else ""
				room_styles[str(key)] = clean
	if not room_styles.has("0"):  # partida anterior a las habitaciones: la sala conserva lo que tenia puesto
		room_styles["0"] = {"wall": str(equipped.get("wall", "")), "floor": str(equipped.get("floor", ""))}
	_apply_style()
	# Partidas anteriores: el cuarto era de una sola pantalla; ahora esa pantalla queda en el centro de la sala.
	var shift_old := int(parsed.get("room_layout", 1)) < 2
	for entry in parsed.get("placed", []):
		if typeof(entry) == TYPE_DICTIONARY and owned.has(entry.get("id", "")) and entry.has("x") and entry.has("y") \
				and Catalog.is_placeable(entry["id"]) and not is_placed(entry["id"]):
			var ex := clampf(float(entry["x"]), 0.0, 1.0)
			if shift_old:
				ex = 0.25 + ex * 0.5
			var loaded := {"id": entry["id"], "x": ex, "y": clampf(float(entry["y"]), 0.0, 1.0),
				"room": clampi(int(entry.get("room", 0)), 0, Rooms.count() - 1)}
			if str(entry.get("on", "")) != "":
				loaded["on"] = str(entry["on"])
				loaded["ox"] = float(entry.get("ox", 0.0))
			placed.append(loaded)
	for p in placed:  # un adorno solo queda "apoyado" si su mueble sigue ahi, en la misma habitacion
		if p.has("on"):
			var support := placed.filter(func(q): return q["id"] == p["on"] and int(q["room"]) == int(p["room"]))
			if support.is_empty() or Catalog.surface_of(p["on"]).is_empty() or not Catalog.is_small(p["id"]):
				p.erase("on")
				p.erase("ox")
	# Partidas anteriores: los muebles ya comprados se colocan solos.
	for id in owned:
		if Catalog.is_placeable(id) and not is_placed(id):
			place_item(id)
	missions_day = int(parsed.get("missions_day", 0))
	mission_progress = parsed.get("mission_progress", {})
	missions_claimed = parsed.get("missions_claimed", [])
	pass_xp = int(parsed.get("pass_xp", 0))
	farewell = str(parsed.get("farewell", ""))
	last_stage = int(parsed.get("last_stage", -1))
	tips_seen = parsed.get("tips_seen", [])
	friend_points = parsed.get("friend_points", {})
	friend_actions = parsed.get("friend_actions", {})
	neighbors_met = []
	var saved_met = parsed.get("neighbors_met", [])
	if typeof(saved_met) == TYPE_ARRAY:
		for id in saved_met:
			neighbors_met.append(str(id))
	daily_gift_day = int(parsed.get("daily_gift_day", 0))
	gift_streak = int(parsed.get("gift_streak", 0))
	jobs_done = int(parsed.get("jobs_done", 0))
	level_seen = int(parsed.get("level_seen", 0))
	var saved_title := str(parsed.get("player_title", ""))
	player_title = saved_title if saved_title in ["f", "m", "n"] else ""
	player_name = clean_player_name(str(parsed.get("player_name", "")))
	cloud_code = CloudCode.clean_code(str(parsed.get("cloud_code", "")))
	cloud_synced_at = str(parsed.get("cloud_synced_at", ""))
	friend_code = CloudCode.clean_friend(str(parsed.get("friend_code", "")))
	friend_secret = str(parsed.get("friend_secret", ""))
	friends = _friend_list(parsed.get("friends", []))
	friend_requests = _friend_list(parsed.get("friend_requests", []))
	friend_sent = _friend_list(parsed.get("friend_sent", []))
	Neighbors.set_friends(friends)
	_load_math(parsed)
	# JSON devuelve numeros como float: normalizamos a int.
	pass_claimed = []
	for t in parsed.get("pass_claimed", []):
		pass_claimed.append(int(t))
	pompon = null
	if typeof(parsed.get("pompon")) == TYPE_DICTIONARY:
		pompon = Pompon.from_dict(parsed["pompon"])
		# Tiempo transcurrido con la app cerrada.
		var away := float(int(Time.get_unix_time_from_system()) - last_saved)
		offline_seconds = int(maxf(away, 0.0))
		if pompon.advance(away, Catalog.has_required_furniture(pompon.species, placed_ids())):
			_pompon_abandons()
		elif not pompon.hatched and owns_crib():
			hatch_now()
	buddy = {}
	var saved_buddy = parsed.get("buddy", {})
	if typeof(saved_buddy) == TYPE_DICTIONARY and str(saved_buddy.get("species", "")) in Pompon.SPECIES and saved_buddy.has("seed"):
		buddy = {"id": "buddy", "name": str(saved_buddy.get("name", "Tobi")), "species": str(saved_buddy["species"]),
			"seed": int(saved_buddy["seed"]), "same_age": true}
	if pompon != null:
		_ensure_buddy()


## Lee el progreso de matematicas del guardado descartando lo que no sea valido.
func _load_math(parsed: Dictionary) -> void:
	math_progress = {}
	math_weak = {}
	var saved = parsed.get("math_progress", {})
	if typeof(saved) == TYPE_DICTIONARY:
		for camino in MathProblems.TRACKS + EnglishProblems.TRACKS:
			if not (saved.has(camino) and typeof(saved[camino]) == TYPE_DICTIONARY):
				continue
			var s: Dictionary = saved[camino]
			var history := []
			for h in s.get("history", []):
				if typeof(h) == TYPE_DICTIONARY and h.has("c") and h.has("t"):
					history.append({"c": bool(h["c"]), "t": float(h["t"])})
			var lessons := []
			for l in s.get("lessons", []):
				lessons.append(int(l))
			math_progress[camino] = {
				"level": clampi(int(s.get("level", 1)), 1, Jobs.problems(Jobs.subject_of(camino)).MAX_LEVEL), "history": history,
				"answered": maxi(0, int(s.get("answered", 0))), "correct": maxi(0, int(s.get("correct", 0))),
				"completed": bool(s.get("completed", false)), "lessons": lessons,
			}
	var weak = parsed.get("math_weak", {})
	if typeof(weak) == TYPE_DICTIONARY:
		for camino in MathProblems.TRACKS:
			var list := []
			for w in weak.get(camino, []):
				if typeof(w) == TYPE_DICTIONARY and w.get("op", "") in ["add", "sub", "mul", "div"] and w.has("a") and w.has("b"):
					list.append({"op": w["op"], "a": int(w["a"]), "b": int(w["b"]), "streak": int(w.get("streak", 0))})
			math_weak[camino] = list
		for camino in EnglishProblems.TRACKS:  # palabras de ingles: solo las que siguen existiendo
			var words := []
			for w in weak.get(camino, []):
				if typeof(w) == TYPE_DICTIONARY and typeof(w.get("key")) == TYPE_STRING and not EnglishProblems.find_item(camino, w["key"]).is_empty():
					words.append({"key": w["key"], "streak": int(w.get("streak", 0))})
			math_weak[camino] = words


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_paused_at = int(Time.get_unix_time_from_system())
			save_game()
		NOTIFICATION_APPLICATION_RESUMED:
			_catch_up_after_pause()
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_game()
		NOTIFICATION_WM_GO_BACK_REQUEST:  # boton "atras" de Android
			_on_back()


## En Android la app pausada no corre _process: aplicamos el tiempo que estuvo en segundo plano.
func _catch_up_after_pause() -> void:
	if _paused_at <= 0 or pompon == null:
		_paused_at = 0
		return
	var away := float(int(Time.get_unix_time_from_system()) - _paused_at)
	_paused_at = 0
	if pompon.advance(away, Catalog.has_required_furniture(pompon.species, placed_ids())):
		_pompon_abandons()


func _on_back() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	match scene.scene_file_path.get_file().get_basename():
		"menu":
			get_tree().quit()
		"home", "intro":
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
		"job_menu":
			get_tree().change_scene_to_file("res://scenes/job_board.tscn")
		"job_game":
			get_tree().change_scene_to_file("res://scenes/job_menu.tscn")
		"math_game", "simon_game", "pattern_game":
			get_tree().change_scene_to_file("res://scenes/minigames.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/home.tscn")
