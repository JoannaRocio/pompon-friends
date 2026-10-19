extends SceneTree
## El cine: tres peliculas (terror, romantica y accion) que rotan cada semana, la boleteria (esta
## semana, la proxima, con quien ir), la entrada,
## la pelicula en escenas (tocar pasa, "Saltar" termina) y el final con la opinion de tu Pompon.


func _labels(node: Node) -> String:
	var texts := ""
	for lbl in node.find_children("*", "Label", true, false):
		texts += lbl.text + " | "
	return texts


func _press(node: Node, text: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text.begins_with(text):
			b.pressed.emit()
			return true
	return false


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var movies: GDScript = load("res://scripts/movies.gd")
	var today: int = Missions.today(int(Time.get_unix_time_from_system()))
	var week: Array = []
	var monday: int = today + movies.days_left(today)   # el proximo cambio
	for wk in 4:
		week.append(movies.of_day(monday + wk * 7)["title"])
	print("cartelera de 4 semanas: ", week, " | 3 distintas y vuelve a empezar: ", week[0] != week[1] and week[1] != week[2] and week[3] == week[0])
	var same_week := true
	for d in 7:
		same_week = same_week and movies.of_day(monday + d)["id"] == movies.of_day(monday)["id"]
	print("toda la semana la misma (de lunes a domingo): ", same_week, " | cambia el lunes siguiente: ", movies.of_day(monday + 7)["id"] != movies.of_day(monday)["id"],
		" | el dia antes del cambio es otra: ", movies.of_day(monday - 1)["id"] != movies.of_day(monday)["id"])
	for m in movies.MOVIES:
		print("  ", m["genre"], " - ", m["title"], ": ", m["scenes"].size(), " escenas | mensaje: '", m["message"], "' | termina con FIN: ", String(m["scenes"][-1]["text"]).ends_with("FIN"))

	gs.new_pompon("Felino", "Hembra")
	var p: Pompon = gs.pompon
	p.hatched = true
	p.nickname = "Mochi"
	p.born_at = int(Time.get_unix_time_from_system()) - 20 * 86400
	p.stats["diversion"] = 30.0
	gs.coins = 5
	gs.movies_seen = {}
	gs.pending_thoughts = []

	var cine: Control = load("res://scenes/cinema.tscn").instantiate()
	root.add_child(cine)
	await create_timer(0.3).timeout
	var t := _labels(cine)
	print("boleteria: ", t.contains("Cine Pompon"), " | hoy: ", t.contains(cine.movie["title"]), " | proxima: ", t.contains("Próxima: " + movies.next_of(today)["title"]),
		" | con quien: ", cine._companion_buttons.size(), " opciones")
	_press(cine, "Ver la película")
	await process_frame
	print("sin monedas: ", cine.state, " | aviso: ", _labels(cine._layer).contains("Te faltan monedas"))
	cine._layer.close()
	await process_frame
	gs.coins = 100
	var buddy: Dictionary = Neighbors.all()[0]
	cine._pick_companion(buddy)
	_press(cine, "Ver la película")
	await create_timer(0.3).timeout
	print("entrada: monedas=", gs.coins, " (100 - ", movies.TICKET, ") | en la sala: ", cine.state, " | subtitulo: '", cine._subtitle.text, "'")
	print("  invitado en la butaca: ", cine._buddy != null, " | pochoclos: ", cine.get_node_or_null("Popcorn") != null)
	var shown := [cine.screen.scene_i]
	for i in 3:
		cine.next_scene()
		await process_frame
		shown.append(cine.screen.scene_i)
	print("tocar la pantalla pasa de escena: ", shown)
	await create_timer(movies.scene_seconds(cine._subtitle.text) + 0.3).timeout
	print("sola pasa a la siguiente: escena ", cine.screen.scene_i)
	_press(cine, "Saltar")
	await process_frame
	var end := _labels(cine._layer)
	print("saltar -> final: ", cine.state, " | '", end.substr(0, 160), "'")
	print("vista: ", gs.movies_seen, " | diversion ", p.stats["diversion"], " (subio) | al diario: ", gs.pending_thoughts.map(func(e): return e["text"]))
	_press(cine._layer, "Boletería")
	await create_timer(0.2).timeout
	print("de vuelta en la boleteria dice que ya la vio: ", _labels(cine).contains("Ya la viste 1 vez"))
	cine.queue_free()
	await process_frame

	# todas las escenas de las tres peliculas se dibujan sin errores
	var screen: Control = load("res://scripts/movie_screen.gd").new()
	screen.size = Vector2(588, 470)
	root.add_child(screen)
	var count := 0
	for m in movies.MOVIES:
		screen.setup(m)
		for i in m["scenes"].size():
			screen.show_scene(i)
			screen.t = 2.0
			await process_frame
			count += 1
	print("escenas dibujadas: ", count)
	quit()
