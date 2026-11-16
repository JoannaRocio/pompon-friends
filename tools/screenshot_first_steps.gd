extends SceneTree
## Herramienta de desarrollo: capturas de los primeros pasos (elegir idioma, edad y nombre con "Volver",
## bienvenida con la flechita). Guarda en docs/capturas/primeros_pasos/.
## OJO: cambia la partida local (respaldar user://save.json* antes y restaurar despues).
## Uso (con ventana): Godot_*win64.exe --path . --resolution 720x1280 --script tools/screenshot_first_steps.gd

var gs: Node
var out_dir := ""
var sv: SubViewport


func _shot(file: String) -> void:
	await create_timer(0.8).timeout
	var img := sv.get_texture().get_image()
	var path := out_dir.path_join(file)
	print("guardado: ", path, " -> ", img.save_png(path))


func _press(node: Node, text: String) -> void:
	for b in node.find_children("*", "Button", true, false):
		if b.text == text and not b.is_queued_for_deletion():
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


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	var t: GDScript = load("res://scripts/t.gd")
	out_dir = ProjectSettings.globalize_path("res://docs/capturas/primeros_pasos")
	DirAccess.make_dir_recursive_absolute(out_dir)
	sv = SubViewport.new()
	sv.size = Vector2i(720, 1280)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)

	gs.reset_game()
	gs.language = ""
	gs.age_group = ""
	t.apply("es")
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	menu.theme = root.theme
	sv.add_child(menu)
	await create_timer(1.6).timeout
	menu.ask_language()
	await _shot("1_idioma_es.png")
	_press(menu._lang, "English")
	await _shot("2_idioma_en.png")
	_press(menu._lang, "Done!")
	await process_frame
	gs.set_language("es")
	menu._relabel()
	menu._on_play()
	await _shot("3_edad_volver.png")
	_press(_notice(menu), "18 o más")
	await _shot("4_nombre_volver.png")
	menu.queue_free()
	await process_frame
	gs.player_name = "Ana"
	gs.player_title = "f"
	var w: Control = load("res://scenes/welcome.tscn").instantiate()
	w.theme = root.theme
	sv.add_child(w)
	await _shot("5_bienvenida_volver.png")
	quit()
