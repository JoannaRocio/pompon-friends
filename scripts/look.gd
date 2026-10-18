extends Node
## Autoload "Look": tema visual acogedor (colores calidos, bordes redondeados) para toda la interfaz.

const INK := Color("5b3a4a")
const BTN := Color("ffd9b8")
const BTN_BORDER := Color("d9a06b")


func _ready() -> void:
	get_tree().root.theme = _build()
	# Zonas seguras (notch, barras del sistema): se aplican a cada escena nueva en Android.
	get_tree().node_added.connect(_on_node_added)
	get_tree().root.size_changed.connect(_apply_to_current_scene)


## Margenes (izq, arriba, der, abajo) en pixeles logicos del juego. Solo en Android;
## en escritorio la ventana ya esta dentro del area util, asi que son cero.
func safe_insets() -> Vector4:
	if OS.get_name() != "Android":
		return Vector4.ZERO
	var win := get_window()
	var screen := Vector2(DisplayServer.screen_get_size(win.current_screen))
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if screen.x <= 0.0 or safe.size.x <= 0.0:
		return Vector4.ZERO
	var logical_w := get_viewport().get_visible_rect().size.x
	var px_per_unit := screen.x / maxf(logical_w, 1.0)
	return Vector4(
		safe.position.x, safe.position.y,
		maxf(0.0, screen.x - safe.end.x), maxf(0.0, screen.y - safe.end.y)) / px_per_unit


func _on_node_added(node: Node) -> void:
	# la escena que acaba de cargarse es un Control hijo directo de la ventana
	if node is Control and node.get_parent() == get_tree().root:
		_apply_insets.call_deferred(node)


func _apply_to_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene is Control:
		_apply_insets(scene)


func _apply_insets(scene: Control) -> void:
	if not is_instance_valid(scene) or scene.get_parent() != get_tree().root:
		return
	var m := safe_insets()
	scene.offset_left = m.x
	scene.offset_top = m.y
	scene.offset_right = -m.z
	scene.offset_bottom = -m.w


func _box(bg: Color, border: Color, radius := 26, border_w := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	sb.shadow_color = Color(0.36, 0.23, 0.29, 0.18)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 3)
	return sb


func _build() -> Theme:
	var t := Theme.new()

	# Fredoka (SIL OFL): tipografia redondeada para todo el juego.
	var font := FontVariation.new()
	font.base_font = load("res://assets/fonts/Fredoka.ttf")
	font.variation_opentype = {2003265652: 600}  # etiqueta OpenType "wght" (peso)
	font.variation_embolden = 0.25
	t.default_font = font

	t.set_stylebox("normal", "Button", _box(BTN, BTN_BORDER))
	t.set_stylebox("hover", "Button", _box(Color("ffe6cc"), BTN_BORDER))
	var pressed := _box(Color("f5c396"), BTN_BORDER)
	pressed.shadow_size = 0
	t.set_stylebox("pressed", "Button", pressed)
	var disabled := _box(Color("eadfd3"), Color("cbb9a6"))
	disabled.shadow_size = 0
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("a8978a"))

	t.set_color("font_color", "Label", INK)

	var bar_bg := _box(Color("f0e0cc"), BTN_BORDER, 14, 3)
	bar_bg.shadow_size = 0
	bar_bg.content_margin_top = 0.0
	bar_bg.content_margin_bottom = 0.0
	t.set_stylebox("background", "ProgressBar", bar_bg)
	var bar_fill := _box(Color("93d3a2"), Color("93d3a2"), 14, 0)
	bar_fill.shadow_size = 0
	bar_fill.content_margin_top = 0.0
	bar_fill.content_margin_bottom = 0.0
	t.set_stylebox("fill", "ProgressBar", bar_fill)

	t.set_stylebox("panel", "PanelContainer", _box(Color("fff8ea"), Color("e3c9a6"), 28, 4))

	# Campo de texto (por ejemplo para ponerle nombre al Pompon)
	var field := _box(Color("fffdf6"), BTN_BORDER, 24, 3)
	field.shadow_size = 0
	var field_focus := _box(Color("fffdf6"), Color("ff9ecb"), 24, 4)
	field_focus.shadow_size = 0
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", field_focus)
	t.set_stylebox("read_only", "LineEdit", field)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_selected_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(INK, 0.45))
	t.set_color("caret_color", "LineEdit", INK)
	t.set_color("selection_color", "LineEdit", Color("ffd0e2"))
	return t
