extends SceneTree
## Herramienta de desarrollo: abre una escena con una partida de ejemplo y guarda una captura.
## Uso: godot --path . --rendering-method gl_compatibility --resolution 540x960 \
##        --script tools/screenshot_scene.gd -- <escena.tscn> <salida.png> [huevo|bebe|nino|adulto]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path: String = args[0]
	var out: String = args[1]
	var stage: String = args[2] if args.size() > 2 else "adulto"
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	var p: Pompon = gs.pompon
	p.nickname = "Mochi"
	p.hatched = stage != "huevo"
	p.species = ["Felino", "Conejo", "Dragon", "Canino", "Ave", "Raton", "Reptil"][int(args[3]) if args.size() > 3 else 0]
	p.color_primary = Color("ffb3cc")
	p.color_secondary = Color("fff0f5")
	var age: int = {"huevo": 0, "bebe": 3 * 86400, "nino": 12 * 86400, "adulto": 90 * 86400}[stage]
	p.born_at = int(Time.get_unix_time_from_system()) - age
	gs.coins = 120
	gs.player_name = "Nube"
	gs.player_title = "f"
	gs.daily_gift_day = Missions.today(int(Time.get_unix_time_from_system()))  # sin avisos tapando la captura
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends"]
	gs.owned = ["hat_bow", "shirt_dress", "furn_scratcher", "furn_bed", "furn_cushion", "furn_sofa", "furn_plant",
		"furn_lamp", "furn_fireplace", "furn_bookshelf", "deco_window", "deco_picture", "deco_clock", "deco_garland",
		"wall_stars", "floor_wood", "glasses_round"]
	gs.equipped = {"hat": "hat_bow", "shirt": "shirt_dress", "wall": "wall_stars", "floor": "floor_wood"}
	gs.placed = []
	for id in gs.owned:
		gs.place_item(id)
	p.stats["alimentacion"] = 70.0
	p.stats["amor"] = 80.0
	var scene: Control = load(scene_path).instantiate()
	root.add_child(scene)
	if args.size() > 4 and args[4] == "edit" and scene.has_method("_set_edit"):
		scene._set_edit(true)
	if args.size() > 4 and args[4] == "lesson" and scene.has_method("_show_lesson"):
		scene._show_lesson("addsub", 4)
	if args.size() > 4 and args[4] == "expand" and scene.get("_toggle_button") != null:
		scene._toggle_button.pressed.emit()
	await create_timer(float(args[5]) if args.size() > 5 else 0.8).timeout
	var img := root.get_viewport().get_texture().get_image()
	print("guardado: ", out, " -> ", img.save_png(out), " ", img.get_size())
	quit()
