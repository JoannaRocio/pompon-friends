class_name ActionButton
extends Button
## Boton de la casa: un circulo de color con un icono blanco y una etiqueta corta debajo.
## Se usa en la barra de abajo (cuidados y lugares) y arriba (menu, misiones, vecinos).

var kind := "star"
var tint := Color("ff8fb8")
var caption := ""
var badge := 64.0
var label_size := 20
var _badge: Control
var _label: Label


class Badge extends Control:
	var owner_button: ActionButton

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var b := owner_button
		var r := minf(size.x, size.y) * 0.5
		var c := size * 0.5
		var pressed := b.button_pressed or (b.is_hovered() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
		draw_circle(c + Vector2(0, 4.0 if not pressed else 1.0), r, Color(b.tint.darkened(0.35), 0.5))
		draw_circle(c, r, Color.WHITE)
		draw_circle(c, r - 4.0, b.tint if not b.disabled else Color("cdbfc6"))
		draw_circle(c + Vector2(-r * 0.28, -r * 0.34), r * 0.42, Color(1, 1, 1, 0.16))
		Hud.draw_icon(self, b.kind, c, r * 1.15, Color.WHITE, b.tint.darkened(0.25))


func setup(icon_kind: String, text_caption: String, color: Color, badge_size := 64.0) -> ActionButton:
	kind = icon_kind
	caption = text_caption
	tint = color
	badge = badge_size
	text = ""
	return self


## Cambia el icono, el texto y el color despues de armado el boton (por ejemplo una habitacion que se abre).
func restyle(icon_kind: String, text_caption: String, color: Color) -> void:
	kind = icon_kind
	tint = color
	caption = text_caption
	if _label != null:
		_label.text = T.label(text_caption)
	if _badge != null:
		_badge.queue_redraw()


func _ready() -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	focus_mode = Control.FOCUS_NONE
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(holder)
	_badge = Badge.new()
	(_badge as Badge).owner_button = self
	_badge.custom_minimum_size = Vector2(badge, badge)
	holder.add_child(_badge)
	if caption != "":
		_label = Label.new()
		_label.text = T.label(caption)   # (caption queda en español: es el id del boton)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.add_theme_font_size_override("font_size", label_size)
		_label.add_theme_color_override("font_color", Hud.INK)
		col.add_child(_label)
	button_down.connect(_press_in)
	button_up.connect(_press_out)
	toggled.connect(func(_on): _badge.queue_redraw())
	mouse_entered.connect(func(): _badge.queue_redraw())
	mouse_exited.connect(func(): _badge.queue_redraw())


func _press_in() -> void:
	pivot_offset = size * 0.5
	create_tween().tween_property(self, "scale", Vector2(0.9, 0.9), 0.07)
	_badge.queue_redraw()


func _press_out() -> void:
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_badge.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED or what == NOTIFICATION_ENABLED:
		if _badge != null:
			_badge.queue_redraw()
