extends MiniGameBase
## Minijuego "Patrones": elige la pieza que sigue en la serie (cada color tiene su forma).

const QUESTIONS := 5
const PALETTE := [
	Color("ff6b7a"), Color("5bb8f5"), Color("5fd48a"),
	Color("ffd24d"), Color("b08be0"), Color("ff9b54"),
]
const OUT := Color("5b3a4a")

var _asked := 0
var _correct := 0
var _answer := -1
var _locked := false

var _series_row: HBoxContainer
var _options_row: HBoxContainer


## Una pieza: circulo, cuadrado, rombo, corazon, estrella o triangulo (segun el color).
class Piece extends Control:
	var color_index := 0
	var unknown := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.44
		if unknown:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(1, 1, 1, 0.7)
			sb.border_color = Color("5fb88a")
			sb.set_border_width_all(6)
			sb.set_corner_radius_all(int(r * 0.5))
			draw_style_box(sb, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0))
			draw_string(get_theme_default_font(), c + Vector2(-r, r * 0.42), "?", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 1.5), Color("5fb88a"))
			return
		var col: Color = PALETTE[color_index]
		var pts := PackedVector2Array()
		match color_index % 6:
			0:
				for i in 32:
					pts.append(c + Vector2(cos(TAU * i / 32.0), sin(TAU * i / 32.0)) * r)
			1:
				var s := r * 0.88
				pts = PackedVector2Array([c + Vector2(-s, -s), c + Vector2(s, -s), c + Vector2(s, s), c + Vector2(-s, s)])
			2:
				pts = PackedVector2Array([c + Vector2(0, -r * 1.1), c + Vector2(r * 0.95, 0), c + Vector2(0, r * 1.1), c + Vector2(-r * 0.95, 0)])
			3:
				for i in 32:
					var a := TAU * i / 32.0
					pts.append(c + Vector2(16.0 * pow(sin(a), 3.0), -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))) * (r / 17.0) + Vector2(0, r * 0.05))
			4:
				for i in 10:
					var a2 := -PI / 2.0 + PI * i / 5.0
					pts.append(c + Vector2(cos(a2), sin(a2)) * (r * 1.12 if i % 2 == 0 else r * 0.5))
			5:
				pts = PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 1.05, r * 0.85), c + Vector2(-r * 1.05, r * 0.85)])
		draw_colored_polygon(pts, col)
		pts.append(pts[0])
		draw_polyline(pts, Color("5b3a4a"), 5.0, true)
		draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.14, Color(1, 1, 1, 0.55))


func _ready() -> void:
	game_id = "pattern"
	_build_chrome(Color("dcf7e6"), QUESTIONS)
	content.add_theme_constant_override("separation", 40)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 44, Color.WHITE, 4, 12))
	content.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	card.add_child(inner)
	inner.add_child(_label("¿Qué sigue?", 40, Color("3f8f68")))
	_series_row = HBoxContainer.new()
	_series_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_series_row.add_theme_constant_override("separation", 6)
	inner.add_child(_series_row)
	_options_row = HBoxContainer.new()
	_options_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_options_row.add_theme_constant_override("separation", 22)
	content.add_child(_options_row)
	_next_question()


func _piece(color_index: int, px: float, unknown := false) -> Piece:
	var p := Piece.new()
	p.color_index = color_index
	p.unknown = unknown
	p.custom_minimum_size = Vector2(px, px)
	return p


func _next_question() -> void:
	if _asked >= QUESTIONS:
		_finish()
		return
	_locked = false
	_asked += 1
	for c in _series_row.get_children():
		c.queue_free()
	for c in _options_row.get_children():
		c.queue_free()

	# Un patron repetido de 2 o 3 piezas; se muestran 5 y se oculta la siguiente.
	var period := 2 + randi() % 2
	var base := range(PALETTE.size())
	base.shuffle()
	var unit := base.slice(0, period)
	for i in 5:
		_series_row.add_child(_piece(unit[i % period], 92))
	_series_row.add_child(_piece(0, 92, true))
	_answer = unit[5 % period]

	var options := [_answer]
	for c in base:
		if options.size() < 3 and c != _answer:
			options.append(c)
	options.shuffle()
	for opt in options:
		var b := Button.new()
		b.custom_minimum_size = Vector2(190, 190)
		Hud.style_soft(b, 20)
		var inner := _piece(opt, 0)
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.offset_left = 28
		inner.offset_top = 28
		inner.offset_right = -28
		inner.offset_bottom = -28
		b.add_child(inner)
		b.set_meta("value", opt)
		b.pressed.connect(_on_option.bind(opt))
		_options_row.add_child(b)


func _on_option(color_index: int) -> void:
	if _locked or _ended:
		return
	_locked = true
	var right := color_index == _answer
	if right:
		_correct += 1
		Audio.play("coin")
	else:
		Audio.play("fail")
	for b in _options_row.get_children():
		if int(b.get_meta("value", -1)) == _answer:
			b.self_modulate = Color(0.55, 0.9, 0.6)
		elif int(b.get_meta("value", -1)) == color_index:
			b.self_modulate = Color(1.0, 0.55, 0.55)
	_mark(right)
	await get_tree().create_timer(0.8).timeout
	if is_inside_tree():
		_next_question()


func _finish() -> void:
	_ended = true
	for c in _series_row.get_children():
		c.queue_free()
	for c in _options_row.get_children():
		c.queue_free()
	var title := "¡Muy bien!" if _correct >= 4 else ("¡Bien!" if _correct >= 2 else "¡Sigue practicando!")
	_show_result(title, _correct, QUESTIONS)
