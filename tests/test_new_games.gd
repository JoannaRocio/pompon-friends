extends SceneTree
## Minijuegos nuevos: Salto al cielo (Fisico), Pintar (pixel art que se cuelga o se regala a un amigo
## de verdad, con un servidor de mentira) y Hacer musica (Musica).

var gs: Node
var friends: Node


func _labels(node: Node) -> String:
	var texts := ""
	for lbl in node.find_children("*", "Label", true, false):
		texts += lbl.text + " | "
	return texts


func _press(node: Node, text: String) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if b.text == text:
			b.pressed.emit()
			return true
	return false


func _be(name: String, code: String, secret: String) -> void:
	gs.new_pompon("Felino", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.nickname = name
	gs.pompon.born_at = int(Time.get_unix_time_from_system()) - 10 * 86400
	gs.player_name = name
	gs.player_title = "f"
	gs.friend_code = code
	gs.friend_secret = secret
	gs.friends = []
	gs.friend_requests = []
	gs.friend_sent = []
	gs.pending_thoughts = []


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	friends = root.get_node("Friends")
	root.get_node("Cloud").fake_server = {}

	# ---------- pixel art
	var px: String = PixelArt.blank()
	px = PixelArt.set_pixel(px, 3, 4, 2)
	print("pintar un cuadrito: color=", PixelArt.get_pixel(px, 3, 4), " | pintados=", PixelArt.painted(px), " | valido=", PixelArt.valid(px), " | invalido=", PixelArt.valid("zz"))
	px = PixelArt.fill(px, 0, 0, 6)
	print("balde: pintados=", PixelArt.painted(px), " (255 azules + 1 rojo) | colores=", PixelArt.colors_used(px))

	_be("Mochi", "", "")
	gs.owned = []
	gs.placed = []
	gs.current_room = 0
	var id: String = gs.add_painting(px)
	print("dibujo guardado: ", id, " | es un cuadro de pared: ", Catalog.get_item(id).get("category", ""), " | en Decorar: ", gs.owned.has(id))
	gs.hang_painting(id)
	print("colgado: ", gs.is_placed(id), " | el Pompon va a verlo al volver: ", gs.discover_next, " | lo admira: ", PomponPlay.play_of(id).get("text", ""))
	var saved: Dictionary = JSON.parse_string(JSON.stringify(gs.save_dict()))
	gs.apply_save(saved)
	print("guardar y cargar: sigue colgado=", gs.is_placed(id), " | mismo dibujo=", PixelArt.cache.get(id, {}).get("px", "") == px)
	var holder := Control.new()
	root.add_child(holder)
	holder.draw.connect(func(): ItemArt.draw_item(holder, id, Vector2(100, 100)))
	holder.queue_redraw()
	await process_frame
	print("se dibuja en el cuarto sin errores")
	holder.queue_free()

	# ---------- el juego de pintar
	var paint: Control = load("res://scenes/paint_game.tscn").instantiate()
	root.add_child(paint)
	await process_frame
	paint._finish()
	await process_frame
	print("con poco pintado pide mas: ", _labels(paint._notice).contains("Pinta un poquito más"))
	paint._notice.close()
	for y in 8:
		for x in 16:
			paint.paint_at(Vector2i(x, y))
	print("pintados=", PixelArt.painted(paint.px), " | estrellas=", paint.results.size(), " | monedas=", paint.earned)
	paint._pick_tool("fill")
	paint._pick_color(5)
	paint.paint_at(Vector2i(0, 12))
	print("balde abajo: pintados=", PixelArt.painted(paint.px), " | estrellas=", paint.results.size())
	paint._finish()
	await process_frame
	print("terminar: '", _labels(paint._notice).substr(0, 40), "' | botones: ", paint._notice.find_children("*", "Button", true, false).map(func(b): return b.text))
	_press(paint._notice, "Colgar en mi cuarto")
	await process_frame
	_press(paint._notice, "¡Bien!")
	await process_frame
	print("colgado en el cuarto: ", gs.is_placed(paint.saved_id), " | tarjeta de premios: ", paint._layer != null)
	paint.queue_free()
	await process_frame

	# ---------- regalar un dibujo a un amigo de verdad (servidor de mentira)
	_be("Mochi", "", "")
	await friends.activate()
	var ana := {"code": gs.friend_code, "secret": gs.friend_secret}
	_be("Luna", "", "")
	await friends.activate()
	var leo := {"code": gs.friend_code, "secret": gs.friend_secret}
	await friends.request(ana["code"])
	_be("Mochi", ana["code"], ana["secret"])
	await friends.refresh()
	await friends.answer(leo["code"], true)
	var paint2: Control = load("res://scenes/paint_game.tscn").instantiate()
	root.add_child(paint2)
	await process_frame
	for y in 16:
		paint2.paint_at(Vector2i(y, y))
		paint2.paint_at(Vector2i(15 - y, y))
	paint2._finish()
	await process_frame
	_press(paint2._notice, "Regalar a un amigo")
	await process_frame
	var choices: Array = paint2._notice.find_children("*", "Button", true, false).map(func(b): return b.text)
	print("elegir amigo: ", choices)
	_press(paint2._notice, choices[0])
	for i in 6:
		await process_frame
	print("enviado: ", _labels(paint2._notice).contains("Le va a llegar"))
	var gift_px: String = paint2.px
	paint2.queue_free()
	var r_more: Array = []
	for i in 3:
		r_more.append((await friends.send_art(leo["code"], gift_px))["result"])
	print("mas regalos el mismo dia: ", r_more, " (hasta 3)")
	_be("Luna", leo["code"], leo["secret"])
	gs.owned = []
	gs.paintings = []
	PixelArt.cache = {}
	await friends.refresh()
	var got: Array = gs.paintings.filter(func(p): return p["px"] == gift_px)
	print("a Luna le llego el dibujo: ", got.size() >= 1, " | de: '", got[0]["from"] if got.size() > 0 else "", "' | para colgar: ", gs.owned.has(got[0]["id"]) if got.size() > 0 else false,
		" | en su diario: ", gs.pending_thoughts.any(func(e): return str(e["text"]).contains("me regaló un dibujo")))
	print("  nombre en Decorar: ", Catalog.get_item(got[0]["id"])["name"] if got.size() > 0 else "")

	# ---------- salto al cielo
	_be("Mochi", "", "")
	var jump: Control = load("res://scenes/jump_game.tscn").instantiate()
	root.add_child(jump)
	await process_frame
	await process_frame
	print("salto: nubes=", jump.platforms.size(), " | esperando el primer toque=", not jump.started)
	jump._start()
	var heights := 0
	var aim := -1.0
	for i in 2400:   # el "dedo" va hacia la nube de arriba mas facil de alcanzar (se decide al rebotar)
		if jump.vel.y < -1000.0 or aim < 0.0:
			var best_dx := 1e9
			for pl in jump.platforms:
				var dy: float = jump.pos.y - pl["pos"].y
				if pl["kind"] != "ground" and dy > 40.0 and dy < 320.0 and absf(pl["pos"].x - jump.pos.x) < best_dx:
					best_dx = absf(pl["pos"].x - jump.pos.x)
					aim = pl["pos"].x
		jump.target_x = aim
		jump.step(1.0 / 60.0)
		if jump.over:
			break
	print("subio ", int(jump.best / 10.0), " m | estrellas=", jump.results.size(), " | monedas=", jump.earned, " | se cayo=", jump.over)
	jump.target_x = 0.0
	jump.pos.y = jump.cam_y + jump.field.size.y + 400.0
	jump.step(1.0 / 60.0)
	await create_timer(0.7).timeout
	print("al caerse termina con premios: ", jump._layer != null)
	jump.queue_free()
	await process_frame

	# ---------- hacer musica
	var music: Control = load("res://scenes/music_game.tscn").instantiate()
	root.add_child(music)
	await process_frame
	var tone: AudioStreamWAV = music.tone(523.25)
	print("nota armada por codigo: ", tone.data.size(), " bytes")
	music._finish()
	await process_frame
	print("sin notas pide mas: ", music._notice != null)
	music._notice.close()
	for s in 8:
		music.toggle(s % 5, s)
	music.toggle(5, 0)
	music.toggle(5, 4)
	print("notas=", music.notes_count(), " | estrellas=", music.results.size())
	music.set_playing(true)
	await create_timer(0.28 * 8 * 2 + 0.6).timeout
	print("tocando: vueltas=", music.loops, " | estrellas=", music.results.size())
	music._finish()
	await process_frame
	print("terminar: premios=", music._layer != null)
	var skill_before := PomponSkills.xp(gs.pompon, "musica")
	print("habilidades: salto->", PomponSkills.GAME_SKILL["jump"], " pintar->", PomponSkills.GAME_SKILL["paint"], " musica->", PomponSkills.GAME_SKILL["music"], " | sumo musica=", skill_before > 0.0)
	music.queue_free()

	# ---------- el menu
	var menu: Control = load("res://scenes/minigames.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var t := _labels(menu)
	print("menu: ", t.contains("Salto al cielo") and t.contains("Pintar") and t.contains("Hacer música"))
	menu.queue_free()
	await process_frame
	quit()
