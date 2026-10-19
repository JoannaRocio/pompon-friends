extends SceneTree
## Reel vertical para TikTok con escenas reales del juego y textos encima. Graba un cuadro por paso
## (correr con --fixed-fps 30) en la carpeta que se pasa como argumento; despues se unen con ffmpeg
## (que los agranda a 1080 x 1920).
## Uso: ver tools/promo_reel.ps1 (respalda la partida guardada antes, porque el reel juega partidas de prueba).

const W := 720
const H := 1280
const PINK := Color("d6336c")
const MAX_FRAMES := 1500

var dir := ""
var vp: SubViewport
var stage: Control
var caps: Control
var flash: ColorRect
var frame := 0
var recording := false
var gs: Node


func _process(_delta: float) -> bool:
	if recording:
		var img := vp.get_texture().get_image()
		img.save_png("%s/f%04d.png" % [dir, frame])
		frame += 1
		if frame > MAX_FRAMES:  # por si algo se traba: no grabar para siempre
			push_error("demasiados cuadros")
			quit(1)
	return false


func _initialize() -> void:
	dir = OS.get_cmdline_user_args()[0]
	gs = root.get_node("GameState")
	root.get_node("Cloud").enabled = false
	vp = SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	stage = Control.new()
	stage.size = Vector2(W, H)
	stage.clip_contents = true
	vp.add_child(stage)
	var top := CanvasLayer.new()
	top.layer = 50
	vp.add_child(top)
	caps = Control.new()
	caps.size = Vector2(W, H)
	caps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(caps)
	flash = ColorRect.new()
	flash.size = Vector2(W, H)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(flash)
	await process_frame
	await process_frame
	stage.theme = root.theme   # la letra del juego (Look la arma al arrancar)
	caps.theme = root.theme
	print("tema: ", root.theme != null)

	# 1) gancho: un Pompon grande en su casa linda
	_grown(12.0)
	var h := _scene("res://scenes/home.tscn")
	await _wait(0.6)
	recording = true
	_caption("¿Te imaginas un Tamagotchi con inteligencia artificial?", 58)
	await _wait(3.4)
	# 2) es mi proyecto
	_caption("Este es mi proyecto...", 60, "¡y está a punto de estrenarse en Android!")
	h._on_action("Caricia")
	await _wait(1.4)
	h._say("¡Te quiero mucho!", 4.0)
	await _wait(1.8)

	# 3) nace de un huevo
	_egg()
	h = await _cut("res://scenes/home.tscn", 0.5)
	_caption("Nace de un huevo...", 58)
	await _wait(0.5)
	for i in 3:
		h._on_pet_tapped()
		await _wait(0.45)
	await _wait(2.6)

	# 4) piensa y siente
	_baby()
	h = await _cut("res://scenes/home.tscn", 0.4)
	_caption("Piensa, siente y escribe su diario", 56)
	h._say("¡Hola! ¿Jugamos un ratito?", 5.0)
	await _wait(1.6)
	h._show_thought_pill({"kind": PomponThoughts.KIND_FEEL, "text": "Me encanta cuando me hacen mimos", "stat": "amor"})
	h._on_action("Caricia")
	await _wait(1.6)

	# 5) el vestidor
	_grown(12.0)
	await _cut("res://scenes/wardrobe.tscn", 0.4)
	_caption("Lo vistes como quieras", 58)
	await _wait(2.6)

	# 6) amigos
	_grown(12.0)
	var first: Dictionary = Neighbors.all()[0]
	Neighbors.current = first["id"]
	gs.neighbors_met = [first["id"]]
	var visit := await _cut("res://scenes/visit.tscn", 0.6)
	_caption("Hace amigos y juega con otros Pompons", 54)
	visit._on_action("play")
	await _wait(1.6)
	visit._on_action("pet")
	await _wait(1.4)

	# 7) la noche
	_grown(23.0)
	await _cut("res://scenes/home.tscn", 0.8)
	_caption("De noche se pone el pijama y duerme", 54)
	await _wait(2.6)

	# 8) aprender trabajando
	DayClock.debug_hour = 12.0
	gs.tips_seen.append_array(["job_intro", "job_hired", "job_first_shift", "job_english"])
	Jobs.current = "english"
	EnglishProblems.current_track = "en_words"
	gs.math_state("en_words")["level"] = 3
	gs.math_state("en_words")["lessons"] = [3]
	var job := await _cut("res://scenes/job_game.tscn", 0.3)
	job._close_layer()
	job._start_play()
	_caption("Y tú aprendes inglés y matemáticas", 56)
	for k in 40:  # que salga el gatito
		job.state = 1
		job.exam_ready = true
		job._on_exam_tapped()
		if job._problem["en"] == "cat":
			break
		job._close_layer()
	await _wait(1.5)
	var box: Node = job._layer.get_child(1).get_child(0)
	for b in box.get_node("Options").get_children():
		if str(b.get_meta("value")) == "cat":
			b.pressed.emit()
	await _wait(1.3)

	# 9) cierre
	await _end_card()
	recording = false
	print("cuadros: ", frame)
	quit()


# ------------------------------------------------------------------ escenas

func _scene(path: String) -> Control:
	for c in stage.get_children():
		c.queue_free()
	var s: Control = load(path).instantiate()
	stage.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return s


## Corte con un destello blanco; `settle` = segundos para que la escena se acomode (sin grabar).
func _cut(path: String, settle: float) -> Control:
	_caption("")
	flash.color.a = 1.0
	recording = false
	var s := _scene(path)
	await _wait(settle)
	recording = true
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.25)
	return s


func _wait(t: float) -> void:
	await create_timer(t).timeout


func _base(hour: float) -> Pompon:
	DayClock.debug_hour = hour
	gs.new_pompon("Felino", "Hembra")
	var p: Pompon = gs.pompon
	p.hatched = true
	p.nickname = "Mochi"
	p.color_primary = Color("ffb3cc")
	p.color_secondary = Color("fff0f5")
	gs.player_name = "Ana"
	gs.player_title = "f"
	gs.coins = 3200
	gs.jobs_done = 30
	gs.daily_gift_day = Missions.today(int(Time.get_unix_time_from_system()))
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends", "growth", "night1"]
	gs.pending_thoughts = []
	return p


func _furnish(items: Array, equipped: Dictionary) -> void:
	gs.owned = items.duplicate()
	gs.equipped = equipped.duplicate()
	gs.placed = []
	for id in items:
		if Catalog.is_placeable(id):
			gs.place_item(id)
	gs.room_styles = {"0": {"wall": equipped.get("wall", ""), "floor": equipped.get("floor", "")}}


func _grown(hour: float) -> void:
	var p := _base(hour)
	p.born_at = int(Time.get_unix_time_from_system()) - 45 * 86400
	gs.last_stage = 3
	gs.level_seen = 999   # sin carteles de "¡Nivel X!"
	_furnish(["furn_crib", "furn_bed_cloud", "furn_piano_gold", "deco_garland_lights", "furn_lamp_stars", "wall_rainbow", "floor_cloud",
		"hat_crown_diamond", "shirt_cape_royal", "glasses_star_gold"],
		{"hat": "hat_crown_diamond", "shirt": "shirt_cape_royal", "wall": "wall_rainbow", "floor": "floor_cloud"})


func _baby() -> void:
	var p := _base(12.0)
	p.born_at = int(Time.get_unix_time_from_system()) - 2 * 86400
	gs.last_stage = 1
	gs.level_seen = 999
	_furnish(["furn_crib", "furn_lamp_stars", "deco_garland_lights"], {})


func _egg() -> void:
	_base(12.0)
	gs.new_pompon("Felino", "Hembra")
	gs.pompon.color_primary = Color("ffb3cc")
	gs.pompon.color_secondary = Color("fff0f5")
	gs.pompon.nickname = "Mochi"
	gs.owned = []
	gs.placed = []
	gs.equipped = {}
	gs.room_styles = {}
	gs.tips_seen = ["egg1", "job1", "shopcrib"]
	gs.coins = 60
	gs.buy("furn_crib")


# ------------------------------------------------------------------ textos

## Texto grande arriba (zona libre de la interfaz de TikTok), con un renglon chico opcional.
func _caption(text: String, size := 56, sub := "") -> void:
	for c in caps.get_children():
		c.queue_free()
	if text == "":
		return
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.93), 36, Color("ffb3d1"), 6, 14))
	panel.position = Vector2(40, 150)
	panel.size = Vector2(W - 80, 0)
	caps.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(_text(text, size, PINK))
	if sub != "":
		box.add_child(_text(sub, int(size * 0.68), Color("5b3a4a")))
	panel.pivot_offset = Vector2((W - 80) * 0.5, 60)
	panel.scale = Vector2(0.6, 0.6)
	panel.modulate.a = 0.0
	var tw := panel.create_tween().set_parallel()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.18)


func _text(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(W - 130, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Cierre: el Pompon festejando y el pedido de seguir la cuenta.
func _end_card() -> void:
	_caption("")
	flash.color.a = 1.0
	recording = false
	for c in stage.get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = Color("ffe6ef")
	bg.size = Vector2(W, H)
	stage.add_child(bg)
	var dots := Control.new()
	dots.size = Vector2(W, H)
	dots.draw.connect(func():
		for i in 46:
			var x := float((i * 157) % W)
			var y := float((i * 271) % H)
			dots.draw_circle(Vector2(x, y), 10.0 + (i % 4) * 4.0, Color(1, 1, 1, 0.55)))
	stage.add_child(dots)
	_grown(12.0)
	var view := PomponView.new()
	view.size = Vector2(440, 500)
	view.position = Vector2((W - 440) * 0.5, 560)
	view.set_pompon(gs.pompon, gs.equipped)
	stage.add_child(view)
	await _wait(0.2)
	recording = true
	flash.create_tween().tween_property(flash, "color:a", 0.0, 0.25)
	_caption("Si quieres apoyar este proyecto, me ayudaría muchísimo que me sigas", 50, "¡para enterarte del estreno!")
	view.celebrate(8)
	await _wait(3.4)
	_caption("¡Te lo agradecería muchísimo!", 54, "Voy a leer cada comentario. ¡Gracias!")
	view.celebrate(10)
	await _wait(3.4)
