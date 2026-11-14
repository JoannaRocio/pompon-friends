extends MiniGameBase
## Minijuego "Salto al cielo" (Sky Jump): tu Pompon salta solo de nube en nube y el jugador lo mueve
## de costado con el dedo (o con las flechas). Mientras mas alto llega, mas estrellas; por el camino
## hay monedas. Si se cae, termina. Arriba el cielo se va poniendo de noche y aparecen estrellas.
## Entrena el Fisico del Pompon.

const STAR_HEIGHTS := [600.0, 1800.0, 3600.0, 6000.0, 9000.0]   # px de altura para cada estrella
const GRAVITY := 2000.0
const JUMP_SPEED := 1180.0
const SPRING_SPEED := 1750.0
const MOVE_SPEED := 820.0
const PLAYER := 140.0
const CLOUD_W := 140.0
const COIN_VALUE := 1

var field: Control
var player: PomponView
var started := false
var over := false
var pos := Vector2.ZERO          # pies del Pompon en el mundo (y crece hacia abajo; arriba es negativo)
var vel := Vector2.ZERO
var cam_y := 0.0                 # y del mundo que se ve arriba de la pantalla
var best := 0.0                  # altura maxima (px)
var platforms: Array = []        # {"pos": Vector2 (centro arriba), "w", "kind": "cloud"|"move"|"spring", "dir"}
var coins: Array = []            # Vector2
var coins_got := 0
var target_x := -1.0
var _top_y := 0.0                # la nube mas alta generada
var _rng := RandomNumberGenerator.new()
var _hint: Control
var _height_label: Label
var _stars_done := 0
var _world_ready := false


func _ready() -> void:
	game_id = "jump"
	_rng.randomize()
	_build_chrome(Color("cdeeff"), STAR_HEIGHTS.size(), 2)
	_pet.visible = false
	content.visible = false
	field = Control.new()
	field.set_anchors_preset(Control.PRESET_FULL_RECT)
	field.clip_contents = true
	field.draw.connect(_draw_field)
	field.gui_input.connect(_on_input)
	add_child(field)
	move_child(field, 2)   # arriba del fondo, debajo de la barra de arriba
	player = PomponView.new()
	player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player.size = Vector2(PLAYER, PLAYER)
	if GameState.pompon != null:
		player.set_pompon(GameState.pompon, GameState.equipped)
	field.add_child(player)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.92), 26, Color.WHITE, 3, 6))
	chip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	chip.offset_top = 104
	chip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(chip)
	_height_label = _label("0 m", 30, Color("3f66b0"))
	_height_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_height_label.custom_minimum_size = Vector2(110, 0)
	chip.add_child(_height_label)
	_hint = _label(T.s("Mueve el dedo de un lado a otro\npara saltar de nube en nube"), 34, Color("3f66b0"))
	_hint.set_anchors_preset(Control.PRESET_CENTER)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.grow_vertical = Control.GROW_DIRECTION_BOTH
	_hint.custom_minimum_size = Vector2(620, 0)
	_hint.add_theme_color_override("font_outline_color", Color.WHITE)
	_hint.add_theme_constant_override("outline_size", 12)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)


func _reset_world() -> void:
	_world_ready = true
	var w := field.size.x
	var h := field.size.y
	platforms = [{"pos": Vector2(w * 0.5, 0.0), "w": w * 0.9, "kind": "ground", "dir": 0.0}]
	coins = []
	pos = Vector2(w * 0.5, 0.0)
	vel = Vector2.ZERO
	cam_y = -h * 0.82
	_top_y = 0.0
	target_x = pos.x
	_generate()
	_place_player()


## Mas nubes hacia arriba, cada vez mas separadas (y algunas se mueven o tienen resorte).
func _generate() -> void:
	var w := field.size.x
	while _top_y > cam_y - field.size.y * 1.5:
		var height := -_top_y
		var gap := _rng.randf_range(130.0, 175.0) + minf(height / 9000.0, 1.0) * 60.0
		_top_y -= gap
		var kind := "cloud"
		if height > 1500.0 and _rng.randf() < 0.25:
			kind = "move"
		elif height > 400.0 and _rng.randf() < 0.08:
			kind = "spring"
		var x := _rng.randf_range(CLOUD_W * 0.6, w - CLOUD_W * 0.6)
		platforms.append({"pos": Vector2(x, _top_y), "w": CLOUD_W, "kind": kind, "dir": 1.0 if _rng.randf() < 0.5 else -1.0})
		if _rng.randf() < 0.18:
			coins.append(Vector2(clampf(x + _rng.randf_range(-120.0, 120.0), 40.0, w - 40.0), _top_y - _rng.randf_range(70.0, 130.0)))
	# lo que quedo muy abajo se olvida
	platforms = platforms.filter(func(pl): return pl["pos"].y < cam_y + field.size.y + 200.0)
	coins = coins.filter(func(c): return c.y < cam_y + field.size.y + 200.0)


func _on_input(event: InputEvent) -> void:
	if over:
		return
	if event is InputEventMouseButton and event.pressed:
		target_x = event.position.x
		_start()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		target_x = event.position.x


func _start() -> void:
	if started:
		return
	if not _world_ready:
		_reset_world()
	started = true
	vel.y = -JUMP_SPEED
	if is_instance_valid(_hint):
		_hint.queue_free()


func _process(delta: float) -> void:
	if not _world_ready and field.size.x > 0.0:   # recien cuando la pantalla tiene su tamaño
		_reset_world()
		field.queue_redraw()
	if not started or over or field.size.x <= 0.0:
		return
	step(minf(delta, 1.0 / 30.0))


## Un paso del juego (separado para poder probarlo).
func step(delta: float) -> void:
	var w := field.size.x
	# de costado: hacia el dedo (o con las flechas)
	var dir := Input.get_axis("ui_left", "ui_right")
	if dir != 0.0:
		target_x = -1.0
		vel.x = dir * MOVE_SPEED
	elif target_x >= 0.0:
		vel.x = clampf((target_x - pos.x) * 9.0, -MOVE_SPEED, MOVE_SPEED)
	else:
		vel.x = 0.0
	if absf(vel.x) > 20.0:
		player.facing = signf(vel.x)
	pos.x = wrapf(pos.x + vel.x * delta, 0.0, w)   # sale por un costado y entra por el otro
	if target_x >= 0.0 and absf(target_x - pos.x) > w * 0.5:
		target_x = pos.x
	# las nubes que se mueven
	for pl in platforms:
		if pl["kind"] == "move":
			var p2: Vector2 = pl["pos"]
			p2.x += pl["dir"] * 140.0 * delta
			pl["pos"] = p2
			if p2.x < CLOUD_W * 0.5 or p2.x > w - CLOUD_W * 0.5:
				pl["dir"] = -pl["dir"]
	# caer y rebotar en una nube (solo bajando)
	var prev_y := pos.y
	vel.y += GRAVITY * delta
	pos.y += vel.y * delta
	if vel.y > 0.0:
		for pl in platforms:
			var top: float = pl["pos"].y
			if prev_y <= top and pos.y >= top and absf(pos.x - pl["pos"].x) <= pl["w"] * 0.5 + 18.0:
				pos.y = top
				vel.y = -(SPRING_SPEED if pl["kind"] == "spring" else JUMP_SPEED)
				player.celebrate(0)
				Audio.play("click", 1.6 if pl["kind"] == "spring" else 1.25)
				break
	# monedas
	for i in range(coins.size() - 1, -1, -1):
		if coins[i].distance_to(pos + Vector2(0, -PLAYER * 0.5)) < 70.0:
			coins.remove_at(i)
			coins_got += 1
			earned += COIN_VALUE
			_coin_label.text = str(earned)
			Audio.play("coin")
	# la camara sube con el Pompon (nunca baja)
	cam_y = minf(cam_y, pos.y - field.size.y * 0.45)
	best = maxf(best, -pos.y)
	_height_label.text = "%d m" % int(best / 10.0)
	while _stars_done < STAR_HEIGHTS.size() and best >= STAR_HEIGHTS[_stars_done]:
		_stars_done += 1
		_mark(true)
	_generate()
	_place_player()
	field.queue_redraw()
	if pos.y - cam_y > field.size.y + PLAYER:   # se cayo
		_fall()


func _place_player() -> void:
	player.position = Vector2(pos.x - PLAYER * 0.5, pos.y - cam_y - PLAYER + 8.0)


func _fall() -> void:
	if over:
		return
	over = true
	_ended = true
	Audio.play("fail")
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		_show_result(T.s("¡Llegaste a %d metros!") % int(best / 10.0), _stars_done, STAR_HEIGHTS.size())


func _draw_field() -> void:
	var w := field.size.x
	var h := field.size.y
	# el cielo se oscurece al subir
	var k := clampf(best / 9000.0, 0.0, 1.0)
	var top_col := Color("cdeeff").lerp(Color("3b2f6b"), k)
	var bottom_col := Color("eaf7ff").lerp(Color("8a6fc0"), k)
	field.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([top_col, top_col, bottom_col, bottom_col]))
	if k > 0.3:   # estrellitas fijas del fondo
		for i in 40:
			var sp := Vector2(fmod(i * 173.0, w), fmod(i * 311.0 - cam_y * 0.1, h))
			field.draw_circle(sp, 2.5, Color(1, 1, 1, (k - 0.3) * 1.2))
	for pl in platforms:
		var c: Vector2 = pl["pos"] - Vector2(0, cam_y)
		if c.y < -60.0 or c.y > h + 60.0:
			continue
		if pl["kind"] == "ground":
			field.draw_rect(Rect2(0, c.y, w, h), Color("9fdc8e"))
			field.draw_line(Vector2(0, c.y), Vector2(w, c.y), INK, 4.0)
			continue
		var cw: float = pl["w"]
		var col := Color.WHITE if pl["kind"] != "move" else Color("ffe3f0")
		for part in [[-0.32, 14.0, 0.24], [0.0, 6.0, 0.3], [0.32, 14.0, 0.24]]:
			field.draw_circle(c + Vector2(cw * part[0], part[1]), cw * part[2], col)
		field.draw_rect(Rect2(c.x - cw * 0.45, c.y + 10.0, cw * 0.9, 22.0), col)
		field.draw_line(Vector2(c.x - cw * 0.45, c.y + 32.0), Vector2(c.x + cw * 0.45, c.y + 32.0), Color(INK, 0.35), 3.0)
		if pl["kind"] == "spring":   # resorte
			for z in 3:
				field.draw_line(c + Vector2(-14, -4 - z * 9), c + Vector2(14, -8 - z * 9), INK, 4.0, true)
			field.draw_rect(Rect2(c.x - 20, c.y - 36, 40, 10), Color("ff7aa8"))
	for coin in coins:
		var cc: Vector2 = coin - Vector2(0, cam_y)
		field.draw_circle(cc, 20.0, Color("ffcf3f"))
		field.draw_arc(cc, 20.0, 0.0, TAU, 20, Color("b87400"), 3.0, true)
		field.draw_circle(cc + Vector2(-6, -6), 5.0, Color(1, 1, 1, 0.7))
