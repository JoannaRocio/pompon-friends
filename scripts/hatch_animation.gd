class_name HatchAnimation
extends Control
## El nacimiento: el huevo salta, se menea cada vez mas fuerte, se va rajando (tic, tic, tic) y ¡POP!:
## salen las dos mitades de la cascara, destellos y corazones, y aparece el bebe Pompon sentado
## en su mitad de cascara. Se puede tocar para seguir. Despues viene ponerle nombre.

signal finished

const OUT := Color("5b3a4a")
const T_POP := 2.7
const T_END := 5.4
const S := 2.5          # escala del huevo (unidades de diseno -> pixeles)

var pompon: Pompon
var t := 0.0
var _c1 := Color("ffb3cc")
var _c2 := Color("fff0f5")
var _egg_pts := PackedVector2Array()
var _zig: Array = []
var _baby: PomponView
var _front: Control
var _cracks_shown := 0
var _popped := false
var _done := false
var _particles: Array = []
var _rng := RandomNumberGenerator.new()


class Front extends Control:
	var anim: HatchAnimation

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		anim._draw_front(self)


func _ready() -> void:
	_rng.randomize()
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	if pompon != null:
		_c1 = pompon.color_primary
		_c2 = pompon.color_secondary
	# silueta del huevo (igual que en PomponView) y la linea quebrada por donde se abre
	for i in 48:
		var a := TAU * i / 48.0
		var x := cos(a) * 62.0
		var y := sin(a) * 82.0
		if y < 0.0:
			x *= 1.0 - 0.18 * (-y / 82.0)
		_egg_pts.append(Vector2(x, y - 84.0))
	for i in 9:
		var zy := -84.0 if (i == 0 or i == 8) else -84.0 + (14.0 if i % 2 == 0 else -14.0)
		_zig.append(Vector2(-61.0 + i * 15.25, zy))
	_baby = PomponView.new()
	_baby.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if pompon != null:
		_baby.set_pompon(pompon, GameState.equipped)
	_baby.visible = false
	add_child(_baby)
	_front = Front.new()
	(_front as Front).anim = self
	_front.anchor_right = 1.0
	_front.anchor_bottom = 1.0
	add_child(_front)
	resized.connect(_layout)
	_layout.call_deferred()


func origin() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.66)


func _layout() -> void:
	var o := origin()
	_baby.size = Vector2(440, 520)
	_baby.position = Vector2(o.x - 220.0, o.y - 520.0 - 135.0)   # sentado dentro de la cascara, con la cabeza asomando
	_baby.pivot_offset = Vector2(220, 514)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and t > T_POP + 0.9:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func():
		finished.emit()
		queue_free())


# ----------------------------------------------------------------- animacion

func _wobble() -> float:
	# tres tandas de meneos, cada una mas fuerte
	var windows := [[0.55, 1.0, 0.07], [1.2, 1.75, 0.13], [1.95, 2.55, 0.2]]
	for w in windows:
		if t >= w[0] and t <= w[1]:
			var k: float = (t - w[0]) / (w[1] - w[0])
			return sin(k * TAU * 3.0) * w[2] * sin(k * PI)
	return 0.0


func _process(delta: float) -> void:
	t += delta
	# grietas que van apareciendo (cada una con su "tic")
	var want := 0
	if t > 0.9:
		want = 1
	if t > 1.6:
		want = 2
	if t > 2.25:
		want = 3
	while _cracks_shown < want:
		_cracks_shown += 1
		Audio.play("click", 0.9 + 0.2 * _cracks_shown)
		_flecks(origin() + Vector2(_rng.randf_range(-40, 40), -S * 100.0), 5)
	if not _popped and t >= T_POP:
		_pop()
	if t > T_END and not _done:
		_finish()
	for p in _particles:
		p["age"] += delta
		p["pos"] += p["vel"] * delta
		p["vel"] += Vector2(0, p["g"]) * delta
	_particles = _particles.filter(func(p): return p["age"] < p["life"])
	if _popped:
		var k := clampf((t - T_POP - 0.1) / 0.7, 0.0, 1.0)
		var bounce := _back_out(k)
		_baby.scale = Vector2(bounce, bounce)
	queue_redraw()
	_front.queue_redraw()


func _back_out(x: float) -> float:
	var c1 := 2.2
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


func _pop() -> void:
	_popped = true
	_baby.visible = true
	_baby.scale = Vector2.ZERO
	_baby.celebrate(8)
	Audio.play("hatch")
	var o := origin()
	for i in 26:
		var a := _rng.randf() * TAU
		_particles.append({"pos": o + Vector2(0, -S * 90.0), "vel": Vector2(cos(a), sin(a)) * _rng.randf_range(160.0, 520.0) + Vector2(0, -160),
			"age": 0.0, "life": _rng.randf_range(0.8, 1.4), "g": 420.0, "kind": "star",
			"color": [Color("ffd33d"), Color("ff8fc8"), Color("8ecae6"), Color("90be6d"), Color.WHITE][i % 5], "size": _rng.randf_range(9.0, 18.0)})
	for i in 10:
		_particles.append({"pos": o + Vector2(_rng.randf_range(-80, 80), -S * 60.0), "vel": Vector2(_rng.randf_range(-60, 60), _rng.randf_range(-200, -110)),
			"age": -_rng.randf_range(0.0, 0.6), "life": 1.8, "g": -20.0, "kind": "heart", "color": Color("ff7aa8"), "size": _rng.randf_range(0.8, 1.4)})
	_flecks(o + Vector2(0, -S * 80.0), 16)


func _flecks(pos: Vector2, n: int) -> void:
	for i in n:
		var a := _rng.randf() * TAU
		_particles.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * _rng.randf_range(60.0, 220.0) + Vector2(0, -80),
			"age": 0.0, "life": _rng.randf_range(0.5, 0.9), "g": 520.0, "kind": "fleck", "color": _c2.lerp(_c1, 0.4), "size": _rng.randf_range(5.0, 10.0)})


# -------------------------------------------------------------------- dibujo

func _egg_base() -> Color:
	return _c2.lerp(_c1, 0.3)


func _xf(rot: float, offset: Vector2, scale_f: float) -> Transform2D:
	return Transform2D(rot, Vector2(S * scale_f, S * scale_f), 0.0, origin() + offset)


func _shell_polys() -> Array:
	# [mitad de arriba, mitad de abajo] en coordenadas de diseno
	var top := PackedVector2Array()
	for i in range(24, 48):
		top.append(_egg_pts[i])
	top.append(_egg_pts[0])
	for i in range(_zig.size() - 1, -1, -1):
		top.append(_zig[i])
	var bottom := PackedVector2Array()
	for i in range(0, 25):
		bottom.append(_egg_pts[i])
	for i in _zig.size():
		bottom.append(_zig[i])
	return [top, bottom]


func _draw() -> void:
	var o := origin()
	# fondo suave y brillo detras del huevo
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.15, 0.3, 0.55 * minf(t / 0.4, 1.0)))
	var glow := 0.25 + 0.6 * clampf((t - T_POP + 0.3) / 0.5, 0.0, 1.0)
	for k in 5:
		draw_circle(o + Vector2(0, -S * 84.0), (150.0 + k * 55.0) * (1.0 + 0.1 * sin(t * 3.0)), Color(1.0, 0.95, 0.75, 0.05 * glow))
	if not _popped:
		_draw_egg_whole()
	else:
		_draw_top_shell()
	# estrellitas y corazones
	for p in _particles:
		var age: float = p["age"]
		if age < 0.0:
			continue
		var life: float = p["life"]
		var a := clampf(1.0 - age / life, 0.0, 1.0)
		var col: Color = p["color"]
		col.a = a
		match p["kind"]:
			"star":
				var pts := PackedVector2Array()
				var r: float = p["size"] * (0.5 + 0.5 * a)
				for i in 10:
					var ang := -PI / 2.0 + PI * i / 5.0 + age * 3.0
					pts.append(p["pos"] + Vector2(cos(ang), sin(ang)) * (r if i % 2 == 0 else r * 0.4))
				draw_colored_polygon(pts, col)
			"fleck":
				draw_circle(p["pos"], p["size"] * a, col)
			"heart":
				var hp := PackedVector2Array()
				for i in 28:
					var ang2 := TAU * i / 28.0
					hp.append(p["pos"] + Vector2(16.0 * pow(sin(ang2), 3.0), -(13.0 * cos(ang2) - 5.0 * cos(2.0 * ang2) - 2.0 * cos(3.0 * ang2) - cos(4.0 * ang2))) * float(p["size"]))
				draw_colored_polygon(hp, col)
	# destello blanco al abrirse
	if _popped and t < T_POP + 0.4:
		var f := 1.0 - (t - T_POP) / 0.4
		draw_circle(o + Vector2(0, -S * 84.0), 120.0 + 420.0 * (1.0 - f), Color(1, 1, 1, 0.65 * f))


func _draw_egg_whole() -> void:
	var drop := clampf(t / 0.5, 0.0, 1.0)
	var sc := _back_out(drop)
	var squash := 1.0 - 0.04 * absf(sin(t * 12.0)) * (1.0 if _wobble() != 0.0 else 0.0)
	var xf := Transform2D(_wobble(), Vector2(S * sc, S * sc * squash), 0.0, origin() + Vector2(0, (1.0 - drop) * -40.0))
	draw_set_transform_matrix(xf)
	draw_colored_polygon(_egg_pts, _egg_base())
	for pos in [Vector2(-25, -120), Vector2(22, -100), Vector2(-8, -150), Vector2(30, -140)]:
		draw_circle(pos, 9.0, _c1)
	var zig := []
	for i in 9:
		zig.append(Vector2(-52.0 + i * 13.0, -62.0 + (8.0 if i % 2 == 0 else -8.0)))
	draw_polyline(PackedVector2Array(zig), _c1, 7.0, true)
	draw_circle(Vector2(-26, -140), 9.0, Color(1, 1, 1, 0.55))
	var outline: PackedVector2Array = _egg_pts.duplicate()
	outline.append(outline[0])
	draw_polyline(outline, OUT, 5.0, true)
	# grietas
	var cracks := [
		[Vector2(-4, -164), Vector2(5, -150), Vector2(-6, -138), Vector2(4, -124), Vector2(-3, -112)],
		[Vector2(36, -112), Vector2(22, -100), Vector2(32, -88), Vector2(18, -78)],
		[Vector2(-40, -78), Vector2(-24, -90), Vector2(-34, -102), Vector2(-20, -112)],
	]
	for i in _cracks_shown:
		draw_polyline(PackedVector2Array(cracks[i]), Color("5b3a4a"), 4.0, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## La mitad de arriba sale volando hacia arriba y a un costado, girando y desvaneciendose.
func _draw_top_shell() -> void:
	var k := clampf((t - T_POP) / 1.0, 0.0, 1.0)
	if k >= 1.0:
		return
	var polys := _shell_polys()
	var off := Vector2(190.0 * k, -420.0 * k + 560.0 * k * k)
	var rot := 1.4 * k
	draw_set_transform_matrix(Transform2D(rot, Vector2(S, S), 0.0, origin() + off))
	var col := _egg_base()
	col.a = 1.0 - k * k
	draw_colored_polygon(polys[0], col)
	var line: PackedVector2Array = (polys[0] as PackedVector2Array).duplicate()
	line.append(line[0])
	draw_polyline(line, Color(OUT.r, OUT.g, OUT.b, 1.0 - k * k), 5.0, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Lo que va por delante del bebe: la mitad de abajo de la cascara y el cartel "¡Nació!".
func _draw_front(cv: Control) -> void:
	if not _popped:
		return
	var polys := _shell_polys()
	var settle := _back_out(clampf((t - T_POP) / 0.5, 0.0, 1.0))
	cv.draw_set_transform_matrix(Transform2D(0.0, Vector2(S, S), 0.0, origin() + Vector2(0, 6.0 * (1.0 - settle))))
	var bottom: PackedVector2Array = polys[1]
	cv.draw_colored_polygon(bottom, _egg_base())
	cv.draw_polyline(PackedVector2Array([_zig[0], _zig[1], _zig[2], _zig[3], _zig[4], _zig[5], _zig[6], _zig[7], _zig[8]]), Color("fffaf0"), 5.0, true)
	var line: PackedVector2Array = bottom.duplicate()
	line.append(line[0])
	cv.draw_polyline(line, OUT, 5.0, true)
	for pos in [Vector2(-30, -26), Vector2(20, -14), Vector2(0, -40)]:
		cv.draw_circle(pos, 8.0, _c1)
	cv.draw_set_transform_matrix(Transform2D.IDENTITY)
	if t > T_POP + 0.6:
		var a := clampf((t - T_POP - 0.6) / 0.4, 0.0, 1.0)
		var font := get_theme_default_font()
		var y := size.y * 0.2
		cv.draw_string_outline(font, Vector2(0, y), "¡Nació!", HORIZONTAL_ALIGNMENT_CENTER, size.x, 110, 20, Color(1, 1, 1, a))
		cv.draw_string(font, Vector2(0, y), "¡Nació!", HORIZONTAL_ALIGNMENT_CENTER, size.x, 110, Color(0.84, 0.2, 0.42, a))
		if t > T_POP + 1.4:
			var blink := 0.5 + 0.5 * sin(t * 4.0)
			cv.draw_string(font, Vector2(0, size.y * 0.9), "Toca para seguir", HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, Color(1, 1, 1, 0.5 + 0.5 * blink))
