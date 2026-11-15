extends SceneTree
## Genera las imagenes para la ficha de Google Play (capturas 1080x1920 y grafico 1024x500).
## Uso: godot --path . --rendering-method gl_compatibility --resolution 540x960 \
##        --script tools/store_images.gd -- <carpeta_salida> [es|en]
## Las capturas van a <carpeta_salida>/<idioma>/ (el grafico de funciones, sin texto traducido, a la carpeta).
## Respaldar antes %APPDATA%\Godot\app_userdata\Pompon Friends\save.json* (guarda partidas de ejemplo).
## Google Play acepta hasta 8 capturas por idioma: ver la seleccion sugerida en docs/store/store-listing.md.

const SHOTS := [
	# [escena, archivo, especie (indice), modo]
	["menu", "01-menu", 0, ""],
	["home", "02-casa", 1, ""],
	["home", "03-decorar", 3, "edit"],
	["shop", "04-tienda", 0, ""],
	["job_board", "05-empleos", 3, ""],
	["job_menu", "06-aula", 0, ""],
	["job_game", "07-cuentas", 1, "job"],
	["job_game", "08-aprende", 3, "job_wrong"],
	["job_menu", "09-idiomas", 2, "lang"],
	["minigames", "10-minijuegos", 4, ""],
	["town", "11-pueblo", 0, "scroll"],
	["cinema", "12-cine", 1, ""],
	["neighbors", "13-vecinos", 3, ""],
]
const SPECIES := ["Felino", "Conejo", "Dragon", "Canino", "Ave", "Raton", "Reptil"]
const COLORS := [["ffb3cc", "fff0f5"], ["a8d8f0", "f4f9ff"], ["9ad9a8", "e8f8d8"], ["e8c08c", "fff0d8"], ["ffe27a", "fff6cf"]]
const FRIENDS := [
	["Conejo", "a8d8f0", "f4f9ff", "redondos", "sonrisa", "redonda", {"hat": "hat_beanie", "shirt": "shirt_sweater"}],
	["Canino", "e8c08c", "fff0d8", "ovalados", "colmillitos", "ovalada", {"glasses": "glasses_round", "shirt": "shirt_red"}],
	["Dragon", "9ad9a8", "e8f8d8", "brillantes", "sonrisa", "ancha", {"shirt": "shirt_hoodie"}],
	["Felino", "ffb3cc", "fff0f5", "tiernos", "bigotes", "redonda", {"hat": "hat_bow", "shirt": "shirt_dress"}],
	["Ave", "ffe27a", "fff6cf", "redondos", "pico", "ancha", {"hat": "hat_cap"}],
]

var _out := "user://store"
var _lang := "es"


## Fondo del grafico de funciones: pared de estrellitas y piso, de dia.
class Backdrop extends Control:
	func _draw() -> void:
		ItemArt.draw_wall(self, Rect2(0, 0, size.x, 330), "")
		draw_rect(Rect2(0, 312, size.x, 20), Color("fffaf0"))
		draw_line(Vector2(0, 332), Vector2(size.x, 332), Color("5b3a4a"), 3.0)
		ItemArt.draw_floor(self, Rect2(0, 332, size.x, size.y - 332), "")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1 and args[1] in ["es", "en"]:
		_lang = args[1]
	var shots_dir := _out.path_join(_lang)
	DirAccess.make_dir_recursive_absolute(shots_dir)
	await process_frame
	var gs := root.get_node("GameState")
	gs.set_language(_lang)
	load("res://scripts/day_clock.gd").debug_hour = 14.0   # capturas siempre de dia (sin el cartel de la noche)

	for shot in SHOTS:
		_prepare_game(gs, shot[2])
		var sv := SubViewport.new()
		sv.size = Vector2i(1080, 1920)
		sv.size_2d_override = Vector2i(720, 1280)
		sv.size_2d_override_stretch = true
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(sv)
		var jobs: GDScript = load("res://scripts/jobs.gd")
		jobs.current = "english" if shot[3] == "lang" else "math"   # (en ingles, la clase de idiomas es de Español)
		var scene: Control = load("res://scenes/%s.tscn" % shot[0]).instantiate()
		scene.theme = root.theme  # un SubViewport no hereda el tema de la ventana
		sv.add_child(scene)
		if shot[3] == "edit":
			scene._set_edit(true)
		if shot[3] == "scroll":   # el pueblo: que se vean la tienda y el cine
			await create_timer(0.5).timeout
			scene._scroll.scroll_horizontal = 520
		if scene.get("room") != null:
			scene.room.hour_override = 14.0  # capturas siempre de dia
		if shot[3] in ["job", "job_wrong"]:  # trabajo en el salon: se llega hasta un examen
			await create_timer(0.5).timeout
			scene._close_layer()
			scene._start_play()
			scene._signal_t = 0.1
			await create_timer(2.5).timeout
			if shot[3] == "job":
				for k in 3:  # unos objetos ya ordenados para que se vea vivo
					await create_timer(0.2).timeout
			scene._on_exam_tapped()
			await create_timer(0.4).timeout
			if shot[3] == "job_wrong":
				for b in scene._layer.get_child(1).get_child(0).get_node("Options").get_children():
					if int(b.get_meta("value")) != scene._problem["answer"]:
						b.pressed.emit()
						break
		await create_timer(1.2).timeout
		var img := sv.get_texture().get_image()
		print(shot[1], " -> ", img.save_png("%s/%s.png" % [shots_dir, shot[1]]), " ", img.get_size())
		sv.queue_free()
		await process_frame

	await _feature_graphic()
	quit()


func _prepare_game(gs: Node, species_index: int) -> void:
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	var p: Pompon = gs.pompon
	p.nickname = "Mochi"
	p.species = SPECIES[species_index % SPECIES.size()]
	var c: Array = COLORS[species_index % COLORS.size()]
	p.color_primary = Color(c[0])
	p.color_secondary = Color(c[1])
	p.born_at = int(Time.get_unix_time_from_system()) - 90 * 86400
	gs.last_stage = 4
	gs.stage_news = ""
	gs.daily_gift_day = int(Time.get_unix_time_from_system()) / 86400  # sin ventanas emergentes
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends"]
	gs.coins = 120
	gs.player_name = "Ana"
	gs.player_title = "f"  # ya dijo su nombre y como quiere que la llamen
	gs.age_group = "adult"
	gs.tutorial["off"] = true
	gs.notify_on = false
	gs.jobs_done = 3  # ya no se muestra la explicacion inicial del trabajo
	for camino in MathProblems.TRACKS:  # lecciones ya vistas: se llega directo al juego
		for lvl in range(1, 11):
			gs.math_state(camino)["lessons"].append(lvl)
	gs.math_state("mul")["level"] = 3
	gs.math_state("mul")["history"] = [{"c": true, "t": 1.5}, {"c": true, "t": 2.0}, {"c": true, "t": 1.8}, {"c": false, "t": 3.0}, {"c": true, "t": 6.0}]
	gs.math_state("mul")["answered"] = 25
	gs.math_state("mul")["correct"] = 21
	var math: GDScript = load("res://scripts/math_problems.gd")
	math.current_track = "mul"
	gs.owned = ["hat_bow", "hat_party", "shirt_dress", "shirt_scarf", "glasses_heart", "furn_scratcher", "furn_bed", "furn_cushion",
		"furn_sofa", "furn_plant", "furn_lamp", "furn_bookshelf", "deco_window", "deco_picture", "deco_garland",
		"wall_stars", "floor_wood", "glasses_round", "furn_tunnel", "furn_swing", "furn_heat", "furn_wheel"]
	gs.equipped = {"hat": "hat_bow", "shirt": "shirt_dress", "wall": "wall_stars", "floor": "floor_wood"}
	gs.placed = []
	for id in gs.owned:
		gs.place_item(id)
	# solo los mas bonitos en pantalla: se guardan los muebles de otras especies
	for id in ["furn_scratcher", "furn_bed", "furn_cushion", "furn_tunnel", "furn_swing", "furn_heat", "furn_wheel"]:
		if id != Catalog.required_furniture(p.species).get("id", ""):
			gs.store_item(id)
	p.stats["alimentacion"] = 80.0
	p.stats["amor"] = 85.0


func _feature_graphic() -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(1024, 500)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var backdrop := Backdrop.new()
	backdrop.size = Vector2(1024, 500)
	sv.add_child(backdrop)
	var logo := RichTextLabel.new()
	logo.bbcode_enabled = true
	logo.fit_content = true
	logo.scroll_active = false
	logo.position = Vector2(30, 70)
	logo.size = Vector2(430, 200)
	logo.add_theme_font_size_override("normal_font_size", 92)
	logo.add_theme_color_override("font_outline_color", Color.WHITE)
	logo.add_theme_constant_override("outline_size", 14)
	logo.text = "[color=#f2b705]P[/color][color=#4cc9a4]o[/color][color=#f2b705]m[/color][color=#4cc9a4]p[/color][color=#f28ca8]o[/color][color=#9b7bd8]n[/color]\n[color=#f28ca8]F[/color][color=#f2b705]r[/color][color=#4cc9a4]i[/color][color=#9b7bd8]e[/color][color=#f28ca8]n[/color][color=#f2b705]d[/color][color=#4cc9a4]s[/color]"
	sv.add_child(logo)
	var i := 0
	for f in FRIENDS:
		var v := PomponView.new()
		v.animated = false
		v.size = Vector2(140, 330)
		v.position = Vector2(470 + i * 108, 150)
		v.set_pompon(PomponView.make_sample(f[0], Color(f[1]), Color(f[2]), f[3], f[4], f[5]), f[6])
		sv.add_child(v)
		i += 1
	await create_timer(0.8).timeout
	var img := sv.get_texture().get_image()
	print("feature-graphic -> ", img.save_png("%s/feature-graphic.png" % _out), " ", img.get_size())
