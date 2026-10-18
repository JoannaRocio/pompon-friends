extends SceneTree
## Como se siente el Pompon: frases segun sus necesidades (lo urgente primero), con su nombre y su genero,
## y la casa las muestra bajo la tarjeta de estado cambiando cada tanto.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon("Felino", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.born_at = int(Time.get_unix_time_from_system()) - 90 * 86400
	gs.pompon.nickname = "Tofu"
	var mood: GDScript = load("res://scripts/pompon_mood.gd")
	var p: Pompon = gs.pompon
	for s in p.stats:
		p.stats[s] = 90.0
	p.stats["diversion"] = 40.0
	var msgs: Array = mood.messages(p)
	print("aburrida (hembra): ", msgs[0]["text"], " | nivel=", msgs[0]["level"])
	p.sex = "Macho"
	print("aburrido (macho): ", mood.messages(p)[0]["text"])
	p.stats["alimentacion"] = 10.0
	var urgent: Array = mood.messages(p)
	print("lo urgente va primero: ", urgent[0]["text"], " | stat=", urgent[0]["stat"])
	var rot: Array = mood.rotation(p)
	print("rotacion: ", rot.map(func(m): return m["text"]))
	for s in p.stats:
		p.stats[s] = 95.0
	p.stats["amor"] = 90.0
	var happy: Array = mood.messages(p)
	print("todo bien: ", happy.size(), " frases | todas positivas=", happy.all(func(m): return m["level"] == 0), " | ej: ", happy[0]["text"])
	print("frases con el nombre: ", happy.all(func(m): return m["text"].begins_with("Tofu")))

	# en la casa
	gs.daily_gift_day = int(Time.get_unix_time_from_system()) / 86400
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends"]
	p.stats["diversion"] = 40.0
	p.stats["amor"] = 20.0
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(1.0).timeout
	h._offline_checked = true
	h._thought_timer = 9999.0
	print("al abrir con amor muy bajo ya lo dice (1 mensaje): visible=", h._mood_pill.visible)
	gs.journal = []
	# una necesidad urgente se dice sola (una vez), queda en el diario y se ve en la pildora
	p.stats["diversion"] = 10.0
	h._stat_check = 0.0
	await create_timer(1.0).timeout
	print("lo urgente se anota en el diario: entradas=", gs.journal.size(), " | '", h._mood_label.text, "' visible=", h._mood_pill.visible)
	var before: int = gs.journal.size()
	h._stat_check = 0.0
	await create_timer(1.0).timeout
	print("no se repite enseguida: ", gs.journal.size() == before)
	# la pildora desaparece sola
	h._pill_left = 0.0
	await create_timer(0.3).timeout
	print("la pildora se va sola: visible=", h._mood_pill.visible)
	# cuidarlo a veces genera una reaccion, siempre respetando el intervalo minimo
	var n0: int = gs.journal.size()
	for i in 6:
		h._react("fed", 1.0)
	print("las reacciones no inundan el diario: nuevas=", gs.journal.size() - n0, " (maximo 1)")
	h._show_journal()
	await create_timer(0.4).timeout
	print("el diario se abre: ", h._journal_panel != null)
	quit()
