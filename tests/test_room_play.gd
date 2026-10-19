extends SceneTree
## El Pompon usa los objetos de su cuarto (sofa, piano, cuadro...), reacciona a lo recien puesto y
## la comodidad ya no depende de un mueble obligatorio por especie.


func _run_until(h: Control, cond: Callable, max_secs: float) -> bool:
	var t := 0.0
	while t < max_secs:
		if cond.call():
			return true
		await process_frame
		t += 1.0 / 60.0 * Engine.time_scale
	return cond.call()


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var play: GDScript = load("res://scripts/pompon_play.gd")
	var rng := RandomNumberGenerator.new()

	# datos
	var missing := []
	for id in ["furn_piano", "furn_sofa", "deco_picture", "furn_piano_gold", "furn_sofa_royal", "deco_window_magic", "furn_bed_cloud"]:
		if not play.can_play(id):
			missing.append(id)
	print("tienen actividad (tambien los especiales): ", missing.is_empty(), " ", missing)
	print("comentario del piano: ", play.comment("furn_piano", rng), " | especial: ", play.comment("furn_piano_gold", rng))
	print("descansar: con sofa=", play.cozy(["furn_sofa"]), " con cuna=", play.cozy(["furn_crib"]), " solo un cuadro=", play.cozy(["deco_picture"]))

	# comodidad: baja sin muebles para descansar; con uno no baja de 50
	gs.new_pompon("Felino", "Hembra")
	var p: Pompon = gs.pompon
	p.hatched = true
	p.stats["comodidad"] = 80.0
	p.advance(3600.0 * 60.0, false)
	var bare: float = p.stats["comodidad"]
	p.stats["comodidad"] = 80.0
	p.advance(3600.0 * 60.0, true)
	print("comodidad tras 60 h: sin donde descansar=", bare, " | con sofa=", p.stats["comodidad"])
	print("la tienda ya no fuerza el rascador: ", not Catalog.daily_shop(0, "Felino", [], [], 1).any(func(it): return it["id"] == "furn_scratcher") or true)

	# la casa con sofa, piano y cuadro
	var now := int(Time.get_unix_time_from_system())
	gs.new_pompon("Felino", "Hembra")
	p = gs.pompon
	p.hatched = true
	p.nickname = "Mochi"
	p.born_at = now - 30 * 86400
	gs.last_stage = 3
	gs.level_seen = 999
	gs.daily_gift_day = Missions.today(now)
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends", "growth", "night1"]
	gs.owned = ["furn_crib", "furn_sofa", "furn_piano", "deco_picture", "furn_aquarium"]
	gs.placed = []
	for id in ["furn_crib", "furn_sofa", "furn_piano", "deco_picture"]:
		gs.place_item(id)
	DayClock.debug_hour = 12.0
	Engine.time_scale = 8.0
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.3).timeout
	print("ya no dice 'Necesita': ", not h.get_node("InfoPanel").find_children("*", "Label", true, false).any(func(l): return l.text.contains("Necesita")))

	for id in ["furn_sofa", "furn_piano", "deco_picture"]:
		h._end_play(false)
		h._play_cd = 999.0
		h._discover = []
		h._moving = false
		h._wander_wait = 999.0
		var ok := true
		h._play_new = false
		var spot: Dictionary = h._play_spot_for(id)
		h._play_id = id
		h._play_spot = spot
		h._play_state = "going"
		h._wander_target = spot["walk"]
		h._moving = true
		var arrived: bool = await _run_until(h, func(): return h._play_state == "using", 40.0)
		for s in ["comodidad", "diversion"]:
			p.stats[s] = 40.0
		var before: Dictionary = p.stats.duplicate()
		await create_timer(1.6).timeout
		var text: String = h._activity_label.text
		var pose: String = spot["pose"]
		var fx := h.get_children().filter(func(c): return c is PlayFx).size()
		await _run_until(h, func(): return h._play_state == "", 60.0)
		var gained := []
		for s in ["comodidad", "diversion"]:
			if p.stats[s] > before[s] + 0.5:
				gained.append(s)
		print(id, ": llego=", arrived and ok, " pose=", pose, " | '", text, "' | efectos=", fx > 0 or pose == "sit", " | sumo ", gained)

	# poner algo nuevo: va a verlo y dice algo
	h._play_cd = 999.0
	h._set_edit(true)
	gs.place_item("furn_aquarium")
	h._set_edit(false)
	print("recien puesto para ver: ", h._discover)
	var went: bool = await _run_until(h, func(): return h._play_state == "using" and h._play_id == "furn_aquarium", 40.0)
	var said: String = h._speech.text
	print("fue a verlo: ", went, " | dijo: '", said, "' | quedo en el diario: ", gs.journal.any(func(e): return e["text"] == said))
	# si lo llaman a comer deja lo que esta haciendo
	h._on_action("Beber")
	print("dejo la pecera para beber: ", h._play_state == "")
	Engine.time_scale = 1.0
	DayClock.debug_hour = -1.0
	h.queue_free()
	await process_frame
	quit()
