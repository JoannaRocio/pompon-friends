extends SceneTree
## Progreso de largo plazo (calendario semanal y logros), el aviso semanal en el celular y el tutorial
## guiado por capitulos con el boton resaltado.


func _labels(node: Node) -> String:
	var texts := ""
	for lbl in node.find_children("*", "Label", true, false):
		texts += lbl.text + " | "
	return texts


func _press(node: Node, text: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text.begins_with(text) and b.is_visible_in_tree():
			b.pressed.emit()
			return true
	return false


func _wait_tut(h: Control, secs := 3.0) -> bool:
	var t := 0.0
	while t < secs and h._tut == null:
		await process_frame
		t += 1.0 / 60.0
	return h._tut != null


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var notifier := root.get_node("Notifier")
	var progress: GDScript = load("res://scripts/progress.gd")

	# ---------- calendario semanal: un sello por dia distinto (no hace falta que sean seguidos)
	var monday := (int(Time.get_unix_time_from_system()) / 86400 + 7)   # un dia cualquiera de la semana que viene
	monday += 7 - posmod(monday + 3, 7)   # ... que sea lunes
	gs.week_visits = {"week": -1, "days": [], "claimed": 0}
	gs.days_visited = 0
	gs.last_visit_day = -1
	gs.coins = 0
	for d in [0, 0, 2, 5]:   # lunes (dos veces), miercoles y sabado
		gs.mark_visit((monday + d) * 86400 + 3600)
	print("sellos esta semana: ", gs.week_stamps(), " (lunes, miercoles y sabado) | dias en total: ", gs.days_visited, " | para cobrar: ", gs.week_claimable())
	var got := [gs.claim_week_stamp(), gs.claim_week_stamp(), gs.claim_week_stamp(), gs.claim_week_stamp()]
	print("cobrar: ", got, " (10, 10, 15 y ya no hay mas) | monedas=", gs.coins)
	gs.mark_visit((monday + 7) * 86400 + 3600)
	print("el lunes siguiente empieza otra semana: sellos=", gs.week_stamps(), " cobrados=", gs.week_visits["claimed"], " | dias en total=", gs.days_visited)

	# ---------- logros
	gs.new_pompon("Felino", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.pompon.born_at = int(Time.get_unix_time_from_system()) - 2 * 86400
	gs.jobs_done = 12
	gs.games_played = 3
	gs.movies_seen = {"colina": 1}
	gs.achievements_claimed = {}
	for id in ["jobs", "games", "movies", "days", "growth"]:
		var def: Dictionary = progress.get_def(id)
		print("logro ", def["name"], ": valor=", gs.achievement_value(id), " medallas=", progress.tier_for(def, gs.achievement_value(id)),
			" | ", progress.goal_text(def, progress.next_goal(def, gs.achievement_value(id))), " | para cobrar: ", gs.achievement_claimable(id))
	var c0: int = gs.coins
	print("cobrar Profe estrella (bronce): +", gs.claim_achievement("jobs"), " | otra vez: +", gs.claim_achievement("jobs"), " | monedas +", gs.coins - c0)
	print("algo para cobrar (punto rojo): ", gs.progress_to_claim())

	# ---------- pantalla de Misiones
	var ms: Control = load("res://scenes/missions.tscn").instantiate()
	root.add_child(ms)
	await create_timer(0.3).timeout
	var mt := _labels(ms)
	print("misiones: semana=", mt.contains("Esta semana"), " | logros=", mt.contains("Logros") and mt.contains("Cinéfilo"), " | cobrar sello visible=", ms.find_children("*", "Button", true, false).any(func(b): return b.text.begins_with("Cobrar el sello")))
	ms.queue_free()
	await process_frame

	# ---------- aviso semanal
	var now := int(Time.get_unix_time_from_system())
	var at: int = notifier.fire_time(now)
	var local_hour := posmod(at + int(Time.get_time_zone_from_system().get("bias", 0)) * 60, 86400) / 3600
	print("aviso: dentro de ", snappedf((at - now) / 86400.0, 0.1), " dias, a las ", local_hour, " h")
	gs.notify_on = true
	notifier.schedule(now)
	print("  programado: '", notifier.planned.get("title", ""), "' - '", notifier.planned.get("text", ""), "'")
	notifier.cancel()
	print("  al abrir el juego se cancela: ", notifier.planned.is_empty())
	gs.notify_on = false
	notifier.schedule(now)
	print("  con la campana apagada no se programa: ", notifier.planned.is_empty())
	gs.notify_on = true

	# ---------- tutorial
	gs.tutorial = {"chapter": 0, "step": 0, "off": false, "done_at": 0, "done_day": -1}
	gs.tips_seen = ["egg1", "job1", "shopcrib", "night1"]
	gs.daily_gift_day = Missions.today(now)
	gs.level_seen = 999
	gs.last_stage = 1
	gs.pending_thoughts = []
	DayClock.debug_hour = 12.0
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	print("capitulo 1 (cuidar): aparece=", await _wait_tut(h), " | '", _labels(h._tut._card).substr(0, 70), "'")
	print("  el tutorial tapa los avisos sueltos: ", gs.tips_seen.has("care"))
	_press(h._tut, "¡Entendido!")
	await _wait_tut(h)
	var target: Control = h._tut.target
	print("  paso 2 resalta: ", target.caption if target is ActionButton else target, " | modo=", h._tut.mode)
	target.pressed.emit()   # el jugador toca Caricia
	await _wait_tut(h)
	print("  paso 3 resalta: ", h._tut.target.caption)
	h._tut.target.pressed.emit()   # toca Comer: se abre el menu de comidas
	await create_timer(0.8).timeout
	print("  con el menu de comidas abierto, el tutorial espera: ", h._tut == null)
	h._food_panel.queue_free()
	h._food_panel = null
	await _wait_tut(h)
	print("  paso 4 resalta la tarjeta de necesidades: ", h._tut.target == h.get_node("InfoPanel"))
	_press(h._tut, "¡Entendido!")
	await _wait_tut(h)
	print("  paso 5 resalta el Diario: ", h._tut.target.caption)
	_press(h._tut, "¡Entendido!")
	await create_timer(0.8).timeout
	print("capitulo 1 terminado: capitulo=", gs.tutorial["chapter"], " | el siguiente espera un ratito: ", h._tut == null and not gs.tutorial_ready())
	gs.tutorial["done_at"] = now - 60
	print("capitulo 2 (crecer): ", await _wait_tut(h), " | '", _labels(h._tut._card).substr(0, 90), "' | dibujo de etapas: ", h._tut._card.find_children("*", "Control", true, false).size() > 5)
	_press(h._tut, "¡Entendido!")
	await _wait_tut(h)
	_press(h._tut, "¡Entendido!")
	await create_timer(0.8).timeout
	gs.tutorial["done_at"] = now - 999
	print("capitulo 3 (casa): ", await _wait_tut(h), " | resalta la solapa Casa: ", h._tut.target == h._dock.tab_button(1))
	h._tut.target.pressed.emit()
	await _wait_tut(h)
	print("  despues resalta la Tienda: ", h._tut.target.caption)
	_press(h._tut, "¡Entendido!")
	await _wait_tut(h)
	_press(h._tut, "¡Entendido!")
	await _wait_tut(h)
	h._tut.target.pressed.emit()   # vuelve a la solapa Pompon
	await create_timer(0.8).timeout
	print("capitulo 4 (amigos) espera a otro dia: ", h._tut == null and gs.tutorial_chapter_id() == "amigos" and not gs.tutorial_ready())
	gs.tutorial["done_day"] = Missions.today(now) - 1
	await _wait_tut(h)
	print("  resalta Vecinos: ", h._tut.target.caption)
	h._tut.finish()   # (como si lo tocara: se va a la pantalla de vecinos, que sigue el capitulo)
	h.queue_free()
	await process_frame
	var nb: Control = load("res://scenes/neighbors.tscn").instantiate()
	root.add_child(nb)
	await create_timer(0.5).timeout
	if nb._tut != null:
		print("  en Vecinos resalta la tarjeta de amigos: ", nb._tut.target == nb._friends_card_node, " | '", _labels(nb._tut._card).substr(0, 60), "'")
		_press(nb._tut, "¡Entendido!")
	else:
		print("  en Vecinos: sin servidor de amigos, se saltea")
	await process_frame
	print("  capitulo siguiente: ", gs.tutorial_chapter_id())
	nb.queue_free()
	await process_frame
	# saltar el tutorial
	gs.tutorial["done_at"] = now - 999
	var h2: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h2)
	await _wait_tut(h2)
	_press(h2._tut, "Saltar tutorial")
	await create_timer(0.6).timeout
	print("saltar tutorial: apagado=", gs.tutorial["off"], " | sin cartel: ", h2._tut == null)
	DayClock.debug_hour = -1.0
	h2.queue_free()
	await process_frame
	quit()
