extends SceneTree
## Primeros pasos de una partida nueva: elegir el idioma la primera vez (con el del celular marcado) y
## poder volver atras en la edad y en el nombre (con los botones y con el "atras" de Android).

var gs: Node


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _notice(parent: Node) -> Node:
	var found: Node = null
	for c in parent.get_children():
		if c is BigNotice and not c.is_queued_for_deletion():
			found = c
	return found


func _button(node: Node, text: String) -> Button:
	if node == null:
		return null
	for b in node.find_children("*", "Button", true, false):
		if b.text == text and not b.is_queued_for_deletion():
			return b
	return null


func _press(node: Node, text: String) -> bool:
	var b := _button(node, text)
	if b == null:
		return false
	b.pressed.emit()
	return true


func _check(ok: bool, what: String) -> void:
	print(("ok: " if ok else "FALLA: ") + what)


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	var t: GDScript = load("res://scripts/t.gd")
	gs.reset_game()
	gs.language = ""
	gs.age_group = ""
	t.apply("")
	print("idioma del celular (en la prueba): ", t.device_lang())

	# ---------- 1) elegir idioma: el del celular viene marcado; tocar el otro cambia el cartel al momento
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await _frames(2)
	menu.ask_language()
	await _frames(2)
	var lang: Node = menu._lang
	_check(lang != null, "aparece el cartel de idioma")
	var es_btn := _button(lang, "Español")
	var en_btn := _button(lang, "English")
	_check(es_btn != null and en_btn != null, "hay botones Español y English")
	_check(es_btn.button_pressed and not en_btn.button_pressed, "viene marcado el idioma del celular (Español)")
	_check(_button(lang, "¡Listo!") != null, "boton ¡Listo! en español")
	en_btn.button_pressed = true
	en_btn.pressed.emit()
	await process_frame
	_check(_button(lang, "Done!") != null, "al tocar English el boton dice Done!")
	_check(gs.language == "", "todavia no se guardo (falta tocar Done!)")
	_press(lang, "Done!")
	await _frames(2)
	_check(gs.language == "en" and t.lang() == "en", "eligio English y quedo guardado: " + gs.language)
	_check(menu._lang == null, "se cerro el cartel de idioma")
	gs.set_language("es")

	# ---------- 2) la edad tiene "Volver": cierra la pregunta y deja el menu
	menu._on_play()
	await _frames(2)
	var age: Node = _notice(menu)
	_check(age != null and _button(age, "Volver") != null, "la pregunta de edad tiene Volver")
	_press(age, "Volver")
	await _frames(2)
	_check(_notice(menu) == null and menu._age == null and menu._profile == null, "Volver en la edad cierra la pregunta")
	_check(gs.age_group == "", "sin elegir edad no se guarda nada")

	# ---------- 3) del nombre se vuelve a la edad
	menu._on_play()
	await _frames(2)
	_press(_notice(menu), "18 o más")
	await _frames(2)
	var dlg: Control = menu._profile
	_check(dlg != null and gs.age_group == "adult", "eligio 18 o más y aparece ¿Cómo te llamas?")
	_check(_button(dlg, "Volver") != null, "el nombre tiene Volver")
	_press(dlg, "Volver")
	await _frames(2)
	_check(menu._profile == null and _notice(menu) != null, "Volver en el nombre vuelve a la edad")
	_press(_notice(menu), "9")
	await _frames(2)
	_check(gs.age_group == "child" and menu._profile != null, "se pudo corregir la edad (9 -> child) y sigue al nombre")

	# ---------- 4) el "atras" de Android hace lo mismo (en vez de salir del juego)
	_check(menu.handle_back() and menu._profile == null and menu._age != null, "atras en el nombre -> edad")
	await _frames(2)
	_check(menu.handle_back() and menu._age == null, "atras en la edad -> menu")
	await _frames(2)
	_check(not menu.handle_back(), "atras en el menu sin preguntas -> sale (como antes)")
	menu.queue_free()

	# ---------- 5) la bienvenida: el primer paso tiene flechita de volver y el atras vuelve un paso
	gs.player_name = "Ana"
	gs.player_title = "f"
	var w: Control = load("res://scenes/welcome.tscn").instantiate()
	root.add_child(w)
	await _frames(2)
	_check(w._back_target.is_valid(), "bienvenida: el primer paso tiene volver")
	w._choose_species()
	await _frames(2)
	_check(w.handle_back(), "bienvenida: atras en la especie vuelve")
	w.queue_free()
	await _frames(2)
	print("fin")
	quit()
