class_name BigNotice
extends Control
## Cartel grande en el centro de la pantalla (tutorial, primer trabajo, ascensos): oscurece el fondo y
## la tarjeta aparece con un saltito. Poco texto: un titulo, una linea, dibujos y un boton.

signal closed

var box: VBoxContainer
var _panel: PanelContainer


func _init(width := 640.0) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.12, 0.2, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -width * 0.5
	_panel.offset_right = width * 0.5
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := Hud.card(Color("fffafc"), 44, Color("ffb3d1"), 6, 16)
	sb.set_content_margin_all(28.0)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	_panel.add_child(box)


func _ready() -> void:
	_panel.modulate.a = 0.0
	_pop.call_deferred()


func _pop() -> void:
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.85, 0.85)
	var tw := create_tween().set_parallel()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func title(text: String, color := Color("d6336c"), font_size := 44) -> Label:
	var l := text_line(text, font_size, color)
	return l


func text_line(text: String, font_size := 30, color := Hud.INK) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(400, 0)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	box.add_child(l)
	return l


func add(node: Control) -> Control:
	box.add_child(node)
	return node


## Boton grande. `primary` = color lleno; si no, boton suave.
func button(text: String, callback: Callable, primary := true, color := Color("ff8fb8")) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 92 if primary else 76)
	b.focus_mode = Control.FOCUS_NONE
	if primary:
		Hud.style_primary(b, 38, color)
	else:
		Hud.style_soft(b, 30)
	b.pressed.connect(callback)
	box.add_child(b)
	return b


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


## Tira de dibujos en circulos con flechitas entre medio ("trabajo -> monedas -> Pompon feliz").
## `steps` = [[icono, Color], ...]. Cada circulo da un saltito, uno detras del otro.
static func icon_strip(steps: Array) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size = Vector2(0, 130)
	for i in steps.size():
		if i > 0:
			var arrow := Control.new()
			arrow.custom_minimum_size = Vector2(44, 110)
			arrow.draw.connect(func():
				var c := arrow.size * 0.5
				arrow.draw_polyline(PackedVector2Array([c + Vector2(-10, -16), c + Vector2(8, 0), c + Vector2(-10, 16)]), Color("e0a3bd"), 8.0, true))
			row.add_child(arrow)
		var kind: String = steps[i][0]
		var tint: Color = steps[i][1]
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(118, 118)
		dot.draw.connect(func():
			var c := dot.size * 0.5
			dot.draw_circle(c + Vector2(0, 5), 56.0, Color(tint.darkened(0.35), 0.4))
			dot.draw_circle(c, 56.0, Color.WHITE)
			dot.draw_circle(c, 51.0, tint)
			if kind == "coin":
				Hud.draw_icon(dot, "coin", c, 70.0, Color.WHITE)
			else:
				Hud.draw_icon(dot, kind, c, 66.0, Color.WHITE, tint.darkened(0.25)))
		row.add_child(dot)
		var delay := 0.25 + i * 0.35
		dot.ready.connect(func():
			dot.pivot_offset = Vector2(59, 59)
			var tw := dot.create_tween().set_loops()
			tw.tween_interval(delay)
			tw.tween_property(dot, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_SINE)
			tw.tween_property(dot, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE)
			tw.tween_interval(1.4 - delay))
	return row
