class_name RoomView
extends Control
## Habitacion acogedora y ancha (varias pantallas): pared, zocalo, piso, alfombras y los muebles colocados.
## Se recorre deslizando a izquierda y derecha. En modo edicion se arrastran los items (los guarda
## GameState.placed) y los adornos chicos se apoyan sobre mesas, estantes y comodas.

signal selection_changed(item_id: String)
signal panned   # el jugador movio la camara con el dedo

const OUTLINE := Color("5b3a4a")
const FLOOR_START := 0.5  # fraccion de alto donde empieza el piso (16/11/2026: era 0.6; mas piso para decorar)
const FLOOR_Y_RANGE := Vector2(0.54, 0.86)  # donde pueden ir los muebles de piso (centro)
const WALL_Y_RANGE := Vector2(0.10, 0.40)
const BOTTOM_RESERVE := 250.0  # px de abajo ocupados por la barra de botones: los muebles llegan hasta ahi
const EDGE_ZONE := 80.0       # al arrastrar un item cerca del borde, la camara avanza sola
const SNAP_RANGE := 80.0      # que tan cerca de una superficie se pega un adorno

var wall_id := ""
var floor_id := ""
var placed: Array = []      # misma lista que GameState.placed (se edita en el lugar)
var room_index := -1        # que habitacion se muestra (-1 = todos los items, para las visitas)
var world_screens := Rooms.WORLD_SCREENS:
	set(v):
		world_screens = v
		_layout()
## El cuarto se dibuja en `_world` (ancho de todo el mundo) y deslizar solo lo mueve: no hace falta
## volver a dibujar todos los muebles en cada cuadro. Encima van la vineta (fija) y las chispitas.
var _world: Control
var _vignette: Control
var _shine: Control   # chispitas de los especiales
var _canvas: CanvasItem   # donde dibujan las funciones de dibujo (_world o _vignette)
var _specials: Array = []   # items especiales del cuarto (se arma al dibujar el cuarto; las chispitas los recorren cada cuadro)
var scroll := 0.0:
	set(v):
		scroll = clampf(v, 0.0, max_scroll())
		if _world != null:
			_world.position.x = -scroll
var edit_mode := false:
	set(v):
		edit_mode = v
		if not v:
			selected = ""
			_dragging = false
			selection_changed.emit("")
		redraw()
var selected := ""

var hour_override := -1.0   # para pruebas y capturas; -1 usa la hora real

var _sig := 0
var _dragging := false
var _panning := false
var _drag_offset := Vector2.ZERO
var _pointer := Vector2.ZERO
var _snap_support := ""
var _hour_bucket := -1
var _check := 0.0
var _scroll_tween: Tween

# Hora -> [oscuridad de noche (0-1), calidez de amanecer/atardecer (0-1)]
const DAY_KEYS := [
	[0.0, 1.0, 0.0], [5.5, 1.0, 0.0], [7.0, 0.5, 1.0], [8.5, 0.0, 0.4], [10.0, 0.0, 0.0],
	[16.5, 0.0, 0.0], [18.0, 0.3, 1.0], [20.0, 0.8, 0.5], [21.5, 1.0, 0.0], [24.0, 1.0, 0.0],
]
const LIGHT_SOURCES := {"furn_lamp": Vector2(0, -50), "furn_fireplace": Vector2(0, 40), "furn_heat": Vector2(20, -20),
	"toy_lamp": Vector2(0, -20), "toy_candles": Vector2(0, -24), "deco_stars": Vector2.ZERO}


func world_w() -> float:
	return size.x * world_screens


func max_scroll() -> float:
	return maxf(world_w() - size.x, 0.0)


func _hour() -> float:
	if hour_override >= 0.0:
		return hour_override
	return DayClock.hour_now()


## [noche, calidez] para la hora actual (interpola entre las horas clave).
func _time_state() -> Array:
	var h := _hour()
	for i in range(DAY_KEYS.size() - 1):
		var a: Array = DAY_KEYS[i]
		var b: Array = DAY_KEYS[i + 1]
		if h >= a[0] and h <= b[0]:
			var t := inverse_lerp(a[0], b[0], h)
			return [lerpf(a[1], b[1], t), lerpf(a[2], b[2], t)]
	return [0.0, 0.0]


func _ready() -> void:
	_world = Control.new()
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.draw.connect(_draw_world)
	add_child(_world)
	move_child(_world, 0)
	_vignette = Control.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.draw.connect(_draw_vignette)
	add_child(_vignette)
	move_child(_vignette, 1)
	resized.connect(_layout)
	_layout()
	# capa liviana encima: solo las chispitas de los items especiales (se redibuja cada cuadro)
	_shine = Control.new()
	_shine.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shine.draw.connect(_draw_shine)
	add_child(_shine)


## El cuarto entero cambio (muebles, pared, edicion, hora): se vuelve a dibujar una vez.
func redraw() -> void:
	if _world != null:
		_world.queue_redraw()


## Tamaño del mundo y camara (al cambiar el tamaño o las pantallas de ancho).
func _layout() -> void:
	if _world == null:
		return
	_world.size = Vector2(world_w(), size.y)
	scroll = scroll   # vuelve a acotar la camara
	_world.queue_redraw()
	_vignette.queue_redraw()


func _draw_shine() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for p in _specials:
		var r := _item_rect(p)
		r.position.x -= scroll
		if r.end.x < -40.0 or r.position.x > size.x + 40.0:   # fuera de la pantalla (con margen para las chispitas)
			continue
		ItemArt.draw_shine(_shine, r, t + float(hash(p["id"]) % 100) * 0.1)


func _process(delta: float) -> void:
	if _shine != null and not _specials.is_empty():
		_shine.queue_redraw()
	if _dragging and selected != "":
		var dx := 0.0
		if _pointer.x < EDGE_ZONE:
			dx = -(EDGE_ZONE - _pointer.x) / EDGE_ZONE * 16.0
		elif _pointer.x > size.x - EDGE_ZONE:
			dx = (_pointer.x - (size.x - EDGE_ZONE)) / EDGE_ZONE * 16.0
		if dx != 0.0:
			var before := scroll
			scroll += dx
			if scroll != before:
				_apply_drag()
	_check -= delta
	if _check > 0.0:
		return
	_check = 20.0
	var bucket := int(_hour() * 6.0)  # cada 10 minutos
	if bucket != _hour_bucket:
		_hour_bucket = bucket
		redraw()


func set_state(wall: String, floor_item: String, placed_items: Array, room := -1) -> void:
	var sig := hash([wall, floor_item, placed_items.hash(), selected, edit_mode, room])
	if sig == _sig:
		return
	_sig = sig
	wall_id = wall
	floor_id = floor_item
	placed = placed_items
	room_index = room
	redraw()


## Mueve la camara (con animacion suave si `animated`).
func scroll_to(x: float, animated := true) -> void:
	if _scroll_tween != null:
		_scroll_tween.kill()
	var target := clampf(x, 0.0, max_scroll())
	if not animated:
		scroll = target
		return
	_scroll_tween = create_tween()
	_scroll_tween.tween_property(self, "scroll", target, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Centra la camara en el punto `world_x` (px del mundo).
func center_on(world_x: float, animated := true) -> void:
	scroll_to(world_x - size.x * 0.5, animated)


## Los items de la habitacion que se esta viendo.
func _items() -> Array:
	if room_index < 0:
		return placed
	return placed.filter(func(p): return int(p.get("room", 0)) == room_index)


## Los muebles de piso no pueden bajar hasta los botones de abajo (ni el panel de decorar).
func _floor_y_max(id: String) -> float:
	var half := ItemArt.size_of(id).y * 0.5
	return maxf(FLOOR_Y_RANGE.x, (size.y - BOTTOM_RESERVE - half) / size.y)


## Centro del item en px del mundo. Los adornos apoyados siguen a su mueble.
func _item_center(p: Dictionary) -> Vector2:
	var on := str(p.get("on", ""))
	if on != "":
		var support := _find(on)
		var surf := Catalog.surface_of(on)
		if not support.is_empty() and not surf.is_empty():
			var half_h := ItemArt.size_of(p["id"]).y * 0.5
			return _item_center(support) + Vector2(float(p.get("ox", 0.0)), float(surf["dy"]) - half_h + 3.0)
	var y: float = p["y"]
	if not _is_wall_item(p["id"]):
		y = minf(y, _floor_y_max(p["id"]))
	return Vector2(p["x"] * world_w(), y * size.y)


func _item_rect(p: Dictionary) -> Rect2:
	var s := ItemArt.size_of(p["id"])
	return Rect2(_item_center(p) - s * 0.5, s)


func _is_wall_item(id: String) -> bool:
	return Catalog.get_item(id).get("category", "") == "deco"


## Orden de dibujo (de atras hacia adelante): las alfombras primero; despues por altura y lo apoyado
## va justo despues de su mueble.
func _order_key(p: Dictionary) -> float:
	if Catalog.is_rug(p["id"]):
		return float(p["y"]) - 10.0
	var on := str(p.get("on", ""))
	if on != "":
		var support := _find(on)
		if not support.is_empty():
			return float(support["y"]) + 0.0005
	return float(p["y"])


func _draw_world() -> void:
	_canvas = _world
	var w := size.x
	var ww := world_w()
	var h := size.y
	var fy := h * FLOOR_START

	ItemArt.draw_wall(_canvas, Rect2(0, 0, ww, fy), wall_id)
	_gradient(Rect2(0, 0, ww, fy), Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.0))   # luz suave desde arriba
	_gradient(Rect2(0, fy - 90, ww, 90), Color(0.45, 0.25, 0.35, 0.0), Color(0.45, 0.25, 0.35, 0.10))
	# zocalo (baseboard) con brillo arriba
	_canvas.draw_rect(Rect2(0, fy - 26, ww, 30), Color("fffaf0"))
	_canvas.draw_rect(Rect2(0, fy - 26, ww, 6), Color("ffffff"))
	_canvas.draw_rect(Rect2(0, fy - 2, ww, 6), Color("ecdcc4"))
	_canvas.draw_line(Vector2(0, fy - 26), Vector2(ww, fy - 26), Color(OUTLINE, 0.5), 2.0)
	_canvas.draw_line(Vector2(0, fy + 4), Vector2(ww, fy + 4), OUTLINE, 3.0)
	ItemArt.draw_floor(_canvas, Rect2(0, fy + 2, ww, h - fy), floor_id)
	_gradient(Rect2(0, fy + 4, ww, 110), Color(0.3, 0.15, 0.2, 0.22), Color(0.3, 0.15, 0.2, 0.0))   # sombra bajo la pared
	_gradient(Rect2(0, h * 0.8, ww, h * 0.2), Color(1, 0.95, 0.85, 0.0), Color(1, 0.95, 0.85, 0.10))

	# una alfombra con flequitos y dibujo por cada pantalla de ancho
	var rug := Rooms.rug_color(room_index) if room_index >= 0 else Rooms.rug_color(0)
	if world_screens <= 1.0:
		_rug(Vector2(ww * 0.5, h * 0.68), w, rug)
	else:  # una alfombra grande en el centro (ahi arranca el Pompon) y dos chicas en los extremos
		_rug(Vector2(ww * 0.5, h * 0.68), w, rug)
		_rug(Vector2(w * 0.28, h * 0.7), w * 0.5, rug)
		_rug(Vector2(ww - w * 0.28, h * 0.7), w * 0.5, rug)

	# decoracion de pared primero, despues muebles de atras hacia adelante
	var walls := []
	var floors := []
	var items := _items()
	var had_specials := not _specials.is_empty()
	_specials = items.filter(func(p): return Catalog.is_special(p["id"]))
	if had_specials and _specials.is_empty() and _shine != null:
		_shine.queue_redraw()   # (se saco el ultimo especial: borrar sus chispitas)
	for p in items:
		(walls if _is_wall_item(p["id"]) else floors).append(p)
	floors.sort_custom(func(a, b): return _order_key(a) < _order_key(b))
	var state := _time_state()
	var night: float = state[0]
	var warm: float = state[1]
	ItemArt.night_amount = night
	ItemArt.sky = Color("bfe3f5").lerp(Color("f6b38a"), warm * 0.8).lerp(Color("1f2a5c"), night)
	for p in walls:
		_draw_placed(p)
	for p in floors:
		if str(p.get("on", "")) == "" and not Catalog.is_rug(p["id"]):
			_draw_floor_shadow(p)
		_draw_placed(p)
	ItemArt.night_amount = 0.0
	ItemArt.sky = Color("bfe3f5")

	# luz del dia: la noche oscurece suave el cuarto y el atardecer lo vuelve calido
	if night > 0.01:
		_canvas.draw_rect(Rect2(0, 0, ww, h), Color(0.08, 0.10, 0.30, 0.30 * night))
	if warm > 0.01:
		_canvas.draw_rect(Rect2(0, 0, ww, h), Color(1.0, 0.6, 0.3, 0.10 * warm))
	if night > 0.2:  # lamparas y chimenea siguen encendidas
		for p in items:
			var shape := Catalog.shape_of(p["id"])
			if LIGHT_SOURCES.has(shape):
				var c: Vector2 = _item_center(p) + LIGHT_SOURCES[shape]
				_canvas.draw_circle(c, 120.0, Color(1.0, 0.85, 0.5, 0.10 * night))
				_canvas.draw_circle(c, 70.0, Color(1.0, 0.88, 0.55, 0.16 * night))

	# las esquinas de la habitacion se ven un poco mas oscuras: marcan donde termina
	_gradient(Rect2(0, 0, 90, h), Color(0.25, 0.1, 0.2, 0.22), Color(0.25, 0.1, 0.2, 0.0), true)
	_gradient(Rect2(ww - 90, 0, 90, h), Color(0.25, 0.1, 0.2, 0.0), Color(0.25, 0.1, 0.2, 0.22), true)

	if edit_mode:
		_draw_edit_marks()


## Un item del cuarto (dado vuelta si `flip`).
func _draw_placed(p: Dictionary) -> void:
	var c := _item_center(p)
	if bool(p.get("flip", false)) and Catalog.can_flip(p["id"]):
		_canvas.draw_set_transform(c, 0.0, Vector2(-1.0, 1.0))
		ItemArt.draw_item(_canvas, p["id"], Vector2.ZERO)
		_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		ItemArt.draw_item(_canvas, p["id"], c)


## Sombrita suave en el piso, debajo de cada mueble: lo "apoya" en el cuarto.
func _draw_floor_shadow(p: Dictionary) -> void:
	var r := _item_rect(p)
	var w := r.size.x * 0.46
	var base := Vector2(r.get_center().x, r.end.y - 6.0)
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		pts.append(base + Vector2(cos(a) * w, sin(a) * 13.0))
	_canvas.draw_colored_polygon(pts, Color(0.35, 0.15, 0.25, 0.13))


func _draw_vignette() -> void:
	_canvas = _vignette
	var w := size.x
	var h := size.y
	# bordes mas oscuros (vineta): enfoca la mirada al centro
	_gradient(Rect2(0, 0, 70, h), Color(0.25, 0.1, 0.2, 0.12), Color(0.25, 0.1, 0.2, 0.0), true)
	_gradient(Rect2(w - 70, 0, 70, h), Color(0.25, 0.1, 0.2, 0.0), Color(0.25, 0.1, 0.2, 0.12), true)


func _rug(rc: Vector2, w: float, rug: Color) -> void:
	_ellipse(rc + Vector2(0, 10), w * 0.405, 90.0, Color(0.3, 0.15, 0.2, 0.14), false)
	for i in 36:
		var a := TAU * i / 36.0
		_canvas.draw_circle(rc + Vector2(cos(a) * w * 0.41, sin(a) * 88.0), 7.0, Color("fff1de"))
	_ellipse(rc, w * 0.40, 86.0, Color("fff6e8"))
	_ellipse(rc, w * 0.35, 68.0, rug, false)
	_ellipse(rc, w * 0.31, 58.0, Color("fff6e8"), false)
	for i in 14:
		var a2 := TAU * i / 14.0
		_canvas.draw_circle(rc + Vector2(cos(a2) * w * 0.33, sin(a2) * 62.0), 6.0, Color("ffc2d9"))


## Degradado lineal (vertical por defecto; horizontal si `horizontal`).
func _gradient(r: Rect2, from: Color, to: Color, horizontal := false) -> void:
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var cols := PackedColorArray([from, to, to, from]) if horizontal else PackedColorArray([from, from, to, to])
	_canvas.draw_polygon(pts, cols)


func _draw_edit_marks() -> void:
	var dragging_small := _dragging and Catalog.is_small(selected)
	if dragging_small:  # lineas rosas donde se puede apoyar el adorno
		for p in _items():
			var surf := Catalog.surface_of(p["id"])
			if surf.is_empty() or p["id"] == selected:
				continue
			var pc := _item_center(p)
			var hw: float = surf["hw"]
			var yy: float = pc.y + float(surf["dy"])
			var on: bool = p["id"] == _snap_support
			_canvas.draw_line(Vector2(pc.x - hw, yy), Vector2(pc.x + hw, yy), Color("ff7aa0") if on else Color(1, 1, 1, 0.8), 8.0 if on else 5.0, true)
	for p in _items():
		var r := _item_rect(p).grow(6.0)
		var on2: bool = p["id"] == selected
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.16 if on2 else 0.0)
		sb.border_color = Color("ff7aa0") if on2 else Color(1, 1, 1, 0.65)
		sb.set_border_width_all(4 if on2 else 2)
		sb.set_corner_radius_all(14)
		_canvas.draw_style_box(sb, r)


func _ellipse(c: Vector2, rx: float, ry: float, fill: Color, outline := true) -> void:
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	_canvas.draw_colored_polygon(pts, fill)
	if outline:
		pts.append(pts[0])
		_canvas.draw_polyline(pts, OUTLINE, 4.0, true)


# ------------------------------------------------------------------ camara y edicion

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
				scroll_to(scroll - size.x * 0.25)
			MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
				scroll_to(scroll + size.x * 0.25)
			MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_on_press(mb.position)
				else:
					_on_release()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _dragging and selected != "":
			_pointer = mm.position
			_apply_drag()
		elif _panning:
			scroll -= mm.relative.x
			panned.emit()


func _on_press(pos: Vector2) -> void:
	_pointer = pos
	if edit_mode:
		var hit := _item_at(pos)
		select(hit)
		if hit != "":
			_dragging = true
			_drag_offset = _item_center(_find(hit)) - (pos + Vector2(scroll, 0.0))
			redraw()
			return
	_panning = true
	if _scroll_tween != null:
		_scroll_tween.kill()


func _on_release() -> void:
	if _dragging:
		_drop_selected()
		GameState.save_game()
	_dragging = false
	_panning = false
	_snap_support = ""
	redraw()


## El item seleccionado sigue al dedo; un adorno chico se pega a la superficie que tenga cerca.
func _apply_drag() -> void:
	var id := selected
	var pos := _pointer + Vector2(scroll, 0.0) + _drag_offset
	var nx := clampf(pos.x / world_w(), 0.04, 0.96)
	var wall := _is_wall_item(id)
	if Catalog.is_small(id):
		var snap := _surface_for(id, Vector2(nx * world_w(), pos.y))
		if not snap.is_empty():
			_snap_support = snap["support"]
			GameState.attach_item(id, snap["support"], snap["ox"])
			var c := _item_center(_find(id))
			GameState.move_item(id, c.x / world_w(), c.y / size.y)  # por si despues se suelta en el aire
			redraw()
			return
		_snap_support = ""
		GameState.detach_item(id)
	var y_range := WALL_Y_RANGE if wall else Vector2(FLOOR_Y_RANGE.x, _floor_y_max(id))
	if Catalog.is_small(id):
		y_range = Vector2(WALL_Y_RANGE.x, _floor_y_max(id))
	GameState.move_item(id, nx, clampf(pos.y / size.y, y_range.x, y_range.y))
	redraw()


## Al soltar: un adorno que no quedo sobre nada cae al piso.
func _drop_selected() -> void:
	if selected == "" or not Catalog.is_small(selected):
		return
	var p := _find(selected)
	if p.is_empty() or str(p.get("on", "")) != "":
		return
	GameState.move_item(selected, p["x"], clampf(p["y"], FLOOR_Y_RANGE.x, _floor_y_max(selected)))


## La superficie (de un mueble o estante) donde se apoyaria `id` si estuviera con el centro en `center`.
func _surface_for(id: String, center: Vector2) -> Dictionary:
	var isz := ItemArt.size_of(id)
	var foot := center.y + isz.y * 0.5
	var best := {}
	var best_d := SNAP_RANGE
	for p in _items():
		if p["id"] == id or str(p.get("on", "")) != "":
			continue
		var surf := Catalog.surface_of(p["id"])
		if surf.is_empty():
			continue
		var hw: float = surf["hw"]
		if isz.x > hw * 2.0 + 70.0:  # un adorno muy ancho no entra en una superficie chica
			continue
		var pc := _item_center(p)
		var dx := absf(center.x - pc.x)
		if dx > hw + 24.0:
			continue
		var d := absf(foot - (pc.y + float(surf["dy"]))) + dx * 0.15
		if d < best_d:
			best_d = d
			var lim := maxf(hw - isz.x * 0.3, 0.0)
			best = {"support": p["id"], "ox": clampf(center.x - pc.x, -lim, lim)}
	return best


func select(item_id: String) -> void:
	if selected == item_id:
		return
	selected = item_id
	selection_changed.emit(item_id)
	redraw()


func _find(item_id: String) -> Dictionary:
	for p in placed:
		if p["id"] == item_id:
			return p
	return {}


## El item de mas arriba (el dibujado al final) que contiene el punto de pantalla.
func _item_at(point: Vector2) -> String:
	var wp := point + Vector2(scroll, 0.0)
	var order := _items().duplicate()
	order.sort_custom(func(a, b):
		var aw := _is_wall_item(a["id"])
		var bw := _is_wall_item(b["id"])
		if aw != bw:
			return aw  # pared primero (queda debajo)
		var ar := Catalog.is_rug(a["id"])
		if ar != Catalog.is_rug(b["id"]):
			return ar  # despues las alfombras: se agarra primero el mueble que tienen encima
		return _order_key(a) < _order_key(b))
	for i in range(order.size() - 1, -1, -1):
		if _item_rect(order[i]).grow(6.0).has_point(wp):
			return order[i]["id"]
	return ""
