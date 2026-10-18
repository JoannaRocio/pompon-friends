extends SceneTree
## Habitaciones (hasta 6, se abren por nivel), cuarto ancho con deslizamiento, estantes y adornos apoyados.


func _click(room: Control, pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	room._gui_input(e)


func _motion(room: Control, pos: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.relative = rel
	room._gui_input(e)


func _item(gs: Node, id: String) -> Dictionary:
	for p in gs.placed:
		if p["id"] == id:
			return p
	return {}


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.coins = 100000
	gs.owned = []
	gs.placed = []
	gs.equipped = {}
	gs.room_styles = {}
	gs.current_room = 0
	var now := int(Time.get_unix_time_from_system())

	# --- cuantas habitaciones hay y cuando se abren
	print("habitaciones: ", Rooms.count(), " (max 6=", Rooms.count() == 6, ")")
	var levels: Array = Rooms.LIST.map(func(r): return r["level"])
	print("niveles de apertura: ", levels, " crecientes=", levels == levels.duplicate() and levels[0] == 1)
	gs.pompon.born_at = now - 2 * 86400
	print("nivel ", gs.pompon_level(), ": abiertas=", gs.rooms_unlocked(), " (esperado 1) | ir a la 2da: ", gs.set_room(1), " (esperado false)")
	gs.pompon.born_at = now - 20 * 86400
	print("nivel ", gs.pompon_level(), ": abiertas=", gs.rooms_unlocked(), " (esperado 3)")
	gs.pompon.born_at = now - 70 * 86400
	print("nivel ", gs.pompon_level(), ": abiertas=", gs.rooms_unlocked(), " (esperado 6)")

	# --- cada habitacion tiene su pared y piso
	print("sala sin cambios: pared='", gs.equipped.get("wall", ""), "' piso='", gs.equipped.get("floor", ""), "'")
	gs.buy("wall_mint")
	gs.equip("wall_mint")
	print("sala con pared menta: ", gs.equipped.get("wall"))
	print("ir al dormitorio: ", gs.set_room(1), " pared=", gs.equipped.get("wall"), " piso=", gs.equipped.get("floor"), " (esperado wall_lilac, floor_pink)")
	gs.buy("wall_blue")
	gs.equip("wall_blue")
	gs.set_room(0)
	print("volver a la sala conserva su pared: ", gs.equipped.get("wall"), " (esperado wall_mint)")
	gs.set_room(1)
	print("dormitorio conserva la suya: ", gs.equipped.get("wall"), " (esperado wall_blue)")
	gs.set_room(5)
	print("terraza: pared=", gs.equipped.get("wall"), " piso=", gs.equipped.get("floor"))
	gs.set_room(0)

	# --- los muebles se colocan en la habitacion actual
	gs.buy("furn_sofa")
	gs.set_room(2)
	gs.buy("furn_table")
	print("sofa en sala: room=", _item(gs, "furn_sofa").get("room"), " | mesa en cocina: room=", _item(gs, "furn_table").get("room"))

	# --- adornos chicos: se apoyan solos sobre un mueble libre
	gs.set_room(0)
	gs.buy("furn_dresser")
	gs.buy("toy_vase")
	gs.buy("toy_blocks")
	var dresser := _item(gs, "furn_dresser")
	var vase := _item(gs, "toy_vase")
	var blocks := _item(gs, "toy_blocks")
	print("florero apoyado en: ", vase.get("on"), " | cubos apoyados en: ", blocks.get("on"), " (esperado furn_dresser los dos)")
	print("no se pisan: ox florero=", snappedf(float(vase.get("ox", 0.0)), 0.1), " ox cubos=", snappedf(float(blocks.get("ox", 0.0)), 0.1))
	gs.buy("furn_bed")
	print("un mueble grande no se apoya: on=", _item(gs, "furn_bed").has("on"))

	# --- el adorno sigue al mueble y se guarda con el
	var room: Control = load("res://scripts/room_view.gd").new()
	room.custom_minimum_size = Vector2(720, 1280)   # que el layout no lo achique a 0
	root.add_child(room)
	room.size = Vector2(720, 1280)
	room.set_state("", "", gs.placed, 0)
	await process_frame
	var c_before: Vector2 = room._item_center(vase)
	gs.move_item("furn_dresser", dresser["x"] + 0.1, dresser["y"])
	var c_after: Vector2 = room._item_center(vase)
	print("al mover la comoda el florero se movio: ", snappedf(c_after.x - c_before.x, 1.0), " px (esperado 144)")
	var surf: Dictionary = Catalog.surface_of("furn_dresser")
	var foot: float = c_after.y + ItemArt.size_of("toy_vase").y * 0.5
	var top: float = room._item_center(dresser).y + float(surf["dy"])
	print("el florero apoya en la tapa: diferencia=", snappedf(foot - top, 1.0), " px (esperado ~3)")

	# --- arrastrar un adorno del piso hasta la tapa de la comoda lo apoya
	gs.detach_item("toy_vase")
	var vp := _item(gs, "toy_vase")
	vp["x"] = 0.30
	vp["y"] = 0.72
	room.set_state("", "", gs.placed, 0)
	room.edit_mode = true
	await process_frame
	var start: Vector2 = room._item_center(vp) - Vector2(room.scroll, 0.0)
	_click(room, start, true)
	var dc: Vector2 = room._item_center(dresser)
	var target := Vector2(dc.x - room.scroll + 20.0, dc.y + float(surf["dy"]) - ItemArt.size_of("toy_vase").y * 0.5 + 10.0)
	_motion(room, target, target - start)
	print("arrastrado sobre la comoda: on=", _item(gs, "toy_vase").get("on"), " (esperado furn_dresser)")
	_motion(room, Vector2(40, 900), Vector2(-200, 500))
	print("al alejarlo se despega: on=", _item(gs, "toy_vase").has("on"))
	_click(room, Vector2(40, 900), false)
	var landed := _item(gs, "toy_vase")
	print("suelto en el aire cae al piso: y=", snappedf(float(landed["y"]), 0.01), " >= ", room.FLOOR_Y_RANGE.x)

	# --- deslizar la camara
	print("ancho del cuarto: ", room.world_w(), " | max scroll=", room.max_scroll(), " (esperado 1440 / 720)")
	room.scroll = 99999.0
	print("scroll limitado a la derecha: ", room.scroll)
	room.scroll = -50.0
	print("scroll limitado a la izquierda: ", room.scroll)
	room.edit_mode = false
	_click(room, Vector2(360, 300), true)
	_motion(room, Vector2(260, 300), Vector2(-100, 0))
	_click(room, Vector2(260, 300), false)
	print("arrastrar el fondo mueve la camara: ", room.scroll, " (esperado 100)")
	# los items se eligen segun la camara
	room.edit_mode = true
	room.scroll = 300.0
	var sofa := _item(gs, "furn_sofa")
	var sp: Vector2 = room._item_center(sofa) - Vector2(room.scroll, 0.0)
	_click(room, sp, true)
	print("toco el sofa con la camara corrida: ", room.selected)
	_click(room, sp, false)
	room.edit_mode = false

	# --- guardar un mueble guarda tambien lo de encima
	gs.place_item("toy_vase")
	gs.attach_item("toy_vase", "furn_dresser", 0.0)
	gs.store_item("furn_dresser")
	print("comoda guardada: colocada=", gs.is_placed("furn_dresser"), " florero=", gs.is_placed("toy_vase"), " cubos=", gs.is_placed("toy_blocks"), " (esperado todo false)")

	# --- guardado: habitacion actual, estilos y adornos apoyados
	gs.place_item("furn_dresser")
	gs.place_item("toy_vase")
	var on_before: String = str(_item(gs, "toy_vase").get("on", ""))
	gs.set_room(1)
	gs.save_game()
	gs.placed = []
	gs.equipped = {}
	gs.current_room = 0
	gs.room_styles = {}
	gs.load_game()
	print("tras recargar: habitacion=", gs.current_room, " pared=", gs.equipped.get("wall"), " (esperado 1 y wall_blue)")
	gs.set_room(0)
	print("sala recargada: pared=", gs.equipped.get("wall"), " (esperado wall_mint) | florero apoyado=", str(_item(gs, "toy_vase").get("on", "")) == on_before, " en ", on_before)

	# --- partida vieja: el cuarto era de una sola pantalla
	var legacy := {
		"version": 2, "coins": 5, "owned": ["furn_sofa", "furn_plant", "wall_mint"], "equipped": {"wall": "wall_mint"},
		"placed": [{"id": "furn_sofa", "x": 0.0, "y": 0.7}, {"id": "furn_plant", "x": 0.5, "y": 0.68}],
		"pompon": null,
	}
	var f := FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy))
	f.close()
	gs.placed = []
	gs.equipped = {}
	gs.room_styles = {}
	gs.current_room = 0
	gs.load_game()
	print("partida vieja: sofa x=", _item(gs, "furn_sofa").get("x"), " (esperado 0.25) planta x=", _item(gs, "furn_plant").get("x"), " (esperado 0.5) sala=", _item(gs, "furn_sofa").get("room"), " pared=", gs.equipped.get("wall"))

	# --- todas las habitaciones se dibujan sin errores
	gs.owned = Catalog.ITEMS.map(func(x): return x["id"])
	gs.placed = []
	var n := 0
	for it in Catalog.ITEMS:
		if Catalog.is_placeable(it["id"]):
			gs.current_room = n % Rooms.count()
			gs.place_item(it["id"])
			n += 1
	for i in Rooms.count():
		room.set_state(Rooms.default_style(i)["wall"], Rooms.default_style(i)["floor"], gs.placed, i)
		room.hour_override = [12.0, 22.0, 7.5][i % 3]
		room.scroll = 0.0
		room.queue_redraw()
		await process_frame
		room.scroll = room.max_scroll()
		await process_frame
	print("las ", Rooms.count(), " habitaciones se dibujan: ", gs.placed.size(), " items en total")
	var per_room := {}
	for p in gs.placed:
		per_room[p["room"]] = int(per_room.get(p["room"], 0)) + 1
	print("items por habitacion: ", per_room)
	room.queue_free()
	var f2 := FileAccess.open("user://save.json", FileAccess.WRITE)
	f2.store_string("{}")
	f2.close()
	quit()
