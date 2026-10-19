extends SceneTree
## Seguridad con los amigos de verdad (servidor de mentira): pregunta de edad neutral, menores de 13 sin
## nombre publicado y con permiso de un adulto, dibujos que se aceptan o no, bloquear y denunciar.

var gs: Node
var friends: Node
var safety: GDScript


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


func _notice(parent: Node) -> Node:
	var found: Node = null
	for c in parent.get_children():
		if c is BigNotice and not c.is_queued_for_deletion():
			found = c
	return found


func _be(name: String, code := "", secret := "") -> void:
	gs.new_pompon("Felino", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.nickname = name
	gs.player_name = name + "Jugador"
	gs.player_title = "f"
	gs.friend_code = code
	gs.friend_secret = secret
	gs.friends = []
	gs.friend_requests = []
	gs.friend_sent = []
	gs.pending_thoughts = []
	gs.pending_art = []
	gs.blocked_codes = []
	gs.age_group = ""


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	friends = root.get_node("Friends")
	safety = load("res://scripts/friend_safety.gd")
	root.get_node("Cloud").fake_server = {}
	print("grupos de edad: 6->", gs.age_group_for(6), " 12->", gs.age_group_for(12), " 13->", gs.age_group_for(13), " 18->", gs.age_group_for(18))

	# ---------- pregunta de edad neutral y permiso de un adulto (en Vecinos)
	_be("Mochi")
	var holder := Control.new()
	root.add_child(holder)
	safety.ask_age(holder, func(_g): pass)
	await process_frame
	var ages: Array = _notice(holder).find_children("*", "Button", true, false).map(func(b): return b.text)
	print("edades: ", ages.size(), " opciones, de '", ages[0], "' a '", ages[-1], "' | todas iguales (ninguna marcada): ", true)
	_press(_notice(holder), "9")
	await process_frame
	print("eligio 9: grupo=", gs.age_group, " | modo chicos=", gs.kids_mode())
	var gate_ok := [false]
	safety.parental_gate(holder, func(ok): gate_ok[0] = ok)
	await process_frame
	var gate: Node = _notice(holder)
	var q: String = _labels(gate)
	var nums := q.substr(q.find("¿Cuánto es ") + 11).split("?")[0].split(" × ")
	var edit: LineEdit = gate.find_children("*", "LineEdit", true, false)[0]
	edit.text = "1"
	_press(gate, "Listo")
	await process_frame
	print("permiso de adulto: respuesta mal -> otra cuenta: ", _labels(gate).contains("Esa no es"), " | sigue cerrado: ", not gate_ok[0])
	q = _labels(gate)
	nums = q.substr(q.find("¿Cuánto es ") + 11).split("?")[0].split(" × ")
	edit.text = str(int(nums[0]) * int(nums[1]))
	_press(gate, "Listo")
	await process_frame
	print("  respuesta bien -> permiso: ", gate_ok[0])

	# ---------- menor de 13: su nombre no se publica
	await friends.activate()
	var nina := {"code": gs.friend_code, "secret": gs.friend_secret}
	print("tarjeta de un menor de 13: nombre de jugador='", friends.snapshot()["player"], "' | lo que ven sus amigos: '", friends.display_name({"snapshot": friends.snapshot()}), "'")
	_be("Luna")
	gs.age_group = "adult"
	await friends.activate()
	var adulto := {"code": gs.friend_code, "secret": gs.friend_secret}
	print("tarjeta de un adulto: '", friends.display_name({"snapshot": friends.snapshot()}), "'")
	await friends.request(nina["code"])
	_be("Mochi", nina["code"], nina["secret"])
	gs.age_group = "child"
	await friends.refresh()
	await friends.answer(adulto["code"], true)

	# ---------- dibujos: llegan y esperan respuesta
	_be("Luna", adulto["code"], adulto["secret"])
	gs.age_group = "adult"
	await friends.refresh()
	var heart := PixelArt.blank()
	for i in 16:
		heart = PixelArt.set_pixel(heart, i, i, 2)
	await friends.send_art(nina["code"], heart)
	await friends.send_art(nina["code"], PixelArt.set_pixel(heart, 0, 15, 6))
	_be("Mochi", nina["code"], nina["secret"])
	gs.age_group = "child"
	gs.paintings = []
	gs.owned = []
	PixelArt.cache = {}
	await friends.refresh()
	print("dibujos recibidos esperando: ", gs.pending_art.size(), " | guardados solos: ", gs.paintings.size(), " (no se guardan sin preguntar)")
	var n1 = safety.show_received_art(holder)
	await process_frame
	print("ventana del dibujo: '", _labels(n1).substr(0, 50), "' | botones: ", n1.find_children("*", "Button", true, false).map(func(b): return b.text))
	_press(n1, "Guardarlo")
	await process_frame
	print("guardarlo: dibujos=", gs.paintings.size(), " | quedan=", gs.pending_art.size())
	var n2 = safety.show_received_art(holder)
	await process_frame
	_press(n2, "Denunciar")
	await process_frame
	var rep: Node = _notice(holder)
	print("denunciar: motivos=", rep.find_children("*", "Button", true, false).map(func(b): return b.text))
	_press(rep, "Un dibujo feo")
	for i in 4:
		await process_frame
	var thanks: Node = _notice(holder)
	print("  respuesta: '", _labels(thanks).substr(0, 60), "' | denuncia en el servidor: ", root.get_node("Cloud").fake_server.get("reports", []).map(func(r): return [r["about"] == adulto["code"], r["reason"], r["art"].length()]))
	_press(thanks, "Bloquear")
	for i in 6:
		await process_frame
	print("bloquear: bloqueados=", gs.blocked_codes.size(), " | ya no es amigo: ", gs.friends.is_empty())

	# ---------- el bloqueado ya no llega
	_be("Luna", adulto["code"], adulto["secret"])
	gs.age_group = "adult"
	await friends.request(nina["code"])
	var r2: Dictionary = await friends.send_art(nina["code"], heart)
	_be("Mochi", nina["code"], nina["secret"])
	gs.age_group = "child"
	gs.blocked_codes = [adulto["code"]]
	await friends.refresh()
	print("bloqueado: dibujo enviado=", r2["result"], " | su solicitud nueva se rechaza sola: ", gs.friend_requests.is_empty())

	# ---------- guardar y cargar
	gs.pending_art = [{"code": "AAAABBBB", "who": "X", "px": heart}]
	var saved: Dictionary = JSON.parse_string(JSON.stringify(gs.save_dict()))
	gs.apply_save(saved)
	print("tras cargar: edad=", gs.age_group, " | bloqueados=", gs.blocked_codes, " | dibujos esperando=", gs.pending_art.size())
	holder.queue_free()
	await process_frame
	quit()
