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
	gs.reset_game()
	gs.set_language("")
	quit()
