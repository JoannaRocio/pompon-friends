extends SceneTree
## Herramienta de desarrollo: captura una escena con un tamano logico (para probar pantallas
## altas o tablets). Con el escalado "expand" del proyecto, un celular 20:9 equivale a 720x1600
## y una tablet vertical 3:4 a 960x1280.
## Uso: godot --path . --rendering-method gl_compatibility --resolution 540x960 \
##        --script tools/screenshot_logical.gd -- <escena> <salida.png> <ancho> <alto> [edit]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_name: String = args[0]
	var out: String = args[1]
	var size := Vector2i(int(args[2]), int(args[3]))
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	var p: Pompon = gs.pompon
	p.nickname = "Mochi"
	p.species = "Conejo"
	p.color_primary = Color("a8d8f0")
	p.color_secondary = Color("f4f9ff")
	p.born_at = int(Time.get_unix_time_from_system()) - 90 * 86400
	gs.last_stage = 4
	gs.daily_gift_day = int(Time.get_unix_time_from_system()) / 86400  # sin ventanas emergentes
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends"]
	gs.coins = 120
	gs.owned = ["hat_bow", "shirt_dress", "furn_tunnel", "furn_sofa", "furn_plant", "furn_lamp", "furn_bookshelf",
		"deco_window", "deco_picture", "deco_garland", "wall_stars", "floor_wood"]
	gs.equipped = {"hat": "hat_bow", "shirt": "shirt_dress", "wall": "wall_stars", "floor": "floor_wood"}
	gs.placed = []
	for id in gs.owned:
		gs.place_item(id)
	var sv := SubViewport.new()
	sv.size = size
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var scene: Control = load("res://scenes/%s.tscn" % scene_name).instantiate()
	scene.theme = root.theme  # un SubViewport no hereda el tema de la ventana
	sv.add_child(scene)
	if args.size() > 4 and args[4] == "edit" and scene.has_method("_set_edit"):
		scene._set_edit(true)
	if args.size() > 5 and scene.get("room") != null:
		scene.room.hour_override = float(args[5])  # ej. 23 = noche, 18.5 = atardecer
	await create_timer(1.0).timeout
	var img := sv.get_texture().get_image()
	print("guardado: ", out, " -> ", img.save_png(out), " ", img.get_size())
	quit()
