extends SceneTree
## Herramienta de desarrollo: mide el rendimiento de las pantallas mas pesadas (FPS, tiempo de cada cuadro,
## tiempo de proceso y tiempo de _draw) y guarda capturas para comparar antes/despues.
## Uso (CON ventana, no la consola ni --headless, porque hay que dibujar de verdad):
##   Godot_v4.7.2-stable_win64.exe --path . --resolution 720x1280 --script tools/perf_check.gd -- <carpeta> [segundos]
## Respaldar antes %APPDATA%\Godot\app_userdata\Pompon Friends\save.json* (la herramienta guarda una partida de ejemplo).
##
## Escenarios: la casa con muchos muebles (quieta y deslizando con el dedo), el pueblo (quieto y deslizando)
## y el cine (mirando una pelicula). Sin vsync ni tope de FPS: los FPS son "cuantos cuadros por segundo
## podria hacer", para comparar (en el celular se limitan a 60).
## Para medir _draw se reemplaza el script de los nodos que dibujan por una copia que cronometra cada _draw
## (sin cambiar lo que dibujan). Resultado: <carpeta>/perf.md y perf.json, y capturas <escenario>.png;
## room.png es solo el cuarto (sin el Pompon, que se mueve), para comparar pixel por pixel.

var gs: Node
var out_dir := ""
var seconds := 4.0
var results := []


## Copia de un script que cronometra los metodos de dibujo que tenga (`methods`).
func _timed(path: String, methods: Array) -> GDScript:
	var base: GDScript = load(path)
	var names := base.get_script_method_list().map(func(m): return m["name"])
	var src := "extends \"%s\"\nvar perf_us := 0\nvar perf_n := 0\n" % path
	for m in methods:
		if not m in names:
			continue
		src += "func %s() -> void:\n\tvar __t := Time.get_ticks_usec()\n\tsuper()\n\tperf_us += Time.get_ticks_usec() - __t\n\tperf_n += 1\n" % m
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else "user://perf"
	seconds = float(args[1]) if args.size() > 1 else 4.0
	DirAccess.make_dir_recursive_absolute(out_dir)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await process_frame
	gs = root.get_node("GameState")
	load("res://scripts/day_clock.gd").debug_hour = 12.0   # mediodia (de noche el cuarto dibuja mas)
	_setup_game()
	await _home()
	await _room_only()
	await _town()
	await _cinema()
	_write_report()
	quit()


func _setup_game() -> void:
	gs.new_pompon("Conejo", "Hembra")
	var p: Pompon = gs.pompon
	p.nickname = "Mochi"
	p.hatched = true
	p.color_primary = Color("ffb3cc")
	p.color_secondary = Color("fff0f5")
	p.born_at = int(Time.get_unix_time_from_system()) - 90 * 86400
	for k in p.stats:
		p.stats[k] = 90.0
	gs.coins = 500
	gs.player_name = "Nube"
	gs.player_title = "f"
	gs.age_group = "adult"
	gs.tutorial["off"] = true
	gs.notify_on = false
	gs.daily_gift_day = Missions.today(int(Time.get_unix_time_from_system()))
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends", "town1", "night1", "notify_ask", "kid_names"]
	gs.current_room = 0
	# muchos muebles en la sala: todo lo que se puede colocar (comunes y especiales, que brillan)
	gs.owned = []
	gs.placed = []
	for it in Catalog.ITEMS:
		if Catalog.is_placeable(it["id"]) and gs.owned.size() < 46:
			gs.owned.append(it["id"])
	for id in gs.owned:
		gs.place_item(id)
	gs.equipped = {"wall": "wall_stars", "floor": "floor_wood"}
	print("muebles en la sala: ", gs.placed.size())


## Mide `seconds` segundos (despues de medio segundo de calentamiento). `step` se llama cada cuadro.
func _measure(label: String, timed: Array, step := Callable()) -> void:
	for n in timed:
		n.perf_us = 0
		n.perf_n = 0
	for i in 30:
		if step.is_valid():
			step.call(i)
		await process_frame
	for n in timed:
		n.perf_us = 0
		n.perf_n = 0
	var frames := 0
	var t0 := Time.get_ticks_usec()
	var last := t0
	var worst := 0.0
	var proc := 0.0
	while Time.get_ticks_usec() - t0 < int(seconds * 1000000.0):
		if step.is_valid():
			step.call(frames)
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		proc += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		frames += 1
	var total := (Time.get_ticks_usec() - t0) / 1000000.0
	var draw_us := 0
	var draw_n := 0
	for n in timed:
		draw_us += n.perf_us
		draw_n += n.perf_n
	var r := {"escenario": label, "fps": snappedf(frames / total, 0.1), "ms_cuadro": snappedf(total * 1000.0 / frames, 0.01),
		"peor_ms": snappedf(worst, 0.01), "proceso_ms": snappedf(proc / frames, 0.01),
		"draws_por_s": snappedf(draw_n / total, 0.1), "ms_por_draw": snappedf(draw_us / 1000.0 / maxf(draw_n, 1), 0.001),
		"draw_ms_por_s": snappedf(draw_us / 1000.0 / total, 0.01)}
	results.append(r)
	print(r)


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))


# ---------------------------------------------------------------- escenarios

func _home() -> void:
	var home: Control = load("res://scenes/home.tscn").instantiate()
	var room: Control = home.get_node("Room")
	room.set_script(_timed("res://scripts/room_view.gd", ["_draw", "_draw_world", "_draw_shine"]))
	root.add_child(home)
	await create_timer(1.0).timeout
	await _measure("casa (quieta)", [room])
	await _shot("casa")
	var w: float = room.max_scroll()
	await _measure("casa (deslizando)", [room], func(i): room.scroll = (sin(i * 0.05) * 0.5 + 0.5) * w)
	home.queue_free()
	await process_frame


## Solo el cuarto (sin Pompon ni botones), siempre igual: para comparar pixel por pixel antes/despues.
func _room_only() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(720, 1280)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var room: Control = load("res://scripts/room_view.gd").new()
	room.size = Vector2(720, 1280)
	room.hour_override = 12.0
	vp.add_child(room)
	room.set_state("wall_stars", "floor_wood", gs.placed, 0)
	for x in [0.0, 0.5, 1.0]:
		room.scroll = room.max_scroll() * x
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(out_dir.path_join("room_%d.png" % int(x * 100)))
	vp.queue_free()
	await process_frame


func _town() -> void:
	var town: Control = load("res://scenes/town.tscn").instantiate()
	town.set_script(_timed("res://scripts/town.gd", ["_draw_street"]))
	root.add_child(town)
	await create_timer(1.0).timeout
	await _measure("pueblo (quieto)", [town])
	await _shot("pueblo")
	var sc: ScrollContainer = town._scroll
	var w := float(sc.get_h_scroll_bar().max_value - sc.size.x)
	await _measure("pueblo (deslizando)", [town], func(i): sc.scroll_horizontal = int((sin(i * 0.05) * 0.5 + 0.5) * w))
	town.queue_free()
	await process_frame


func _cinema() -> void:
	var cinema: Control = load("res://scenes/cinema.tscn").instantiate()
	root.add_child(cinema)
	await create_timer(0.6).timeout
	cinema._start_movie()
	# la pantalla del cine se arma en codigo: se le cambia el script por la copia que cronometra
	var screen: Control = cinema.screen
	var movie: Dictionary = screen.movie
	var timed := _timed("res://scripts/movie_screen.gd", ["_draw", "_draw_front"])
	for c in screen.get_children():
		c.queue_free()
	screen.set_script(timed)
	screen.setup(movie)
	await create_timer(0.5).timeout
	await _measure("cine (pelicula)", [screen])
	await _shot("cine")
	cinema.queue_free()
	await process_frame


func _write_report() -> void:
	var f := FileAccess.open(out_dir.path_join("perf.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(results, "\t"))
	f.close()
	var md := "| Escenario | FPS | ms/cuadro | peor ms | proceso ms | _draw por s | ms por _draw | ms de _draw por s |\n|---|---|---|---|---|---|---|---|\n"
	for r in results:
		md += "| %s | %s | %s | %s | %s | %s | %s | %s |\n" % [r["escenario"], r["fps"], r["ms_cuadro"], r["peor_ms"], r["proceso_ms"], r["draws_por_s"], r["ms_por_draw"], r["draw_ms_por_s"]]
	var g := FileAccess.open(out_dir.path_join("perf.md"), FileAccess.WRITE)
	g.store_string(md)
	g.close()
	print(md)
