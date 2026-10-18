extends SceneTree


func _initialize() -> void:
	var gs := root.get_node("GameState")
	gs.coins = 50
	gs.owned = []
	gs.equipped = {}
	var now := int(Time.get_unix_time_from_system())
	var a := Catalog.daily_shop(now)
	var b := Catalog.daily_shop(now)
	var c := Catalog.daily_shop(now + 86400)
	print("tienda: ", a.size(), " items; estable=", a == b, " cambia_manana=", a != c)
	var ids := []
	for it in a:
		ids.append(it["id"])
	print("sin repetidos=", ids.size() == ids.duplicate().filter(func(x): return ids.count(x) == 1).size())
	print("compra caro sin monedas: ", gs.buy("furn_bed"), " monedas=", gs.coins)
	print("compra gorro: ", gs.buy("hat_cap"), " monedas=", gs.coins)
	print("recompra: ", gs.buy("hat_cap"))
	gs.equip("hat_cap")
	print("equipado: ", gs.equipped)
	gs.save_game()
	gs.owned = []
	gs.equipped = {}
	gs.load_game()
	print("tras recargar: owned=", gs.owned, " equipped=", gs.equipped, " coins=", gs.coins)
	gs.equip("hat_cap")
	print("quitar: ", gs.equipped)

	for scn in ["shop", "wardrobe", "home"]:
		var s: Control = load("res://scenes/%s.tscn" % scn).instantiate()
		root.add_child(s)
		await process_frame
		await process_frame
		print("escena ", scn, " ok")
		s.queue_free()
	quit()
