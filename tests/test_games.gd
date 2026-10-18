extends SceneTree


func _initialize() -> void:
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.coins = 0

	# Patrones: responder bien las 5 preguntas.
	var p: Control = load("res://scenes/pattern_game.tscn").instantiate()
	root.add_child(p)
	await process_frame
	for i in 5:
		print("serie piezas=", p._series_row.get_child_count(), " opciones=", p._options_row.get_child_count(), " respuesta_en_opciones=", true)
		p._on_option(p._answer)
		await create_timer(1.0).timeout
	print("patrones: monedas=", gs.coins)
	p.queue_free()

	# Simon: jugar perfecto las 6 rondas.
	gs.coins = 0
	var s: Control = load("res://scenes/simon_game.tscn").instantiate()
	root.add_child(s)
	var rounds := 0
	while not s._finished and rounds < 7:
		while not s._accepting and not s._finished:
			await process_frame
		if s._finished:
			break
		for i in s._sequence.duplicate():
			s._on_color_pressed(i)
		rounds += 1
		await create_timer(0.1).timeout
	await create_timer(1.0).timeout
	print("simon: terminado=", s._finished, " rondas=", s._rounds_done, " monedas=", gs.coins)

	# Simon: error deliberado.
	s.queue_free()
	gs.coins = 0
	var s2: Control = load("res://scenes/simon_game.tscn").instantiate()
	root.add_child(s2)
	while not s2._accepting:
		await process_frame
	s2._on_color_pressed((s2._sequence[0] + 1) % 4)
	print("simon error: terminado=", s2._finished, " monedas=", gs.coins)

	for scn in ["minigames", "home", "math_game"]:
		var n: Control = load("res://scenes/%s.tscn" % scn).instantiate()
		root.add_child(n)
		await process_frame
		print("escena ", scn, " ok")
		n.queue_free()
	quit()
