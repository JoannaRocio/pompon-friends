extends Control
## Bienvenida e inicio de la partida: saluda al jugador por su nombre, deja elegir la especie y el
## sexo del Pompon (las especies solo se ven como sombras: el diseno es sorpresa) y una cigüeña
## trae el huevo. Despues se va a la casa. Pocas palabras, todo con toques grandes.

const SPECIES := ["Felino", "Canino", "Conejo", "Ave", "Dragon", "Raton", "Reptil"]
const SIL_COLOR := Color("7a63a0")
const SIL_SHADER := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.48, 0.39, 0.63, 1.0);
void fragment() {
	COLOR = vec4(tint.rgb, COLOR.a);
}
"""
const PINK := Color("ff8fb8")
const BLUE := Color("74b9ff")
const HOME_SCENE := "res://scenes/home.tscn"

var _step: Control
var _species := ""
var _sex := ""
var _sil_material: ShaderMaterial

# cigueña
var _stork: StorkView
var _egg_view: PomponView
var _nest_front: Control
var _fx: Control
var _caption: Label
var _go_button: Button
var _t := -1.0
var _flap := 0.0
var _hearts: Array = []
var _burst := false
var _landed := false
var _nest := Vector2.ZERO
var _hover := Vector2.ZERO
var _len_target := 300.0
var _first := true


# ------------------------------------------------------------------ nido

class NestPart extends Control:
	var front := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var line := Color("8a5a35")
		if not front:
			var back := PackedVector2Array()
			for i in 40:
				var a := TAU * i / 40.0
				back.append(Vector2(cos(a) * 158.0, sin(a) * 44.0))
			draw_colored_polygon(back, Color("b98556"))
			back.append(back[0])
			draw_polyline(back, line, 5.0, true)
			var inner := PackedVector2Array()
			for i in 40:
				var a2 := TAU * i / 40.0
				inner.append(Vector2(cos(a2) * 134.0, sin(a2) * 30.0 + 4.0))
			draw_colored_polygon(inner, Color("e9cf9c"))
		else:
			var belly := PackedVector2Array()
			for i in 21:
				var a5 := PI * float(i) / 20.0
				belly.append(Vector2(cos(a5) * 158.0, sin(a5) * 96.0))
			draw_colored_polygon(belly, Color("d9a86b"))
			for r in [0.34, 0.6, 0.84]:
				var ring := PackedVector2Array()
				for i in 21:
					var a6 := PI * float(i) / 20.0
					ring.append(Vector2(cos(a6) * 158.0 * r, sin(a6) * 96.0 * r + 44.0 * (1.0 - r) * 0.0))
				draw_polyline(ring, Color("b98556"), 3.5, true)
			for k in range(-3, 4):
				draw_line(Vector2(k * 40.0, 24.0), Vector2(k * 34.0, 24.0 + 64.0 - absf(k) * 8.0), Color("b98556"), 3.5, true)
			belly.append(belly[0])
			draw_polyline(belly, line, 5.0, true)
			var lip := PackedVector2Array()
			for i in 21:
				var a7 := PI * float(i) / 20.0
				lip.append(Vector2(cos(a7) * 158.0, sin(a7) * 44.0))
			draw_colored_polygon(lip, Color("c99560"))
			draw_polyline(lip, line, 5.0, true)


# --------------------------------------------------------------- ayudas

func _ready() -> void:
	_first = not GameState.tips_seen.has("egg1")
	var shader := Shader.new()
	shader.code = SIL_SHADER
	_sil_material = ShaderMaterial.new()
	_sil_material.shader = shader
	for mode in ["sky", "air", "land"]:
		var layer := MenuBackdrop.new()
		layer.mode = mode
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(layer)
	_welcome()


func _new_step() -> Control:
	if _step != null:
		_step.queue_free()
	_step = Control.new()
	_step.set_anchors_preset(Control.PRESET_FULL_RECT)
	_step.modulate.a = 0.0
	add_child(_step)
	create_tween().tween_property(_step, "modulate:a", 1.0, 0.35)
	return _step


func _label(parent: Control, text: String, font_size: int, color: Color, top: float, outline := true) -> Label:
	var l := Label.new()
	l.text = text
	l.set_anchors_preset(Control.PRESET_TOP_WIDE)
	l.offset_top = top
	l.offset_left = 20
	l.offset_right = -20
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", Color.WHITE)
		l.add_theme_constant_override("outline_size", 16)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _style(bg: Color, border: Color, radius: int, border_w: int, shadow: int, shadow_color := Color("c2477d", 0.4)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = shadow_color
	sb.shadow_size = shadow
	sb.shadow_offset = Vector2(0, 6)
	return sb


func _big_button(text: String, bg: Color, font_size := 56) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Color.WHITE)
	b.add_theme_color_override("font_outline_color", bg.darkened(0.3))
	b.add_theme_constant_override("outline_size", 12)
	b.add_theme_stylebox_override("normal", _style(bg, Color.WHITE, 68, 8, 8, bg.darkened(0.35)))
	b.add_theme_stylebox_override("hover", _style(bg.lightened(0.06), Color.WHITE, 68, 8, 8, bg.darkened(0.35)))
	b.add_theme_stylebox_override("pressed", _style(bg.darkened(0.08), Color.WHITE, 68, 8, 0, bg.darkened(0.35)))
	return b


func _pulse(node: Control) -> void:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "scale", Vector2(1.04, 1.04), 0.9).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE)


func _silhouette(species: String, animated := true) -> PomponView:
	var v := PomponView.new()
	v.animated = animated
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.material = _sil_material
	v.set_pompon(PomponView.make_sample(species, Color.WHITE, Color.WHITE), {})
	return v


func _back_button(target: Callable) -> Button:
	var b := Button.new()
	b.set_anchors_preset(Control.PRESET_TOP_LEFT)
	b.offset_left = 28
	b.offset_top = 28
	b.offset_right = 112
	b.offset_bottom = 112
	var sb := _style(Color(1, 1, 1, 0.92), Color.WHITE, 42, 4, 6, Color(0.36, 0.23, 0.29, 0.25))
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, sb)
	b.draw.connect(func():
		var c := b.size * 0.5
		b.draw_polyline(PackedVector2Array([c + Vector2(8, -20), c + Vector2(-10, 0), c + Vector2(8, 20)]), Color("5b3a4a"), 7.0, true))
	b.pressed.connect(target)
	return b


# ----------------------------------------------------------- paso 1: bienvenida

func _welcome() -> void:
	var s := _new_step()
	var who := GameState.player_name if GameState.player_name != "" else T.g("welcome.friend", GameState.player_title)
	var size_px := 104 if who.length() <= 6 else (86 if who.length() <= 9 else 68)
	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 150
	title.offset_left = 10
	title.offset_right = -10
	title.add_theme_font_size_override("normal_font_size", size_px)
	title.add_theme_color_override("default_color", Color("a0527a"))
	title.add_theme_color_override("font_outline_color", Color.WHITE)
	title.add_theme_constant_override("outline_size", 22)
	title.text = "[center][wave amp=14.0 freq=2.5 connected=0]%s[/wave][/center]" % T.t("welcome.hello", {"name": "[color=#d6336c]%s[/color]" % who})
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(title)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = 330
	panel.offset_bottom = 480
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.88), Color.WHITE, 40, 4, 8, Color(0.36, 0.23, 0.29, 0.18)))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(panel)
	var msg := Label.new()
	msg.text = T.t("welcome.first") if _first else T.t("welcome.again")
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.add_theme_font_size_override("font_size", 40)
	msg.add_theme_color_override("font_color", Color("a0527a"))
	panel.add_child(msg)

	# tres sombras misteriosas con signo de pregunta
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = -330
	row.offset_right = 330
	row.offset_top = -800
	row.offset_bottom = -380
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", -14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(row)
	var shown := ["Conejo", "Felino", "Dragon"]
	var widths := [150, 205, 150]
	for i in 3:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(widths[i], widths[i] * 1.86)
		holder.size_flags_vertical = Control.SIZE_SHRINK_END
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(holder)
		var sil := _silhouette(shown[i])
		sil.set_anchors_preset(Control.PRESET_FULL_RECT)
		holder.add_child(sil)
		var q := Label.new()
		q.text = "?"
		q.set_anchors_preset(Control.PRESET_CENTER_TOP)
		q.offset_left = -40
		q.offset_right = 40
		q.offset_top = 6
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.add_theme_font_size_override("font_size", 70)
		q.add_theme_color_override("font_color", Color.WHITE)
		q.add_theme_color_override("font_outline_color", Color("7a63a0"))
		q.add_theme_constant_override("outline_size", 14)
		holder.add_child(q)
		var bob := q.create_tween().set_loops()
		bob.tween_interval(0.25 * i)
		bob.tween_property(q, "offset_top", -10.0, 0.6).set_trans(Tween.TRANS_SINE)
		bob.tween_property(q, "offset_top", 6.0, 0.6).set_trans(Tween.TRANS_SINE)

	var adopt := _big_button(T.t("common.adopt"), PINK, 54)
	adopt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	adopt.offset_left = 90
	adopt.offset_right = -90
	adopt.offset_top = -300
	adopt.offset_bottom = -160
	adopt.pressed.connect(_choose_species)
	s.add_child(adopt)
	_pulse.call_deferred(adopt)


# ----------------------------------------------------------- paso 2: especie

func _choose_species() -> void:
	Audio.play("click")
	var s := _new_step()
	s.add_child(_back_button(_welcome))
	_label(s, T.t("welcome.species"), 84, Color("d6336c"), 120)
	_label(s, T.t("welcome.colors"), 32, Color("a0527a"), 232)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.set_anchors_preset(Control.PRESET_CENTER_TOP)
	grid.offset_left = -330
	grid.offset_right = 330
	grid.offset_top = 330
	grid.grow_horizontal = Control.GROW_DIRECTION_BOTH
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 16)
	s.add_child(grid)
	var cards: Array = []
	for sp in SPECIES:
		cards.append(_species_card(grid, sp))
	cards.append(_species_card(grid, ""))  # sorpresa
	for i in cards.size():
		var c: Control = cards[i]
		c.scale = Vector2(0.01, 0.01)
		c.pivot_offset = c.custom_minimum_size * 0.5
		var tw := c.create_tween()
		tw.tween_interval(0.05 * i)
		tw.tween_property(c, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _species_card(parent: Control, species: String) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(156, 270)
	card.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.92), Color("ffd0e2"), 36, 5, 6, Color(0.36, 0.23, 0.29, 0.2)))
	card.add_theme_stylebox_override("hover", _style(Color("fff0f6"), Color("ffb3d1"), 36, 5, 6, Color(0.36, 0.23, 0.29, 0.2)))
	card.add_theme_stylebox_override("pressed", _style(Color("ffd9e8"), Color("ff8fb8"), 36, 5, 0, Color(0.36, 0.23, 0.29, 0.2)))
	parent.add_child(card)
	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_label.offset_top = -52
	name_label.offset_bottom = -8
	name_label.add_theme_font_size_override("font_size", 27)
	card.add_child(name_label)
	if species == "":
		name_label.text = T.t("welcome.surprise")
		var q := Label.new()
		q.text = "?"
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		q.set_anchors_preset(Control.PRESET_FULL_RECT)
		q.offset_bottom = -52
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		q.add_theme_font_size_override("font_size", 120)
		q.add_theme_color_override("font_color", Color("ff8fb8"))
		card.add_child(q)
		card.pressed.connect(func(): _pick_species(SPECIES.pick_random()))
	else:
		name_label.text = Pompon.species_label(species)
		var sil := _silhouette(species, false)
		sil.set_anchors_preset(Control.PRESET_FULL_RECT)
		sil.offset_top = 14
		sil.offset_bottom = -56
		sil.offset_left = 4
		sil.offset_right = -4
		card.add_child(sil)
		card.pressed.connect(func(): _pick_species(species))
	return card


func _pick_species(species: String) -> void:
	Audio.play("click")
	_species = species
	_choose_sex()


# ------------------------------------------------------------- paso 3: sexo

class SexIcon extends Control:
	var female := true

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var col := Color.WHITE
		if female:
			draw_arc(c + Vector2(0, -8), 22.0, 0.0, TAU, 28, col, 7.0, true)
			draw_line(c + Vector2(0, 14), c + Vector2(0, 42), col, 7.0, true)
			draw_line(c + Vector2(-13, 28), c + Vector2(13, 28), col, 7.0, true)
		else:
			draw_arc(c + Vector2(-6, 8), 22.0, 0.0, TAU, 28, col, 7.0, true)
			var tip := c + Vector2(26, -26)
			draw_line(c + Vector2(10, -8), tip, col, 7.0, true)
			draw_line(tip, tip + Vector2(-18, 0), col, 7.0, true)
			draw_line(tip, tip + Vector2(0, 18), col, 7.0, true)


func _choose_sex() -> void:
	var s := _new_step()
	s.add_child(_back_button(_choose_species))
	_label(s, T.t("welcome.sex"), 78, Color("d6336c"), 120)

	var box := Control.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -190
	box.offset_right = 190
	box.offset_top = -420
	box.offset_bottom = 90
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(box)
	var sil := _silhouette(_species if _species != "" else "Felino")
	sil.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_child(sil)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_left = 40
	row.offset_right = -40
	row.offset_top = -330
	row.offset_bottom = -110
	row.add_theme_constant_override("separation", 26)
	s.add_child(row)
	for entry in [["Hembra", PINK, true], ["Macho", BLUE, false]]:
		var b := _big_button("", entry[1], 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 220)
		var col := VBoxContainer.new()
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(col)
		var icon := SexIcon.new()
		icon.female = entry[2]
		icon.custom_minimum_size = Vector2(0, 100)
		col.add_child(icon)
		var l := Label.new()
		l.text = T.label(entry[0])   # (entry[0] sigue siendo el valor que se guarda)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("font_size", 46)
		l.add_theme_color_override("font_color", Color.WHITE)
		l.add_theme_color_override("font_outline_color", (entry[1] as Color).darkened(0.3))
		l.add_theme_constant_override("outline_size", 10)
		col.add_child(l)
		var sex_value: String = entry[0]
		b.pressed.connect(func(): _pick_sex(sex_value))
		row.add_child(b)


func _pick_sex(sex: String) -> void:
	Audio.play("click")
	_sex = sex
	_adopt()


# ------------------------------------------------- paso 4: la cigüeña trae el huevo

func _adopt() -> void:
	GameState.new_pompon(_species, _sex)   # se guarda ya: si cierran el juego, el huevo igual llego
	var s := _new_step()
	_nest = Vector2(size.x * 0.5, size.y * 0.76)
	var nest_back := NestPart.new()
	nest_back.position = _nest
	s.add_child(nest_back)

	_egg_view = PomponView.new()
	_egg_view.size = Vector2(340, 360)
	_egg_view.position = Vector2(_nest.x - 170.0, _nest.y + 22.0 - 354.0)
	_egg_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_egg_view.set_pompon(GameState.pompon, {})
	_egg_view.pivot_offset = Vector2(170, 354)
	_egg_view.scale = Vector2.ZERO
	s.add_child(_egg_view)

	_nest_front = NestPart.new()
	(_nest_front as NestPart).front = true
	_nest_front.position = _nest
	s.add_child(_nest_front)

	_stork = StorkView.new()
	_stork.scale = Vector2(0.9, 0.9)
	_hover = Vector2(_nest.x - 171.0, size.y * 0.5)
	_stork.position = Vector2(-320.0, _hover.y - 120.0)
	_stork.bundle_len = 110.0
	_stork.egg_color_a = Color("fff1d6")
	s.add_child(_stork)
	_len_target = (_nest.y - 60.0 - _hover.y) / 0.9 + 18.0

	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.draw.connect(_draw_fx)
	s.add_child(_fx)

	_caption = _label(s, T.t("welcome.egg"), 84, Color("d6336c"), 150)
	_caption.modulate.a = 0.0

	_go_button = _big_button(T.t("welcome.go_home"), PINK, 54)
	_go_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_go_button.offset_left = 120
	_go_button.offset_right = -120
	_go_button.offset_top = -250
	_go_button.offset_bottom = -110
	_go_button.modulate.a = 0.0
	_go_button.disabled = true
	_go_button.pressed.connect(_go_home)
	s.add_child(_go_button)
	_t = 0.0


func _go_home() -> void:
	GameState.save_game()
	get_tree().change_scene_to_file(HOME_SCENE)


func _process(delta: float) -> void:
	if _t < 0.0 or _stork == null:
		return
	_t += delta
	_flap += delta * (11.0 if _t < 4.2 else 14.0)
	_stork.flap = _flap
	_stork.queue_redraw()
	var t := _t
	if t < 2.6:
		var k := ease(t / 2.6, 0.45)
		_stork.position = Vector2(lerpf(-320.0, _hover.x, k), _hover.y - 120.0 * (1.0 - k) + sin(t * 2.4) * 12.0)
		_stork.sway = sin(t * 3.0) * 0.14 * (1.0 - k * 0.6)
		_stork.bundle_len = 110.0
	elif t < 3.9:
		var k2 := ease(clampf((t - 2.6) / 1.3, 0.0, 1.0), -1.6)
		_stork.position = Vector2(_hover.x, _hover.y + sin(t * 2.4) * 8.0)
		_stork.bundle_len = lerpf(110.0, _len_target, k2)
		_stork.sway = sin(t * 3.0) * 0.1 * (1.0 - k2)
	else:
		if t >= 4.15 and not _landed:
			_landed = true
			_land()
		var k3 := clampf((t - 4.5) / 1.1, 0.0, 1.0)
		var away := clampf((t - 5.2) / 1.6, 0.0, 1.0)
		_stork.bundle_len = lerpf(_len_target, 90.0, ease(k3, -2.0))
		_stork.squash = clampf(1.0 - (t - 3.9) / 0.4, 0.0, 1.0)
		_stork.sway = sin(t * 4.0) * 0.08
		_stork.position = Vector2(_hover.x + 1100.0 * ease(away, 2.2), _hover.y - 260.0 * ease(away, 1.8) + sin(t * 2.4) * 8.0 * (1.0 - away))
	if t > 3.85 and t < 4.5:
		_stork.squash = clampf((t - 3.85) / 0.15, 0.0, 1.0) * clampf((4.5 - t) / 0.5, 0.0, 1.0)
	if t > 5.0 and _caption.modulate.a < 1.0:
		_caption.modulate.a = minf(1.0, _caption.modulate.a + delta * 2.5)
	if t > 5.4 and _go_button.modulate.a < 1.0:
		_go_button.modulate.a = minf(1.0, _go_button.modulate.a + delta * 3.0)
		if _go_button.modulate.a >= 1.0:
			_go_button.disabled = false
			_pulse(_go_button)
	for h in _hearts:
		h["age"] += delta
		h["p"] = h["p"] + Vector2(h["v"]) * delta
	_hearts = _hearts.filter(func(h): return h["age"] < 1.6)
	_fx.queue_redraw()


## El huevo sale del paño: aparece con un saltito y salen corazones.
func _land() -> void:
	_stork.show_egg = false
	_stork.bundle_state = 1.0
	Audio.play("success")
	var tw := create_tween()
	tw.tween_property(_egg_view, "scale", Vector2(1.12, 0.9), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_egg_view, "scale", Vector2(0.94, 1.08), 0.16).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_egg_view, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_egg_view.celebrate(5)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 12:
		_hearts.append({
			"p": _nest + Vector2(rng.randf_range(-90.0, 90.0), rng.randf_range(-230.0, -120.0)),
			"v": Vector2(rng.randf_range(-24.0, 24.0), rng.randf_range(-90.0, -50.0)),
			"age": -rng.randf_range(0.0, 0.5), "s": rng.randf_range(0.8, 1.5),
			"c": [Color("ff7aa8"), Color("ffb3c8"), Color("ffd34d"), Color("c9a8f0")][i % 4],
		})


func _draw_fx() -> void:
	for h in _hearts:
		var age: float = h["age"]
		if age < 0.0:
			continue
		var a := clampf(1.6 - age, 0.0, 1.0)
		var col: Color = h["c"]
		var pts := PackedVector2Array()
		for i in 32:
			var ang := TAU * i / 32.0
			var x := 16.0 * pow(sin(ang), 3.0)
			var y := -(13.0 * cos(ang) - 5.0 * cos(2.0 * ang) - 2.0 * cos(3.0 * ang) - cos(4.0 * ang))
			pts.append(Vector2(h["p"]) + Vector2(x, y) * float(h["s"]) * 1.1)
		_fx.draw_colored_polygon(pts, Color(col, a))
