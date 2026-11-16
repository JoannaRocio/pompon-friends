extends SceneTree
## Herramienta de desarrollo: capturas de la tienda y de Decorar (tienda, filtros, bandeja, un cuarto
## decorado de punta a punta). Idioma y carpeta por argumento.
## OJO: cambia la partida local (respaldar user://save.json* antes y restaurar despues).
## Uso (con ventana, POMPON_HOUR=12): Godot_*win64.exe --path . --resolution 720x1280 --script tools/screenshot_decor.gd -- <carpeta> [es|en]

var gs: Node
var sv: SubViewport
var out_dir := ""


func _shot(file: String, wait := 0.8) -> void:
	await create_timer(wait).timeout
	var img := sv.get_texture().get_image()
	var path := out_dir.path_join(file)
	print("guardado: ", path, " -> ", img.save_png(path), " ", img.get_size())


func _add(scene: Control) -> void:
	scene.theme = root.theme
	sv.add_child(scene)


func _clear() -> void:
	for c in sv.get_children():
		c.queue_free()
	await process_frame


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://docs/capturas/decorar")
	var lang: String = args[1] if args.size() > 1 else "es"
	DirAccess.make_dir_recursive_absolute(out_dir)
	sv = SubViewport.new()
	sv.size = Vector2i(720, 1280)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	gs.reset_game()
	gs.set_language(lang)

	var now := int(Time.get_unix_time_from_system())
	gs.set_profile("Ana", "f")
	gs.age_group = "adult"
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.color_primary = Color("ffb3cc")
	gs.pompon.color_secondary = Color("fff0f5")
	gs.pompon.born_at = now - 15 * 86400
	gs.pompon.nickname = "Mochi"
	gs.hatch_anim_pending = false
	gs.daily_gift_day = Missions.today(now)
	gs.tips_seen = ["egg1", "job1", "shopcrib", "notify_ask", "night1", "town1", "decor", "growth", "care", "pet", "coins", "friends"]
	gs.tutorial = {"chapter": 0, "step": 0, "off": true, "done_at": 0, "done_day": -1}
	gs.coins = 260

	# tienda
	var shop: Control = load("res://scenes/shop.tscn").instantiate()
	_add(shop)
	await _shot("1-tienda.png", 1.2)
	if shop.has_method("_rebuild"):
		shop._filter = "furn"
		shop._rebuild()
		await _shot("2-tienda-muebles.png")
		var sc: ScrollContainer = shop.find_children("*", "ScrollContainer", true, false)[0]
		sc.scroll_vertical = 1400
		await _shot("3-tienda-muebles-abajo.png")
		sc.scroll_vertical = 0
		await create_timer(0.3).timeout
		for card in shop._grid.get_children():
			var b: Button = card.get_meta("buy") if card.has_meta("buy") else null
			if b != null and not b.disabled:
				b.pressed.emit()
				break
		await _shot("3b-tienda-comprado.png", 0.6)
	await _clear()

	# un cuarto decorado y la bandeja de Decorar
	var buy := ["rug_round", "rug_stripes", "furn_crib", "furn_armchair", "furn_plant", "furn_lamp", "furn_nightstand", "furn_bookshelf",
		"deco_window", "deco_plant_hanging", "deco_mirror", "deco_garland", "deco_shelf", "toy_lamp", "toy_books", "furn_tent",
		"furn_cushions", "deco_stars", "furn_dresser_mint", "toy_teacup", "toy_dino", "furn_tree", "deco_cloud",
		"furn_stool", "deco_moon", "furn_beanbag", "toy_cake", "furn_slide", "wall_flowers", "floor_dark", "wall_brick", "floor_tiles"]
	gs.coins = 99999
	for id in buy:
		if gs.owned.has(id):
			continue
		gs.owned.append(id)
		gs.place_item(id)
	# algunos quedan en la bandeja
	for id in ["furn_stool", "deco_moon", "furn_beanbag", "toy_cake", "furn_slide"]:
		gs.store_item(id)
	gs.equipped["wall"] = "wall_flowers"
	gs.equipped["floor"] = "floor_dark"
	gs.coins = 260
	var hd: Control = load("res://scenes/home.tscn").instantiate()
	_add(hd)
	await create_timer(1.2).timeout
	hd.room.scroll_to(0.0, false)
	await _shot("4-cuarto-izquierda.png", 0.6)
	hd.room.scroll_to(hd.room.max_scroll() * 0.5, false)
	await _shot("5-cuarto-centro.png", 0.6)
	hd.room.scroll_to(hd.room.max_scroll(), false)
	await _shot("6-cuarto-derecha.png", 0.6)
	hd.room.scroll_to(hd.room.max_scroll() * 0.5, false)
	hd._set_edit(true)
	await _shot("7-decorar.png", 0.6)
	hd.room.select("furn_armchair")
	gs.flip_item("furn_armchair")
	hd.room.redraw()
	await _shot("8-decorar-elegido.png", 0.4)
	hd.room.select("")
	hd._tray_tab = "style"
	hd._rebuild_tray()
	await _shot("8b-decorar-pared-piso.png", 0.4)
	hd.room.hour_override = 21.5
	hd._set_edit(false)
	hd.room.redraw()
	await _shot("8c-cuarto-noche.png", 0.6)
	hd.room.hour_override = -1.0
	hd._set_edit(true)
	hd._set_edit(false)
	await _clear()

	# vestidor: solapa Cuarto
	gs.owned.append_array(["wall_stars", "wall_clouds", "floor_wood", "floor_checker"])
	var wd: Control = load("res://scenes/wardrobe.tscn").instantiate()
	wd.set("_tab", "room")
	_add(wd)
	await _shot("9-vestidor-cuarto.png", 1.0)
	await _clear()
	quit()
