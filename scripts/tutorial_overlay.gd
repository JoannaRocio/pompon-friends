class_name TutorialOverlay
extends Control
## Un paso del tutorial: oscurece la pantalla y deja iluminado SOLO el boton importante (con un aro
## que late y una flecha). En los pasos "tap" hay que tocar ese boton (el resto de la pantalla no
## responde); en los "next" se lee el cartelito y se toca "¡Entendido!". Siempre se puede saltear.
## Sigue al boton si se mueve (por ejemplo la puerta, que se desliza con la habitacion).

signal done          # el paso termino (se toco el boton o "¡Entendido!")
signal skipped       # el jugador eligio saltar el tutorial

const DIM := Color(0.16, 0.08, 0.14, 0.62)
const PAD := 12.0

var target: Control
var mode := "next"
var _blockers: Array = []
var _ring: Control
var _arrow: GuideArrow
var _card: PanelContainer
var _t := 0.0
var _finished := false


## `target` puede ser null (cartelito en el medio). `extra` = un dibujo para poner en el cartel.
func setup(text: String, target_node: Control, step_mode: String, extra: Control = null) -> TutorialOverlay:
	target = target_node
	mode = step_mode if target_node != null else "next"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 4:   # cuatro paneles oscuros alrededor del boton (el hueco deja pasar el toque)
		var b := ColorRect.new()
		b.color = DIM
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(b)
		_blockers.append(b)
	if mode == "next":   # en los pasos para leer, el boton resaltado no se puede tocar todavia
		var hole_block := Control.new()
		hole_block.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(hole_block)
		_blockers.append(hole_block)
	_ring = Control.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(_draw_ring)
	add_child(_ring)
	_arrow = GuideArrow.new()
	add_child(_arrow)

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", Hud.card(Color("fffafc"), 34, Color("ffb3d1"), 6, 16))
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_card.add_child(col)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(560, 0)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Hud.INK)
	col.add_child(label)
	if extra != null:
		col.add_child(extra)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	var skip := Button.new()
	skip.text = "Saltar tutorial"
	skip.custom_minimum_size = Vector2(0, 60)
	skip.focus_mode = Control.FOCUS_NONE
	Hud.style_soft(skip, 20)
	skip.pressed.connect(func():
		if not _finished:
			_finished = true
			skipped.emit())
	row.add_child(skip)
	if mode == "next":
		var ok := Button.new()
		ok.text = "¡Entendido!"
		ok.custom_minimum_size = Vector2(240, 76)
		ok.focus_mode = Control.FOCUS_NONE
		Hud.style_primary(ok, 30)
		ok.pressed.connect(finish)
		row.add_child(ok)
	elif target is BaseButton:   # paso "tap": sigue cuando se toca el boton resaltado
		(target as BaseButton).pressed.connect(finish, CONNECT_ONE_SHOT)
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 0.25)
	return self


func finish() -> void:
	if _finished:
		return
	_finished = true
	done.emit()


func _hole() -> Rect2:
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return Rect2(size * 0.5, Vector2.ZERO)
	var r := target.get_global_rect()
	r.position -= global_position
	return r.grow(PAD)


func _process(delta: float) -> void:
	_t += delta
	var h := _hole()
	# los cuatro paneles oscuros: arriba, abajo, izquierda y derecha del hueco
	var rects := [Rect2(0, 0, size.x, h.position.y), Rect2(0, h.end.y, size.x, size.y - h.end.y),
		Rect2(0, h.position.y, h.position.x, h.size.y), Rect2(h.end.x, h.position.y, size.x - h.end.x, h.size.y)]
	if h.size == Vector2.ZERO:
		rects = [Rect2(Vector2.ZERO, size), Rect2(), Rect2(), Rect2()]
	if _blockers.size() > 4:
		rects.append(h)
	for i in _blockers.size():
		var r: Rect2 = rects[i]
		_blockers[i].position = r.position
		_blockers[i].size = Vector2(maxf(r.size.x, 0.0), maxf(r.size.y, 0.0))
	_ring.position = h.position
	_ring.size = h.size
	_ring.queue_redraw()
	_arrow.set_target(target if h.size != Vector2.ZERO else null)
	# el cartelito: abajo del boton si hay lugar; si no, arriba
	_card.size = _card.get_combined_minimum_size()
	var cw := minf(_card.size.x, size.x - 40.0)
	var x := clampf(h.get_center().x - cw * 0.5, 20.0, size.x - cw - 20.0)
	var y := size.y * 0.5 - _card.size.y * 0.5
	if h.size != Vector2.ZERO:
		var below := h.end.y + 120.0
		y = below if below + _card.size.y < size.y - 20.0 else h.position.y - _card.size.y - 120.0
		y = clampf(y, 20.0, size.y - _card.size.y - 20.0)
	_card.position = Vector2(x, y)


func _draw_ring() -> void:
	if _ring.size == Vector2.ZERO:
		return
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = Color(1.0, 0.85, 0.3, 0.7 + 0.3 * pulse)
	sb.set_border_width_all(int(5 + 3 * pulse))
	sb.set_corner_radius_all(int(minf(_ring.size.x, _ring.size.y) * 0.5))
	sb.anti_aliasing = true
	_ring.draw_style_box(sb, Rect2(Vector2(-4, -4) * pulse, _ring.size + Vector2(8, 8) * pulse))


## Dibujo de las etapas: Bebe (dias 1-7), Niño (8-21), Adolescente (22-51) y Grande (52+), con la
## etapa actual marcada.
static func growth_card(stage: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(560, 150)
	var names := ["Bebé", "Niño", "Adolescente", "Grande"]
	var days := ["días 1 a 7", "días 8 a 21", "días 22 a 51", "desde el día 52"]
	c.draw.connect(func():
		var step := c.size.x / 4.0
		var font := c.get_theme_default_font()
		c.draw_line(Vector2(step * 0.5, 46), Vector2(step * 3.5, 46), Color("e6d6df"), 8.0)
		for i in 4:
			var center := Vector2(step * (i + 0.5), 46)
			var now := i == stage - 1
			var past := i < stage - 1
			var r := 26.0 + (6.0 if now else 0.0) + (i * 3.0)
			c.draw_circle(center, r, Color("ff7aa8") if now else (Color("ffc2d9") if past else Color("f1eaf0")))
			c.draw_arc(center, r, 0.0, TAU, 32, Hud.INK, 3.0, true)
			Hud.draw_icon(c, "sprout", center, r * 1.1, Color.WHITE if now or past else Color("c9bfd0"), Color(0, 0, 0, 0))
			c.draw_string(font, Vector2(step * i, 104), names[i], HORIZONTAL_ALIGNMENT_CENTER, step, 22, Hud.INK if now else Color(Hud.INK, 0.7))
			c.draw_string(font, Vector2(step * i, 132), days[i], HORIZONTAL_ALIGNMENT_CENTER, step, 17, Color("a0527a")))
	return c
