extends SceneTree
## Herramienta de desarrollo: recorrido de UX por todas las pantallas (menú, bienvenida, casa, tienda,
## vestidor, trabajo, diario, minijuegos, misiones, vecinos, pueblo, cine). Idioma y carpeta por argumento.
## OJO: cambia la partida local (respaldar user://save.json* antes y restaurar despues).
## Uso (con ventana): Godot_*win64.exe --path . --resolution 720x1280 --script tools/screenshot_ux.gd -- <carpeta> [es|en]

var gs: Node
var sv: SubViewport   # 720x1280 aunque la pantalla de la PC sea mas baja
var out_dir := ""


func _shot(file: String, wait := 0.8) -> void:
	await create_timer(wait).timeout
	var img := sv.get_texture().get_image()
	var path := out_dir.path_join(file)
	print("guardado: ", path, " -> ", img.save_png(path), " ", img.get_size())


func _add(scene: Control) -> void:
	scene.theme = root.theme   # (un SubViewport no hereda el tema de la ventana)
	sv.add_child(scene)


func _clear() -> void:
	for c in sv.get_children():
		c.queue_free()
	await process_frame


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://docs/capturas/ux")
	var lang: String = args[1] if args.size() > 1 else "es"
	DirAccess.make_dir_recursive_absolute(out_dir)
	sv = SubViewport.new()
	sv.size = Vector2i(720, 1280)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	gs.reset_game()
	gs.set_language(lang)

	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	_add(menu)
	await _shot("1-menu.png", 1.6)
	menu._on_play()
	await _shot("2-edad.png")
	for b in menu.find_children("*", "Button", true, false):
		if b.text == "18 or older" or b.text == "18 o más" or b.text == "18 años o más":
			b.pressed.emit()
	await process_frame
	menu._profile.accepted.disconnect(menu._enter_game)
	await _shot("3-nombre.png")
	await _clear()

	gs.set_profile("Ana", "f")
	var w: Control = load("res://scenes/welcome.tscn").instantiate()
	_add(w)
	await _shot("4-bienvenida.png", 1.2)
	w._choose_species()
	await _shot("5-especie.png")
	w._pick_species("Conejo")
	await _shot("6-sexo.png")
	await _clear()

	var now := int(Time.get_unix_time_from_system())
	gs.age_group = "adult"
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.color_primary = Color("ffb3cc")
	gs.pompon.color_secondary = Color("fff0f5")
	gs.pompon.born_at = now - 3600
	gs.pompon.nickname = "Mochi"
	gs.hatch_anim_pending = false
	gs.daily_gift_day = Missions.today(now)
	gs.tips_seen = ["egg1", "job1", "shopcrib", "notify_ask"]
	var h: Control = load("res://scenes/home.tscn").instantiate()
	_add(h)
	await _shot("7-casa-tutorial.png", 2.2)
	await _clear()

	# tienda, vestidor y comida
	gs.tutorial = {"chapter": 0, "step": 0, "off": true, "done_at": 0, "done_day": -1}
	gs.pompon.born_at = now - 4 * 86400
	gs.coins = 40
	gs.owned = ["hat_bow", "shirt_dress", "furn_sofa", "wall_stars", "glasses_round"]
	gs.equipped = {"hat": "hat_bow", "shirt": "shirt_dress", "wall": "wall_stars"}
	var shop: Control = load("res://scenes/shop.tscn").instantiate()
	_add(shop)
	await _shot("8-tienda.png", 1.0)
	shop._filter = "special"
	shop._rebuild()
	await _shot("9-tienda-especial.png")
	await _clear()
	var wd: Control = load("res://scenes/wardrobe.tscn").instantiate()
	_add(wd)
	await _shot("10-vestidor.png", 1.0)
	await _clear()
	var h2: Control = load("res://scenes/home.tscn").instantiate()
	_add(h2)
	await create_timer(1.0).timeout
	h2._show_food_menu()
	await _shot("11-comida.png")
	await _clear()

	# trabajo: periodico, aula, examen de geografia y de matematicas, y la nota
	gs.jobs_done = 3
	gs.tips_seen.append_array(["job_intro", "job_hired", "job_first_shift"])
	var board: Control = load("res://scenes/job_board.tscn").instantiate()
	_add(board)
	await _shot("12-periodico.png", 1.0)
	await _clear()
	Jobs.current = "math"
	var office: Control = load("res://scenes/job_menu.tscn").instantiate()
	_add(office)
	await _shot("13-aula.png", 1.0)
	office._show_lesson("mul", 2)
	await _shot("14-leccion.png")
	await _clear()
	for subject in ["geography", "math"]:
		Jobs.current = subject
		Jobs.set_track("geo_capitals" if subject == "geography" else "addsub")
		var game: Control = load("res://scenes/job_game.tscn").instantiate()
		_add(game)
		await create_timer(0.6).timeout
		game._close_layer()
		game.state = game.State.PLAY
		game._open_question()
		await _shot("15-examen-geografia.png" if subject == "geography" else "16-examen-matematicas.png")
		if subject == "math":
			game._close_layer()
			game.correct = 4
			game.questions_done = 5
			game._finish(true)
			await create_timer(0.4).timeout
			for i in 4:
				if game.find_children("*", "Label", true, false).any(func(l): return l.text == "End of shift!" or l.text == "¡Fin del turno!"):
					break
				game._next_step()
				await process_frame
			await _shot("17-nota.png")
		await _clear()

	# clase de Español (la materia de idiomas cuando se juega en inglés)
	Jobs.current = "english"
	var es_office: Control = load("res://scenes/job_menu.tscn").instantiate()
	_add(es_office)
	await _shot("18-aula-espanol.png", 1.0)
	await _clear()
	for track in ["es_words", "es_meaning"]:
		Jobs.set_track(track)
		var es_game: Control = load("res://scenes/job_game.tscn").instantiate()
		_add(es_game)
		await create_timer(0.6).timeout
		es_game._close_layer()
		es_game.state = es_game.State.PLAY
		es_game._open_question()
		await _shot("19-examen-espanol.png" if track == "es_words" else "20-examen-espanol-significado.png")
		await _clear()
	Jobs.current = "math"

	# diario, ficha y album (con frases generadas en inglés)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	gs.tutorial = {"chapter": 0, "step": 0, "off": true, "done_at": 0, "done_day": -1}
	gs.pompon.born_at = now - 5 * 86400
	gs.journal = []
	var ctx := {"now": now, "hour": 15.0, "room": 0, "items": ["furn_sofa", "furn_piano"], "equipped": {"hat": "hat_bow"},
		"events": {"fed": now - 30, "played": now - 30}, "jobs_done": 4, "level": 5}
	for i in 7:
		var e: Dictionary = PomponThoughts.spontaneous(gs.pompon, ctx, gs.recent_journal_texts(14), rng)
		if not e.is_empty():
			e["t"] = now - (7 - i) * 900
			gs.journal.append(e)
	var fe: Dictionary = PomponFirsts.experience(gs.pompon, "bath", "", "", now, rng)
	fe["t"] = now - 60
	gs.journal.append(fe)
	var hd: Control = load("res://scenes/home.tscn").instantiate()
	_add(hd)
	await create_timer(1.0).timeout
	await _shot("21-casa.png")
	hd._dock.show_tab(1)
	await _shot("21b-casa-solapa-casa.png", 0.5)
	hd._set_edit(true)
	await _shot("21c-decorar.png", 0.6)
	hd._set_edit(false)
	hd._dock.show_tab(0)
	hd._show_journal()
	await _shot("22-diario.png")
	hd._journal_panel.queue_free()
	hd._journal_panel = null
	hd._show_profile()
	await _shot("23-ficha.png")
	hd._profile_panel.queue_free()
	hd._profile_panel = null
	hd._show_album()
	await _shot("24-album.png")
	await _clear()

	# minijuegos, misiones, vecinos, visita, pueblo y cine
	gs.coins = 120
	gs.tips_seen.append("town1")
	var shots := [["minigames", "25-minijuegos.png"], ["missions", "26-misiones.png"], ["neighbors", "27-vecinos.png"],
		["town", "29-pueblo.png"], ["cinema", "30-cine.png"]]
	for pair in shots:
		var sc: Control = load("res://scenes/%s.tscn" % pair[0]).instantiate()
		_add(sc)
		await _shot(pair[1], 1.6)
		if pair[0] == "cinema":
			sc._start_movie()
			await create_timer(0.4).timeout
			sc._show_scene(2)
			await _shot("31-pelicula.png", 0.8)
		await _clear()
		if pair[0] == "neighbors":
			Neighbors.current = "luna"
			var vs: Control = load("res://scenes/visit.tscn").instantiate()
			_add(vs)
			await _shot("28-visita.png", 2.5)
			await _clear()
	for g in ["math_game", "simon_game", "pattern_game", "jump_game", "paint_game", "music_game"]:
		var mg: Control = load("res://scenes/%s.tscn" % g).instantiate()
		_add(mg)
		await _shot("40-%s.png" % g, 1.8)
		await _clear()
	var mn: Control = load("res://scenes/menu.tscn").instantiate()
	_add(mn)
	await _shot("41-menu-con-partida.png", 1.6)
	mn._open_cloud()
	await _shot("42-nube.png", 0.8)
	await _clear()
	gs.reset_game()
	gs.set_language("")
	quit()
