extends Control
## Vestidor: el Pompon se prueba lo que compraste en un mini cuarto (con la pared y el piso de la
## habitacion actual). Tres solapas: Ropa (gorros, lentes y ropa), Cuarto (pared y piso) y Tazones.
## Tocar una tarjeta lo pone; tocarla de nuevo lo quita.

const TABS := [
	{"key": "wear", "label": "Ropa", "icon": "shirt", "cats": ["hat", "glasses", "shirt"]},
	{"key": "room", "label": "Cuarto", "icon": "house", "cats": ["wall", "floor"]},
	{"key": "bowls", "label": "Tazones", "icon": "apple", "cats": ["bowl_food", "bowl_water"]},
]
const BG := Color("f3ecff")
const ACCENT := Color("ff8fb8")
const STAGE_H := 470.0
const FLOOR_AT := 0.66   # fraccion de alto del mini cuarto donde empieza el piso
const STAGE_RADIUS := 30.0

static var _tab := "wear"   # se recuerda mientras el juego esta abierto

var _stage: Control
var _preview: PomponView
var _room_chip: PanelContainer
var _grid: GridContainer
var _empty: Control
var _scroll: ScrollContainer
var _t := 0.0


func _ready() -> void:
	var bg := Control.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.draw.connect(func(): _draw_backdrop(bg))
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 20
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	# arriba: volver y titulo
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	top.add_child(Hud.back_button(func(): get_tree().change_scene_to_file("res://scenes/home.tscn")))
	var title := Label.new()
	title.text = "Vestidor"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("7a56c4"))
	top.add_child(title)
	var balance := Control.new()  # mismo ancho que el boton de volver: el titulo queda centrado
	balance.custom_minimum_size = Vector2(76, 76)
	top.add_child(balance)

	root.add_child(_make_stage())
	root.add_child(_make_tabs())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	_scroll.add_child(list)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	list.add_child(_grid)
	_empty = _make_empty()
	list.add_child(_empty)

	_rebuild()


func _process(delta: float) -> void:
	_t += delta
	_stage.queue_redraw()  # los tazones y las motitas se mueven un poquito


# ------------------------------------------------------------------ fondo

func _draw_backdrop(cv: Control) -> void:
	cv.draw_rect(Rect2(Vector2.ZERO, cv.size), BG)
	# burbujas suaves de colores
	var spots := [[Vector2(0.08, 0.06), 150.0, Color("ffd6e7")], [Vector2(0.95, 0.2), 190.0, Color("dcd0ff")],
		[Vector2(0.02, 0.62), 170.0, Color("d6f0ff")], [Vector2(1.0, 0.86), 210.0, Color("ffe3cc")]]
	for s in spots:
		cv.draw_circle(Vector2(s[0]) * cv.size, float(s[1]), Color(s[2], 0.55))


# ------------------------------------------------------------- mini cuarto

func _make_stage() -> Control:
	var frame := PanelContainer.new()
	var sb := Hud.card(Color.WHITE, int(STAGE_RADIUS) + 8, Color.WHITE, 3, 10)
	sb.set_content_margin_all(8.0)
	frame.add_theme_stylebox_override("panel", sb)

	_stage = Control.new()
	_stage.custom_minimum_size = Vector2(0, STAGE_H)
	_stage.draw.connect(_draw_stage)
	frame.add_child(_stage)

	_preview = PomponView.new()
	_preview.custom_minimum_size = Vector2(370, 450)
	_preview.size = Vector2(370, 450)
	_preview.petted.connect(func(): Audio.play("pet"))
	_stage.add_child(_preview)
	_stage.resized.connect(_place_preview)

	# en que habitacion se cambia la pared y el piso
	_room_chip = PanelContainer.new()
	var chip_sb := Hud.card(Color(1, 1, 1, 0.9), 24, Color.WHITE, 2, 4)
	chip_sb.content_margin_left = 10.0
	chip_sb.content_margin_right = 16.0
	chip_sb.content_margin_top = 4.0
	chip_sb.content_margin_bottom = 4.0
	_room_chip.add_theme_stylebox_override("panel", chip_sb)
	_room_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_room_chip.position = Vector2(14, 14)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(34, 34)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func():
		icon.draw_circle(icon.size * 0.5, 17.0, Color("a98bea"))
		Hud.draw_icon(icon, "house", icon.size * 0.5, 24.0, Color.WHITE, Color("a98bea")))
	row.add_child(icon)
	var name_label := Label.new()
	name_label.text = Rooms.room_name(GameState.current_room)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Hud.INK)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(name_label)
	_room_chip.add_child(row)
	_stage.add_child(_room_chip)
	return frame


func _place_preview() -> void:
	var floor_y := _stage.size.y * FLOOR_AT
	# los pies quedan sobre el piso, un poco mas abajo de donde empieza
	_preview.position = Vector2((_stage.size.x - _preview.size.x) * 0.5, floor_y + 90.0 - _preview.size.y)


func _draw_stage() -> void:
	var r := Rect2(Vector2.ZERO, _stage.size)
	var floor_y := r.size.y * FLOOR_AT
	var wall: String = GameState.equipped.get("wall", "")
	var floor_id: String = GameState.equipped.get("floor", "")
	ItemArt.draw_wall(_stage, Rect2(0, 0, r.size.x, floor_y), wall, 0.6)
	ItemArt.draw_floor(_stage, Rect2(0, floor_y, r.size.x, r.size.y - floor_y), floor_id, 0.6)
	_stage.draw_line(Vector2(0, floor_y), Vector2(r.size.x, floor_y), Color(Hud.INK, 0.35), 4.0)
	# alfombra redonda debajo del Pompon
	var rug_c := Vector2(r.size.x * 0.5, floor_y + 90.0)
	_ellipse(rug_c, 150.0, 30.0, Rooms.rug_color(GameState.current_room).darkened(0.08))
	_ellipse(rug_c, 136.0, 24.0, Rooms.rug_color(GameState.current_room))

	# en la solapa de tazones se ven los dos tazones al lado del Pompon
	if _tab == "bowls":
		for side in [-1, 1]:
			var food: bool = side < 0
			var id: String = GameState.equipped.get("bowl_food" if food else "bowl_water", "")
			var at := Vector2(r.size.x * 0.5 + side * 225.0, floor_y + 70.0)
			_stage.draw_set_transform(at, 0.0, Vector2(0.62, 0.62))
			BowlArt.draw_bowl(_stage, id, food, 0.2, _t)
		_stage.draw_set_transform(Vector2.ZERO)

	# motitas de luz que flotan
	for i in 6:
		var a := _t * 0.6 + i * 1.7
		var p := Vector2(r.size.x * (0.1 + 0.16 * i) + sin(a) * 12.0, floor_y * (0.25 + 0.1 * float(i % 3)) + cos(a * 0.8) * 10.0)
		_stage.draw_circle(p, 4.0 + 2.0 * sin(a * 1.3), Color(1, 1, 1, 0.55))

	_round_corners(r, STAGE_RADIUS, Color.WHITE)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	_stage.draw_colored_polygon(pts, col)


## Tapa las esquinas del dibujo con el color del marco, asi el mini cuarto queda redondeado.
func _round_corners(r: Rect2, rad: float, col: Color) -> void:
	var corners := [[r.position, Vector2(1, 1)], [Vector2(r.end.x, r.position.y), Vector2(-1, 1)],
		[r.end, Vector2(-1, -1)], [Vector2(r.position.x, r.end.y), Vector2(1, -1)]]
	for cn in corners:
		var corner: Vector2 = cn[0]
		var dir: Vector2 = cn[1]
		var center := corner + dir * rad
		var pts := PackedVector2Array([corner])
		for i in 9:  # cuarto de circulo desde un borde hasta el otro
			var a := PI * 0.5 * float(i) / 8.0
			pts.append(center - Vector2(cos(a) * dir.x, sin(a) * dir.y) * rad)
		_stage.draw_colored_polygon(pts, col)


# ------------------------------------------------------------------ solapas

func _make_tabs() -> Control:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	var group := ButtonGroup.new()
	for t in TABS:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 76)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", Hud.pill(Color("fff1f6"), Color("ffc2d9"), 38, 3))
		b.add_theme_stylebox_override("hover", Hud.pill(Color("ffe4ee"), Color("ffb3d1"), 38, 3))
		b.add_theme_stylebox_override("pressed", Hud.pill(ACCENT, Color.WHITE, 38, 0))
		b.add_theme_stylebox_override("hover_pressed", Hud.pill(ACCENT, Color.WHITE, 38, 0))
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(row)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var kind: String = t["icon"]
		icon.draw.connect(func():
			Hud.draw_icon(icon, kind, icon.size * 0.5, 36.0, Color.WHITE if b.button_pressed else ACCENT, ACCENT if b.button_pressed else Color("fff1f6")))
		row.add_child(icon)
		var label := Label.new()
		label.text = t["label"]
		label.add_theme_font_size_override("font_size", 26)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		var paint := func(on: bool):
			label.add_theme_color_override("font_color", Color.WHITE if on else Hud.INK)
			label.add_theme_color_override("font_outline_color", ACCENT.darkened(0.3))
			label.add_theme_constant_override("outline_size", 8 if on else 0)
			icon.queue_redraw()
		b.toggled.connect(paint)
		var key: String = t["key"]
		b.pressed.connect(func():
			_tab = key
			_scroll.scroll_vertical = 0
			_rebuild())
		b.button_pressed = key == _tab
		paint.call(b.button_pressed)
		tabs.add_child(b)
	return tabs


func _tab_cats() -> Array:
	for t in TABS:
		if t["key"] == _tab:
			return t["cats"]
	return []


# ------------------------------------------------------------------ tarjetas

func _rebuild() -> void:
	_preview.set_pompon(GameState.pompon, GameState.equipped)
	_preview.visible = GameState.has_pompon()
	_room_chip.visible = _tab == "room"
	_stage.queue_redraw()
	for c in _grid.get_children():
		c.queue_free()
	var cats := _tab_cats()
	var ids := []
	for cat in cats:  # agrupados por tipo: gorros, despues lentes, despues ropa
		for id in GameState.owned:
			if Catalog.get_item(id).get("category", "") == cat:
				ids.append(id)
	_empty.visible = ids.is_empty()
	for id in ids:
		_grid.add_child(_make_tile(id))


func _make_tile(id: String) -> Control:
	var item := Catalog.get_item(id)
	var on: bool = GameState.equipped.get(item["category"], "") == id
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 216)
	b.focus_mode = Control.FOCUS_NONE
	var normal := Hud.card(Color("ffeaf2") if on else Color(1, 1, 1, 0.96), 30, ACCENT if on else Color.WHITE, 6 if on else 3, 6)
	var pressed := Hud.card(Color("ffdbe9"), 30, ACCENT, 6, 2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 14
	box.offset_bottom = -10
	box.offset_left = 8
	box.offset_right = -8
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(holder)
	var icon := ItemIcon.new()
	icon.set_item(id, 128.0)
	holder.add_child(icon)
	var name_label := Label.new()
	name_label.text = item["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_constant_override("line_spacing", -4)
	name_label.add_theme_color_override("font_color", Hud.INK)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	if on:  # tilde: lo tiene puesto
		var badge := Control.new()
		badge.custom_minimum_size = Vector2(44, 44)
		badge.size = Vector2(44, 44)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.draw.connect(func():
			badge.draw_circle(Vector2(22, 22), 22.0, Color.WHITE)
			badge.draw_circle(Vector2(22, 22), 18.0, ACCENT)
			Hud.draw_icon(badge, "check", Vector2(22, 22), 28.0, Color.WHITE))
		b.add_child(badge)
		b.resized.connect(func(): badge.position = Vector2(b.size.x - 50, 6))

	b.pressed.connect(func(): _toggle(id))
	return b


func _toggle(id: String) -> void:
	var cat: String = Catalog.get_item(id)["category"]
	var was_on: bool = GameState.equipped.get(cat, "") == id
	GameState.equip(id)
	_rebuild()
	if not was_on and GameState.has_pompon():
		_preview.celebrate(4)  # salto con corazones al estrenar algo


func _make_empty() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 34, Color.WHITE, 3, 8))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(0, 96)
	icon.draw.connect(func():
		var c := icon.size * 0.5
		icon.draw_circle(c, 44.0, Color("ffd6e7"))
		Hud.draw_icon(icon, "bag", c, 60.0, ACCENT, Color("ffd6e7")))
	box.add_child(icon)
	var label := Label.new()
	label.text = "¡Aún no tienes nada aquí!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Hud.INK)
	box.add_child(label)
	var go := Button.new()
	go.text = "Ir a la tienda"
	go.custom_minimum_size = Vector2(320, 80)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.focus_mode = Control.FOCUS_NONE
	Hud.style_primary(go, 30, Color("5fc77f"))
	go.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/shop.tscn"))
	box.add_child(go)
	return card
