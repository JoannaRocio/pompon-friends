class_name EnglishPicture
extends Control
## Dibujo de una palabra de ingles (todo por codigo): "c:rrggbb" una mancha de pintura de ese color,
## "n:3" tres puntos en una tabla de diez, y si no un objeto o animal sencillo ("cat", "apple"...).

const OUT := Color("5b3a4a")

var pic := ""


static func has_picture(code: String) -> bool:
	return code.begins_with("c:") or code.begins_with("n:") or code in KINDS


const KINDS := ["cat", "dog", "fish", "bird", "rabbit", "duck", "mouse", "bear", "apple", "banana", "bread", "milk",
	"water", "cheese", "egg", "cake", "cookie", "shirt", "pants", "hat", "dress", "glasses", "house", "door", "window",
	"bed", "table", "chair", "lamp", "book", "pencil", "ruler", "sun", "moon", "star", "tree", "flower", "rain", "cloud", "snow"]


func show_pic(code: String) -> void:
	pic = code
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	if pic.begins_with("c:"):
		_paint(c, s, Color(pic.substr(2)))
	elif pic.begins_with("n:"):
		_ten_frame(c, s, int(pic.substr(2)))
	elif has_method("_" + pic):
		call("_" + pic, c, s * 0.5)


# ---------------------------------------------------------------- ayudas

func _blob(c: Vector2, r: Vector2, col: Color, w := 4.0) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)
	pts.append(pts[0])
	draw_polyline(pts, OUT, w, true)


func _poly(pts: PackedVector2Array, col: Color, w := 4.0) -> void:
	draw_colored_polygon(pts, col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, OUT, w, true)


func _rect(r: Rect2, col: Color, radius := 8.0, w := 4.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = OUT
	sb.set_border_width_all(int(w))
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	draw_style_box(sb, r)


func _eyes(c: Vector2, gap: float, r: float) -> void:
	for sx: float in [-1.0, 1.0]:
		draw_circle(c + Vector2(gap * sx, 0), r, OUT)
		draw_circle(c + Vector2(gap * sx + r * 0.35, -r * 0.35), r * 0.35, Color.WHITE)


func _smile(c: Vector2, r: float) -> void:
	draw_arc(c, r, 0.2, PI - 0.2, 12, OUT, 3.0, true)


func _cheeks(c: Vector2, gap: float, r: float) -> void:
	for sx: float in [-1.0, 1.0]:
		draw_circle(c + Vector2(gap * sx, 0), r, Color(1.0, 0.55, 0.65, 0.55))


## Mancha de pintura (con gotitas) del color de la palabra.
func _paint(c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		var r := s * (0.34 + 0.05 * sin(a * 5.0) + 0.03 * cos(a * 3.0))
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	_poly(pts, col, 5.0)
	_blob(c + Vector2(s * 0.40, -s * 0.30), Vector2(s * 0.06, s * 0.06), col)
	_blob(c + Vector2(-s * 0.42, s * 0.28), Vector2(s * 0.045, s * 0.045), col)
	draw_circle(c + Vector2(-s * 0.12, -s * 0.13), s * 0.06, Color(1, 1, 1, 0.45))


## Tabla de diez (dos filas de cinco) con `n` puntos llenos: se cuentan de un vistazo.
func _ten_frame(c: Vector2, s: float, n: int) -> void:
	var cell := minf(size.x / 5.6, s * 0.36)
	var origin := c - Vector2(cell * 2.5, cell)
	_rect(Rect2(origin, Vector2(cell * 5, cell * 2)), Color("fffaf0"), 10.0)
	for i in 4:
		var x := origin.x + cell * (i + 1)
		draw_line(Vector2(x, origin.y + 4), Vector2(x, origin.y + cell * 2 - 4), Color(OUT, 0.35), 2.0)
	draw_line(Vector2(origin.x + 4, origin.y + cell), Vector2(origin.x + cell * 5 - 4, origin.y + cell), Color(OUT, 0.35), 2.0)
	for i in clampi(n, 0, 10):
		var p := origin + Vector2(cell * (i % 5 + 0.5), cell * (i / 5 + 0.5))
		draw_circle(p, cell * 0.34, Color("ff7aa8"))
		draw_arc(p, cell * 0.34, 0.0, TAU, 20, OUT, 3.0, true)


# ---------------------------------------------------------------- animales (r = medio tamaño)

func _cat(c: Vector2, r: float) -> void:
	var col := Color("ffb26b")
	for sx: float in [-1.0, 1.0]:
		_poly(PackedVector2Array([c + Vector2(sx * r * 0.62, -r * 0.2), c + Vector2(sx * r * 0.7, -r * 0.85), c + Vector2(sx * r * 0.15, -r * 0.5)]), col)
	_blob(c + Vector2(0, r * 0.1), Vector2(r * 0.72, r * 0.6), col)
	_eyes(c + Vector2(0, 0), r * 0.28, r * 0.09)
	draw_circle(c + Vector2(0, r * 0.18), r * 0.06, Color("ff7aa8"))
	for sx: float in [-1.0, 1.0]:
		for k: float in [-1.0, 1.0]:
			draw_line(c + Vector2(sx * r * 0.3, r * 0.24), c + Vector2(sx * r * 0.85, r * (0.2 + 0.1 * k)), OUT, 2.0, true)


func _dog(c: Vector2, r: float) -> void:
	var col := Color("e6b98a")
	_blob(c + Vector2(0, r * 0.05), Vector2(r * 0.66, r * 0.62), col)
	for sx: float in [-1.0, 1.0]:
		_blob(c + Vector2(sx * r * 0.66, r * 0.05), Vector2(r * 0.2, r * 0.42), Color("9c6b45"))
	_eyes(c + Vector2(0, -r * 0.08), r * 0.25, r * 0.09)
	_blob(c + Vector2(0, r * 0.22), Vector2(r * 0.14, r * 0.1), OUT, 2.0)
	_smile(c + Vector2(0, r * 0.28), r * 0.14)


func _fish(c: Vector2, r: float) -> void:
	var col := Color("5bb8f5")
	_poly(PackedVector2Array([c + Vector2(r * 0.45, 0), c + Vector2(r * 0.95, -r * 0.42), c + Vector2(r * 0.95, r * 0.42)]), col.darkened(0.15))
	_blob(c + Vector2(-r * 0.1, 0), Vector2(r * 0.65, r * 0.45), col)
	draw_circle(c + Vector2(-r * 0.42, -r * 0.08), r * 0.09, OUT)
	draw_arc(c + Vector2(-r * 0.05, 0), r * 0.25, -1.0, 1.0, 10, OUT, 3.0, true)


func _bird(c: Vector2, r: float) -> void:
	var col := Color("ff8fab")
	_blob(c, Vector2(r * 0.62, r * 0.55), col)
	_blob(c + Vector2(r * 0.1, r * 0.12), Vector2(r * 0.32, r * 0.2), col.darkened(0.12))
	_poly(PackedVector2Array([c + Vector2(-r * 0.58, -r * 0.08), c + Vector2(-r * 0.92, r * 0.02), c + Vector2(-r * 0.58, r * 0.12)]), Color("ffb938"))
	draw_circle(c + Vector2(-r * 0.3, -r * 0.18), r * 0.08, OUT)
	draw_line(c + Vector2(-r * 0.1, r * 0.55), c + Vector2(-r * 0.1, r * 0.8), OUT, 3.0)
	draw_line(c + Vector2(r * 0.15, r * 0.55), c + Vector2(r * 0.15, r * 0.8), OUT, 3.0)


func _rabbit(c: Vector2, r: float) -> void:
	var col := Color("f4eef2")
	for sx: float in [-1.0, 1.0]:
		_blob(c + Vector2(sx * r * 0.25, -r * 0.55), Vector2(r * 0.14, r * 0.42), col)
		draw_line(c + Vector2(sx * r * 0.25, -r * 0.8), c + Vector2(sx * r * 0.25, -r * 0.32), Color("ffb3c8"), r * 0.1, true)
	_blob(c + Vector2(0, r * 0.25), Vector2(r * 0.6, r * 0.5), col)
	_eyes(c + Vector2(0, r * 0.15), r * 0.24, r * 0.08)
	draw_circle(c + Vector2(0, r * 0.32), r * 0.06, Color("ff7aa8"))
	_cheeks(c + Vector2(0, r * 0.38), r * 0.38, r * 0.09)


func _duck(c: Vector2, r: float) -> void:
	var col := Color("ffd84d")
	_blob(c + Vector2(r * 0.1, r * 0.35), Vector2(r * 0.7, r * 0.4), col)
	_blob(c + Vector2(-r * 0.25, -r * 0.25), Vector2(r * 0.38, r * 0.36), col)
	_blob(c + Vector2(-r * 0.68, -r * 0.18), Vector2(r * 0.2, r * 0.09), Color("ff9b54"), 3.0)
	draw_circle(c + Vector2(-r * 0.32, -r * 0.33), r * 0.07, OUT)
	draw_arc(c + Vector2(r * 0.15, r * 0.3), r * 0.25, 0.2, PI - 0.4, 10, OUT, 3.0, true)


func _mouse(c: Vector2, r: float) -> void:
	var col := Color("c9c3cf")
	for sx: float in [-1.0, 1.0]:
		_blob(c + Vector2(sx * r * 0.52, -r * 0.4), Vector2(r * 0.32, r * 0.32), col)
		draw_circle(c + Vector2(sx * r * 0.52, -r * 0.4), r * 0.18, Color("ffc2d4"))
	_blob(c + Vector2(0, r * 0.12), Vector2(r * 0.55, r * 0.5), col)
	_eyes(c + Vector2(0, r * 0.05), r * 0.22, r * 0.08)
	draw_circle(c + Vector2(0, r * 0.28), r * 0.07, Color("ff7aa8"))


func _bear(c: Vector2, r: float) -> void:
	var col := Color("b07a52")
	for sx: float in [-1.0, 1.0]:
		_blob(c + Vector2(sx * r * 0.52, -r * 0.45), Vector2(r * 0.2, r * 0.2), col)
	_blob(c + Vector2(0, r * 0.05), Vector2(r * 0.68, r * 0.62), col)
	_blob(c + Vector2(0, r * 0.25), Vector2(r * 0.28, r * 0.2), Color("e7c39c"), 3.0)
	_eyes(c + Vector2(0, -r * 0.1), r * 0.26, r * 0.08)
	draw_circle(c + Vector2(0, r * 0.18), r * 0.07, OUT)


# ---------------------------------------------------------------- comida

func _apple(c: Vector2, r: float) -> void:
	_blob(c + Vector2(-r * 0.2, r * 0.1), Vector2(r * 0.45, r * 0.55), Color("ef4444"))
	_blob(c + Vector2(r * 0.2, r * 0.1), Vector2(r * 0.45, r * 0.55), Color("ef4444"))
	draw_circle(c + Vector2(-r * 0.25, -r * 0.1), r * 0.1, Color(1, 1, 1, 0.5))
	draw_line(c + Vector2(0, -r * 0.4), c + Vector2(r * 0.06, -r * 0.7), OUT, 4.0, true)
	_blob(c + Vector2(r * 0.25, -r * 0.6), Vector2(r * 0.18, r * 0.09), Color("5fc77f"), 3.0)


func _banana(c: Vector2, r: float) -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 17:
		var a := PI * 0.15 + PI * 0.7 * i / 16.0
		outer.append(c + Vector2(cos(a), sin(a) - 0.5) * r * 0.95)
		inner.append(c + Vector2(cos(a) * 0.9, sin(a) * 0.4 - 0.23) * r * 0.95)
	inner.reverse()
	outer.append_array(inner)
	_poly(outer, Color("ffd84d"))


func _bread(c: Vector2, r: float) -> void:
	_blob(c + Vector2(0, -r * 0.2), Vector2(r * 0.7, r * 0.4), Color("e0a96d"))
	_rect(Rect2(c + Vector2(-r * 0.62, -r * 0.25), Vector2(r * 1.24, r * 0.85)), Color("e0a96d"), 12.0)
	_rect(Rect2(c + Vector2(-r * 0.45, -r * 0.1), Vector2(r * 0.9, r * 0.55)), Color("fbe3bf"), 10.0, 0.0)


func _milk(c: Vector2, r: float) -> void:
	_poly(PackedVector2Array([c + Vector2(-r * 0.4, -r * 0.4), c + Vector2(0, -r * 0.85), c + Vector2(r * 0.4, -r * 0.4)]), Color("5bb8f5"))
	_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.4), Vector2(r * 0.8, r * 1.2)), Color.WHITE, 6.0)
	_blob(c + Vector2(0, r * 0.2), Vector2(r * 0.22, r * 0.22), Color("5bb8f5"), 3.0)


func _water(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var a := PI * i / 24.0
		pts.append(c + Vector2(cos(a) * r * 0.5, r * 0.15 + sin(a) * r * 0.55))
	pts.append(c + Vector2(0, -r * 0.85))
	_poly(pts, Color("7cc8ff"))
	draw_circle(c + Vector2(-r * 0.2, r * 0.2), r * 0.1, Color(1, 1, 1, 0.6))


func _cheese(c: Vector2, r: float) -> void:
	_poly(PackedVector2Array([c + Vector2(-r * 0.75, r * 0.45), c + Vector2(r * 0.75, r * 0.45), c + Vector2(r * 0.75, -r * 0.15), c + Vector2(-r * 0.75, -r * 0.45)]), Color("ffd84d"))
	for p in [Vector2(-0.35, 0.15), Vector2(0.2, 0.05), Vector2(0.45, 0.28)]:
		draw_circle(c + p * r, r * 0.09, Color("e6b800"))


func _egg(c: Vector2, r: float) -> void:
	_blob(c + Vector2(0, r * 0.05), Vector2(r * 0.85, r * 0.6), Color.WHITE)
	_blob(c + Vector2(0, r * 0.05), Vector2(r * 0.3, r * 0.3), Color("ffc93c"), 3.0)


func _cake(c: Vector2, r: float) -> void:
	_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.1), Vector2(r * 1.4, r * 0.65)), Color("ffb3c8"), 10.0)
	_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.18), Vector2(r * 1.4, r * 0.22)), Color.WHITE, 10.0)
	_rect(Rect2(c + Vector2(-r * 0.05, -r * 0.6), Vector2(r * 0.1, r * 0.42)), Color("5bb8f5"), 3.0, 3.0)
	_blob(c + Vector2(0, -r * 0.7), Vector2(r * 0.07, r * 0.11), Color("ffb938"), 2.0)
	draw_circle(c + Vector2(-r * 0.35, r * 0.25), r * 0.07, Color("ef4444"))
	draw_circle(c + Vector2(r * 0.35, r * 0.25), r * 0.07, Color("ef4444"))


func _cookie(c: Vector2, r: float) -> void:
	_blob(c, Vector2(r * 0.72, r * 0.72), Color("d9a066"))
	for p in [Vector2(-0.3, -0.25), Vector2(0.25, -0.3), Vector2(0.05, 0.1), Vector2(-0.25, 0.32), Vector2(0.35, 0.28)]:
		draw_circle(c + p * r, r * 0.08, Color("6b3e26"))


# ---------------------------------------------------------------- ropa

func _shirt(c: Vector2, r: float) -> void:
	_poly(PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.6), c + Vector2(-r * 0.85, -r * 0.3), c + Vector2(-r * 0.65, r * 0.0),
		c + Vector2(-r * 0.45, -r * 0.1), c + Vector2(-r * 0.45, r * 0.7), c + Vector2(r * 0.45, r * 0.7), c + Vector2(r * 0.45, -r * 0.1),
		c + Vector2(r * 0.65, r * 0.0), c + Vector2(r * 0.85, -r * 0.3), c + Vector2(r * 0.3, -r * 0.6), c + Vector2(0, -r * 0.45)]), Color("a98bea"))


func _pants(c: Vector2, r: float) -> void:
	_poly(PackedVector2Array([c + Vector2(-r * 0.5, -r * 0.7), c + Vector2(r * 0.5, -r * 0.7), c + Vector2(r * 0.6, r * 0.8),
		c + Vector2(r * 0.12, r * 0.8), c + Vector2(0, -r * 0.1), c + Vector2(-r * 0.12, r * 0.8), c + Vector2(-r * 0.6, r * 0.8)]), Color("3b82f6"))


func _hat(c: Vector2, r: float) -> void:
	_blob(c + Vector2(0, r * 0.3), Vector2(r * 0.9, r * 0.22), Color("e0609e"))
	_poly(PackedVector2Array([c + Vector2(-r * 0.45, r * 0.3), c + Vector2(-r * 0.4, -r * 0.45), c + Vector2(r * 0.4, -r * 0.45), c + Vector2(r * 0.45, r * 0.3)]), Color("e0609e"))
	_rect(Rect2(c + Vector2(-r * 0.43, r * 0.02), Vector2(r * 0.86, r * 0.18)), Color("ffd84d"), 2.0, 3.0)


func _dress(c: Vector2, r: float) -> void:
	_poly(PackedVector2Array([c + Vector2(-r * 0.25, -r * 0.75), c + Vector2(r * 0.25, -r * 0.75), c + Vector2(r * 0.32, -r * 0.1),
		c + Vector2(r * 0.75, r * 0.75), c + Vector2(-r * 0.75, r * 0.75), c + Vector2(-r * 0.32, -r * 0.1)]), Color("ff8fab"))
	draw_line(c + Vector2(-r * 0.32, -r * 0.1), c + Vector2(r * 0.32, -r * 0.1), OUT, 3.0)


func _glasses(c: Vector2, r: float) -> void:
	for sx: float in [-1.0, 1.0]:
		_blob(c + Vector2(sx * r * 0.42, 0), Vector2(r * 0.32, r * 0.28), Color(0.75, 0.9, 1.0, 0.8), 5.0)
	draw_arc(c + Vector2(0, r * 0.02), r * 0.12, PI + 0.3, TAU - 0.3, 8, OUT, 5.0, true)


# ---------------------------------------------------------------- la casa

func _house(c: Vector2, r: float) -> void:
	_rect(Rect2(c + Vector2(-r * 0.6, -r * 0.1), Vector2(r * 1.2, r * 0.85)), Color("fff0d6"), 4.0)
	_poly(PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.05), c + Vector2(0, -r * 0.8), c + Vector2(r * 0.8, -r * 0.05)]), Color("ef4444"))
	_rect(Rect2(c + Vector2(-r * 0.15, r * 0.3), Vector2(r * 0.3, r * 0.45)), Color("b07a52"), 4.0, 3.0)


func _door(c: Vector2, r: float) -> void:
	_rect(Rect2(c + Vector2(-r * 0.42, -r * 0.8), Vector2(r * 0.84, r * 1.6)), Color("b07a52"), 10.0)
	_rect(Rect2(c + Vector2(-r * 0.28, -r * 0.62), Vector2(r * 0.56, r * 0.5)), Color("c9925f"), 6.0, 3.0)
	draw_circle(c + Vector2(r * 0.25, r * 0.1), r * 0.07, Color("ffd84d"))


func _window(c: Vector2, r: float) -> void:
	_rect(Rect2(c - Vector2(r * 0.7, r * 0.6), Vector2(r * 1.4, r * 1.2)), Color("bfe6ff"), 8.0)
	draw_line(c + Vector2(0, -r * 0.6), c + Vector2(0, r * 0.6), OUT, 4.0)
	draw_line(c + Vector2(-r * 0.7, 0), c + Vector2(r * 0.7, 0), OUT, 4.0)
	draw_line(c + Vector2(-r * 0.5, -r * 0.4), c + Vector2(-r * 0.25, -r * 0.15), Color(1, 1, 1, 0.8), 4.0)


func _bed(c: Vector2, r: float) -> void:
	_rect(Rect2(c + Vector2(-r * 0.85, -r * 0.5), Vector2(r * 0.18, r * 1.0)), Color("b07a52"), 4.0)
	_rect(Rect2(c + Vector2(-r * 0.75, 0), Vector2(r * 1.6, r * 0.32)), Color("7b8ce0"), 6.0)
	_blob(c + Vector2(-r * 0.45, -r * 0.08), Vector2(r * 0.22, r * 0.12), Color.WHITE, 3.0)
	draw_line(c + Vector2(-r * 0.7, r * 0.32), c + Vector2(-r * 0.7, r * 0.55), OUT, 4.0)
	draw_line(c + Vector2(r * 0.78, r * 0.32), c + Vector2(r * 0.78, r * 0.55), OUT, 4.0)


func _table(c: Vector2, r: float) -> void:
	_rect(Rect2(c + Vector2(-r * 0.85, -r * 0.2), Vector2(r * 1.7, r * 0.2)), Color("c9925f"), 5.0)
	for x: float in [-0.7, 0.62]:
		_rect(Rect2(c + Vector2(r * x, 0), Vector2(r * 0.08, r * 0.65)), Color("b07a52"), 2.0, 3.0)


func _chair(c: Vector2, r: float) -> void:
	_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.8), Vector2(r * 0.12, r * 1.4)), Color("c9925f"), 3.0, 3.0)
	_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.05), Vector2(r * 0.8, r * 0.16)), Color("ff8fab"), 5.0)
	_rect(Rect2(c + Vector2(r * 0.3, r * 0.1), Vector2(r * 0.1, r * 0.5)), Color("c9925f"), 3.0, 3.0)


func _lamp(c: Vector2, r: float) -> void:
	_poly(PackedVector2Array([c + Vector2(-r * 0.25, -r * 0.7), c + Vector2(r * 0.25, -r * 0.7), c + Vector2(r * 0.5, -r * 0.15), c + Vector2(-r * 0.5, -r * 0.15)]), Color("ffd84d"))
	draw_line(c + Vector2(0, -r * 0.15), c + Vector2(0, r * 0.6), OUT, 5.0)
	_blob(c + Vector2(0, r * 0.65), Vector2(r * 0.35, r * 0.1), Color("a98bea"), 3.0)


# ---------------------------------------------------------------- la escuela

func _book(c: Vector2, r: float) -> void:
	_rect(Rect2(c - Vector2(r * 0.7, r * 0.55), Vector2(r * 0.7, r * 1.1)), Color("5bb8f5"), 6.0)
	_rect(Rect2(c - Vector2(0, r * 0.55), Vector2(r * 0.7, r * 1.1)), Color("5bb8f5"), 6.0)
	for k in 3:
		draw_line(c + Vector2(-r * 0.55, -r * 0.3 + r * 0.25 * k), c + Vector2(-r * 0.15, -r * 0.3 + r * 0.25 * k), Color.WHITE, 3.0)
		draw_line(c + Vector2(r * 0.15, -r * 0.3 + r * 0.25 * k), c + Vector2(r * 0.55, -r * 0.3 + r * 0.25 * k), Color.WHITE, 3.0)


func _pencil(c: Vector2, r: float) -> void:
	var d := Vector2(1, -1).normalized()
	var n := Vector2(d.y, -d.x) * -1.0
	var a := c - d * r * 0.7
	var b := c + d * r * 0.45
	_poly(PackedVector2Array([a + n * r * 0.16, b + n * r * 0.16, b - n * r * 0.16, a - n * r * 0.16]), Color("ffd84d"))
	_poly(PackedVector2Array([b + n * r * 0.16, c + d * r * 0.82, b - n * r * 0.16]), Color("f3d9b1"))
	_poly(PackedVector2Array([a + n * r * 0.16, a - n * r * 0.16, a - d * r * 0.15 - n * r * 0.16, a - d * r * 0.15 + n * r * 0.16]), Color("ff8fab"))


func _ruler(c: Vector2, r: float) -> void:
	_rect(Rect2(c - Vector2(r * 0.9, r * 0.22), Vector2(r * 1.8, r * 0.44)), Color("ffd84d"), 5.0)
	for k in 9:
		var x := -r * 0.75 + r * 0.1875 * k
		draw_line(c + Vector2(x, -r * 0.2), c + Vector2(x, -r * (0.02 if k % 2 == 0 else 0.1)), OUT, 2.0)


# ---------------------------------------------------------------- naturaleza

func _sun(c: Vector2, r: float) -> void:
	for i in 10:
		var a := TAU * i / 10.0
		draw_line(c + Vector2(cos(a), sin(a)) * r * 0.55, c + Vector2(cos(a), sin(a)) * r * 0.85, Color("ffb938"), 6.0, true)
	_blob(c, Vector2(r * 0.45, r * 0.45), Color("ffd84d"))
	_eyes(c + Vector2(0, -r * 0.05), r * 0.15, r * 0.05)
	_smile(c + Vector2(0, r * 0.06), r * 0.13)


func _moon(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	var mid := c + Vector2(r * 0.3, 0)
	for i in 25:  # borde de afuera (medio circulo hacia la izquierda) y la curva de adentro
		var a := PI * 0.5 + PI * i / 24.0
		pts.append(mid + Vector2(cos(a), sin(a)) * r * 0.75)
	for i in range(1, 24):
		var a := PI * 1.5 - PI * i / 24.0
		pts.append(mid + Vector2(cos(a) * r * 0.32, sin(a) * r * 0.75))
	_poly(pts, Color("ffe17a"))


func _star(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + PI * i / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * r * (0.8 if i % 2 == 0 else 0.36))
	_poly(pts, Color("ffd84d"))


func _tree(c: Vector2, r: float) -> void:
	_rect(Rect2(c + Vector2(-r * 0.12, r * 0.1), Vector2(r * 0.24, r * 0.7)), Color("b07a52"), 4.0)
	_blob(c + Vector2(-r * 0.3, -r * 0.15), Vector2(r * 0.38, r * 0.35), Color("5fc77f"))
	_blob(c + Vector2(r * 0.3, -r * 0.15), Vector2(r * 0.38, r * 0.35), Color("5fc77f"))
	_blob(c + Vector2(0, -r * 0.45), Vector2(r * 0.42, r * 0.38), Color("5fc77f"))


func _flower(c: Vector2, r: float) -> void:
	draw_line(c + Vector2(0, r * 0.1), c + Vector2(0, r * 0.85), Color("3fa35b"), 6.0)
	_blob(c + Vector2(r * 0.2, r * 0.55), Vector2(r * 0.18, r * 0.09), Color("5fc77f"), 3.0)
	for i in 6:
		var a := TAU * i / 6.0
		_blob(c + Vector2(0, -r * 0.2) + Vector2(cos(a), sin(a)) * r * 0.32, Vector2(r * 0.2, r * 0.2), Color("ff8fab"), 3.0)
	_blob(c + Vector2(0, -r * 0.2), Vector2(r * 0.18, r * 0.18), Color("ffd84d"), 3.0)


func _cloud_shape(c: Vector2, r: float, col: Color) -> void:
	_blob(c + Vector2(-r * 0.4, r * 0.05), Vector2(r * 0.32, r * 0.26), col)
	_blob(c + Vector2(r * 0.4, r * 0.05), Vector2(r * 0.32, r * 0.26), col)
	_blob(c + Vector2(0, -r * 0.12), Vector2(r * 0.42, r * 0.36), col)
	_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.05), Vector2(r * 0.8, r * 0.36)), col, 2.0, 0.0)
	draw_line(c + Vector2(-r * 0.42, r * 0.31), c + Vector2(r * 0.42, r * 0.31), OUT, 4.0)


func _cloud(c: Vector2, r: float) -> void:
	_cloud_shape(c, r, Color("f4f7ff"))


func _rain(c: Vector2, r: float) -> void:
	_cloud_shape(c + Vector2(0, -r * 0.3), r, Color("c9d3e8"))
	for x: float in [-0.4, 0.0, 0.4]:
		_blob(c + Vector2(r * x, r * 0.5 + (r * 0.12 if x == 0.0 else 0.0)), Vector2(r * 0.07, r * 0.12), Color("5bb8f5"), 2.0)


func _snow(c: Vector2, r: float) -> void:
	for i in 3:
		var a := PI * i / 3.0
		var d := Vector2(cos(a), sin(a)) * r * 0.75
		draw_line(c - d, c + d, Color("5bb8f5"), 6.0, true)
		for sgn: float in [-1.0, 1.0]:
			var tip := c + d * sgn
			var back := c + d * sgn * 0.62
			var n := Vector2(-d.y, d.x).normalized() * r * 0.14
			draw_line(back + n, tip - d * sgn * 0.12, Color("5bb8f5"), 4.0, true)
			draw_line(back - n, tip - d * sgn * 0.12, Color("5bb8f5"), 4.0, true)
	draw_circle(c, r * 0.1, Color("5bb8f5"))
