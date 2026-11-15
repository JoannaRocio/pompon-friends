extends RefCounted
## Dibujitos de cada comida (para el menú de comer), hechos por código como el resto del arte.
## `draw(cv, id, c, s)`: dibuja la comida `id` centrada en `c`, de tamaño `s` (alto aproximado).

const OUTLINE := Color("5a3a4a")


static func draw(cv: CanvasItem, id: String, c: Vector2, s: float) -> void:
	var u := s / 100.0   # una "unidad": el dibujo se piensa en una caja de 100 x 100
	var w := maxf(2.0, 3.2 * u)
	match id:
		"papilla":
			_bowl(cv, c, u, w, Color("ffe8a8"))
			cv.draw_line(c + Vector2(8, -16) * u, c + Vector2(30, -44) * u, Color("c9c9d6"), 7.0 * u)
			cv.draw_circle(c + Vector2(6, -12) * u, 7.0 * u, Color("c9c9d6"))
		"pan":
			var pts := PackedVector2Array()
			for i in 13:   # la parte de arriba redondeada
				var a := PI + PI * i / 12.0
				pts.append(c + Vector2(cos(a) * 34, -6 + sin(a) * 22) * u)
			pts.append(c + Vector2(30, 36) * u)
			pts.append(c + Vector2(-30, 36) * u)
			_poly(cv, pts, Color("d99a5b"), w)
			var inner := PackedVector2Array()
			for p in pts:
				inner.append(c + (p - c) * 0.78 + Vector2(0, 3) * u)
			cv.draw_colored_polygon(inner, Color("ffe1a8"))
		"arroz":
			_bowl(cv, c, u, w, Color("fffaf0"))
			for v in [Vector2(-18, -8), Vector2(-6, -12), Vector2(8, -9), Vector2(20, -7), Vector2(-12, -2), Vector2(2, -4), Vector2(14, -2)]:
				cv.draw_circle(c + v * u, 3.2 * u, Color("e8dcc0"))
			cv.draw_circle(c + Vector2(-2, -18) * u, 5.0 * u, Color("8fd18b"))
		"manzana":
			cv.draw_line(c + Vector2(0, -22) * u, c + Vector2(4, -40) * u, Color("8a5a3c"), 5.0 * u)
			_circle(cv, c + Vector2(0, 8) * u, 32.0 * u, Color("ff5a5f"), w)
			_leaf(cv, c + Vector2(14, -34) * u, u, w)
			cv.draw_circle(c + Vector2(-14, -4) * u, 7.0 * u, Color(1, 1, 1, 0.55))
		"banana":
			var outer := PackedVector2Array()
			var inner_pts := PackedVector2Array()
			for i in 15:
				var a := deg_to_rad(10.0 + 160.0 * i / 14.0)
				outer.append(c + Vector2(cos(a) * 42, sin(a) * 34 - 12) * u)
				inner_pts.append(c + Vector2(cos(a) * 36, sin(a) * 8 - 10) * u)
			inner_pts.reverse()
			_poly(cv, outer + inner_pts, Color("ffd84d"), w)
			cv.draw_circle(outer[0], 4.0 * u, Color("8a5a3c"))
			cv.draw_circle(outer[outer.size() - 1], 4.0 * u, Color("8a5a3c"))
		"zanahoria":
			for a in [-0.5, 0.0, 0.5]:
				_leaf(cv, c + Vector2(0, -26) * u + Vector2(sin(a), -cos(a)) * 12.0 * u, u, w, a)
			_poly(cv, PackedVector2Array([c + Vector2(-17, -26) * u, c + Vector2(17, -26) * u, c + Vector2(0, 42) * u]), Color("ff9a3d"), w)
			for y in [-10.0, 6.0, 20.0]:
				cv.draw_line(c + Vector2(-8, y) * u, c + Vector2(-1, y) * u, Color("d9732a"), 3.0 * u)
		"galletitas":
			_circle(cv, c + Vector2(10, 10) * u, 26.0 * u, Color("e0a35c"), w)
			_circle(cv, c + Vector2(-8, -6) * u, 30.0 * u, Color("f2b96b"), w)
			for v in [Vector2(-18, -14), Vector2(2, -18), Vector2(-4, 4), Vector2(10, -2), Vector2(-20, 6)]:
				cv.draw_circle(c + v * u, 4.5 * u, Color("6b3f2a"))
		"pizza":
			var tip := c + Vector2(0, 40) * u
			_poly(cv, PackedVector2Array([c + Vector2(-34, -24) * u, c + Vector2(34, -24) * u, tip]), Color("ffd166"), w)
			var crust := Rect2(c + Vector2(-38, -38) * u, Vector2(76, 16) * u)
			cv.draw_rect(crust, Color("d99a5b"))
			cv.draw_rect(crust, OUTLINE, false, w)
			for v in [Vector2(-12, -10), Vector2(12, -8), Vector2(0, 12)]:
				cv.draw_circle(c + v * u, 7.0 * u, Color("e8505b"))
		"helado":
			_poly(cv, PackedVector2Array([c + Vector2(-20, -2) * u, c + Vector2(20, -2) * u, c + Vector2(0, 44) * u]), Color("e9b36a"), w)
			cv.draw_line(c + Vector2(-10, 8) * u, c + Vector2(6, 26) * u, Color("c98c45"), 2.5 * u)
			cv.draw_line(c + Vector2(10, 8) * u, c + Vector2(-6, 26) * u, Color("c98c45"), 2.5 * u)
			_circle(cv, c + Vector2(0, -18) * u, 24.0 * u, Color("ffb3cc"), w)
			cv.draw_circle(c + Vector2(0, -44) * u, 6.0 * u, Color("e8505b"))
		"torta":
			_poly(cv, PackedVector2Array([c + Vector2(-36, 34) * u, c + Vector2(36, 34) * u, c + Vector2(36, -10) * u, c + Vector2(-36, 6) * u]), Color("fff0d6"), w)
			cv.draw_line(c + Vector2(-34, 20) * u, c + Vector2(34, 12) * u, Color("ff8fb1"), 6.0 * u)
			_poly(cv, PackedVector2Array([c + Vector2(-36, 6) * u, c + Vector2(36, -10) * u, c + Vector2(36, -18) * u, c + Vector2(-36, -2) * u]), Color("ffb3cc"), w)
			_circle(cv, c + Vector2(14, -26) * u, 10.0 * u, Color("ff4d6d"), w)
			_leaf(cv, c + Vector2(14, -38) * u, u * 0.7, w)
		"fideos":
			_bowl(cv, c, u, w, Color("ffe08a"))
			for i in 3:
				var y := -14.0 + i * 5.0
				var pts := PackedVector2Array()
				for k in 9:
					pts.append(c + Vector2(-26 + k * 6.5, y + sin(k * 1.4 + i) * 3.0) * u)
				cv.draw_polyline(pts, Color("e9b84a"), 2.5 * u)
			cv.draw_circle(c + Vector2(0, -16) * u, 9.0 * u, Color("e8505b"))
		_:
			Hud.draw_icon(cv, "apple", c, s * 0.7, Color.WHITE, Color(0, 0, 0, 0.3))


static func _bowl(cv: CanvasItem, c: Vector2, u: float, w: float, food_col: Color) -> void:
	# la comida asoma por arriba y el tazón la tapa por delante
	cv.draw_colored_polygon(_ellipse(c + Vector2(0, -8) * u, 34 * u, 14 * u), food_col)
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		pts.append(c + Vector2(cos(a) * 40, -6 + sin(a) * 38) * u)
	_poly(cv, pts, Color("8ec5ff"), w)
	cv.draw_line(c + Vector2(-40, -6) * u, c + Vector2(40, -6) * u, OUTLINE, w)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _poly(cv: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	cv.draw_colored_polygon(pts, col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	cv.draw_polyline(closed, OUTLINE, w, true)


static func _circle(cv: CanvasItem, c: Vector2, r: float, col: Color, w: float) -> void:
	cv.draw_circle(c, r, col)
	cv.draw_arc(c, r, 0, TAU, 32, OUTLINE, w, true)


static func _leaf(cv: CanvasItem, c: Vector2, u: float, w: float, angle := 0.4) -> void:
	var pts := _ellipse(Vector2.ZERO, 6 * u, 12 * u)
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + p.rotated(angle))
	_poly(cv, out, Color("6cc56a"), w * 0.7)
