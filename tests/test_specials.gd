extends SceneTree
## Objetos especiales: caros, con brillo, siempre a la vista en "Especial" y fuera de la tienda diaria.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var cat: GDScript = load("res://scripts/catalog.gd")
	var specials: Array = cat.specials()
	var prices := specials.map(func(it): return int(it["price"]))
	print("especiales: ", specials.size(), " | precios de ", prices.min(), " a ", prices.max(), " | ordenados: ", prices == prices.duplicate().filter(func(_x): return true) and prices[0] <= prices[-1])
	var in_daily := false
	var now := int(Time.get_unix_time_from_system())
	for d in 60:
		for it in cat.daily_shop(now + d * 86400, "", [], [], 9999):
			in_daily = in_daily or it.get("special", false)
	print("nunca en la tienda diaria (60 dias): ", not in_daily)
	print("no aparecen en 'se desbloquea al subir de nivel': ", cat.locked_items(1, 999).all(func(it): return not it.get("special", false)))
	print("dibujo de base: corona de diamantes -> ", cat.shape_of("hat_crown_diamond"), " | cama de nube -> ", cat.shape_of("furn_bed_cloud"),
		" | superficie del piano dorado: ", not cat.surface_of("furn_piano_gold").is_empty(), " | acuario de colores es chico: ", cat.is_small("furn_aquarium_rainbow"))
	print("camas para dormir: cama amplia=", cat.is_bed("furn_bed"), " cama de nube=", cat.is_bed("furn_bed_cloud"), " sofa=", cat.is_bed("furn_sofa"))

	# comprar y ponerse algo especial
	gs.new_pompon()
	var p: Pompon = gs.pompon
	p.hatched = true
	p.born_at = now - 60 * 86400
	gs.coins = 5000
	gs.owned = []
	gs.equipped = {}
	print("comprar corona de diamantes: ", gs.buy("hat_crown_diamond"), " monedas=", gs.coins, " (5000 - 1200)")
	gs.equip("hat_crown_diamond")
	print("puesta: ", gs.equipped.get("hat", ""))
	var view := PomponView.new()
	view.custom_minimum_size = Vector2(300, 360)
	view.size = Vector2(300, 360)
	root.add_child(view)
	for it in specials:
		if it["category"] in ["hat", "glasses", "shirt"]:
			view.set_pompon(p, {it["category"]: it["id"]})
			await process_frame
	print("el Pompon se dibuja con toda la ropa especial (sin errores)")
	view.queue_free()

	# la pestaña Especial muestra todos (los de nivel alto con candado)
	gs.daily_gift_day = Missions.today(now)
	var shop: Control = load("res://scenes/shop.tscn").instantiate()
	root.add_child(shop)
	await process_frame
	shop._filter = "special"
	shop._rebuild()
	await process_frame
	print("pestaña Especial: ", shop._grid.get_child_count(), " tarjetas (", specials.size(), ")")
	shop.queue_free()
	await process_frame

	# de noche, un Pompon grande duerme en la cama de nube (antes que en la cama amplia)
	DayClock.debug_hour = 23.0
	gs.coins = 5000
	gs.buy("furn_bed")
	gs.buy("furn_bed_cloud")
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends", "growth", "night1"]
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.5).timeout
	var cloud_pos := Vector2.ZERO
	for pl in gs.placed:
		if pl["id"] == "furn_bed_cloud":
			cloud_pos = h.room._item_center(pl)
	print("de noche elige la cama de nube: ", absf(h._night_pos.x - cloud_pos.x) < 1.0, " | durmiendo: ", h.pet.sleeping)
	DayClock.debug_hour = -1.0
	h.queue_free()
	await process_frame
	quit()
