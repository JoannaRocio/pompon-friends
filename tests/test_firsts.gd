extends SceneTree
## Primeras veces en el diario: la primera siempre se anota; las repeticiones de vez en cuando.


func _texts(list: Array) -> Array:
	return list.map(func(e): return str(e.get("text", "")))


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	var p: Pompon = gs.pompon
	p.hatched = true
	p.nickname = "Mochi"
	p.born_at = int(Time.get_unix_time_from_system()) - 10 * 86400
	var firsts: GDScript = load("res://scripts/pompon_firsts.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var now := int(Time.get_unix_time_from_system())

	# la primera vez siempre; despues, con pausa y cada vez menos
	var e1: Dictionary = firsts.experience(p, "bath", "", "", now, rng)
	print("primer baño: '", e1.get("text", ""), "'")
	var e2: Dictionary = firsts.experience(p, "bath", "", "", now + 10, rng)
	print("segundo baño enseguida (sin pausa): ", e2.is_empty())
	var shown := 0
	for i in 200:
		var t := now + 1000 * (i + 1)
		if not firsts.experience(p, "bath", "", "", t, rng).is_empty():
			shown += 1
	print("baños 3 a 202 (con pausa): anotados ", shown, " de 200 (pocos, al azar)")
	print("veces contadas: ", firsts.times(p, "bath"), " (esperado 202)")
	var r1: Dictionary = firsts.experience(p, "room", "2", "la cocina", now, rng)
	var r2: Dictionary = firsts.experience(p, "room", "2", "la cocina", now + 99999, rng)
	print("habitacion: primera='", r1.get("text", ""), "' | otra vez nunca: ", r2.is_empty())

	# cada cosa nueva, aunque sea seguida, se anota siempre
	var news := []
	for food in ["papa", "pizza", "helado"]:
		news.append(firsts.experience(p, "food", food, food, now, rng, 1))
	print("tres comidas nuevas seguidas: ", _texts(news))

	# enganches del juego: minijuego, ropa, habitacion, vecino
	gs.pending_thoughts = []
	gs.owned = ["hat_bow"]
	gs.equipped = {}
	gs.reward_minigame(0, "simon", 1.0)
	gs.equip("hat_bow")
	p.born_at = int(Time.get_unix_time_from_system()) - 60 * 86400   # nivel alto: todas las habitaciones abiertas
	gs.set_room(1)
	gs.friend_actions = {}
	gs.friend_visit("luna")
	var firsts_in_queue: Array = gs.pending_thoughts.filter(func(e): return str(e.get("key", "")).begins_with("first:"))
	print("en la cola del diario: ", _texts(firsts_in_queue))

	# en la casa: comer algo por primera vez y bañarse
	gs.pending_thoughts = []
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.5).timeout
	gs.journal = []
	var tastes: GDScript = load("res://scripts/pompon_tastes.gd")
	h._on_food(tastes.FOODS[1])
	h._on_action("Beber")
	var j: Array = _texts(gs.journal) + _texts(gs.pending_thoughts)
	print("diario tras comer pan y beber: ", j)
	quit()
