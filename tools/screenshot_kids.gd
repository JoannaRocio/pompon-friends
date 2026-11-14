extends SceneTree
## Herramienta de desarrollo: capturas de la edad al empezar y de las grillas de nombres para menores
## de 13 (jugador, Pompon recien nacido y el cartel de partidas viejas). Guarda en docs/capturas/edad/.
## OJO: cambia la partida local (respaldar user://save.json* antes y restaurar despues).
## Uso (con ventana): Godot_*win64.exe --path . --resolution 720x1280 --script tools/screenshot_kids.gd

var gs: Node
var out_dir := ""
var sv: SubViewport   # 720x1280 aunque la pantalla de la PC sea mas baja


func _shot(file: String) -> void:
	await create_timer(0.7).timeout
	var img := sv.get_texture().get_image()
	var path := out_dir.path_join(file)
	print("guardado: ", path, " -> ", img.save_png(path), " ", img.get_size())


func _clear() -> void:
	for c in sv.get_children():
		if c is Control:
			c.queue_free()
	await process_frame


func _add(scene: Control) -> void:
	scene.theme = root.theme   # (un SubViewport no hereda el tema de la ventana)
	sv.add_child(scene)


func _press(node: Node, text: String) -> void:
	for b in node.find_children("*", "Button", true, false):
		if b.text == text:
			if b.toggle_mode:
				b.button_pressed = true
			b.pressed.emit()
			return


func _notice(parent: Node) -> Node:
	var found: Node = null
	for c in parent.get_children():
		if c is BigNotice and not c.is_queued_for_deletion():
			found = c
	return found


func _pompon(nickname: String) -> void:
	var now := int(Time.get_unix_time_from_system())
	gs.new_pompon("Conejo", "Hembra")
	var p = gs.pompon
	p.hatched = true
	p.color_primary = Color("ffb3cc")
	p.color_secondary = Color("fff0f5")
	p.born_at = now - 2 * 86400
	p.nickname = nickname
	gs.hatch_anim_pending = false
	gs.daily_gift_day = Missions.today(now)
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends", "growth", "night1", "notify_ask"]
	gs.tutorial = {"chapter": 0, "step": 0, "off": true, "done_at": 0, "done_day": -1}


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	out_dir = ProjectSettings.globalize_path("res://docs/capturas/edad")
	DirAccess.make_dir_recursive_absolute(out_dir)
	sv = SubViewport.new()
	sv.size = Vector2i(720, 1280)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)

	# 1) partida nueva: la edad, antes del nombre
	gs.reset_game()
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	_add(menu)
	await create_timer(0.5).timeout
	menu._on_play()
	await _shot("1-edad.png")

	# 2) menor de 13: ¿Cómo te llamas? con la grilla (sin teclado)
	_press(_notice(menu), "9")
	await process_frame
	menu._profile.accepted.disconnect(menu._enter_game)
	var picker = menu._profile.find_children("*", "NamePicker", true, false)[0]
	picker.pick(picker.visible_names()[4])
	_press(menu._profile, "Soy ella")
	await _shot("2-nombre-jugador-grilla.png")
	_press(picker, "Ver otros")
	await _shot("3-nombre-jugador-ver-otros.png")
	await _clear()

	# 3) el Pompon nacio: nombre de la grilla
	gs.reset_game()
	gs.age_group = "child"
	gs.set_profile("Canela", "f")
	_pompon("")
	var h: Control = load("res://scenes/home.tscn").instantiate()
	_add(h)
	await create_timer(0.6).timeout
	if h._name_panel:
		var pk = h._name_panel.find_children("*", "NamePicker", true, false)[0]
		pk.pick(pk.visible_names()[1])
	await _shot("4-nombre-pompon-grilla.png")
	await _clear()

	# 4) partida vieja sin edad: pregunta en la casa y, si es menor, cartel de nombres nuevos
	gs.reset_game()
	gs.set_profile("Joaquina", "f")
	_pompon("Firulais")
	var hv: Control = load("res://scenes/home.tscn").instantiate()
	_add(hv)
	await create_timer(0.6).timeout
	await _shot("5-partida-vieja-edad.png")
	_press(_notice(hv), "8")
	await create_timer(0.4).timeout
	await _shot("6-partida-vieja-nombres-nuevos.png")
	_press(_notice(hv), "Elegir")
	await create_timer(0.3).timeout
	var pdlg = hv._kid_layer
	var pk2 = pdlg.find_children("*", "NamePicker", true, false)[0]
	pk2.pick(pk2.visible_names()[0])
	pdlg._accept()
	await create_timer(0.3).timeout
	if hv._name_panel:
		var pk3 = hv._name_panel.find_children("*", "NamePicker", true, false)[0]
		pk3.pick(pk3.visible_names()[6])
	await _shot("7-partida-vieja-nombre-pompon.png")

	# 5) adulto: igual que antes (con teclado)
	await _clear()
	gs.reset_game()
	gs.age_group = "adult"
	var menu2: Control = load("res://scenes/menu.tscn").instantiate()
	_add(menu2)
	await create_timer(0.5).timeout
	menu2._on_play()
	await process_frame
	menu2._profile.accepted.disconnect(menu2._enter_game)
	await _shot("8-adulto-con-teclado.png")
	gs.reset_game()
	quit()
