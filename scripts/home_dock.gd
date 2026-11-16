class_name HomeDock
extends PanelContainer
## Barra de abajo de la casa, en dos solapas:
##  - "Pompon": lo que se hace con el Pompon (comer y beber en un solo boton, bañar, caricia y juegos).
##  - "Casa": tienda, vestidor, decorar y las habitaciones (con candado hasta abrirlas).
## Mientras el Pompon es un huevo no hay solapas: solo la Tienda. Lo del cuidador (Trabajo, Diario,
## Misiones, Vecinos) esta arriba en la casa.

signal eat_pressed
signal care_pressed(action_name: String)
signal games_pressed
signal shop_pressed
signal wardrobe_pressed
signal decorate_pressed
signal room_pressed(index: int)

const CARE_ICONS := {"Bañar": ["bubbles", Color("3cc9b0")], "Caricia": ["heart", Color("ff7aa8")]}
const PAGE_HEIGHT := 232.0        # solapa Casa (dos filas)
const POMPON_PAGE_HEIGHT := 120.0  # solapa Pompon (una fila, solo iconos)
const LOCKED_TINT := Color("b9b1bd")

var shop_button: ActionButton
var buttons := {}               # nombre -> boton ("Comer", "Caricia", "Tienda"...), para el tutorial

var _tab_bar: HBoxContainer
var _tab_buttons: Array[Button] = []
var _pages: Array[Control] = []
var _egg_row: HBoxContainer
var _nav_house: HBoxContainer
var _room_buttons: Array[ActionButton] = []
var _tab := 0
var _born := true


func _init() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 14
	offset_right = -14
	offset_bottom = -14
	offset_top = -20
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 38, Color.WHITE, 3, 12))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)

	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 10)
	col.add_child(_tab_bar)
	for i in 2:
		var tb := Button.new()
		tb.text = T.label(["Pompon", "Casa"][i])
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 54)
		tb.focus_mode = Control.FOCUS_NONE
		tb.pressed.connect(show_tab.bind(i))
		_tab_bar.add_child(tb)
		_tab_buttons.append(tb)

	# solapa "Pompon"
	var page_a := VBoxContainer.new()
	page_a.add_theme_constant_override("separation", 6)
	page_a.custom_minimum_size = Vector2(0, POMPON_PAGE_HEIGHT)
	col.add_child(page_a)
	_pages.append(page_a)
	page_a.alignment = BoxContainer.ALIGNMENT_CENTER
	var care := _row(page_a)
	# solo iconos (manzana, gota, burbujas, corazon, joystick): se entienden sin leer
	_button(care, "Comer", "apple", Color("ffa94d"), eat_pressed.emit, 104.0, 22, false)
	for action_name in CARE_ICONS:
		_button(care, action_name, CARE_ICONS[action_name][0], CARE_ICONS[action_name][1], care_pressed.emit.bind(action_name), 104.0, 22, false)
	_button(care, "Juegos", "game", Color("a98bea"), games_pressed.emit, 104.0, 22, false)

	# solapa "Casa"
	var page_b := VBoxContainer.new()
	page_b.add_theme_constant_override("separation", 6)
	page_b.custom_minimum_size = Vector2(0, PAGE_HEIGHT)
	page_b.visible = false
	col.add_child(page_b)
	_pages.append(page_b)
	_nav_house = _row(page_b)
	shop_button = _button(_nav_house, "Tienda", "bag", Color("5fc77f"), shop_pressed.emit, 78.0)
	_button(_nav_house, "Vestidor", "shirt", Color("5bb8f5"), wardrobe_pressed.emit, 78.0)
	_button(_nav_house, "Decorar", "house", Color("ff7aa8"), decorate_pressed.emit, 78.0)
	page_b.add_child(_divider())
	var rooms := _row(page_b)
	for i in Rooms.count():
		var rb := _button(rooms, Rooms.short_name(i), Rooms.LIST[i]["icon"], Color("a98bea"), room_pressed.emit.bind(i), 52.0, 16)
		_room_buttons.append(rb)

	# el huevo: solo la Tienda (Trabajo esta arriba)
	_egg_row = _row(col)
	_egg_row.visible = false
	_apply_tabs()


func _row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	return row


func _divider() -> ColorRect:
	var d := ColorRect.new()
	d.color = Color("f3dbe6")
	d.custom_minimum_size = Vector2(0, 3)
	return d


func _button(row: HBoxContainer, label: String, kind: String, color: Color, callback: Callable, badge: float, label_size := 20, with_label := true) -> ActionButton:
	var b := ActionButton.new().setup(kind, label, color, badge)
	buttons[label] = b
	b.label_size = label_size
	b.show_label = with_label
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, badge + (34.0 if with_label else 8.0))
	b.pressed.connect(callback)
	row.add_child(b)
	return b


func tab_button(i: int) -> Button:
	return _tab_buttons[i]


func show_tab(i: int) -> void:
	_tab = clampi(i, 0, 1)
	_apply_tabs()


func current_tab() -> int:
	return _tab


## Con el Pompon nacido hay dos solapas; siendo huevo, solo la Tienda.
func set_born(born: bool) -> void:
	if born == _born:
		return
	_born = born
	if born:
		shop_button.reparent(_nav_house, false)
		_nav_house.move_child(shop_button, 0)
	else:
		shop_button.reparent(_egg_row, false)
	_apply_tabs()


func _apply_tabs() -> void:
	_tab_bar.visible = _born
	_egg_row.visible = not _born
	for i in _pages.size():
		_pages[i].visible = _born and i == _tab
	for i in _tab_buttons.size():
		if i == _tab:
			Hud.style_primary(_tab_buttons[i], 28)
		else:
			Hud.style_soft(_tab_buttons[i], 28)


## Pone los botones de habitacion al dia: abiertas (la actual en rosa) o con candado y su nivel.
func refresh_rooms(level: int, current: int) -> void:
	for i in _room_buttons.size():
		if Rooms.is_unlocked(i, level):
			_room_buttons[i].restyle(Rooms.LIST[i]["icon"], Rooms.short_name(i), Color("ff7aa8") if i == current else Color("a98bea"))
		else:
			_room_buttons[i].restyle("lock", str(Rooms.unlock_level(i)), LOCKED_TINT)   # candado y el nivel en que abre
