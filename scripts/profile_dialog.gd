class_name ProfileDialog
extends Control
## "¿Cómo te llamas?" + pronombres ("Soy ella" / "Soy él"): se pregunta la primera vez que se juega,
## corto y rapido. Con eso el trabajo dice "Profesora" o "Profesor". Se puede volver a abrir para cambiarlo.

signal accepted
signal cancelled

## Nombres tiernos, sin genero, para el boton "Inventar".
const NAME_IDEAS := ["Coco", "Pelusa", "Manchas", "Mochi", "Copito", "Tofu", "Kiwi", "Canela", "Nube", "Chispa",
	"Bolita", "Galleta", "Pompi", "Migas", "Brisa", "Cacao", "Mimo", "Nuez", "Botón", "Pochi", "Brote", "Pelotita"]

var _edit: LineEdit
var _gender := ""
var _ok: Button
var _random: Button
var _buttons := {}
var _last_idea := ""


func setup(can_cancel: bool) -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.12, 0.2, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -470   # arriba, para que no lo tape el teclado del celular
	panel.offset_bottom = -90
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", _style(Color("fffafc"), Color("ffb3d1"), 34, 6, 16))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var head := Label.new()
	head.text = "¿Cómo te llamas?"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 42)
	head.add_theme_color_override("font_color", Color("d6336c"))
	box.add_child(head)

	_edit = LineEdit.new()
	_edit.placeholder_text = "Tu nombre"
	_edit.max_length = GameState.PLAYER_NAME_MAX
	_edit.text = GameState.player_name
	_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit.custom_minimum_size = Vector2(0, 80)
	_edit.add_theme_font_size_override("font_size", 38)
	_edit.add_theme_stylebox_override("normal", _style(Color("fffdfb"), Color("ffc2d9"), 40, 4, 0))
	_edit.add_theme_stylebox_override("focus", _style(Color("fffdfb"), Color("ff8fb8"), 40, 5, 0))
	_edit.text_changed.connect(func(_t): _refresh())
	_edit.text_submitted.connect(func(_t): _accept())
	box.add_child(_edit)

	_random = Button.new()
	_random.text = "Inventar un nombre"
	_random.custom_minimum_size = Vector2(0, 64)
	_random.add_theme_font_size_override("font_size", 26)
	_random.add_theme_stylebox_override("normal", _style(Color("fff1f6"), Color("ffc2d9"), 32, 4, 4))
	_random.add_theme_stylebox_override("hover", _style(Color("ffe4ee"), Color("ffb3d1"), 32, 4, 4))
	_random.add_theme_stylebox_override("pressed", _style(Color("ffd0e2"), Color("ffb3d1"), 32, 4, 0))
	_random.pressed.connect(_invent_name)
	box.add_child(_random)

	var sex_ask := Label.new()
	sex_ask.text = "Pronombres"
	sex_ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sex_ask.add_theme_font_size_override("font_size", 28)
	box.add_child(sex_ask)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var group := ButtonGroup.new()
	for choice in Jobs.TITLE_CHOICES:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.text = choice["label"]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 84)
		b.add_theme_font_size_override("font_size", 32)
		b.add_theme_stylebox_override("normal", _style(Color("fff1f6"), Color("ffc2d9"), 40, 4, 4))
		b.add_theme_stylebox_override("hover", _style(Color("ffe4ee"), Color("ffb3d1"), 40, 4, 4))
		b.add_theme_stylebox_override("pressed", _style(Color("ff8fb8"), Color.WHITE, 40, 4, 0))
		b.add_theme_stylebox_override("hover_pressed", _style(Color("ff8fb8"), Color.WHITE, 40, 4, 0))
		for state in ["font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(state, Color.WHITE)
		var key: String = choice["key"]
		b.pressed.connect(func():
			_gender = key
			_refresh())
		row.add_child(b)
		_buttons[key] = b
	if GameState.player_title in _buttons:
		_gender = GameState.player_title
		_buttons[_gender].button_pressed = true

	_ok = Button.new()
	_ok.text = "¡Listo!"
	_ok.custom_minimum_size = Vector2(0, 88)
	_ok.add_theme_font_size_override("font_size", 38)
	_ok.add_theme_stylebox_override("normal", _style(Color("ff8fb8"), Color.WHITE, 44, 6, 6))
	_ok.add_theme_stylebox_override("hover", _style(Color("ff9dc2"), Color.WHITE, 44, 6, 6))
	_ok.add_theme_stylebox_override("pressed", _style(Color("f0709f"), Color.WHITE, 44, 6, 0))
	_ok.add_theme_stylebox_override("disabled", _style(Color("f1dbe4"), Color("fffafc"), 44, 6, 0))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		_ok.add_theme_color_override(state, Color.WHITE)
	_ok.add_theme_color_override("font_disabled_color", Color("b99aa8"))
	_ok.pressed.connect(_accept)
	box.add_child(_ok)
	if can_cancel:
		var cancel := Button.new()
		cancel.text = "Cancelar"
		cancel.custom_minimum_size = Vector2(0, 56)
		cancel.add_theme_font_size_override("font_size", 24)
		cancel.pressed.connect(func(): cancelled.emit())
		box.add_child(cancel)
	_refresh()


## Pone un nombre tierno al azar (nunca el mismo dos veces seguidas).
func _invent_name() -> void:
	var pick: String = NAME_IDEAS.pick_random()
	while pick == _last_idea:
		pick = NAME_IDEAS.pick_random()
	_last_idea = pick
	_edit.text = pick
	Audio.play("click")
	_refresh()


func _style(bg: Color, border: Color, radius: int, border_w: int, shadow: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	sb.shadow_color = Color(0.76, 0.28, 0.49, 0.3)
	sb.shadow_size = shadow
	sb.shadow_offset = Vector2(0, 4)
	return sb


func _refresh() -> void:
	_ok.disabled = GameState.clean_player_name(_edit.text) == "" or _gender == ""


func _accept() -> void:
	if _ok.disabled:
		if GameState.clean_player_name(_edit.text) == "":
			_edit.placeholder_text = "¡Falta tu nombre!"
		return
	GameState.set_profile(_edit.text, _gender)
	Audio.play("success")
	accepted.emit()
