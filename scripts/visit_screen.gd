extends Control
## Visita a la casa de un vecino: tu Pompon y el suyo en su cuarto.
## - La primera vez que se conocen hay una presentacion timida (se huelen, se hacen mimos o se saludan).
## - Arriba, el panel de amistad: nivel con corazones, barra 0-100 y lo que ya sumo hoy.
## - Abajo, tres actividades con animacion. La primera de cada tipo por dia suma 1 punto; despues se
##   pueden repetir (sin puntos); cada una descansa un ratito despues de usarla.
## - Mientras no haces nada, los Pompons juegan solos. La barra "Socializando" se llena en 20 s: al
##   completarse, Social de tu Pompon queda al maximo y caen monedas (1 vez al dia por vecino).

const AVATAR := 340.0
const PINK := Color("ff7aa8")
const HOME_MINE := 0.28     # posiciones de reposo (fraccion del ancho)
const HOME_THEIRS := 0.70
const FEET := 0.76          # altura de los pies (fraccion del alto)

var _data := {}
var _entry := {}
var _id := ""
var _room: RoomView
var _mine: PomponView
var _theirs: PomponView
var _fx: VisitFx
var _message: Label
var _friend_bar: StatBar
var _social_bar: StatBar
var _hearts: HeartsRow
var _level_label: Label
var _today_dots: Array = []
var _coins_label: Label
var _shown_coins := 0
var _buttons := {}
var _badges := {}             # accion -> insignia (precio o tilde)
var _rings := {}              # accion -> anillo de descanso
var _done := {}               # accion -> ya sumo hoy

var _busy := false            # hay una animacion en curso
var _rest := {}               # accion -> segundos de descanso que le faltan (solo la que se uso)
var _idle := 5.0              # cuenta para el proximo juego espontaneo
var _watch := 0.0             # segundos mirando
var _watch_paid := false
var _carry_gift := false


func _ready() -> void:
	_entry = Neighbors.get_entry(Neighbors.current)
	if _entry.is_empty():
		_entry = Neighbors.all()[0]
		Neighbors.current = _entry["id"]
	_id = _entry["id"]
	_data = Neighbors.build(_entry)
	_watch_paid = GameState.friend_done_today(_id, "watch")
	_shown_coins = GameState.coins

	_room = RoomView.new()
	_room.set_anchors_preset(Control.PRESET_FULL_RECT)
	_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room.world_screens = float(_data.get("screens", 1.0))   # vecinos: una pantalla; amigos de verdad: su cuarto entero
	add_child(_room)
	_room.set_state(_data["wall"], _data["floor"], _data["placed"])

	_theirs = PomponView.new()
	_theirs.facing = -1.0
	_theirs.set_pompon(_data["pompon"], _data["equipped"])
	_theirs.petted.connect(func():
		Audio.play(["voice_a", "voice_b", "voice_c"].pick_random(), randf_range(0.9, 1.2)))
	add_child(_theirs)
	_mine = PomponView.new()
	if GameState.pompon != null:
		_mine.set_pompon(GameState.pompon, GameState.equipped)
	add_child(_mine)
	_fx = VisitFx.new()
	add_child(_fx)
	_fx.coin_arrived.connect(func():
		_shown_coins = mini(_shown_coins + 2, GameState.coins)
		_coins_label.text = str(_shown_coins)
		Audio.play("coin", randf_range(1.0, 1.3)))

	_build_top()
	_build_bottom()
	resized.connect(_layout)
	_layout()
	_refresh()
	_start.call_deferred()


func _can_play() -> bool:
	return GameState.pompon != null and GameState.pompon.hatched


func _layout() -> void:
	for v in [_theirs, _mine]:
		v.size = Vector2(AVATAR, AVATAR)
		v.position.y = size.y * FEET - AVATAR + 6.0
	if not _busy:
		_mine.position.x = _x(HOME_MINE)
		_theirs.position.x = _x(HOME_THEIRS)
	if _room.world_screens > 1.0:
		_room.scroll_to(_room.max_scroll() * 0.5, false)   # el centro de su cuarto


## Posicion x de la vista para que el Pompon quede centrado en la fraccion `f` del ancho.
func _x(f: float) -> float:
	return size.x * f - AVATAR * 0.5


func _head(v: PomponView) -> Vector2:
	return v.position + v.head_point()


func _nose(v: PomponView) -> Vector2:
	return _head(v) + Vector2(v.facing * 80.0, 20.0) * v.body_scale()


func _wait(t: float) -> void:
	await create_tween().tween_interval(t).finished


# ------------------------------------------------------------------ armado

func _build_top() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 20
	row.offset_right = -20
	row.offset_top = 20
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	var back := Hud.back_button(func(): get_tree().change_scene_to_file("res://scenes/town.tscn" if Town.from_town else "res://scenes/neighbors.tscn"))
	back.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(back)

	# panel de amistad
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 32, Color.WHITE, 3, 8))
	row.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	card.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	var title := Label.new()
	var player := str(_data.get("player", ""))
	title.text = "Casa de %s" % _data["name"] if player == "" else "%s (de %s)" % [_data["name"], player]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("7a56c4"))
	head.add_child(title)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 4)
	coin_row.add_child(Hud.coin_icon(30.0))
	_coins_label = Label.new()
	_coins_label.text = str(_shown_coins)
	_coins_label.add_theme_font_size_override("font_size", 26)
	_coins_label.add_theme_color_override("font_color", Color("b87400"))
	coin_row.add_child(_coins_label)
	head.add_child(coin_row)

	var lvl := HBoxContainer.new()
	lvl.add_theme_constant_override("separation", 8)
	col.add_child(lvl)
	_hearts = HeartsRow.new().setup(1, 24.0, Neighbors.LEVELS.size())
	lvl.add_child(_hearts)
	_level_label = Label.new()
	_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level_label.add_theme_font_size_override("font_size", 22)
	_level_label.add_theme_color_override("font_color", PINK.darkened(0.2))
	lvl.add_child(_level_label)
	var today := Label.new()
	today.text = "Hoy"
	today.add_theme_font_size_override("font_size", 18)
	today.add_theme_color_override("font_color", Color(Hud.INK, 0.6))
	lvl.add_child(today)
	for key in Neighbors.DAILY_KEYS:
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(28, 28)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var look := Neighbors.daily_look(key)
		var k: String = key
		dot.draw.connect(func():
			var tint: Color = look[1] if GameState.friend_done_today(_id, k) else Color("e6dce3")
			dot.draw_circle(Vector2(14, 14), 14.0, tint)
			Hud.draw_icon(dot, look[0], Vector2(14, 14), 19.0, Color.WHITE, tint))
		lvl.add_child(dot)
		_today_dots.append(dot)

	_friend_bar = StatBar.new().setup("", "heart", PINK)
	_friend_bar.custom_minimum_size = Vector2(0, 34)
	_friend_bar.font_size = 17
	_friend_bar.warn_low = false
	_friend_bar.max_value = float(Neighbors.MAX_POINTS)
	col.add_child(_friend_bar)

	# se llena mientras se quedan juntos
	_social_bar = StatBar.new().setup("", "people", Color("5fc77f"))
	_social_bar.custom_minimum_size = Vector2(0, 34)
	_social_bar.font_size = 17
	_social_bar.warn_low = false
	_social_bar.max_value = Neighbors.WATCH_SECONDS
	col.add_child(_social_bar)
	_update_social_bar()


func _build_bottom() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 20
	box.offset_right = -20
	box.offset_top = -290
	box.offset_bottom = -20
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	# globo: lo que pasa
	var bubble := PanelContainer.new()
	var sb := Hud.card(Color(1, 1, 1, 0.96), 30, Color.WHITE, 3, 6)
	sb.content_margin_left = 22.0
	sb.content_margin_right = 22.0
	bubble.add_theme_stylebox_override("panel", sb)
	box.add_child(bubble)
	_message = Label.new()
	_message.text = "¡Hola! ¿Qué hacemos?"
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(500, 0)
	_message.add_theme_font_size_override("font_size", 24)
	_message.add_theme_color_override("font_color", Hud.INK)
	bubble.add_child(_message)
	var tail := Control.new()  # piquito del globo
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tail.show_behind_parent = true
	bubble.add_child(tail)
	tail.draw.connect(func():
		# el piquito sale del borde de arriba del globo, hacia el vecino que habla
		var x := tail.size.x * 0.66
		var y := -sb.content_margin_top + 4.0
		tail.draw_colored_polygon(PackedVector2Array([Vector2(x - 20, y), Vector2(x + 20, y), Vector2(x + 10, y - 26)]), Color(1, 1, 1, 0.96)))
	bubble.resized.connect(tail.queue_redraw)

	# tres acciones redondas
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 36, Color.WHITE, 3, 8))
	box.add_child(card)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	for act in Neighbors.ACTIONS:
		var key: String = act["key"]
		var b := ActionButton.new().setup(act["icon"], act["short"], Color(act["color"]), 82.0)
		b.label_size = 22
		b.custom_minimum_size = Vector2(150, 126)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_action.bind(key))
		row.add_child(b)
		_buttons[key] = b
		# anillo que se llena mientras los Pompons descansan
		var ring := Control.new()
		ring.set_anchors_preset(Control.PRESET_FULL_RECT)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tint := Color(act["color"])
		ring.draw.connect(func():
			var left: float = _rest.get(key, 0.0)
			if left <= 0.0 or _busy or b._badge == null:
				return
			var c: Vector2 = b._badge.get_global_rect().get_center() - b.global_position
			var k := 1.0 - left / Neighbors.REST_SECONDS
			ring.draw_arc(c, 46.0, -PI / 2.0, -PI / 2.0 + TAU * k, 40, tint, 6.0, true))
		b.add_child(ring)
		_rings[key] = ring
		# precio (regalo, si todavia no sumo hoy) o tilde (ya sumo hoy), arriba a la derecha
		var badge := Control.new()
		badge.custom_minimum_size = Vector2(40, 40)
		badge.size = Vector2(40, 40)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cost: int = act["cost"]
		badge.draw.connect(func():
			var c := Vector2(20, 20)
			if _done.get(key, false):
				badge.draw_circle(c, 18.0, Color.WHITE)
				badge.draw_circle(c, 15.0, Color("5fc77f"))
				Hud.draw_icon(badge, "check", c, 22.0, Color.WHITE)
			elif cost > 0:
				Hud.draw_icon(badge, "coin", c, 40.0, Color.WHITE)
				var font := badge.get_theme_default_font()
				badge.draw_string_outline(font, Vector2(0, 28), str(cost), HORIZONTAL_ALIGNMENT_CENTER, 40, 20, 5, Color("b87400"))
				badge.draw_string(font, Vector2(0, 28), str(cost), HORIZONTAL_ALIGNMENT_CENTER, 40, 20, Color.WHITE))
		b.add_child(badge)
		b.resized.connect(func(): badge.position = Vector2(b.size.x * 0.5 + 18.0, 0.0))
		_badges[key] = badge


func _refresh() -> void:
	var pts := int(GameState.friend_points.get(_id, 0))
	_friend_bar.value = float(pts)
	_friend_bar.text = "%d / %d" % [pts, Neighbors.MAX_POINTS]
	_hearts.value = Neighbors.level_index(pts) + 1
	_hearts.queue_redraw()
	_level_label.text = Neighbors.level_name(pts)
	for dot in _today_dots:
		dot.queue_redraw()
	if not _fx.busy():
		_shown_coins = GameState.coins
		_coins_label.text = str(_shown_coins)
	for act in Neighbors.ACTIONS:
		var key: String = act["key"]
		_done[key] = GameState.friend_done_today(_id, key)
		(_badges[key] as Control).queue_redraw()
	_update_buttons()


func _update_buttons() -> void:
	for key in _buttons:
		var b: ActionButton = _buttons[key]
		var off := _busy or float(_rest.get(key, 0.0)) > 0.0 or not _can_play()
		if b.disabled != off:
			b.disabled = off
			if b._badge != null:
				b._badge.queue_redraw()  # el circulo se pinta gris mientras descansan
		(_rings[key] as Control).queue_redraw()


func _update_social_bar() -> void:
	if _watch_paid:
		_social_bar.value = Neighbors.WATCH_SECONDS
		_social_bar.text = "¡Socializaron!"
	else:
		_social_bar.value = _watch
		_social_bar.text = "Socializando..."


# ------------------------------------------------------------------ tiempo

func _process(delta: float) -> void:
	if _carry_gift:
		_fx.gift_pos = _head(_mine) + Vector2(0, -130.0 * _mine.body_scale())
	if not _rest.is_empty() and not _busy:
		for key in _rest.keys():
			_rest[key] = float(_rest[key]) - delta
			if _rest[key] <= 0.0:
				_rest.erase(key)
		_update_buttons()
	if not _can_play():
		return
	# barra Socializando: al llenarse, Social al maximo y monedas (una vez por dia con este vecino)
	if not _watch_paid:
		_watch = minf(_watch + delta, Neighbors.WATCH_SECONDS)
		_update_social_bar()
		if _watch >= Neighbors.WATCH_SECONDS:
			_watch_paid = true
			var got := GameState.friend_watch_reward(_id)
			_update_social_bar()
			if got > 0:
				var between := (_head(_mine) + _head(_theirs)) * 0.5
				var target := _coins_label.get_global_rect().get_center() - global_position
				_fx.drop_coins(between, target, size.y * FEET, got / 2)
				_fx.burst("heart", _head(_mine) + Vector2(0, -90), 3)
				_mine.celebrate(4)
				_message.text = "¡Socializaron un montón! +%d monedas" % got
	# juegos espontaneos cuando no haces nada
	if not _busy:
		_idle -= delta
		if _idle <= 0.0:
			_idle = randf_range(5.0, 8.0)
			_idle_moment()


## Algo chiquito que hacen solos (no suma puntos).
func _idle_moment() -> void:
	match ["look", "hop", "wander"].pick_random():
		"look":
			_face_each_other()
			_fx.burst("heart", _head([_mine, _theirs].pick_random()) + Vector2(0, -90), 1)
		"hop":
			var who: PomponView = [_mine, _theirs].pick_random()
			who.celebrate(0)
			_fx.burst("note", _head(who) + Vector2(0, -100), 2)
		"wander":
			_busy = true
			await _walk_to(_mine, randf_range(0.2, 0.4), 1.0)
			_face_each_other()
			_busy = false


# ------------------------------------------------------------------ movimientos

func _walk_to(v: PomponView, f: float, secs: float) -> void:
	var tx := _x(f)
	if absf(tx - v.position.x) < 2.0:
		return
	v.facing = 1.0 if tx > v.position.x else -1.0
	v.walking = true
	var tw := create_tween()
	tw.tween_property(v, "position:x", tx, secs).set_trans(Tween.TRANS_SINE)
	await tw.finished
	v.walking = false


func _face_each_other() -> void:
	_mine.facing = 1.0 if _mine.position.x <= _theirs.position.x else -1.0
	_theirs.facing = -_mine.facing


func _lean(v: PomponView, angle: float, secs: float) -> void:
	var tw := create_tween()
	tw.tween_property(v, "lean", angle, secs).set_trans(Tween.TRANS_SINE)
	await tw.finished


func _plus(text: String) -> void:
	_fx.burst("plus", _head(_theirs) + Vector2(0, -140.0 * _theirs.body_scale()), 1, 0.0, text)


# ------------------------------------------------------------------ llegada y presentacion

func _start() -> void:
	if not _can_play():
		return
	if not GameState.has_met(_id):
		await _first_meet()
	var v := GameState.friend_visit(_id)
	if v["ok"] and _entry.get("real", false):
		Friends.send_event(_entry["code"], "visit")   # a tu amigo le llega el aviso
	if v["ok"]:
		_plus("+1")
		_message.text = "¡+1 de amistad por visitar!"
	_refresh()


## La primera vez que se ven: timidos, y despues se huelen, se hacen mimos o se saludan (al azar).
func _first_meet() -> void:
	_busy = true
	_update_buttons()
	_message.text = "¡Es la primera vez que se ven!"
	_mine.position.x = _x(0.16)
	_theirs.position.x = _x(0.84)
	_face_each_other()
	for v in [_mine, _theirs]:
		v.face_mood = "shy"
	await _wait(0.6)
	_fx.burst("dots", _head(_theirs) + Vector2(0, -130.0 * _theirs.body_scale()), 1, 0.0)
	var back_x := _theirs.position.x
	var hide := create_tween()  # el vecino se esconde un poquito
	hide.tween_property(_theirs, "position:x", back_x + 26.0, 0.35)
	hide.tween_property(_theirs, "position:x", back_x, 0.5).set_delay(0.5)
	await _wait(0.9)
	_fx.burst("sweat", _head(_mine) + Vector2(50, -60) * _mine.body_scale(), 1, 0.0)
	_fx.burst("dots", _head(_mine) + Vector2(0, -130.0 * _mine.body_scale()), 1, 0.0)
	await _wait(1.0)
	_message.text = "Se acercan despacito..."
	_walk_to(_mine, 0.36, 2.0)
	await _walk_to(_theirs, 0.64, 2.0)
	_face_each_other()
	await _wait(0.3)

	match ["sniff", "nuzzle", "greet"].pick_random():
		"sniff":
			_message.text = "Se huelen..."
			for i in 4:
				var who: PomponView = _mine if i % 2 == 0 else _theirs
				await _lean(who, 0.2, 0.25)
				_fx.burst("sniff", _nose(who), 3, 10.0)
				Audio.play("pet", 1.8)
				await _wait(0.35)
				await _lean(who, 0.0, 0.2)
		"nuzzle":
			_message.text = "Se hacen mimitos..."
			_walk_to(_mine, 0.41, 0.6)
			await _walk_to(_theirs, 0.59, 0.6)
			_face_each_other()
			for i in 3:
				_lean(_mine, 0.22, 0.25)
				await _lean(_theirs, 0.22, 0.25)
				_fx.burst("heart", (_head(_mine) + _head(_theirs)) * 0.5 + Vector2(0, -60), 2)
				Audio.play("pet")
				_lean(_mine, 0.06, 0.25)
				await _lean(_theirs, 0.06, 0.25)
			_lean(_mine, 0.0, 0.2)
			await _lean(_theirs, 0.0, 0.2)
		"greet":
			_message.text = "¡Se saludan!"
			for who in [_mine, _theirs, _mine, _theirs]:
				who.celebrate(0)
				_fx.burst("note", _head(who) + Vector2(0, -100), 2)
				Audio.play(["voice_a", "voice_b", "voice_c"].pick_random(), randf_range(1.0, 1.25))
				await _wait(0.55)

	for v in [_mine, _theirs]:
		v.face_mood = "happy"
		v.celebrate(4)
	_message.text = "¡Ya se conocen!"
	Audio.play("success")
	GameState.mark_met(_id)
	await _wait(1.4)
	for v in [_mine, _theirs]:
		v.face_mood = ""
	_walk_to(_mine, HOME_MINE, 1.0)
	await _walk_to(_theirs, HOME_THEIRS, 1.0)
	_face_each_other()
	_busy = false
	_idle = 6.0
	_update_buttons()


# ------------------------------------------------------------------ actividades

func _on_action(key: String) -> void:
	if _busy or float(_rest.get(key, 0.0)) > 0.0:
		return
	var result := GameState.friend_action(_id, key)
	if not result["ok"]:
		if result["msg"] != "":
			_message.text = result["msg"]
		return
	_busy = true
	_update_buttons()
	_face_each_other()
	match key:
		"pet":
			await _anim_pet()
		"play":
			await _anim_play()
		"gift":
			await _anim_gift()
	_message.text = result["msg"]
	if result["pts"] > 0 and _entry.get("real", false):
		Friends.send_event(_entry["code"], key)
	if result["pts"] > 0:
		_plus("+1")
		var skill: String = Neighbors.get_action(key).get("skill", "")
		if skill != "":
			_fx.burst("plus", _head(_mine) + Vector2(0, -150.0 * _mine.body_scale()), 1, 0.0,
				"+" + String(PomponSkills.SKILLS[skill]["name"]))
	await _walk_to(_mine, HOME_MINE, 0.9)
	_face_each_other()
	for v in [_mine, _theirs]:
		v.face_mood = ""
	_busy = false
	_rest[key] = Neighbors.REST_SECONDS   # descansa solo esta accion; las otras se pueden usar
	_idle = 7.0
	_refresh()


func _anim_pet() -> void:
	_message.text = "Mimitos..."
	await _walk_to(_mine, HOME_THEIRS - 0.17, 0.8)
	_face_each_other()
	_theirs.face_mood = "happy"
	for i in 3:
		await _lean(_mine, 0.26, 0.22)
		_fx.burst("heart", _head(_theirs) + Vector2(0, -80), 2)
		Audio.play("pet", randf_range(0.95, 1.15))
		await _lean(_mine, 0.08, 0.22)
	await _lean(_mine, 0.0, 0.15)
	_theirs.celebrate(4)
	await _wait(0.6)


func _anim_play() -> void:
	_message.text = "¡A jugar a la pelota!"
	await _walk_to(_mine, HOME_MINE + 0.06, 0.5)
	_face_each_other()
	for v in [_mine, _theirs]:
		v.face_mood = "happy"
	var floor_y := size.y * FEET - 40.0
	var a := Vector2(_nose(_mine).x + 20.0, floor_y)
	var b := Vector2(_nose(_theirs).x - 20.0, floor_y)
	_fx.ball_pos = a
	_fx.ball_visible = true
	for i in 4:
		var from := a if i % 2 == 0 else b
		var to := b if i % 2 == 0 else a
		var tw := create_tween()
		tw.tween_method(func(k: float): _fx.ball_pos = from.lerp(to, k) + Vector2(0, -sin(k * PI) * 170.0), 0.0, 1.0, 0.6)
		await tw.finished
		var catcher := _theirs if i % 2 == 0 else _mine
		catcher.celebrate(0)
		_fx.burst("spark", to + Vector2(0, -20), 3, 16.0)
		Audio.play("ding", 1.0 + i * 0.12)
	_fx.ball_visible = false
	_fx.burst("note", (_head(_mine) + _head(_theirs)) * 0.5 + Vector2(0, -80), 3, 40.0)
	Audio.play("success")
	await _wait(0.6)


func _anim_gift() -> void:
	_message.text = "Le llevas un regalo..."
	_fx.gift_open = 0.0
	_fx.gift_visible = true
	_carry_gift = true
	await _walk_to(_mine, HOME_THEIRS - 0.28, 1.0)
	_carry_gift = false
	_face_each_other()
	# lo deja en el piso frente al vecino
	var spot := Vector2(_x(HOME_THEIRS - 0.13) + AVATAR * 0.5, size.y * FEET - 34.0)
	var put := create_tween()
	put.tween_property(_fx, "gift_pos", spot, 0.45).set_trans(Tween.TRANS_QUAD)
	await put.finished
	await _lean(_theirs, 0.2, 0.3)
	var open := create_tween()
	open.tween_property(_fx, "gift_open", 1.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await open.finished
	Audio.play("coin")
	_fx.burst("spark", spot + Vector2(0, -50), 5, 30.0)
	_fx.burst("heart", _head(_theirs) + Vector2(0, -80), 3)
	await _lean(_theirs, 0.0, 0.2)
	_theirs.face_mood = "happy"
	_theirs.celebrate(6)
	await _wait(1.0)
	_fx.gift_visible = false
