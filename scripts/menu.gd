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
var _lang_button: Button   # idioma (ES / EN)
var _age: BigNotice   # pregunta de edad (partida nueva, antes del nombre)
var _logo: RichTextLabel
var _logo_top := 0.0
var _play: Button
var _reset_button: IconButton
var _cloud_button: IconButton
var _bell_button: IconButton
var _notice: BigNotice
var _lang: BigNotice   # "Elige tu idioma" (la primera vez)


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
		if kind == "bell":  # campana: el aviso semanal en el celular
			draw_colored_polygon(PackedVector2Array([c + Vector2(-16, 10), c + Vector2(-12, -6), c + Vector2(-6, -15), c + Vector2(0, -17),
				c + Vector2(6, -15), c + Vector2(12, -6), c + Vector2(16, 10)]), line)
			draw_rect(Rect2(c + Vector2(-19, 8), Vector2(38, 6)), line)
			draw_circle(c + Vector2(0, 18), 5.0, line)
			if not on:
				draw_line(c + Vector2(-24, -24), c + Vector2(24, 24), Color("e0609e"), 6.0, true)
			return
		if kind == "lang":  # idioma: "ES" o "EN" en un globito
			var font := get_theme_default_font()
			draw_circle(c, 24.0, Color("a98bea"))
			draw_string(font, c + Vector2(-24, 9), T.lang().to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 48, 24, Color.WHITE)
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
	tag_label.text = T.t("menu.tagline")
	tag_label.set_meta("tkey", "menu.tagline")
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
	box.offset_left = 40   # (ancho para los 6 botones redondos; "Jugar" queda angosto, ver abajo)
	box.offset_right = -40
	box.offset_top = -330
	box.offset_bottom = -92
	box.add_theme_constant_override("separation", 22)
	add_child(box)

	_play = Button.new()
	_play.text = T.t("menu.play")
	_play.custom_minimum_size = Vector2(500, 124)
	_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	opts.add_theme_constant_override("separation", 16)
	box.add_child(opts)
	_music_button = _icon_button(opts, "music", func():
		Audio.set_music_on(not Audio.music_on)
		_update_labels())
	_sfx_button = _icon_button(opts, "sound", func():
		Audio.set_sfx_on(not Audio.sfx_on)
		_update_labels())
	_bell_button = _icon_button(opts, "bell", func():
		GameState.notify_on = not GameState.notify_on
		GameState.save_game()
		_update_labels()
		_toast(T.t("menu.notify_on") if GameState.notify_on else T.t("menu.notify_off")))
	_cloud_button = _icon_button(opts, "cloud", _open_cloud)
	_lang_button = _icon_button(opts, "lang", _toggle_language)
	_reset_button = _icon_button(opts, "reset", _ask_reset)
	_reset_button.visible = _has_progress()   # sin partida no hay nada que borrar
	_update_labels()

	var foot := Label.new()
	foot.text = T.t("menu.footer")
	foot.set_meta("tkey", "menu.footer")
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
	_first_steps.call_deferred()


## La primera vez que se abre el juego: elegir el idioma (el del celular ya viene marcado). Y si se volvio
## con "atras" desde la bienvenida, se reabre el "¿Cómo te llamas?" para poder cambiarlo.
func _first_steps() -> void:
	if not is_inside_tree() or get_tree().current_scene != self:   # (en las pruebas el menu no es la escena actual)
		return
	if GameState.has_meta("back_to_name"):
		GameState.remove_meta("back_to_name")
		_ask_name()
	elif GameState.language == "":
		ask_language()


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


## La primera vez se pregunta la edad (para cuidar la privacidad de los chicos), despues el nombre y el
## sexo del jugador; despues se entra directo.
func _on_play() -> void:
	if GameState.has_profile():
		_enter_game()
		return
	if _profile != null or _age != null or _lang != null:
		return
	if GameState.age_group == "":
		_ask_age()
		return
	_ask_name()


## Paso 1 de la partida nueva: la edad. "Volver" cierra la pregunta y deja el menu como estaba.
func _ask_age() -> void:
	_age = FriendSafety.ask_age(self, func(_g):
		_age = null
		_ask_name(), _close_age)


func _close_age() -> void:
	if _age != null:
		_age.close()
		_age = null


## Paso 2: el nombre. "Volver" regresa a la pregunta de edad (para corregirla).
func _ask_name() -> void:
	if _profile != null:
		return
	_profile = ProfileDialog.new()
	add_child(_profile)
	_profile.setup(true, T.t("common.back"))
	_profile.accepted.connect(_enter_game)
	_profile.cancelled.connect(_name_back)


func _name_back() -> void:
	if _profile != null:
		_profile.queue_free()
		_profile = null
	_ask_age()


## Boton "atras" de Android en el menu: si hay una pregunta abierta, vuelve un paso (en vez de salir del juego).
func handle_back() -> bool:
	if _lang != null:
		_choose_language(T.lang())
		return true
	if _profile != null:
		_name_back()
		return true
	if _age != null:
		_close_age()
		return true
	if _notice != null:
		_close_notice()
		return true
	return false


# ------------------------------------------------------------------ idioma

## "Elige tu idioma": dos botones grandes, con el idioma del celular ya marcado. Tocar uno cambia los textos
## del cartel al momento; "¡Listo!" lo guarda. Se muestra la primera vez y se puede cambiar despues con ES/EN.
func ask_language() -> void:
	if _lang != null:
		return
	var picked := [T.lang()]
	_lang = BigNotice.new(620.0)
	add_child(_lang)
	var head := _lang.title(T.t("lang.title"), Color("7a56c4"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	_lang.add(row)
	var group := ButtonGroup.new()
	var ok := []   # (el boton se crea despues: las lambdas lo leen de aca)
	for code in T.LANGS:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.text = T.LANG_NAMES[code]
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 110)
		Hud.style_soft(b, 36)
		var on := Hud.pill(Color("ff8fb8"), Color.WHITE, 36, 4)
		b.add_theme_stylebox_override("pressed", on)
		b.add_theme_stylebox_override("hover_pressed", on)
		for state in ["font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(state, Color.WHITE)
		b.button_pressed = code == picked[0]
		b.pressed.connect(func():
			picked[0] = code
			Audio.play("click")
			TranslationServer.set_locale(code)   # (vista previa: se guarda recien con "¡Listo!")
			head.text = T.t("lang.title")
			ok[0].text = T.t("common.ready"))
		b.set_meta("lang", code)
		row.add_child(b)
	ok.append(_lang.button(T.t("common.ready"), func(): _choose_language(picked[0]), true, Color("5fc77f")))


func _choose_language(code: String) -> void:
	if _lang != null:
		_lang.close()
		_lang = null
	GameState.set_language(code)
	GameState.save_game()
	if is_inside_tree() and get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		_relabel()


## Sin Pompon todavia (o tras una despedida): primero la adopcion; si ya tiene uno, directo a la casa.
func _enter_game() -> void:
	var scene := "res://scenes/home.tscn" if GameState.pompon != null or GameState.farewell != "" else "res://scenes/welcome.tscn"
	get_tree().change_scene_to_file(scene)


## Cartelito que aparece abajo un ratito.
func _toast(text: String) -> void:
	var chip := Hud.chip(text, Color("fff3d1"), Color("8a6d00"), 24)
	chip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	chip.offset_top = -150
	chip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chip)
	var tw := chip.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(chip, "modulate:a", 0.0, 0.5)
	tw.tween_callback(chip.queue_free)


func _update_labels() -> void:
	_music_button.on = Audio.music_on
	_sfx_button.on = Audio.sfx_on
	_music_button.queue_redraw()
	_sfx_button.queue_redraw()
	if _bell_button != null:
		_bell_button.on = GameState.notify_on
		_bell_button.queue_redraw()
	if _cloud_button != null:
		_cloud_button.on = not Cloud.conflict   # punto rojo: la partida se jugo en otro dispositivo
		_cloud_button.queue_redraw()


# ------------------------------------------------------------------ empezar de nuevo

func _has_progress() -> bool:
	return GameState.pompon != null or GameState.has_profile() or GameState.jobs_done > 0 or GameState.coins > 0


## Cambia de idioma (español <-> inglés) y vuelve a armar el menu con los textos nuevos.
func _toggle_language() -> void:
	var next := "en" if T.lang() == "es" else "es"
	GameState.set_language(next)
	Audio.play("click")
	if is_inside_tree() and get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:   # (en las pruebas el menu no es la escena actual)
		_relabel()


## Textos del menu en el idioma actual (sin rearmarlo).
func _relabel() -> void:
	_play.text = T.t("menu.play")
	if _lang_button != null:
		_lang_button.queue_redraw()
	for l in find_children("*", "Label", true, false):
		if l.has_meta("tkey"):
			l.text = T.t(l.get_meta("tkey"))


## Dos pasos para no borrar sin querer: primero que se pierde todo, despues "¿seguro?".
func _ask_reset() -> void:
	if _notice != null:
		return
	_notice = BigNotice.new(620.0)
	add_child(_notice)
	_notice.title(T.t("menu.reset_title"))
	_notice.text_line(T.t("menu.reset_text"), 28)
	_notice.button(T.t("menu.reset_yes"), _confirm_reset, true, Color("e5484d"))
	_notice.button(T.t("menu.reset_no"), _close_notice, false)


func _confirm_reset() -> void:
	_close_notice()
	_notice = BigNotice.new(620.0)
	add_child(_notice)
	_notice.title(T.g("menu.reset_sure", GameState.player_title), Color("e5484d"))
	var who := GameState.pompon.display_name() if GameState.pompon != null and GameState.pompon.hatched else T.t("menu.your_pompon")
	_notice.text_line(T.t("menu.reset_gone", {"name": who}), 28)
	_notice.button(T.t("menu.reset_stay"), _close_notice, true, Color("5fc77f"))
	_notice.button(T.t("menu.reset_all"), _do_reset, false)


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
