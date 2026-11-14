class_name NamePicker
extends VBoxContainer
## Grilla de nombres prefabricados (para menores de 13: sin teclado ni texto libre). Muestra de a
## PAGE nombres; "Ver otros" pasa a los siguientes. Al tocar uno queda marcado y se emite `picked`.

signal picked(nm: String)

const COLUMNS := 3
const PAGE := 12

var chosen := ""
var _names: Array = []
var _page := 0
var _grid: GridContainer
var _group := ButtonGroup.new()


func setup(names: Array, current := "") -> NamePicker:
	_names = names
	add_theme_constant_override("separation", 12)
	if current in names:
		chosen = current
		_page = floori(names.find(current) / float(PAGE))
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	add_child(_grid)
	var more := Button.new()
	more.text = T.t("names.more")
	more.custom_minimum_size = Vector2(0, 64)
	more.focus_mode = Control.FOCUS_NONE
	Hud.style_soft(more, 26)
	more.pressed.connect(func():
		_page = (_page + 1) % pages()
		Audio.play("click")
		_fill())
	add_child(more)
	_fill()
	return self


func pages() -> int:
	return maxi(1, ceili(_names.size() / float(PAGE)))


## Los nombres que se ven ahora.
func visible_names() -> Array:
	return _names.slice(_page * PAGE, _page * PAGE + PAGE)


## Elige un nombre (como si se tocara su boton).
func pick(nm: String) -> void:
	if not nm in _names:
		return
	chosen = nm
	if not nm in visible_names():
		_page = floori(_names.find(nm) / float(PAGE))
	_fill()
	picked.emit(nm)


func _fill() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	for n in visible_names():
		var b := Button.new()
		b.text = n
		b.toggle_mode = true
		b.button_group = _group
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(176, 70)
		b.clip_text = true
		Hud.style_soft(b, 28)
		b.add_theme_stylebox_override("hover_pressed", Hud.pill(Hud.PINK, Color.WHITE, 36, 0))
		b.add_theme_stylebox_override("pressed", Hud.pill(Hud.PINK, Color.WHITE, 36, 0))
		for state in ["font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(state, Color.WHITE)
		b.button_pressed = n == chosen
		var nm: String = n
		b.pressed.connect(func():
			chosen = nm
			Audio.play("click")
			picked.emit(nm))
		_grid.add_child(b)
