extends Control
## Menu principal: paisaje, logo, los amigos Pompon y opciones de sonido.

const LOGO_BBCODE := "[color=#f2b705]P[/color][color=#4cc9a4]o[/color][color=#f2b705]m[/color][color=#4cc9a4]p[/color][color=#f28ca8]o[/color][color=#9b7bd8]n[/color]"
const FRIENDS := [
	["Conejo", "a8d8f0", "f4f9ff", "redondos", "sonrisa", "redonda", {"hat": "hat_beanie", "shirt": "shirt_sweater"}],
	["Canino", "e8c08c", "fff0d8", "ovalados", "colmillitos", "ovalada", {"glasses": "glasses_round", "shirt": "shirt_red"}],
	["Dragon", "9ad9a8", "e8f8d8", "brillantes", "sonrisa", "ancha", {"shirt": "shirt_hoodie"}],
	["Felino", "ffb3cc", "fff0f5", "tiernos", "bigotes", "redonda", {"hat": "hat_bow", "shirt": "shirt_dress"}],
	["Ave", "ffe27a", "fff6cf", "redondos", "pico", "ancha", {"hat": "hat_cap"}],
]

var _music_button: IconButton
var _sfx_button: IconButton
var _profile: ProfileDialog
var _logo: RichTextLabel
var _logo_top := 0.0
var _play: Button
var _reset_button: IconButton
var _cloud_button: IconButton
var _notice: BigNotice


## Boton redondo con un icono dibujado ("music", "sound" o "reset"); se tacha cuando esta apagado.
class IconButton extends Button:
	var kind := "music"
	var on := true

	func _draw() -> void:
		var c := size * 0.5
		var line := Color("5b3a4a") if on else Color("9a8590")
		if kind == "cloud":  # nube con flechita (guardar / recuperar); punto rojo si hay que elegir partida
			var cl := Color("5bb8f5")
			draw_circle(c + Vector2(-10, 4), 11.0, cl)
			draw_circle(c + Vector2(4, -4), 14.0, cl)
			draw_circle(c + Vector2(15, 6), 9.0, cl)
			draw_rect(Rect2(c + Vector2(-10, 4), Vector2(25, 11)), cl)
			draw_line(c + Vector2(2, 12), c + Vector2(2, -2), Color.WHITE, 4.0, true)
			draw_polyline(PackedVector2Array([c + Vector2(-5, 4), c + Vector2(2, -3), c + Vector2(9, 4)]), Color.WHITE, 4.0, true)
			if not on:
				draw_circle(c + Vector2(26, -26), 9.0, Color("e0295f"))
			return
		if kind == "reset":  # flecha en circulo: empezar de nuevo
			draw_arc(c, 17.0, -0.4 * PI, 1.3 * PI, 24, line, 5.0, true)
			var tip := c + Vector2(cos(-0.4 * PI), sin(-0.4 * PI)) * 17.0
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-9, -6), tip + Vector2(9, -2), tip + Vector2(-2, 10)]), line)
			return
		if kind == "music":
			draw_circle(c + Vector2(-9, 13), 11.0, line)
			draw_line(c + Vector2(1, 13), c + Vector2(1, -19), line, 5.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(1, -19), c + Vector2(20, -10), c + Vector2(20, -2), c + Vector2(1, -10)]), line)
		else:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-22, -8), c + Vector2(-11, -8), c + Vector2(2, -20), c + Vector2(2, 20), c + Vector2(-11, 8), c + Vector2(-22, 8)]), line)
			if on:
				draw_arc(c + Vector2(4, 0), 10.0, -0.9, 0.9, 12, line, 4.0, true)
				draw_arc(c + Vector2(4, 0), 20.0, -0.9, 0.9, 14, line, 4.0, true)
		if not on:
			draw_line(c + Vector2(-24, -24), c + Vector2(24, 24), Color("e0609e"), 6.0, true)


func _ready() -> void:
	for mode in ["sky", "air", "land"]:
		var layer := MenuBackdrop.new()
		layer.mode = mode
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(layer)

	# logo con las letras que ondulan suavemente
	_logo = RichTextLabel.new()
	_logo.bbcode_enabled = true
	_logo.fit_content = true
	_logo.scroll_active = false
	_logo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_logo_top = 96.0
	_logo.offset_top = _logo_top
	_logo.offset_left = 10
	_logo.offset_right = -10
	_logo.add_theme_font_size_override("normal_font_size", 150)
	_logo.add_theme_color_override("font_outline_color", Color.WHITE)
	_logo.add_theme_constant_override("outline_size", 22)
	_logo.text = "[center][wave amp=14.0 freq=2.5 connected=0]%s[/wave][/center]" % LOGO_BBCODE
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)

	var logo2 := RichTextLabel.new()
	logo2.bbcode_enabled = true
	logo2.fit_content = true
	logo2.scroll_active = false
	logo2.set_anchors_preset(Control.PRESET_TOP_WIDE)
	logo2.offset_top = 262
	logo2.offset_left = 10
	logo2.offset_right = -10
	logo2.add_theme_font_size_override("normal_font_size", 118)
	logo2.add_theme_color_override("font_outline_color", Color.WHITE)
	logo2.add_theme_constant_override("outline_size", 22)
	logo2.text = "[center][wave amp=12.0 freq=2.5 connected=0][color=#f28ca8]F[/color][color=#f2b705]r[/color][color=#4cc9a4]i[/color][color=#9b7bd8]e[/color][color=#f28ca8]n[/color][color=#f2b705]d[/color][color=#4cc9a4]s[/color][/wave][/center]"
	logo2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo2)

	# cartelito debajo del logo
	var tag := PanelContainer.new()
	tag.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tag.offset_left = -300
	tag.offset_right = 300
	tag.offset_top = 412
	tag.offset_bottom = 470
	tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var tag_style := StyleBoxFlat.new()
	tag_style.bg_color = Color(1, 1, 1, 0.8)
	tag_style.border_color = Color.WHITE
	tag_style.set_border_width_all(3)
	tag_style.set_corner_radius_all(30)
	tag_style.content_margin_top = 4
	tag_style.content_margin_bottom = 4
	tag.add_theme_stylebox_override("panel", tag_style)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tag)
	var tag_label := Label.new()
	tag_label.text = "Cuida a tu Pompon y aprende jugando"
	tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag_label.add_theme_font_size_override("font_size", 26)
	tag_label.add_theme_color_override("font_color", Color("a0527a"))
	tag.add_child(tag_label)

	# los cinco amigos sobre la colina: el del medio mas grande
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = -360
	row.offset_right = 360
	row.offset_top = -810
	row.offset_bottom = -378
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", -26)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var order := [0, 1, 3, 2, 4]  # Conejo, Canino, Felino (centro), Dragon, Ave
	var widths := [138, 158, 214, 158, 138]
	var friends: Array = []
	for n in 5:
		var f: Array = FRIENDS[order[n]]
		var v := PomponView.new()
		v.custom_minimum_size = Vector2(widths[n], widths[n] * 1.86)
		v.size_flags_vertical = Control.SIZE_SHRINK_END
		v.set_pompon(PomponView.make_sample(f[0], Color(f[1]), Color(f[2]), f[3], f[4], f[5]), f[6])
		v.petted.connect(func(): Audio.play(["voice_a", "voice_b", "voice_c"].pick_random(), randf_range(0.9, 1.2)))
		row.add_child(v)
		friends.append(v)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 110
	box.offset_right = -110
	box.offset_top = -330
	box.offset_bottom = -92
	box.add_theme_constant_override("separation", 22)
	add_child(box)

	_play = Button.new()
	_play.text = "¡Jugar!"
	_play.custom_minimum_size = Vector2(0, 124)
	_play.add_theme_font_size_override("font_size", 64)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_play.add_theme_color_override(state, Color.WHITE)
	_play.add_theme_color_override("font_outline_color", Color("c2477d"))
	_play.add_theme_constant_override("outline_size", 12)
	_play.add_theme_stylebox_override("normal", _play_style(Color("ff8fb8"), 8))
	_play.add_theme_stylebox_override("hover", _play_style(Color("ff9dc2"), 8))
	_play.add_theme_stylebox_override("pressed", _play_style(Color("f0709f"), 0))
	_play.pressed.connect(_on_play)
	box.add_child(_play)

	var opts := HBoxContainer.new()
	opts.alignment = BoxContainer.ALIGNMENT_CENTER
	opts.add_theme_constant_override("separation", 28)
	box.add_child(opts)
	_music_button = _icon_button(opts, "music", func():
		Audio.set_music_on(not Audio.music_on)
		_update_labels())
	_sfx_button = _icon_button(opts, "sound", func():
		Audio.set_sfx_on(not Audio.sfx_on)
		_update_labels())
	_cloud_button = _icon_button(opts, "cloud", _open_cloud)
	_reset_button = _icon_button(opts, "reset", _ask_reset)
	_reset_button.visible = _has_progress()   # sin partida no hay nada que borrar
	_update_labels()

	var foot := Label.new()
	foot.text = "Sin anuncios · Hecho con cariño"
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -56
	foot.offset_bottom = -16
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 20)
	foot.add_theme_color_override("font_color", Color.WHITE)
	foot.add_theme_color_override("font_outline_color", Color("4f9a6a"))
	foot.add_theme_constant_override("outline_size", 6)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(foot)

	_animate_in.call_deferred(friends)


## Entrada animada: el logo cae, los amigos saltan uno por uno y "Jugar" late suavemente.
func _animate_in(friends: Array) -> void:
	_logo.modulate.a = 0.0
	_logo.offset_top = _logo_top - 60.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_logo, "modulate:a", 1.0, 0.5)
	tw.tween_property(_logo, "offset_top", _logo_top, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in friends.size():
		var v: Control = friends[i]
		v.pivot_offset = Vector2(v.size.x * 0.5, v.size.y)
		v.scale = Vector2(0.01, 0.01)
		var t2 := create_tween()
		t2.tween_interval(0.25 + 0.12 * i)
		t2.tween_property(v, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_play.pivot_offset = _play.size * 0.5
	var pulse := create_tween().set_loops()
	pulse.tween_property(_play, "scale", Vector2(1.04, 1.04), 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(_play, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)


func _play_style(bg: Color, shadow: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color.WHITE
	sb.set_border_width_all(8)
	sb.set_corner_radius_all(68)
	sb.shadow_color = Color("c2477d", 0.45)
	sb.shadow_size = shadow
	sb.shadow_offset = Vector2(0, 8)
	return sb


func _icon_button(parent: Control, kind: String, callback: Callable) -> IconButton:
	var b := IconButton.new()
	b.kind = kind
	b.custom_minimum_size = Vector2(88, 88)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.9)
	sb.border_color = Color.WHITE
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(44)
	sb.shadow_color = Color(0.36, 0.23, 0.29, 0.22)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


## La primera vez se pregunta el nombre y el sexo del jugador; despues se entra directo.
func _on_play() -> void:
	if GameState.has_profile():
		_enter_game()
		return
	if _profile != null:
		return
	_profile = ProfileDialog.new()
	add_child(_profile)
	_profile.setup(false)
	_profile.accepted.connect(_enter_game)


## Sin Pompon todavia (o tras una despedida): primero la adopcion; si ya tiene uno, directo a la casa.
func _enter_game() -> void:
	var scene := "res://scenes/home.tscn" if GameState.pompon != null or GameState.farewell != "" else "res://scenes/welcome.tscn"
	get_tree().change_scene_to_file(scene)


func _update_labels() -> void:
	_music_button.on = Audio.music_on
	_sfx_button.on = Audio.sfx_on
	_music_button.queue_redraw()
	_sfx_button.queue_redraw()
	if _cloud_button != null:
		_cloud_button.on = not Cloud.conflict   # punto rojo: la partida se jugo en otro dispositivo
		_cloud_button.queue_redraw()


# ------------------------------------------------------------------ empezar de nuevo

func _has_progress() -> bool:
	return GameState.pompon != null or GameState.has_profile() or GameState.jobs_done > 0 or GameState.coins > 0


## Dos pasos para no borrar sin querer: primero que se pierde todo, despues "¿seguro?".
func _ask_reset() -> void:
	if _notice != null:
		return
	_notice = BigNotice.new(620.0)
	add_child(_notice)
	_notice.title("¿Empezar de nuevo?")
	_notice.text_line("Vas a perder todo: tu Pompon, tus monedas, tu casa y tu diario.", 28)
	_notice.button("Sí, empezar de nuevo", _confirm_reset, true, Color("e5484d"))
	_notice.button("No, seguir jugando", _close_notice, false)


func _confirm_reset() -> void:
	_close_notice()
	_notice = BigNotice.new(620.0)
	add_child(_notice)
	var sure: String = {"f": "¿Estás segura?", "m": "¿Estás seguro?"}.get(GameState.player_title, "¿De verdad?")
	_notice.title(sure, Color("e5484d"))
	var who := GameState.pompon.display_name() if GameState.pompon != null and GameState.pompon.hatched else "Tu Pompon"
	_notice.text_line("%s no va a volver. Esto no se puede deshacer." % who, 28)
	_notice.button("No, me quedo", _close_notice, true, Color("5fc77f"))
	_notice.button("Borrar todo", _do_reset, false)


func _close_notice() -> void:
	if _notice != null:
		_notice.close()
		_notice = null


func _do_reset() -> void:
	_close_notice()
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/intro.tscn")   # como la primera vez que se abre el juego


# ------------------------------------------------------------------ nube

func _open_cloud() -> void:
	if _notice != null:
		return
	var panel := CloudPanel.new()
	_notice = panel
	add_child(panel)
	panel.closed.connect(func():
		_notice = null
		_reset_button.visible = _has_progress()
		_update_labels())
	panel.restored.connect(_enter_game)
