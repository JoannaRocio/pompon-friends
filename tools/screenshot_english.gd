extends SceneTree
## Herramienta de desarrollo: capturas de las pantallas de entrada en inglés (menú, bienvenida, especie,
## sexo, edad, nombre y la casa con el tutorial). Guarda en docs/capturas/ingles/.
## OJO: cambia la partida local (respaldar user://save.json* antes y restaurar despues).
## Uso (con ventana): Godot_*win64.exe --path . --resolution 720x1280 --script tools/screenshot_english.gd

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
	out_dir = ProjectSettings.globalize_path("res://docs/capturas/ingles")
	DirAccess.make_dir_recursive_absolute(out_dir)
	sv = SubViewport.new()
	sv.size = Vector2i(720, 1280)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	gs.reset_game()
	gs.set_language("en")

	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	_add(menu)
	await _shot("1-menu.png", 1.6)
	menu._on_play()
	await _shot("2-edad.png")
	for b in menu.find_children("*", "Button", true, false):
		if b.text == "18 or older":
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
				if game.find_children("*", "Label", true, false).any(func(l): return l.text == "End of shift!"):
					break
				game._next_step()
				await process_frame
			await _shot("17-nota.png")
		await _clear()
	gs.reset_game()
	gs.set_language("")
	quit()
