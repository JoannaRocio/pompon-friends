extends SceneTree
## Cuartos mas grandes (16/11/2026): 3 pantallas de ancho y piso mas profundo. Lo ya decorado en una partida
## vieja (room_layout 2) y en la tarjeta de un amigo con el juego viejo queda en el medio, contra la pared.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	print("pantallas=", Rooms.WORLD_SCREENS, " version=", Rooms.LAYOUT)

	# una partida vieja: sofa en el centro (x 0.5) y en el borde izquierdo (x 0.1), cuadro en la pared
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.owned = ["furn_sofa", "furn_plant", "deco_picture"]
	gs.placed = []
	gs.save_game()
	var f := FileAccess.open("user://save.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	data["room_layout"] = 2
	data["placed"] = [{"id": "furn_sofa", "x": 0.5, "y": 0.66, "room": 0}, {"id": "furn_plant", "x": 0.1, "y": 0.66, "room": 0},
		{"id": "deco_picture", "x": 0.3, "y": 0.34, "room": 0}]
	f = FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	gs.load_game()
	var got := {}
	for p in gs.placed:
		got[p["id"]] = Vector2(snappedf(p["x"], 0.001), snappedf(p["y"], 0.001))
	print("partida vieja: ", got)
	var ok: bool = absf(got["furn_sofa"].x - 0.5) < 0.001 and absf(got["furn_plant"].x - (1.0 / 6.0 + 0.1 * 2.0 / 3.0)) < 0.002 \
		and absf(got["furn_sofa"].y - 0.56) < 0.001 and got["deco_picture"].y < 0.40
	print("lo decorado queda en el medio y contra la pared: ", ok)
	if not ok:
		print("FALLA: migracion de partida vieja")

	# misma distancia a la pared que antes (en px): sofa a 0.06 del piso
	var room_view = load("res://scripts/room_view.gd")
	print("piso desde=", room_view.FLOOR_START, " sofa sobre la linea del piso=", snappedf(got["furn_sofa"].y - room_view.FLOOR_START, 0.001))

	# tarjeta de un amigo con el juego viejo (sin "layout") y una nueva
	var old_card := {"id": "f:ABCD", "name": "X", "real": true, "snapshot": {"placed": [{"id": "furn_sofa", "x": 0.5, "y": 0.66}]}}
	var new_card := {"id": "f:EFGH", "name": "Y", "real": true, "snapshot": {"layout": Rooms.LAYOUT, "placed": [{"id": "furn_sofa", "x": 0.2, "y": 0.7, "flip": true}]}}
	var a: Dictionary = load("res://scripts/neighbors.gd").build(old_card)["placed"][0]
	var b: Dictionary = load("res://scripts/neighbors.gd").build(new_card)["placed"][0]
	print("amigo viejo: x=", snappedf(a["x"], 0.001), " y=", snappedf(a["y"], 0.001), " | amigo nuevo: x=", b["x"], " y=", b["y"], " flip=", b.get("flip", false))
	if absf(float(b["x"]) - 0.2) > 0.0001 or absf(float(a["y"]) - 0.56) > 0.001:
		print("FALLA: tarjetas de amigos")

	# lo nuevo: alfombras adelante; muebles primero contra la pared
	gs.placed = []
	gs.owned = ["rug_round", "furn_sofa", "furn_table"]
	for id in gs.owned:
		gs.place_item(id)
	var ys := {}
	for p in gs.placed:
		ys[p["id"]] = snappedf(p["y"], 0.01)
	print("lugares nuevos: ", ys)
	if ys["rug_round"] < 0.7 or ys["furn_sofa"] > 0.6:
		print("FALLA: lugares de lo recien comprado")
	# contra la pared: la biblioteca recien comprada va atras con el pie sobre la linea del piso, y al
	# arrastrarla cerca de la pared se pega
	gs.placed = []
	gs.owned = ["furn_bookshelf"]
	gs.place_item("furn_bookshelf")
	var shelf: Dictionary = gs.placed[0]
	var foot: float = float(shelf["y"]) * 1280.0 + ItemArt.size_of("furn_bookshelf").y * 0.5
	print("biblioteca nueva contra la pared: pie a ", snappedf(foot - Rooms.FLOOR_START * 1280.0, 0.1), " px de la linea del piso")
	var room: Control = load("res://scripts/room_view.gd").new()
	room.custom_minimum_size = Vector2(720, 1280)
	room.size = Vector2(720, 1280)
	root.add_child(room)
	await process_frame
	room.set_state("", "", gs.placed, 0)
	room.edit_mode = true
	shelf["y"] = 0.7
	room.selected = "furn_bookshelf"
	room._dragging = true
	room._drag_offset = Vector2.ZERO
	room._pointer = Vector2(360, Rooms.wall_y("furn_bookshelf") * 1280.0 + 20.0)   # 20 px delante de la pared
	room._apply_drag()
	print("arrastrada cerca de la pared se pega: ", absf(float(shelf["y"]) - Rooms.wall_y("furn_bookshelf")) < 0.0001, " linea rosa=", room._at_wall)
	room._pointer = Vector2(360, 1000)
	room._apply_drag()
	print("lejos de la pared queda donde se suelta: ", float(shelf["y"]) > 0.7, " linea rosa=", room._at_wall)
	gs.reset_game()
	quit()
