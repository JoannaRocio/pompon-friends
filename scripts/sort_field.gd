class_name SortField
extends Control
## Mini juego relajante de ordenar: aparecen libros, lapices y manzanas y se arrastran a su lugar
## (estante, vaso y canasta). Sin tiempo ni castigos: si te equivocas, el objeto vuelve solito.
## Mientras tanto la profe espera la señal para corregir un examen.
## Si pasan unos segundos sin ordenar nada, un dedito muestra como arrastrar un objeto a su lugar.

signal sorted(correct: bool, kind: String)

const KINDS := ["book", "pencil", "apple"]
const BOOK_COLORS := [Color("ff7aa8"), Color("5bb8f5"), Color("ffcf3f"), Color("7bd389")]
const PENCIL_COLORS := [Color("ff9b54"), Color("a98bea"), Color("3cc9b0"), Color("f2566f")]
const APPLE_COLORS := [Color("f2566f"), Color("8fd16a"), Color("ffcf3f")]
const OUT := Color("5b3a4a")
const MAX_ITEMS := 5

var paused := false
var sorted_total := 0
var combo := 0
var items: Array = []
var particles: Array = []
var popups: Array = []
var bin_count := [0, 0, 0]
var _spawn_t := 0.3
var _drag_id := -1   # id del objeto que se esta arrastrando (-1 = ninguno); por id y no por posicion, porque la lista cambia
var _next_id := 0
var _drag_off := Vector2.ZERO
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var hint_delay := 6.0     # segundos sin ordenar antes de mostrar la ayuda
var hint_enabled := true  # false mientras otra ayuda tiene prioridad (la del examen)
var _idle_t := 0.0
var _hint := {}           # {"id", "from", "to"}: objeto que el dedito muestra como mover
var _hint_t := 0.0
const HINT_LOOP := 2.2    # duracion de una pasada del dedito


func _ready() -> void:
	_rng.randomize()
	clip_contents = true


# ---------------------------------------------------------------- geometria

func bin_rect(i: int) -> Rect2:
	var gap := 14.0
	var w := (size.x - gap * 4.0) / 3.0
	var h := minf(size.y * 0.42, 190.0)
	return Rect2(gap + i * (w + gap), size.y - h - 10.0, w, h)


func item_zone() -> Rect2:
	var bottom := bin_rect(0).position.y - 50.0
	return Rect2(54.0, 54.0, size.x - 108.0, maxf(bottom - 60.0, 80.0))


# ------------------------------------------------------------------ logica

func _process(delta: float) -> void:
	_t += delta
	_update_hint(delta)
	if not paused:
		_spawn_t -= delta
		if _spawn_t <= 0.0 and items.size() < MAX_ITEMS and size.x > 50.0:
			_spawn()
			_spawn_t = _rng.randf_range(1.6, 2.6)
	for it in items:
		match it["state"]:
			"pop":
				it["t"] += delta / 0.35
				it["scale"] = _back_out(clampf(it["t"], 0.0, 1.0))
				if it["t"] >= 1.0:
					it["state"] = "idle"
					it["scale"] = 1.0
			"in":
				it["t"] += delta / 0.38
				var k := clampf(it["t"], 0.0, 1.0)
				var target := bin_rect(it["bin"]).get_center() + Vector2(0, 8)
				it["pos"] = Vector2(it["from"]).lerp(target, k * k * (3.0 - 2.0 * k))
				it["scale"] = lerpf(1.0, 0.45, k)
				it["rot"] = lerpf(float(it["rot0"]), 0.0, k)
				if k >= 1.0:
					it["state"] = "done"
			"back":
				it["t"] += delta / 0.45
				var k2 := clampf(it["t"], 0.0, 1.0)
				var wob := sin(k2 * TAU * 3.0) * 10.0 * (1.0 - k2)
				it["pos"] = Vector2(it["from"]).lerp(it["home"], k2 * k2 * (3.0 - 2.0 * k2)) + Vector2(wob, 0)
				if k2 >= 1.0:
					it["state"] = "idle"
	items = items.filter(func(it): return it["state"] != "done")
	for p in particles:
		p["age"] += delta
		p["pos"] += p["vel"] * delta
		p["vel"] += Vector2(0, 300) * delta
	particles = particles.filter(func(p): return p["age"] < p["life"])
	for p in popups:
		p["age"] += delta
	popups = popups.filter(func(p): return p["age"] < 0.9)
	queue_redraw()


func _back_out(t: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)


func _spawn() -> void:
	var zone := item_zone()
	var pos := Vector2.ZERO
	for attempt in 12:
		pos = Vector2(_rng.randf_range(zone.position.x, zone.end.x), _rng.randf_range(zone.position.y, zone.end.y))
		var free := true
		for it in items:
			if (it["pos"] as Vector2).distance_to(pos) < 120.0:
				free = false
		if free:
			break
	var kind: String = KINDS[_rng.randi() % KINDS.size()]
	_next_id += 1
	items.append({
		"id": _next_id, "kind": kind, "variant": _rng.randi() % 4, "pos": pos, "home": pos, "from": pos, "scale": 0.0, "t": 0.0,
		"rot": _rng.randf_range(-0.35, 0.35), "rot0": 0.0, "state": "pop", "bin": -1,
	})


## Cuenta el tiempo sin ordenar y elige que objeto mostrar con el dedito.
func _update_hint(delta: float) -> void:
	if paused or _drag_id >= 0:
		_idle_t = 0.0
		_hint = {}
		return
	_idle_t += delta
	if not hint_enabled:
		_hint = {}
		return
	if not _hint.is_empty():  # el objeto ya no esta quieto: se elige otro
		var still := false
		for it in items:
			if it["id"] == _hint["id"] and it["state"] == "idle":
				still = true
				_hint["from"] = it["pos"]
		if not still:
			_hint = {}
	if _hint.is_empty() and _idle_t >= hint_delay:
		for it in items:
			if it["state"] == "idle":
				var b := KINDS.find(it["kind"])
				_hint = {"id": it["id"], "from": it["pos"], "to": bin_rect(b).get_center() + Vector2(0, 10)}
				_hint_t = 0.0
				break
	if not _hint.is_empty():
		_hint_t += delta


func is_hinting() -> bool:
	return not _hint.is_empty()


## Dedito que toca el objeto, lo lleva por un caminito de puntos y lo suelta en su lugar.
func _draw_hint() -> void:
	var from: Vector2 = _hint["from"]
	var to: Vector2 = _hint["to"]
	var pink := Color("ff4f86")
	var fade := clampf(_hint_t / 0.4, 0.0, 1.0)
	# caminito de puntos con punta de flecha
	var dist := from.distance_to(to)
	var dir := (to - from) / maxf(dist, 1.0)
	var n := int(dist / 26.0)
	for i in range(1, n):
		var p := from + dir * (26.0 * i)
		draw_circle(p, 5.0, Color(pink, 0.55 * fade))
	var side := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([to, to - dir * 30.0 + side * 18.0, to - dir * 30.0 - side * 18.0]), Color(pink, 0.8 * fade))
	# el objeto y su lugar brillan
	var glow := 0.5 + 0.5 * sin(_t * 6.0)
	draw_arc(from, 60.0, 0.0, TAU, 32, Color(pink, (0.35 + 0.35 * glow) * fade), 5.0, true)
	# el dedito: aprieta, arrastra y suelta
	var k := fmod(_hint_t, HINT_LOOP) / HINT_LOOP
	var move := clampf((k - 0.18) / 0.55, 0.0, 1.0)
	move = move * move * (3.0 - 2.0 * move)
	var at := from.lerp(to, move)
	var pressing := k > 0.12 and k < 0.8
	if k < 0.18 or (k > 0.73 and k < 0.9):  # anillo de toque al apretar y al soltar
		var ring := fmod(k * 6.0, 1.0)
		draw_arc(at, 30.0 + 26.0 * ring, 0.0, TAU, 28, Color(pink, (1.0 - ring) * fade), 4.0, true)
	if k < 0.92:
		_draw_finger(at + Vector2(14, 22) * (0.8 if pressing else 1.0), fade)


func _draw_finger(tip: Vector2, a: float) -> void:
	# mano blanca con contorno: palma redonda y el indice apuntando hacia arriba a la izquierda
	var outline := Color(OUT, a)
	var skin := Color(1, 1, 1, a)
	var palm := tip + Vector2(22, 40)
	draw_circle(palm, 27.0, outline)
	draw_circle(palm, 23.0, skin)
	draw_line(tip, palm + Vector2(-8, -12), outline, 22.0, true)
	draw_line(tip, palm + Vector2(-8, -12), skin, 14.0, true)
	draw_circle(tip, 11.0, outline)
	draw_circle(tip, 7.0, skin)
	draw_circle(palm + Vector2(-8, -12), 7.0, skin)


## El objeto que se esta arrastrando (o {} si no hay).
func _dragged() -> Dictionary:
	if _drag_id < 0:
		return {}
	for it in items:
		if it["id"] == _drag_id:
			return it
	_drag_id = -1  # ya no existe
	return {}


func _item_at(p: Vector2) -> int:
	for i in range(items.size() - 1, -1, -1):
		var it: Dictionary = items[i]
		if it["state"] in ["idle", "pop"] and (it["pos"] as Vector2).distance_to(p) < 62.0:
			return i
	return -1


func _bin_at(p: Vector2) -> int:
	for i in 3:
		if bin_rect(i).grow(18.0).has_point(p):
			return i
	return -1


func _gui_input(event: InputEvent) -> void:
	if paused:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var idx := _item_at(event.position)
			_drag_id = -1
			if idx >= 0:
				var it: Dictionary = items[idx]
				_drag_id = it["id"]
				it["state"] = "idle"
				it["scale"] = 1.0
				_drag_off = (it["pos"] as Vector2) - event.position
				items.append(items.pop_at(idx))  # al frente
				Audio.play("click", 1.2)
				_idle_t = 0.0
				_hint = {}
		else:
			_release(event.position)
	elif event is InputEventMouseMotion and _drag_id >= 0:
		var it2 := _dragged()
		if not it2.is_empty():
			var zone := Rect2(Vector2.ZERO, size).grow(-30.0)
			it2["pos"] = (event.position + _drag_off).clamp(zone.position, zone.end)


func _release(at: Vector2) -> void:
	var it := _dragged()
	_drag_id = -1
	if it.is_empty():
		return
	var b := _bin_at(it["pos"])
	if b < 0:
		it["home"] = it["pos"]
		return
	var right: bool = (KINDS[b] == it["kind"])
	it["from"] = it["pos"]
	it["t"] = 0.0
	if right:
		it["state"] = "in"
		it["bin"] = b
		it["rot0"] = it["rot"]
		bin_count[b] += 1
		sorted_total += 1
		combo += 1
		Audio.play("stamp", minf(1.0 + 0.04 * combo, 1.5))
		_burst(bin_rect(b).get_center(), 10)
		_popup(T.s("¡Listo!") if combo % 4 != 0 else T.s("¡Racha x%d!") % combo, bin_rect(b).position + Vector2(bin_rect(b).size.x * 0.5, -6.0), Color("1f7a52") if combo % 4 != 0 else Color("d6336c"))
		sorted.emit(true, it["kind"])
	else:
		it["state"] = "back"
		combo = 0
		Audio.play("click", 0.8)
		sorted.emit(false, it["kind"])


func _burst(pos: Vector2, n: int) -> void:
	var palette := [Color("ffd33d"), Color("ff8fc8"), Color("8ecae6"), Color("90be6d"), Color.WHITE]
	for i in n:
		var a := _rng.randf() * TAU
		particles.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * _rng.randf_range(80.0, 240.0) + Vector2(0, -90),
			"age": 0.0, "life": _rng.randf_range(0.45, 0.8), "color": palette[_rng.randi() % palette.size()]})


func _popup(text: String, pos: Vector2, color: Color) -> void:
	popups.append({"text": text, "pos": pos, "age": 0.0, "color": color})


# ------------------------------------------------------------------ dibujo

func _draw() -> void:
	for i in 3:
		_draw_bin(i)
	for it in items:
		var s: float = it["scale"]
		var lift := 0.0
		if it["id"] == _drag_id:
			s = 1.12
			lift = -10.0
			draw_circle((it["pos"] as Vector2) + Vector2(0, 52), 34.0, Color(0, 0, 0, 0.15))
		_draw_item(it["kind"], it["variant"], (it["pos"] as Vector2) + Vector2(0, lift), s, it["rot"])
	var font := get_theme_default_font()
	for p in popups:
		var a := clampf(1.0 - float(p["age"]) / 0.9, 0.0, 1.0)
		var pos: Vector2 = p["pos"] + Vector2(0, -50.0 * float(p["age"]))
		var col: Color = p["color"]
		col.a = a
		draw_string_outline(font, pos + Vector2(-100, 0), p["text"], HORIZONTAL_ALIGNMENT_CENTER, 200, 34, 8, Color(1, 1, 1, a))
		draw_string(font, pos + Vector2(-100, 0), p["text"], HORIZONTAL_ALIGNMENT_CENTER, 200, 34, col)
	for q in particles:
		var life: float = float(q["age"]) / float(q["life"])
		var c: Color = q["color"]
		c.a = 1.0 - life
		draw_circle(q["pos"], 7.0 * (1.0 - life * 0.5), c)
	if not _hint.is_empty():
		_draw_hint()


func _draw_bin(i: int) -> void:
	var r := bin_rect(i)
	var c := r.get_center()
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(30)
	sb.set_border_width_all(5)
	sb.border_color = OUT
	var held := _dragged()
	var hover := not held.is_empty() and _bin_at(held["pos"] as Vector2) == i
	match i:
		0:  # estante con libros
			sb.bg_color = Color("e7b98a")
			draw_style_box(sb, r)
			var inner := r.grow(-14.0)
			draw_rect(Rect2(inner.position, inner.size), Color("c98f5e"))
			draw_rect(Rect2(inner.position.x, inner.position.y + inner.size.y * 0.52, inner.size.x, 8), Color("8a5a35"))
			for k in mini(int(bin_count[0]), 6):
				var bx := inner.position.x + 10.0 + k * (inner.size.x - 20.0) / 6.0
				draw_rect(Rect2(bx, inner.position.y + inner.size.y * 0.52 - 52.0 + (k % 2) * 8, 20, 52 - (k % 2) * 8), BOOK_COLORS[k % 4])
			for k in 4:
				var bx2 := inner.position.x + 14.0 + k * 26.0
				draw_rect(Rect2(bx2, inner.position.y + inner.size.y - 50.0, 20, 46), BOOK_COLORS[(k + 1) % 4])
		1:  # vaso de lapices
			sb.bg_color = Color("9be3d0")
			draw_style_box(sb, Rect2(r.position + Vector2(r.size.x * 0.14, r.size.y * 0.3), Vector2(r.size.x * 0.72, r.size.y * 0.7)))
			for k in mini(int(bin_count[1]) + 3, 7):
				var px := c.x - 36.0 + k * 12.0
				var h := 60.0 + (k % 3) * 14.0
				draw_line(Vector2(px, r.position.y + r.size.y * 0.34), Vector2(px + (k - 3) * 3.0, r.position.y + r.size.y * 0.34 - h * 0.6), PENCIL_COLORS[k % 4], 9.0)
			draw_rect(Rect2(r.position.x + r.size.x * 0.14, r.position.y + r.size.y * 0.42, r.size.x * 0.72, 10), Color("6fc9b3"))
			draw_style_box(sb, Rect2(r.position + Vector2(r.size.x * 0.14, r.size.y * 0.3), Vector2(r.size.x * 0.72, r.size.y * 0.7)))
			draw_rect(Rect2(r.position.x + r.size.x * 0.14 + 6, r.position.y + r.size.y * 0.3 + 6, r.size.x * 0.72 - 12, 12), Color(1, 1, 1, 0.3))
		2:  # canasta con manzanas
			sb.bg_color = Color("e9c98c")
			draw_style_box(sb, Rect2(r.position + Vector2(r.size.x * 0.08, r.size.y * 0.4), Vector2(r.size.x * 0.84, r.size.y * 0.6)))
			for k in mini(int(bin_count[2]) + 2, 6):
				draw_circle(Vector2(c.x - 40.0 + (k % 3) * 40.0, r.position.y + r.size.y * 0.42 - (k / 3) * 22.0), 24.0, APPLE_COLORS[k % 3])
				draw_circle(Vector2(c.x - 48.0 + (k % 3) * 40.0, r.position.y + r.size.y * 0.42 - 8.0 - (k / 3) * 22.0), 5.0, Color(1, 1, 1, 0.45))
			for k in range(-2, 3):
				draw_line(Vector2(c.x + k * 24.0, r.position.y + r.size.y * 0.55), Vector2(c.x + k * 20.0, r.end.y - 14.0), Color("c9a56a"), 4.0)
			draw_style_box(sb, Rect2(r.position + Vector2(r.size.x * 0.08, r.size.y * 0.4), Vector2(r.size.x * 0.84, r.size.y * 0.6)))
			draw_arc(c + Vector2(0, -r.size.y * 0.08), r.size.x * 0.34, PI, TAU, 20, OUT, 5.0, true)
	if hover:
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color(1, 1, 1, 0.0)
		glow.border_color = Color("ff8fb8")
		glow.set_border_width_all(6)
		glow.set_corner_radius_all(34)
		draw_style_box(glow, r.grow(6.0))


func _draw_item(kind: String, variant: int, c: Vector2, s: float, rot: float) -> void:
	if s <= 0.01:
		return
	draw_set_transform(c, rot, Vector2(s, s))
	match kind:
		"book":
			var col: Color = BOOK_COLORS[variant % BOOK_COLORS.size()]
			var r := Rect2(-34, -44, 68, 88)
			var sb := StyleBoxFlat.new()
			sb.bg_color = col
			sb.border_color = OUT
			sb.set_border_width_all(4)
			sb.set_corner_radius_all(8)
			sb.shadow_color = Color(0, 0, 0, 0.16)
			sb.shadow_size = 5
			draw_style_box(sb, r)
			draw_rect(Rect2(-34, -44, 16, 88), col.darkened(0.15))
			draw_line(Vector2(-18, -42), Vector2(-18, 42), OUT, 3.0)
			draw_rect(Rect2(-8, -26, 34, 26), Color(1, 1, 1, 0.8))
			draw_line(Vector2(-4, 16), Vector2(24, 16), Color(1, 1, 1, 0.7), 4.0)
		"pencil":
			var col2: Color = PENCIL_COLORS[variant % PENCIL_COLORS.size()]
			draw_colored_polygon(PackedVector2Array([Vector2(-13, -46), Vector2(13, -46), Vector2(13, 28), Vector2(0, 50), Vector2(-13, 28)]), col2)
			draw_colored_polygon(PackedVector2Array([Vector2(-13, 28), Vector2(13, 28), Vector2(0, 50)]), Color("ffe3b8"))
			draw_colored_polygon(PackedVector2Array([Vector2(-4, 42), Vector2(4, 42), Vector2(0, 50)]), OUT)
			draw_rect(Rect2(-13, -60, 26, 14), Color("ff9eb8"))
			draw_rect(Rect2(-13, -50, 26, 5), Color("c8c8d0"))
			draw_polyline(PackedVector2Array([Vector2(-13, -60), Vector2(13, -60), Vector2(13, 28), Vector2(0, 50), Vector2(-13, 28), Vector2(-13, -60)]), OUT, 4.0, true)
			draw_line(Vector2(-4, -40), Vector2(-4, 24), Color(1, 1, 1, 0.45), 4.0)
		"apple":
			var col3: Color = APPLE_COLORS[variant % APPLE_COLORS.size()]
			draw_circle(Vector2(-14, 4), 30, OUT)
			draw_circle(Vector2(14, 4), 30, OUT)
			draw_circle(Vector2(-14, 4), 26, col3)
			draw_circle(Vector2(14, 4), 26, col3)
			draw_rect(Rect2(-16, -22, 32, 26), col3)
			draw_line(Vector2(0, -22), Vector2(4, -42), OUT, 6.0)
			var leaf := PackedVector2Array()
			for k in 14:
				var a := TAU * k / 14.0
				leaf.append(Vector2(18 + cos(a) * 15, -38 + sin(a) * 7).rotated(-0.4))
			draw_colored_polygon(leaf, Color("6bbf7a"))
			draw_circle(Vector2(-22, -6), 6, Color(1, 1, 1, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
