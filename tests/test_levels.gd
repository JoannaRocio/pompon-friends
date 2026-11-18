extends SceneTree
## Niveles del Pompon (un nivel por dia de vida) y items que se desbloquean al subir de nivel.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var now := int(Time.get_unix_time_from_system())
	gs.new_pompon("Conejo", "Macho")
	var p: Pompon = gs.pompon
	p.hatched = true
	for days in [0, 6, 7, 20, 21, 50, 51, 120]:
		p.born_at = now - days * 86400 - 60
		print("dia ", days, ": nivel=", p.level(now), " etapa=", p.stage_name(now), " | proxima etapa en el nivel ", p.next_stage_level(now))
	var catalog: GDScript = load("res://scripts/catalog.gd")
	print("nivel de desbloqueo: sombrero de bruja=", catalog.unlock_level("hat_witch"), " corona=", catalog.unlock_level("hat_crown"), " cuna=", catalog.unlock_level("furn_crib"), " (sin dato = 1)")
	print("el mueble de cada especie y la cuna estan desde el nivel 1: ", ["furn_crib", "furn_bed", "furn_scratcher", "furn_tunnel", "furn_swing", "furn_wheel", "furn_cushion", "furn_heat"].all(func(id): return catalog.unlock_level(id) == 1))
	var day_items: Array = catalog.daily_shop(now, "", [], [], 1)
	print("tienda del nivel 1: ", day_items.size(), " items | todos desbloqueados=", day_items.all(func(i): return catalog.is_unlocked(i["id"], 1)))
	var high: Array = catalog.daily_shop(now, "", [], [], 60)
	# (la tienda cambia cada dia: en una semana tiene que aparecer algo de nivel alto, sin depender de que dia corre el test)
	var week_high := range(7).any(func(d): return catalog.daily_shop(now + d * 86400, "", [], [], 60).any(func(i): return catalog.unlock_level(i["id"]) > 30))
	print("tienda del nivel 60: ", high.size(), " items | hay de todos los niveles=", week_high)
	var locked: Array = catalog.locked_items(1, 6)
	var ordered := true
	for i in range(1, locked.size()):
		ordered = ordered and catalog.unlock_level(locked[i]["id"]) >= catalog.unlock_level(locked[i - 1]["id"])
	print("bloqueados (nivel 1): ", locked.size(), " ordenados por nivel=", ordered, " | primero=", locked[0]["name"], " nivel ", catalog.unlock_level(locked[0]["id"]))
	print("con nivel 99 no queda nada bloqueado: ", catalog.locked_items(99, 6).is_empty())
	print("items nuevos con dibujo y precio: ", catalog.ITEMS.size(), " en total")

	# la tienda
	p.born_at = now - 2 * 86400
	gs.owned = []
	gs.placed = []
	gs.coins = 100
	var shop: Control = load("res://scenes/shop.tscn").instantiate()
	root.add_child(shop)
	await create_timer(0.4).timeout
	print("tienda en nivel ", gs.pompon_level(), ": tarjetas hoy=", shop._grid.get_child_count(), " | bloqueadas=", shop._locked_grid.get_child_count(), " | titulo='", shop._level_title.text, "'")
	var all_ok := true
	for card in shop._grid.get_children():
		all_ok = all_ok and catalog.is_unlocked(card.get_meta("id"), gs.pompon_level())
	print("todo lo que se ofrece esta desbloqueado: ", all_ok)
	shop._filter = "wear"
	shop._rebuild()
	await process_frame
	var cats_ok := true
	for card in shop._grid.get_children():
		cats_ok = cats_ok and (catalog.get_item(card.get_meta("id"))["category"] in ["hat", "glasses", "shirt"])
	print("filtro Ropa: ", shop._grid.get_child_count(), " tarjetas, todas de ropa=", cats_ok)
	shop.queue_free()
	await process_frame

	# aviso de nivel en la casa
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends"]
	gs.daily_gift_day = now / 86400
	p.nickname = "Tofu"
	p.born_at = now - 6 * 86400   # nivel 7
	gs.level_seen = 3
	gs.tutorial["off"] = true   # (con un paso del tutorial en pantalla los avisos esperan su turno)
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(2.6).timeout
	var banner_text := ""
	if h._tip_panel != null:
		banner_text = h._tip_panel.get_child(0).get_child(1).text
	print("aviso de nivel nuevo: '", banner_text.replace("\n", " | "), "' | nivel visto=", gs.level_seen)
	print("la estrella del nivel muestra: ", h._level_value)
	quit()
