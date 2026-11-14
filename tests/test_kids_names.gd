extends SceneTree
## Edad al empezar y nombres prefabricados para menores de 13: partida nueva (edad antes del nombre,
## grilla sin teclado), adulto (con teclado), nombre del Pompon al nacer, partida vieja sin edad y la
## defensa de la nube y los amigos (servidor de mentira; nunca usa el real).

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


func _labels(node: Node) -> String:
	var texts := ""
	for lbl in node.find_children("*", "Label", true, false):
		texts += lbl.text + " | "
	return texts


func _press(node: Node, text: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text == text and not b.is_queued_for_deletion():
			b.pressed.emit()
			return true
	return false


func _pickers(node: Node) -> Array:
	return node.find_children("*", "NamePicker", true, false).filter(func(x): return not x.is_queued_for_deletion())


func _edits(node: Node) -> int:
	return node.find_children("*", "LineEdit", true, false).filter(func(x): return not x.is_queued_for_deletion()).size()


func _fresh() -> void:
	gs.reset_game()
	gs.age_group = ""


## Una casa con el Pompon ya nacido (sin regalo diario ni avisos pendientes).
func _home_with(nickname: String) -> Control:
	var now := int(Time.get_unix_time_from_system())
	gs.new_pompon("Felino", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.born_at = now - 2 * 86400
	gs.pompon.nickname = nickname
	gs.hatch_anim_pending = false
	gs.daily_gift_day = Missions.today(now)
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends", "growth", "night1", "notify_ask"]
	gs.tutorial = {"chapter": 0, "step": 0, "off": true, "done_at": 0, "done_day": -1}
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	return h


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	var cloud := root.get_node("Cloud")
	var friends := root.get_node("Friends")
	var pd: GDScript = load("res://scripts/profile_dialog.gd")
	var pom: GDScript = load("res://scripts/pompon.gd")
	print("listas: jugador=", pd.NAME_IDEAS.size(), " nombres (distintos: ", _unique(pd.NAME_IDEAS), ") | Pompon=", pom.NAME_IDEAS.size(), " (distintos: ", _unique(pom.NAME_IDEAS), ")")

	# ---------- 1) partida nueva, menor de 13: primero la edad, despues la grilla (sin teclado)
	_fresh()
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await _frames(2)
	menu._on_play()
	await _frames(2)
	var age: Node = _notice(menu)
	print("partida nueva: pregunta la edad primero: ", age != null and _labels(age).contains("¿Cuántos años tienes?"), " | subtitulo: '", "Para cuidar tu privacidad." if age != null and _labels(age).contains("Para cuidar tu privacidad.") else "?", "' | todavia sin nombre: ", menu._profile == null)
	_press(age, "9")
	await _frames(2)
	var dlg: Control = menu._profile
	print("eligio 9 -> grupo=", gs.age_group, " | aparece ¿Cómo te llamas?: ", dlg != null)
	dlg.accepted.disconnect(menu._enter_game)   # (en la prueba no se cambia de escena)
	var picker = _pickers(dlg)[0] if _pickers(dlg).size() > 0 else null
	print("menor de 13: sin cuadro de texto (LineEdit)=", _edits(dlg) == 0, " | grilla de nombres=", picker != null, " | se ven ", picker.visible_names().size() if picker else 0, " nombres")
	var first_page: Array = picker.visible_names()
	_press(picker, "Ver otros")
	await process_frame
	print("  'Ver otros' muestra otros: ", picker.visible_names() != first_page, " | paginas: ", picker.pages())
	var ok_btn: Button = null
	for b in dlg.find_children("*", "Button", true, false):
		if b.text == "¡Listo!":
			ok_btn = b
	print("  sin elegir, ¡Listo! apagado: ", ok_btn.disabled)
	var chosen: String = picker.visible_names()[2]
	_press(picker, chosen)
	_press(dlg, "Soy ella")
	await process_frame
	print("  eligio '", chosen, "' y 'Soy ella' -> ¡Listo! prendido: ", not ok_btn.disabled)
	ok_btn.pressed.emit()
	await process_frame
	print("  guardado: nombre=", gs.player_name, " | de la lista=", gs.is_kid_player_name(gs.player_name), " | pronombre=", gs.player_title)
	menu.queue_free()
	await _frames(2)

	# ---------- 2) adulto: todo igual que antes (con teclado)
	_fresh()
	var menu2: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu2)
	await _frames(2)
	menu2._on_play()
	await _frames(2)
	_press(_notice(menu2), "18 o más")
	await _frames(2)
	var dlg2: Control = menu2._profile
	dlg2.accepted.disconnect(menu2._enter_game)
	print("adulto: grupo=", gs.age_group, " | con cuadro de texto=", _edits(dlg2) == 1, " | sin grilla=", _pickers(dlg2).is_empty())
	dlg2._edit.text = "Joaquina"
	dlg2._edit.text_changed.emit("Joaquina")
	_press(dlg2, "Soy ella")
	dlg2._accept()
	print("  escribe su nombre: ", gs.player_name)
	menu2.queue_free()
	await _frames(2)
	# ya respondio: no se vuelve a preguntar
	var menu3: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu3)
	await _frames(2)
	gs.player_name = ""
	menu3._on_play()
	await _frames(2)
	print("  edad ya respondida: no se pregunta otra vez=", _notice(menu3) == null, " | va directo al nombre=", menu3._profile != null)
	menu3._profile.accepted.disconnect(menu3._enter_game)
	menu3.queue_free()
	await _frames(2)

	# ---------- 3) al nacer: nombre del Pompon
	_fresh()
	gs.age_group = "child"
	gs.set_profile("Mochi", "f")
	var h: Control = _home_with("")
	await create_timer(0.4).timeout
	var np = h._name_panel
	print("Pompon recien nacido (menor de 13): ventana del nombre=", np != null, " | sin cuadro de texto=", _edits(np) == 0 if np else false, " | grilla=", _pickers(np).size() == 1 if np else false)
	if np:
		var pk = _pickers(np)[0]
		var pname: String = pk.visible_names()[0]
		_press(pk, pname)
		_press(np, "¡Listo!")
		await process_frame
		print("  eligio '", pname, "': nickname=", gs.pompon.nickname, " | de la lista Pompon=", gs.is_kid_pompon_name(gs.pompon.nickname), " | ventana cerrada=", h._name_panel == null)
	h.queue_free()
	await _frames(2)
	_fresh()
	gs.age_group = "adult"
	gs.set_profile("Joaquina", "f")
	var ha: Control = _home_with("")
	await create_timer(0.4).timeout
	print("Pompon recien nacido (adulto): con cuadro de texto=", _edits(ha._name_panel) == 1 if ha._name_panel else false, " | sin grilla=", _pickers(ha._name_panel).is_empty() if ha._name_panel else false)
	ha.queue_free()
	await _frames(2)

	# ---------- 4) partida vieja sin edad: se pregunta una vez en la casa; si es menor, nombres nuevos
	_fresh()
	gs.set_profile("Joaquina", "f")
	var hv: Control = _home_with("Firulais")
	await create_timer(0.4).timeout
	var ask: Node = _notice(hv)
	print("partida vieja sin edad: pregunta en la casa=", ask != null and _labels(ask).contains("¿Cuántos años tienes?"), " | bloquea tutorial y otros carteles=", hv._any_modal())
	_press(ask, "8")
	await create_timer(0.3).timeout
	var kn: Node = _notice(hv)
	print("  eligio 8 -> grupo=", gs.age_group, " | cartel 'elige nombres nuevos'=", kn != null and _labels(kn).contains("¡Elige nombres nuevos!"))
	_press(kn, "Elegir")
	await _frames(2)
	var pdlg = hv._kid_layer
	print("  ¿Cómo te llamas? con grilla=", pdlg != null and pdlg.get_script() == pd and _pickers(pdlg).size() == 1, " | sin teclado=", _edits(pdlg) == 0 if pdlg else false)
	var pk2 = _pickers(pdlg)[0]
	_press(pk2, pk2.visible_names()[1])
	pdlg._accept()   # (ya tenia pronombre)
	await _frames(2)
	var rn = hv._name_panel
	print("  despues, el Pompon: ventana=", rn != null and _labels(rn).contains("Elige un nombre"), " | grilla=", _pickers(rn).size() == 1 if rn else false)
	var pk3 = _pickers(rn)[0]
	_press(pk3, pk3.visible_names()[3])
	_press(rn, "¡Listo!")
	await create_timer(0.3).timeout
	print("  nombres nuevos: jugador=", gs.player_name, " Pompon=", gs.pompon.nickname, " | ya no hace falta=", not gs.kid_names_needed(), " | no se repite el cartel=", _notice(hv) == null and hv._kid_layer == null)
	hv.queue_free()
	await _frames(2)
	# adulto en partida vieja: se pregunta la edad y nada mas
	_fresh()
	gs.set_profile("Joaquina", "f")
	var hw: Control = _home_with("Firulais")
	await create_timer(0.4).timeout
	_press(_notice(hw), "18 o más")
	await create_timer(0.4).timeout
	print("partida vieja de un adulto: grupo=", gs.age_group, " | sin cartel de nombres=", _notice(hw) == null and hw._kid_layer == null, " | conserva nombres=", gs.player_name, "/", gs.pompon.nickname)
	hw.queue_free()
	await _frames(2)

	# ---------- 5) defensa: la nube y los amigos no mandan nombres que no son de la lista
	_fresh()
	gs.new_pompon("Felino", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.nickname = "Firulais"
	gs.player_name = "Joaquina"
	gs.player_title = "f"
	gs.age_group = "child"
	cloud.fake_server = {}
	var up: Dictionary = await cloud.upload()
	var row: Dictionary = cloud.fake_server[gs.cloud_code]["data"]
	print("nube (menor, nombres escritos a mano): ok=", up["ok"], " | jugador='", row["player_name"], "' Pompon='", row["pompon"]["nickname"], "' (vacios) | en el celular siguen: ", gs.player_name, "/", gs.pompon.nickname)
	gs.player_name = "Canela"
	gs.pompon.nickname = "Churro"
	await cloud.upload()
	row = cloud.fake_server[gs.cloud_code]["data"]
	print("nube (menor, nombres de la lista): jugador='", row["player_name"], "' Pompon='", row["pompon"]["nickname"], "'")
	var code: String = gs.cloud_code
	gs.player_name = "Joaquina"
	gs.pompon.nickname = "Firulais"
	await cloud.upload()
	gs.reset_game()
	var rs: Dictionary = await cloud.restore(code)
	print("recuperar con nombres vacios: ok=", rs["ok"], " | pide nombre otra vez=", not gs.has_profile(), " | Pompon sin nombre (lo pide la casa)=", gs.pompon.nickname == "" if gs.pompon else false)
	gs.age_group = "adult"
	gs.player_name = "Joaquina"
	gs.pompon.nickname = "Firulais"
	await cloud.upload()
	row = cloud.fake_server[gs.cloud_code]["data"]
	print("nube (adulto): jugador='", row["player_name"], "' Pompon='", row["pompon"]["nickname"], "'")

	# amigos: lo que se publica en la tarjeta (servidor de mentira)
	gs.friend_code = ""
	gs.friend_secret = ""
	gs.friends = []
	gs.friend_requests = []
	gs.friend_sent = []
	gs.age_group = "child"
	await friends.activate()
	var store: Dictionary = cloud.fake_server
	var card := _card(store, gs.friend_code)
	print("amigos (menor, nombres escritos a mano): jugador='", card.get("player", "?"), "' Pompon='", card.get("pompon", {}).get("nickname", "?"), "'")
	gs.pompon.nickname = "Churro"
	await friends.publish()
	card = _card(store, gs.friend_code)
	print("amigos (menor, Pompon de la lista): Pompon='", card.get("pompon", {}).get("nickname", "?"), "' | jugador='", card.get("player", "?"), "'")
	print("  el amigo lo ve como: '", friends.display_name({"snapshot": {"pompon": {"nickname": ""}, "player": ""}}), "' (nombre vacio tolerado)")
	gs.age_group = "adult"
	gs.pompon.nickname = "Firulais"
	await friends.publish()
	card = _card(store, gs.friend_code)
	print("amigos (adulto): jugador='", card.get("player", "?"), "' Pompon='", card.get("pompon", {}).get("nickname", "?"), "'")

	gs.reset_game()
	print("FIN test_kids_names")
	quit()


func _unique(a: Array) -> int:
	var d := {}
	for x in a:
		d[x] = true
	return d.size()


## La tarjeta publicada de un codigo, dentro del servidor de mentira de amigos.
func _card(store: Dictionary, code: String) -> Dictionary:
	for k in store.keys():
		var v = store[k]
		if typeof(v) == TYPE_DICTIONARY and v.has(code) and typeof(v[code]) == TYPE_DICTIONARY and v[code].has("snapshot"):
			return v[code]["snapshot"]
	for k in store.keys():
		if str(k).contains(code) and typeof(store[k]) == TYPE_DICTIONARY and store[k].has("snapshot"):
			return store[k]["snapshot"]
	return {}
