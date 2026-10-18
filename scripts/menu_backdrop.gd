class_name MenuBackdrop
extends Control
## Paisaje del menu principal, dibujado por codigo. Se usa en tres capas:
## "sky" (cielo, fijo), "air" (sol, nubes y destellos, animado) y "land" (colinas, arboles y flores, fijo).

var mode := "sky"
var _t := 0.0
var _clouds := [] # [x 0..1, y 0..1, escala, velocidad]
var _sparks := [] # [x, y, tamano, fase]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 5:
		_clouds.append([rng.randf(), 0.10 + 0.34 * float(i) / 5.0 + rng.randf() * 0.04, 0.7 + rng.randf() * 0.7, 6.0 + rng.randf() * 9.0])
	for i in 22:
		_sparks.append([rng.randf(), rng.randf() * 0.55, 6.0 + rng.randf() * 11.0, rng.randf() * TAU])
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if mode == "air":
		_t += delta
		queue_redraw()


func _draw() -> void:
	match mode:
		"sky":
			_draw_sky()
		"air":
			_draw_air()
		"land":
			_draw_land()


# ------------------------------------------------------------------ cielo

func _draw_sky() -> void:
	var bands := 48
	var top := Color("a9dcf7")
	var mid := Color("ffd6e6")
	var low := Color("fff0cf")
	for i in bands:
		var f := float(i) / float(bands - 1)
		var c: Color = top.lerp(mid, clampf(f * 1.7, 0.0, 1.0)) if f < 0.59 else mid.lerp(low, clampf((f - 0.59) * 2.4, 0.0, 1.0))
		draw_rect(Rect2(0, size.y * i / bands, size.x, size.y / bands + 1.0), c)


func _draw_air() -> void:
	# sol con halo suave
	var sun := Vector2(size.x * 0.84, size.y * 0.13)
	var pulse := 1.0 + 0.03 * sin(_t * 1.2)
	for k in 6:
		draw_circle(sun, (210.0 - k * 28.0) * pulse, Color(1.0, 0.93, 0.7, 0.08 + 0.03 * k))
	draw_circle(sun, 56.0, Color("fff3b0"))
	draw_circle(sun, 44.0, Color("ffe27a"))
	# nubes que se mueven despacio
	for c in _clouds:
		var scale_c: float = c[2]
		var x: float = fposmod(size.x * c[0] + _t * c[3], size.x + 440.0) - 220.0
		_cloud(Vector2(x, size.y * c[1]), scale_c)
	# destellos que titilan
	for s in _sparks:
		var a := 0.35 + 0.65 * (0.5 + 0.5 * sin(_t * 1.6 + float(s[3])))
		_sparkle(Vector2(size.x * s[0], size.y * s[1]), float(s[2]) * (0.7 + 0.3 * a), Color(1, 1, 1, a * 0.9))


func _cloud(p: Vector2, s: float) -> void:
	var col := Color(1, 1, 1, 0.92)
	var shade := Color(0.86, 0.92, 1.0, 0.55)
	for part in [[-52, 8, 34], [-18, -10, 46], [24, -2, 40], [58, 10, 30]]:
		draw_circle(p + Vector2(part[0], part[1] + 10) * s, part[2] * s, shade)
	for part in [[-52, 8, 34], [-18, -10, 46], [24, -2, 40], [58, 10, 30]]:
		draw_circle(p + Vector2(part[0], part[1]) * s, part[2] * s, col)
	for bx in [-60, -30, 0, 30, 60]:
		draw_circle(p + Vector2(bx, 18) * s, 24.0 * s, col)


func _sparkle(p: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * i / 8.0 - PI / 2.0
		var rr := r if i % 2 == 0 else r * 0.28
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)


# ------------------------------------------------------------------ tierra

func _hill(base: float, amp: float, freq: float, phase: float, col: Color, edge: Color) -> void:
	var pts := PackedVector2Array()
	var top := PackedVector2Array()
	var steps := 48
	for i in steps + 1:
		var x := size.x * i / steps
		var y := base + sin(x / size.x * TAU * freq + phase) * amp
		pts.append(Vector2(x, y))
		top.append(Vector2(x, y))
	pts.append(Vector2(size.x, size.y))
	pts.append(Vector2(0, size.y))
	draw_colored_polygon(pts, col)
	draw_polyline(top, edge, 7.0, true)


func _hill_y(base: float, amp: float, freq: float, phase: float, x: float) -> float:
	return base + sin(x / size.x * TAU * freq + phase) * amp


func _tree(p: Vector2, s: float, leaves: Color, light: Color) -> void:
	draw_rect(Rect2(p + Vector2(-7, -58) * s, Vector2(14, 60) * s), Color("b98562"))
	draw_circle(p + Vector2(0, -78) * s, 44.0 * s, leaves)
	draw_circle(p + Vector2(-16, -92) * s, 15.0 * s, light)
	draw_circle(p + Vector2(18, -70) * s, 9.0 * s, light)


func _flower(p: Vector2, s: float, petal: Color) -> void:
	draw_line(p, p + Vector2(0, 16) * s, Color("5fae7e"), 3.0 * s)
	for i in 5:
		var a := TAU * i / 5.0
		draw_circle(p + Vector2(cos(a), sin(a)) * 6.0 * s, 5.0 * s, petal)
	draw_circle(p, 4.5 * s, Color("fff3b0"))


func _draw_land() -> void:
	var h := size.y
	# colinas lejanas, medias y la de adelante
	var far := [h * 0.58, 26.0, 1.0, 0.6]
	var mid := [h * 0.64, 30.0, 1.4, 2.4]
	var near := [h * 0.70, 34.0, 0.8, 4.3]
	_hill(far[0], far[1], far[2], far[3], Color("cdeccd"), Color("e4f7e1"))
	_tree(Vector2(size.x * 0.12, _hill_y(far[0], far[1], far[2], far[3], size.x * 0.12) + 8), 0.8, Color("a8dcb4"), Color("c5ecce"))
	_tree(Vector2(size.x * 0.9, _hill_y(far[0], far[1], far[2], far[3], size.x * 0.9) + 8), 0.9, Color("a8dcb4"), Color("c5ecce"))
	_hill(mid[0], mid[1], mid[2], mid[3], Color("a5dcb0"), Color("c0eac5"))
	_tree(Vector2(size.x * 0.06, _hill_y(mid[0], mid[1], mid[2], mid[3], size.x * 0.06) + 10), 1.15, Color("f6b6cf"), Color("ffd3e3"))
	_tree(Vector2(size.x * 0.95, _hill_y(mid[0], mid[1], mid[2], mid[3], size.x * 0.95) + 10), 1.05, Color("ffd88a"), Color("ffeab5"))
	_tree(Vector2(size.x * 0.78, _hill_y(mid[0], mid[1], mid[2], mid[3], size.x * 0.78) + 6), 0.75, Color("8ed4a4"), Color("b3e6c2"))
	_hill(near[0], near[1], near[2], near[3], Color("86cf9a"), Color("a9e2b6"))
	# flores y pastitos en la colina de adelante
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var petals := [Color("ff9ecb"), Color("fff3b0"), Color("ffffff"), Color("c9a8f0"), Color("ffb38a")]
	for i in 34:
		var x := rng.randf() * size.x
		var y: float = _hill_y(near[0], near[1], near[2], near[3], x) + 26.0 + rng.randf() * (h - near[0] - 230.0)
		_flower(Vector2(x, y), 0.8 + rng.randf() * 0.7, petals[i % petals.size()])
	for i in 30:
		var x := rng.randf() * size.x
		var y: float = _hill_y(near[0], near[1], near[2], near[3], x) + 20.0 + rng.randf() * (h - near[0] - 200.0)
		var g := Color("6cbc84")
		draw_line(Vector2(x, y), Vector2(x - 6, y - 14), g, 3.0, true)
		draw_line(Vector2(x, y), Vector2(x + 7, y - 12), g, 3.0, true)
		draw_line(Vector2(x, y), Vector2(x, y - 17), g, 3.0, true)
