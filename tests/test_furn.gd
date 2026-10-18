extends SceneTree


func _initialize() -> void:
	var gs := root.get_node("GameState")
	for sp in Pompon.SPECIES:
		print(sp, " requiere: ", Catalog.required_furniture(sp).get("name", "NADA"))

	var p := Pompon.generate()
	p.advance(36000.0, false)
	print("sin mueble tras 10h: comodidad=", snappedf(p.stats["comodidad"], 0.1))
	p.advance(36000.0, true)
	print("con mueble: comodidad=", p.stats["comodidad"])

	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	var sp: String = gs.pompon.species
	var req := Catalog.required_furniture(sp)
	gs.coins = 500
	gs.owned = []
	print("tiene mueble antes: ", Catalog.has_required_furniture(sp, gs.owned))
	gs.buy(req["id"])
	print("tiene mueble despues: ", Catalog.has_required_furniture(sp, gs.owned))

	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await process_frame
	await process_frame
	print("home con mueble ok; detalles=", h.details.text.replace("\n", " | "))
	h.queue_free()
	gs.owned = []
	gs.placed = []
	var h2: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h2)
	await process_frame
	await process_frame
	print("home sin mueble; detalles=", h2.details.text.replace("\n", " | "))
	var s: Control = load("res://scenes/shop.tscn").instantiate()
	root.add_child(s)
	await process_frame
	print("shop ok")
	quit()
