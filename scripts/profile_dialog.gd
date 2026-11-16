class_name ProfileDialog
extends Control
## "¿Cómo te llamas?" + pronombres ("Soy ella" / "Soy él"): se pregunta la primera vez que se juega,
## corto y rapido. Con eso el trabajo dice "Profesora" o "Profesor". Se puede volver a abrir para cambiarlo.
## Menores de 13 (GameState.kids_mode): sin teclado, se elige el nombre de una grilla (NamePicker).

signal accepted
signal cancelled

## Nombres tiernos, sin genero, para el boton "Inventar". Los menores de 13 solo eligen de esta lista
## (sin teclado), asi no se sube a la nube ni a los amigos un nombre de verdad.
const NAME_IDEAS := ["Coco", "Pelusa", "Manchas", "Mochi", "Copito", "Tofu", "Kiwi", "Canela", "Nube", "Chispa",
	"Bolita", "Galleta", "Pompi", "Migas", "Brisa", "Cacao", "Mimo", "Nuez", "Botón", "Pochi",
	"Brote", "Pelotita", "Sol", "Cielo", "Trébol", "Rayito", "Burbuja", "Algodón", "Maní", "Miel",
	"Gomita", "Pixel", "Rulo", "Confite", "Mango", "Fresa", "Anís", "Lunar", "Ciruela", "Bambú"]

var _edit: LineEdit
var _picker: NamePicker
var _gender := ""
var _ok: Button
var _random: Button
var _buttons := {}
var _last_idea := ""


## `cancel_text` cambia el texto del boton de abajo (por ejemplo "Volver" en la partida nueva).
func setup(can_cancel: bool, cancel_text := "") -> void:
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
	if GameState.kids_mode():   # sin teclado: centrado y del alto de la grilla
		panel.offset_top = -300
		panel.offset_bottom = 300
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", _style(Color("fffafc"), Color("ffb3d1"), 34, 6, 16))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var head := Label.new()
	head.text = T.t("profile.title")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 42)
	head.add_theme_color_override("font_color", Color("d6336c"))
	box.add_child(head)

	if GameState.kids_mode():
		_picker = NamePicker.new().setup(NAME_IDEAS, GameState.player_name)
		_picker.picked.connect(func(_n): _refresh())
		box.add_child(_picker)
	else:
		_build_edit(box)

	var sex_ask := Label.new()
	sex_ask.text = T.t("profile.pronouns")
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
		b.text = T.label(choice["label"])
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
	_ok.text = T.t("common.ready")
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
		cancel.text = cancel_text if cancel_text != "" else T.t("common.cancel")
		cancel.custom_minimum_size = Vector2(0, 64)
		cancel.focus_mode = Control.FOCUS_NONE
		Hud.style_soft(cancel, 26)
		cancel.pressed.connect(func(): cancelled.emit())
		box.add_child(cancel)
	_refresh()


func _build_edit(box: VBoxContainer) -> void:
	_edit = LineEdit.new()
	_edit.placeholder_text = T.t("profile.placeholder")
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
	_random.text = T.t("profile.invent")
	_random.custom_minimum_size = Vector2(0, 64)
	_random.add_theme_font_size_override("font_size", 26)
	_random.add_theme_stylebox_override("normal", _style(Color("fff1f6"), Color("ffc2d9"), 32, 4, 4))
	_random.add_theme_stylebox_override("hover", _style(Color("ffe4ee"), Color("ffb3d1"), 32, 4, 4))
	_random.add_theme_stylebox_override("pressed", _style(Color("ffd0e2"), Color("ffb3d1"), 32, 4, 0))
	_random.pressed.connect(_invent_name)
	box.add_child(_random)


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


## El nombre elegido: escrito, o de la grilla (menores de 13).
func _name_value() -> String:
	if _picker != null:
		return _picker.chosen
	return GameState.clean_player_name(_edit.text)


func _refresh() -> void:
	_ok.disabled = _name_value() == "" or _gender == ""


func _accept() -> void:
	if _ok.disabled:
		if _name_value() == "" and _edit != null:
			_edit.placeholder_text = T.t("profile.missing")
		return
	GameState.set_profile(_name_value(), _gender)
	Audio.play("success")
	accepted.emit()
