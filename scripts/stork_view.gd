class_name StorkView
extends Control
## La cigueña (dibujada por codigo, estilo kawaii) que trae el huevo colgando de un paño.
## El origen (0, 0) es el centro del cuerpo; mira a la derecha. Se mueve con `position` / `scale`.
## `flap` = fase del aleteo, `bundle_len` = largo del paño colgando, `bundle_state` = 0 con huevo, 1 vacio.

const OUT := Color("5b3a4a")
const WHITE := Color("ffffff")
const SHADE := Color("e9e3f2")
const ORANGE := Color("ff9140")
const CLOTH := Color("bfe3f7")
const CLOTH_DARK := Color("8cc4e6")

var flap := 0.0
var bundle_len := 120.0
var bundle_state := 0.0
var squash := 0.0     # 0..1: el paño se aplasta al apoyarse en el nido
var sway := 0.0       # balanceo del paño (radianes)
var wave := 0.0       # 0..1 saludo con el ala cuando se despide
var egg_color_a := Color("fff1d6")
var show_egg := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ell(c: Vector2, rx: float, ry: float, fill: Color, rot := 0.0, outline := true, w := 4.5) -> void:
	var pts := PackedVector2Array()
	for i in 36:
		var a := TAU * i / 36.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry).rotated(rot) + c)
	draw_colored_polygon(pts, fill)
	if outline:
		pts.append(pts[0])
		draw_polyline(pts, OUT, w, true)


func _poly(points: Array, fill: Color, outline := true, w := 4.5) -> void:
	var pts := PackedVector2Array(points)
	draw_colored_polygon(pts, fill)
	if outline:
		pts.append(pts[0])
		draw_polyline(pts, OUT, w, true)


func _tube(pts: Array, width: float, fill: Color) -> void:
	var packed := PackedVector2Array(pts)
	draw_polyline(packed, OUT, width + 9.0, true)
	draw_circle(packed[0], (width + 9.0) * 0.5, OUT)
	draw_circle(packed[packed.size() - 1], (width + 9.0) * 0.5, OUT)
	draw_polyline(packed, fill, width, true)
	draw_circle(packed[0], width * 0.5, fill)
	draw_circle(packed[packed.size() - 1], width * 0.5, fill)


func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, steps := 12) -> Array:
	var out := []
	for i in steps + 1:
		var t := float(i) / steps
		out.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return out


## Curva cerrada suave por los puntos (Catmull-Rom).
func _smooth(points: Array, steps := 8) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := points.size()
	for i in n:
		var p0: Vector2 = points[(i - 1 + n) % n]
		var p1: Vector2 = points[i]
		var p2: Vector2 = points[(i + 1) % n]
		var p3: Vector2 = points[(i + 2) % n]
		for s in steps:
			var u := float(s) / steps
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u * u + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u * u * u))
	return out


## Ala redondita que sube hacia atras; se mueve desde el hombro. La punta lleva plumas negras.
func _wing(shoulder: Vector2, angle: float, far: bool) -> void:
	var xf := Transform2D(angle, shoulder)
	var base := SHADE if far else WHITE
	var dark := Color("5a4558") if far else Color("3d2b3a")
	for i in 4:
		var c := xf * Vector2(-52.0 - i * 13.0, -112.0 + i * 20.0)
		var rot := angle - 1.2 + i * 0.22
		var pts := PackedVector2Array()
		for k in 24:
			var a := TAU * k / 24.0
			pts.append(c + Vector2(cos(a) * 34.0, sin(a) * 12.0).rotated(rot))
		draw_colored_polygon(pts, dark)
		pts.append(pts[0])
		draw_polyline(pts, OUT, 3.5, true)
	var shape := _smooth([Vector2(36, -2), Vector2(28, -46), Vector2(-4, -92), Vector2(-46, -112), Vector2(-76, -96), Vector2(-76, -56), Vector2(-62, -22), Vector2(-40, 8)])
	var pts2 := PackedVector2Array()
	for p in shape:
		pts2.append(xf * p)
	draw_colored_polygon(pts2, base)
	pts2.append(pts2[0])
	draw_polyline(pts2, OUT, 4.5, true)
	# lineas de plumas
	for dx in [-8.0, -26.0, -44.0]:
		draw_line(xf * Vector2(dx, -14.0), xf * Vector2(dx - 8.0, -64.0), Color(OUT, 0.35), 3.0, true)


func _draw() -> void:
	var f := sin(flap) * 0.6
	# ala de atras
	_wing(Vector2(10, -30), -f * 0.8 + 0.12, true)
	# patas largas hacia atras
	for i in 2:
		var hip := Vector2(-26 + i * 16.0, 36)
		var knee := hip + Vector2(-46, 14 + sin(flap * 0.8 + i) * 5.0)
		var foot := knee + Vector2(-44, 12 + i * 5.0)
		_tube([hip, knee, foot], 6.0, ORANGE)
		_poly([foot + Vector2(-2, -6), foot + Vector2(-22, 2), foot + Vector2(-2, 8)], ORANGE, true, 3.0)
	# cola
	_poly([Vector2(-60, -8), Vector2(-124, -26), Vector2(-132, 0), Vector2(-62, 18)], WHITE)
	_poly([Vector2(-106, -20), Vector2(-124, -26), Vector2(-132, 0), Vector2(-110, 2)], Color("3d2b3a"), false)
	# cuerpo
	_ell(Vector2(0, 0), 80, 52, WHITE)
	_ell(Vector2(8, 22), 58, 26, SHADE, 0.0, false)
	# cuello y cabeza
	_tube(_bezier(Vector2(52, -16), Vector2(92, -36), Vector2(100, -62)), 26.0, WHITE)
	_ell(Vector2(108, -70), 32, 27, WHITE)
	_ell(Vector2(98, -56), 11, 7, Color(1.0, 0.55, 0.65, 0.6), 0.0, false)
	draw_circle(Vector2(116, -76), 6.5, OUT)
	draw_circle(Vector2(118, -78), 2.4, WHITE)
	# pico largo
	_poly([Vector2(130, -84), Vector2(212, -60), Vector2(130, -56)], ORANGE)
	draw_line(Vector2(134, -68), Vector2(196, -62), Color("c9611f"), 2.5, true)
	# ala de adelante
	_wing(Vector2(4, -28), f - 0.05, false)
	_draw_bundle()


func _draw_bundle() -> void:
	var knot := Vector2(190, -56)
	var pivot_xf := Transform2D(sway, knot)
	var len := maxf(bundle_len, 20.0)
	var sack_c := pivot_xf * Vector2(0, len + 40.0)
	var sack_top := pivot_xf * Vector2(0, len)
	# cuerda / punta del paño que cuelga del pico
	_tube([knot, knot.lerp(sack_top, 0.5), sack_top], 7.0, CLOTH)
	var sq := 1.0 - 0.28 * squash
	var rx := 54.0 * (1.0 + 0.18 * squash)
	var ry := 50.0 * sq
	if bundle_state < 0.5:
		# huevito asomando
		if show_egg:
			_ell(sack_c + Vector2(0, -40.0 * sq), 25, 32, egg_color_a, sway)
			for d in [Vector2(-8, -48), Vector2(8, -38), Vector2(-2, -28)]:
				draw_circle(sack_c + Vector2(d.x, d.y * sq), 4.0, Color("e9b88a"))
		_ell(sack_c, rx, ry, CLOTH)
		for d in [Vector2(-26, -8), Vector2(10, -20), Vector2(28, 8), Vector2(-8, 18)]:
			draw_circle(sack_c + d * Vector2(1.0, sq), 6.0, WHITE)
		_poly([sack_c + Vector2(-20, -ry + 6), sack_c + Vector2(-34, -ry - 18), sack_c + Vector2(-4, -ry + 2)], CLOTH, true, 4.0)
		_poly([sack_c + Vector2(20, -ry + 6), sack_c + Vector2(34, -ry - 18), sack_c + Vector2(4, -ry + 2)], CLOTH, true, 4.0)
	else:
		# paño vacio, colgando flojito
		var drape: PackedVector2Array = _smooth([Vector2(-7, 0), Vector2(-36, 36), Vector2(-32, 72), Vector2(0, 88), Vector2(32, 72), Vector2(36, 36), Vector2(7, 0)])
		var pts := PackedVector2Array()
		for p in drape:
			pts.append(sack_top + p.rotated(sway))
		draw_colored_polygon(pts, CLOTH)
		pts.append(pts[0])
		draw_polyline(pts, OUT, 4.5, true)
		for d in [Vector2(-14, 40), Vector2(14, 34), Vector2(0, 64)]:
			draw_circle(sack_top + d.rotated(sway), 5.5, WHITE)
