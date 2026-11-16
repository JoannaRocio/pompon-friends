extends SceneTree


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.coins = 100000
	gs.owned = []
	gs.placed = []
	gs.equipped = {}

	# --- integridad del catalogo
	var ids := {}
	var dup := 0
	var cats := {}
	for it in Catalog.ITEMS:
		if ids.has(it["id"]):
			dup += 1
		ids[it["id"]] = true
		cats[it["category"]] = int(cats.get(it["category"], 0)) + 1
	print("catalogo: ", Catalog.ITEMS.size(), " items, repetidos=", dup, " categorias=", cats)
	for sp in Pompon.SPECIES:
		if Catalog.required_furniture(sp).is_empty():
			print("FALTA mueble clave de ", sp)

	# --- comprar todo coloca los muebles solos
	for it in Catalog.ITEMS:
		gs.buy(it["id"])
	var placeable := Catalog.ITEMS.filter(func(i): return i["category"] in Catalog.PLACEABLE).size()
	var in_range := true
	for p in gs.placed:
		if p["x"] < 0.0 or p["x"] > 1.0 or p["y"] < 0.0 or p["y"] > 1.0:
			in_range = false
	print("colocados=", gs.placed.size(), " de ", placeable, " posiciones validas=", in_range)

	# --- guardar / volver a colocar
	gs.store_item("furn_sofa")
	print("sofa guardado: colocado=", gs.is_placed("furn_sofa"))
	gs.place_item("furn_sofa")
	print("sofa vuelto a colocar: colocado=", gs.is_placed("furn_sofa"), " duplicado=", gs.placed_ids().count("furn_sofa") > 1)
	gs.equip("furn_sofa")
	print("equip ignora muebles: ", not gs.equipped.has("furniture"))

	# --- mueble clave exige estar colocado
	var sp: String = gs.pompon.species
	var req: String = Catalog.required_furniture(sp)["id"]
	gs.store_item(req)
	print("sin colocar el mueble clave: comodo=", Catalog.has_required_furniture(sp, gs.placed_ids()))
	gs.place_item(req)
	print("colocado: comodo=", Catalog.has_required_furniture(sp, gs.placed_ids()))

	# --- guardado conserva posiciones
	gs.move_item("furn_sofa", 0.33, 0.74)
	gs.save_game()
	gs.placed = []
	gs.load_game()
	var sofa: Array = gs.placed.filter(func(p): return p["id"] == "furn_sofa")
	print("posicion tras recargar: ", sofa[0]["x"], ", ", sofa[0]["y"])

	# --- arrastrar un mueble en el cuarto (simula el dedo)
	var room: Control = load("res://scripts/room_view.gd").new()
	room.size = Vector2(720, 1280)
	root.add_child(room)
	room.set_state("", "", gs.placed, 0)
	room.edit_mode = true
	await process_frame
	var start := Vector2(0.33 * 1440.0, 0.74 * 1280.0)  # el cuarto mide 2 pantallas de ancho
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start
	room._gui_input(press)
	print("seleccionado: ", room.selected)
	var move := InputEventMouseMotion.new()
	move.position = start + Vector2(120, 40)
	room._gui_input(move)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = move.position
	room._gui_input(release)
	var moved: Dictionary = gs.placed.filter(func(p): return p["id"] == "furn_sofa")[0]
	print("sofa arrastrado a: ", snappedf(moved["x"], 0.01), ", ", snappedf(moved["y"], 0.01), " (esperado ~0.41, ~0.77)")
	# no se puede sacar un mueble de piso al techo ni una deco al piso
	var far := InputEventMouseMotion.new()
	far.position = Vector2(10, 5)
	var press2 := InputEventMouseButton.new()
	press2.button_index = MOUSE_BUTTON_LEFT
	press2.pressed = true
	press2.position = Vector2(moved["x"] * 1440.0, moved["y"] * 1280.0)
	room._gui_input(press2)
	room._gui_input(far)
	var clamped: Dictionary = gs.placed.filter(func(p): return p["id"] == "furn_sofa")[0]
	print("limites del piso respetados: y=", snappedf(clamped["y"], 0.01), " x=", snappedf(clamped["x"], 0.01))
	room.queue_free()

	# --- todos los items se dibujan sin errores (miniaturas y puestos en cada especie)
	var holder := Control.new()
	holder.size = Vector2(900, 900)
	root.add_child(holder)
	for it in Catalog.ITEMS:
		var icon := ItemIcon.new()
		icon.set_item(it["id"], 90.0)
		holder.add_child(icon)
	var wear := Catalog.ITEMS.filter(func(i): return i["category"] in Catalog.WEARABLE)
	for species in Pompon.SPECIES:
		for it in wear:
			var v := PomponView.new()
			v.animated = false
			v.size = Vector2(120, 120)
			v.set_pompon(PomponView.make_sample(species, Color("a8d8f0"), Color("f4f9ff")), {it["category"]: it["id"]})
			holder.add_child(v)
	await process_frame
	await process_frame
	print("dibujados: ", holder.get_child_count(), " controles sin error")

	# --- tienda diaria con el catalogo nuevo
	var now := int(Time.get_unix_time_from_system())
	var okshop := true
	for d in 40:
		var shop := Catalog.daily_shop(now + d * 86400, sp, [])
		var seen := {}
		for x in shop:
			seen[x["id"]] = true
		if shop.size() != Catalog.SHOP_SIZE or seen.size() != Catalog.SHOP_SIZE:
			okshop = false
	print("tienda 40 dias: ", Catalog.SHOP_SIZE, " items sin repetir=", okshop)
	var owned_all: Array = Catalog.ITEMS.map(func(x): return x["id"])
	print("tienda con todo comprado: ", Catalog.daily_shop(now, sp, owned_all).size(), " items")
	quit()
