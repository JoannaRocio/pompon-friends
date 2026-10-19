extends SceneTree
## El pueblo: la puerta de la casa, los edificios (tu casa, tienda, cine, super, museo y la casa de
## cada vecino), los que abren pronto, el menu de un amigo de verdad y el limite de 10 amigos.


func _labels(node: Node) -> String:
	var texts := ""
	for lbl in node.find_children("*", "Label", true, false):
		texts += lbl.text + " | "
	return texts


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var friends := root.get_node("Friends")
	var now := int(Time.get_unix_time_from_system())
	gs.new_pompon("Felino", "Hembra")
	var p: Pompon = gs.pompon
	p.hatched = true
	p.nickname = "Mochi"
	p.born_at = now - 20 * 86400
	gs.last_stage = 2
	gs.level_seen = 999
	gs.daily_gift_day = Missions.today(now)
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends", "growth", "night1"]
	gs.current_room = 0
	DayClock.debug_hour = 12.0

	# la puerta en la sala
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.4).timeout
	h.room.scroll_to(0.0, false)
	await process_frame
	print("puerta en la sala: visible=", h._door.visible, " | a la izquierda=", h._door.position.x < 60.0, " | aviso del pueblo listo=", h._tip_ready({"when": "door"}))
	h._show_tip(h.TIPS.filter(func(t): return t["id"] == "town1")[0])
	await process_frame
	h._update_arrow()
	print("aviso: '", h._tip_id, "' | la flecha señala la puerta=", h._arrow.target == h._door)
	gs.current_room = 1
	await process_frame
	print("en otra habitacion no hay puerta: ", not h._door.visible)
	gs.current_room = 0
	h.queue_free()
	await process_frame

	# el pueblo
	var town: Control = load("res://scenes/town.tscn").instantiate()
	root.add_child(town)
	await create_timer(0.3).timeout
	var kinds: Array = town.buildings.map(func(b): return b["kind"])
	var houses := kinds.count("house")
	print("edificios: ", kinds.slice(0, 5), " + ", houses, " casas de vecinos (vecinos: ", Neighbors.all().size(), ")")
	print("carteles: ", town.buildings.map(func(b): return b["node"].title).slice(0, 7))
	print("abren pronto: ", town.buildings.filter(func(b): return b["node"].locked).map(func(b): return b["kind"]))
	print("la calle se desliza: ancho=", town._street.custom_minimum_size.x, " > pantalla=", town.size.x)
	town._enter("museum", {}, town.buildings[4]["node"])
	await process_frame
	print("tocar el museo: '", _labels(town._toast) if town._toast != null else "", "'")

	# amigo de verdad: visitar o dejar de ser amigos
	var entry := {"id": "f:ABCDEFGH", "name": "Kiwi", "real": true, "code": "ABCDEFGH"}
	town._friend_menu(entry)
	await process_frame
	var menu: Array = town._notice.find_children("*", "Button", true, false).map(func(b): return b.text)
	print("menu del amigo: ", menu)
	town._notice.close()
	await process_frame
	town._ask_remove(entry)
	await process_frame
	print("confirmar: ", _labels(town._notice).contains("¿Dejar de ser amigos?"))
	town._notice.close()
	await process_frame

	# limite de 10 amigos
	gs.friend_code = "AAAABBBB"
	gs.friend_secret = "secreto-de-prueba"
	gs.friends = []
	for i in 10:
		gs.friends.append({"code": "FRND%04d" % i, "snapshot": {}})
	gs.friend_sent = []
	print("con 10 amigos: lugares libres=", friends.room_left(), " | lleno=", friends.is_full())
	var r1: Dictionary = await friends.request("ZZZZYYYY")
	var r2: Dictionary = await friends.answer("ZZZZYYYY", true)
	print("pedir otro: ", r1["result"], " | aceptar otro: ", r2.get("error", ""))
	gs.friends.pop_back()
	print("con 9 amigos: lugares libres=", friends.room_left())
	gs.friends = []
	gs.friend_code = ""
	gs.friend_secret = ""

	# entrar a la casa de un vecino del barrio: va a la visita y al volver, vuelve al pueblo
	var npc: Dictionary = Neighbors.all()[Neighbors.all().size() - 1]
	town._enter("house", npc, town.buildings[town.buildings.size() - 1]["node"])
	print("visita desde el pueblo: vecino=", Neighbors.current, " | vuelve al pueblo=", load("res://scripts/town.gd").from_town)
	DayClock.debug_hour = -1.0
	await process_frame
	await process_frame
	quit()
