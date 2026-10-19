class_name MovieScreen
extends Control
## La pantalla del cine: dibuja la escena actual de una pelicula (fondo y objetos, todo por codigo) y
## mueve a los actores (PomponView de muestra). `t` = segundos desde que empezo la escena (animaciones).

const OUT := Color("5b3a4a")

var movie := {}
var scene_i := 0
var t := 0.0
var _actors := {}    # quien -> PomponView
var _jump_t := 0.0
var _front: Control  # lo que va delante de los actores (la crema en la nariz)


func setup(m: Dictionary) -> void:
	movie = m
	clip_contents = true
	for who in _actors:   # (si ya tenia otra pelicula)
		_actors[who].queue_free()
	_actors = {}
	if _front == null:
		_front = Control.new()
		_front.set_anchors_preset(Control.PRESET_FULL_RECT)
		_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_front.draw.connect(func():
			for p in scene()["props"]:
				if p[0] == "cream":
					var c := Vector2(p[1] * size.x, p[2] * size.y)
					var s: float = p[3] * size.y
					_front.draw_circle(c, s, Color.WHITE)
					_front.draw_circle(c + Vector2(s * 0.8, s * 0.3), s * 0.6, Color.WHITE))
	for who in m["cast"]:
		var v := PomponView.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_pompon(Movies.cast_pompon(m, who))
		v.visible = false
		add_child(v)
		_actors[who] = v
	if _front != null:
		if _front.get_parent() == null:
			add_child(_front)
		move_child(_front, get_child_count() - 1)
	show_scene(0)


func scene() -> Dictionary:
	return movie["scenes"][scene_i]


func show_scene(i: int) -> void:
	scene_i = clampi(i, 0, movie["scenes"].size() - 1)
	t = 0.0
	for who in _actors:
		_actors[who].visible = false
	for a in scene()["actors"]:
		var v: PomponView = _actors[a[0]]
		var opt: Dictionary = a[3]
		v.visible = not opt.get("hidden", false)
		v.facing = float(opt.get("face", 1))
		v.face_mood = str(opt.get("mood", ""))
		v.walking = bool(opt.get("walk", false))
		v.lean = float(opt.get("lean", 0.0))
	_place_actors()
	queue_redraw()
	if _front != null:
		_front.queue_redraw()


func _actor_size() -> float:
	return size.y * 0.42


func _place_actors() -> void:
	var s := _actor_size()
	for a in scene()["actors"]:
		var v: PomponView = _actors[a[0]]
		v.size = Vector2(s, s)
		var x: float = a[1] * size.x
		if a[3].get("walk", false):   # camina un poquito durante la escena
			x += t * size.x * 0.05
		v.position = Vector2(x - s * 0.5, a[2] * size.y - s + 6.0)


func _process(delta: float) -> void:
	if movie.is_empty():
		return
	t += delta
	_jump_t -= delta
	if _jump_t <= 0.0:
		_jump_t = 1.0
		for a in scene()["actors"]:
			if a[3].get("jump", false):
				_actors[a[0]].celebrate(0)
	_place_actors()
	queue_redraw()


# ---------------------------------------------------------------- dibujo

func _draw() -> void:
	if movie.is_empty() or size.y < 20.0:
		return
	_draw_bg(scene()["bg"])
	for p in scene()["props"]:
		_prop(p)


func _grad(top: Color, bottom: Color, y0 := 0.0, y1 := 1.0) -> void:
	var a := Vector2(0, y0 * size.y)
	var b := Vector2(size.x, y1 * size.y)
	draw_polygon(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]), PackedColorArray([top, top, bottom, bottom]))


static func _rand(i: int, k: float) -> float:
	var v := sin(i * 12.9898 + k * 78.233) * 43758.5453
	return v - floor(v)


func _stars(n: int, alpha := 1.0) -> void:
	for i in n:
		var p := Vector2(_rand(i, 1.0) * size.x, _rand(i, 2.0) * size.y * 0.7)
		var tw := 0.6 + 0.4 * sin(t * 3.0 + i)
		draw_circle(p, 2.0 + (i % 3), Color(1, 1, 1, alpha * tw))


func _draw_bg(bg: String) -> void:
	var w := size.x
	var h := size.y
	match bg:
		"night_room":
			_grad(Color("3b3266"), Color("5a4a8a"), 0.0, 0.8)
			draw_rect(Rect2(0, h * 0.8, w, h * 0.2), Color("6b4f7a"))
		"night_field":
			_grad(Color("1e2452"), Color("4a4f8f"), 0.0, 0.85)
			_stars(30)
			draw_rect(Rect2(0, h * 0.85, w, h * 0.15), Color("3f6b4a"))
		"space":
			_grad(Color("0f1235"), Color("2a1f55"))
			_stars(60)
		"moon":
			_grad(Color("10143a"), Color("2c2a60"), 0.0, 0.85)
			_stars(40)
			draw_rect(Rect2(0, h * 0.84, w, h * 0.16), Color("c9c3cf"))
			for c in [Vector2(0.2, 0.92), Vector2(0.55, 0.95), Vector2(0.85, 0.9)]:
				draw_circle(Vector2(c.x * w, c.y * h), h * 0.03, Color("a9a2b2"))
		"kitchen":
			_grad(Color("fff1e0"), Color("ffe3c4"), 0.0, 0.8)
			for i in int(w / 40.0) + 1:   # azulejos
				draw_line(Vector2(i * 40.0, h * 0.2), Vector2(i * 40.0, h * 0.5), Color(1, 1, 1, 0.5), 2.0)
			draw_rect(Rect2(0, h * 0.8, w, h * 0.2), Color("e0b48f"))
		"garden":
			_grad(Color("bfe6ff"), Color("e6f6ff"), 0.0, 0.8)
			draw_circle(Vector2(w * 0.85, h * 0.18), h * 0.08, Color("ffd84d"))
			draw_rect(Rect2(0, h * 0.8, w, h * 0.2), Color("8fd47e"))
		"sky":
			_grad(Color("8ecdf5"), Color("d9f1ff"))
			draw_circle(Vector2(w * 0.12, h * 0.14), h * 0.07, Color("ffe17a"))
		"field":
			_grad(Color("a9dcff"), Color("e6f6ff"), 0.0, 0.82)
			draw_rect(Rect2(0, h * 0.82, w, h * 0.18), Color("8fd47e"))
	draw_rect(Rect2(Vector2.ZERO, size), OUT, false, 4.0)


func _blob(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c, r, col)


func _cloud(c: Vector2, r: float, col: Color) -> void:
	for part in [[-0.6, 0.15, 0.55], [0.0, -0.1, 0.75], [0.6, 0.15, 0.55]]:
		draw_circle(c + Vector2(part[0], part[1]) * r, part[2] * r, col)
	draw_rect(Rect2(c + Vector2(-0.6, 0.1) * r, Vector2(1.2, 0.5) * r), col)


func _star_shape(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + PI * i / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, col)


func _prop(p: Array) -> void:
	var w := size.x
	var h := size.y
	var c := Vector2(p[1] * w, p[2] * h)
	var s: float = p[3] * h
	match p[0]:
		"moon":
			draw_circle(c, s, Color("ffe9a3"))
			draw_circle(c + Vector2(s * 0.3, -s * 0.2), s * 0.18, Color("f2d27a"))
		"window":
			draw_rect(Rect2(c - Vector2(s * 0.8, s * 0.8), Vector2(s * 1.6, s * 1.6)), Color("1e2452"))
			draw_rect(Rect2(c - Vector2(s * 0.8, s * 0.8), Vector2(s * 1.6, s * 1.6)), Color("c9925f"), false, 8.0)
		"boxes":
			for b in [[-0.5, 0.0, 0.5], [0.05, 0.0, 0.5], [-0.22, -0.45, 0.45]]:
				var r := Rect2(c + Vector2(b[0], b[1] - b[2]) * s, Vector2(b[2], b[2]) * s)
				draw_rect(r, Color("d9a066"))
				draw_rect(r, OUT, false, 3.0)
		"rocket":
			var lift := 0.0
			if p.size() > 4 and p[4] == "launch":
				lift = maxf(0.0, t - 1.6) * h * 0.35
			var drift := t * w * 0.12 if p.size() > 4 and p[4] == "fly" else 0.0
			var base := c + Vector2(drift, -lift)
			if p.size() > 4 and p[4] == "fly":
				draw_set_transform(base, PI / 2.6, Vector2.ONE)
				base = Vector2.ZERO
			var body := Rect2(base + Vector2(-s * 0.22, -s), Vector2(s * 0.44, s * 0.8))
			draw_rect(body, Color("f4eef2"))
			draw_rect(body, OUT, false, 3.0)
			draw_colored_polygon(PackedVector2Array([body.position, body.position + Vector2(body.size.x, 0), base + Vector2(0, -s * 1.35)]), Color("ef4444"))
			draw_circle(base + Vector2(0, -s * 0.7), s * 0.1, Color("7cc8ff"))
			for side in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([base + Vector2(side * s * 0.22, -s * 0.45), base + Vector2(side * s * 0.42, -s * 0.15), base + Vector2(side * s * 0.22, -s * 0.2)]), Color("ef4444"))
			if lift > 0.0 or drift > 0.0 or (p.size() > 4 and t > 1.0):   # fuego
				var f := 0.12 + 0.05 * sin(t * 30.0)
				draw_colored_polygon(PackedVector2Array([base + Vector2(-s * 0.15, -s * 0.2), base + Vector2(s * 0.15, -s * 0.2), base + Vector2(0, s * (0.1 + f))]), Color("ffb938"))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			if p.size() > 4 and p[4] == "launch" and t < 1.6:
				var font := get_theme_default_font()
				var n := 3 - int(t / 0.55)
				draw_string(font, Vector2(0, h * 0.3), str(maxi(n, 1)), HORIZONTAL_ALIGNMENT_CENTER, w, int(h * 0.2), Color("ffe066"))
		"planet":
			draw_circle(c, s, Color("ff9ecb"))
			draw_arc(c, s * 1.5, PI * 0.9, PI * 2.1, 24, Color("ffd84d"), 5.0, true)
		"earth":
			draw_circle(c, s, Color("5bb8f5"))
			draw_circle(c + Vector2(-s * 0.3, -s * 0.2), s * 0.35, Color("5fc77f"))
			draw_circle(c + Vector2(s * 0.35, s * 0.3), s * 0.28, Color("5fc77f"))
		"star":
			_star_shape(c, s * (1.0 + 0.08 * sin(t * 4.0)), Color("ffe066"))
		"table":
			draw_rect(Rect2(c + Vector2(-s, -s * 0.9), Vector2(s * 2.0, s * 0.18)), Color("c9925f"))
			draw_rect(Rect2(c + Vector2(-s * 0.85, -s * 0.72), Vector2(s * 0.12, s * 0.72)), Color("b07a52"))
			draw_rect(Rect2(c + Vector2(s * 0.73, -s * 0.72), Vector2(s * 0.12, s * 0.72)), Color("b07a52"))
		"cake":
			draw_rect(Rect2(c + Vector2(-s, 0), Vector2(s * 2.0, s * 1.1)), Color("ffb3c8"))
			draw_rect(Rect2(c + Vector2(-s, -s * 0.15), Vector2(s * 2.0, s * 0.3)), Color.WHITE)
			for k in 3:
				draw_rect(Rect2(c + Vector2(-s * 0.6 + k * s * 0.55, -s * 0.7), Vector2(s * 0.1, s * 0.55)), Color("5bb8f5"))
				draw_circle(c + Vector2(-s * 0.55 + k * s * 0.55, -s * 0.78), s * 0.09, Color("ffb938"))
		"crumbs":
			for k in 5:
				draw_circle(c + Vector2((k - 2) * s * 0.6, sin(k * 1.7) * s * 0.3), s * 0.18, Color("e0a96d"))
		"question":
			var font2 := get_theme_default_font()
			draw_string(font2, c + Vector2(-s, s * 0.6), "?", HORIZONTAL_ALIGNMENT_CENTER, s * 2.0, int(s * 2.2), Color("d6336c"))
		"magnifier":
			draw_line(c + Vector2(s * 0.7, s * 0.7), c + Vector2(s * 1.6, s * 1.6), Color("8b5a2b"), s * 0.35)
			draw_circle(c, s, Color(0.8, 0.93, 1.0, 0.7))
			draw_arc(c, s, 0.0, TAU, 24, OUT, 5.0, true)
		"bush":
			for k in 3:
				draw_circle(c + Vector2((k - 1) * s * 0.7, -s * (0.5 if k == 1 else 0.3)), s * 0.6, Color("4caf6a"))
		"confetti":
			for k in 24:
				var pos := c + Vector2(fmod(k * 73.0, s * 2.0) - s, fmod(k * 41.0 + t * 90.0, h * 0.7) - s * 0.5)
				draw_rect(Rect2(pos, Vector2(8, 12)), [Color("ff7aa8"), Color("ffd84d"), Color("5bb8f5"), Color("5fc77f")][k % 4])
		"big_cloud":
			_cloud(c, s, Color("eef2f8"))
		"rain":
			for k in 9:
				var x := c.x + (k - 4) * s * 0.22
				var y := c.y + fmod(t * h * 0.5 + k * 37.0, s * 1.6)
				draw_line(Vector2(x, y), Vector2(x - 3, y + 14), Color("5bb8f5"), 3.0, true)
		"cloud_face":
			var mood: String = p[4] if p.size() > 4 else "happy"
			var shake := sin(t * 40.0) * 4.0 if mood == "try" else 0.0
			var cc := c + Vector2(shake, sin(t * 2.0) * 4.0)
			_cloud(cc, s, Color.WHITE)
			for sx in [-1.0, 1.0]:
				if mood == "try":
					draw_line(cc + Vector2(sx * s * 0.3 - 8, -4), cc + Vector2(sx * s * 0.3 + 8, 4 * -sx), OUT, 4.0)
				else:
					draw_circle(cc + Vector2(sx * s * 0.3, 0), s * 0.08, OUT)
			if mood == "sad":
				draw_arc(cc + Vector2(0, s * 0.35), s * 0.18, PI + 0.4, TAU - 0.4, 10, OUT, 4.0, true)
				draw_circle(cc + Vector2(s * 0.42, s * 0.15), s * 0.06, Color("7cc8ff"))   # lagrimita
			else:
				draw_arc(cc + Vector2(0, s * 0.15), s * 0.18, 0.4, PI - 0.4, 10, OUT, 4.0, true)
			draw_circle(cc + Vector2(-s * 0.5, s * 0.18), s * 0.09, Color(1.0, 0.6, 0.7, 0.6))
			draw_circle(cc + Vector2(s * 0.5, s * 0.18), s * 0.09, Color(1.0, 0.6, 0.7, 0.6))
		"flowers":
			var fresh: bool = p.size() > 4 and p[4] == "fresh"
			for k in 5:
				var fx := c.x + (k - 2) * s * 0.42
				var stem := s * (0.55 if fresh else 0.35)
				var base := Vector2(fx, c.y)
				var top := base + (Vector2(0, -stem) if fresh else Vector2(stem * 0.5, -stem * 0.8))
				draw_line(base, top, Color("3fa35b") if fresh else Color("b9a56a"), 4.0, true)
				for petal in 5:
					var a := TAU * petal / 5.0
					draw_circle(top + Vector2(cos(a), sin(a)) * s * 0.07, s * 0.06, [Color("ff7aa8"), Color("ffd84d"), Color("a98bea")][k % 3] if fresh else Color("c9b08a"))
				draw_circle(top, s * 0.05, Color("ffb938") if fresh else Color("a08a5a"))
		"rainbow":
			var cols := [Color("ef4444"), Color("fb923c"), Color("facc15"), Color("22c55e"), Color("3b82f6"), Color("a855f7")]
			for k in cols.size():
				draw_arc(c + Vector2(0, s * 0.6), s - k * s * 0.08, PI, TAU, 40, Color(cols[k], 0.8), s * 0.08, true)
