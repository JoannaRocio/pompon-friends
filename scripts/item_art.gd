class_name ItemArt
extends RefCounted
## Dibujo por codigo de muebles, decoracion, paredes y pisos. Lo usan el cuarto (RoomView)
## y las miniaturas de la tienda (ItemIcon). Todas las funciones reciben el CanvasItem donde dibujar.

const OUTLINE := Color("5b3a4a")
const DEFAULT_WALL := Color("fff1d6")
const DEFAULT_FLOOR := Color("f2d3a4")
const STAR_COLORS := [Color("d9c8f5"), Color("ffd2b8"), Color("bfe8d8"), Color("ffc4dc"), Color("bfe0f5")]
const BOOK_COLORS := [Color("e76f51"), Color("f4a261"), Color("8ecae6"), Color("90be6d"), Color("b388f5"), Color("ffd166")]

# El cuarto actualiza estos valores segun la hora real antes de dibujar la ventana.
static var sky := Color("bfe3f5")
static var night_amount := 0.0

const DEFAULT_SIZE := Vector2(170, 135)
const SIZES := {
	"furn_sofa": Vector2(220, 130), "furn_plant": Vector2(100, 150), "furn_bookshelf": Vector2(150, 190),
	"furn_table": Vector2(170, 120), "furn_lamp": Vector2(80, 190), "furn_fireplace": Vector2(200, 170),
	"furn_toybox": Vector2(140, 110), "furn_crib": Vector2(200, 150),
	"deco_window": Vector2(150, 170), "deco_picture": Vector2(110, 130), "deco_clock": Vector2(100, 100),
	"deco_shelf": Vector2(170, 90), "deco_garland": Vector2(260, 80), "deco_moon": Vector2(120, 120),
	"furn_teddy": Vector2(110, 130), "furn_beanbag": Vector2(160, 110), "furn_globe": Vector2(110, 150),
	"furn_aquarium": Vector2(190, 140), "furn_piano": Vector2(200, 170),
	"deco_rainbow": Vector2(210, 110), "deco_balloons": Vector2(150, 190),
	"furn_dresser": Vector2(200, 150), "furn_desk": Vector2(230, 150), "furn_wardrobe": Vector2(150, 230),
	"furn_stool": Vector2(90, 80), "deco_shelf_long": Vector2(280, 90), "deco_shelf_cloud": Vector2(220, 100),
	"toy_blocks": Vector2(90, 80), "toy_books": Vector2(100, 62), "toy_vase": Vector2(70, 110),
	"toy_cactus": Vector2(70, 100), "toy_cake": Vector2(90, 90), "toy_frame": Vector2(80, 90),
	"toy_musicbox": Vector2(90, 80), "toy_robot": Vector2(80, 110), "toy_trophy": Vector2(70, 100),
	"furn_bed_cloud": Vector2(230, 150),
}


static func size_of(id: String) -> Vector2:
	if PixelArt.is_art(id):
		return Vector2(120, 132)
	return SIZES.get(id, SIZES.get(Catalog.shape_of(id), DEFAULT_SIZE))


## Chispitas que titilan alrededor de un item especial (`t` = tiempo en segundos).
static func draw_shine(cv: CanvasItem, rect: Rect2, t: float) -> void:
	for i in 5:
		var k := fmod(t * 0.55 + i * 0.37, 1.0)
		var a := sin(k * PI)
		var p := rect.position + Vector2(fmod(i * 0.61 + 0.13, 1.0) * rect.size.x, fmod(i * 0.43 + 0.21, 1.0) * rect.size.y * 0.8)
		var r := (5.0 + 7.0 * a) * clampf(rect.size.x / 160.0, 0.5, 1.2)
		var col := Color(1.0, 0.78, 0.2, a)   # dorado (se ve sobre fondos claros y oscuros)
		cv.draw_line(p - Vector2(r, 0), p + Vector2(r, 0), col, 3.0, true)
		cv.draw_line(p - Vector2(0, r), p + Vector2(0, r), col, 3.0, true)
		cv.draw_circle(p, r * 0.32, Color(1, 1, 1, a))


const REF_ROOM := Vector2(720, 1280)   # cuarto de referencia para calcular choques entre items


## De entre `spots` (fracciones del cuarto) devuelve el primero donde `id` no se monta sobre
## ningun item de `placed` (lista de {"id","x","y"}); si todos chocan, el de menor choque.
static func best_spot(id: String, spots: Array, placed: Array, ref := REF_ROOM) -> Vector2:
	var item_size := size_of(id)
	var best: Vector2 = spots[0]
	var best_overlap := INF
	for s in spots:
		var r := Rect2(s * ref - item_size * 0.5, item_size)
		var overlap := 0.0
		for p in placed:
			var other := size_of(p["id"])
			overlap += r.intersection(Rect2(Vector2(p["x"], p["y"]) * ref - other * 0.5, other)).get_area()
		if overlap < best_overlap:
			best = s
			best_overlap = overlap
		if overlap <= 0.0:
			break
	return best


# ------------------------------------------------------------------ helpers

static func _ellipse(cv: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, outline := true, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry).rotated(rot) + c)
	cv.draw_colored_polygon(pts, fill)
	if outline:
		pts.append(pts[0])
		cv.draw_polyline(pts, OUTLINE, 4.0, true)


static func _round(cv: CanvasItem, rect: Rect2, fill: Color, radius := 18) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = OUTLINE
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(radius)
	cv.draw_style_box(sb, rect)


static func _poly(cv: CanvasItem, points: Array, fill: Color, outline := true) -> void:
	var pts := PackedVector2Array(points)
	cv.draw_colored_polygon(pts, fill)
	if outline:
		pts.append(pts[0])
		cv.draw_polyline(pts, OUTLINE, 4.0, true)


static func _star(cv: CanvasItem, c: Vector2, r: float, color: Color, points := 5) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var rr := r if i % 2 == 0 else r * 0.45
		var a := -PI / 2.0 + PI * i / points
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	cv.draw_colored_polygon(pts, color)


# ------------------------------------------------------- pared y piso

static func draw_wall(cv: CanvasItem, rect: Rect2, id: String, k := 1.0) -> void:
	var wc: Color = Catalog.color_of(id) if id != "" else DEFAULT_WALL
	var pattern: String = Catalog.get_item(id).get("pattern", "stars") if id != "" else "stars"
	cv.draw_rect(rect, wc)
	var end := rect.end
	match pattern:
		"stars":
			var step := 120.0 * k
			var row := 0
			var y := rect.position.y + 60.0 * k
			while y < end.y - 20.0 * k:
				var x := rect.position.x + 60.0 * k + (step * 0.5 if row % 2 == 1 else 0.0)
				var i := 0
				while x < end.x - 6.0 * k:
					var col: Color = STAR_COLORS[(i + row * 2) % STAR_COLORS.size()]
					col.a = 0.7
					_star(cv, Vector2(x, y), 18.0 * k, col)
					x += step
					i += 1
				y += 100.0 * k
				row += 1
		"dots":
			var step2 := 64.0 * k
			var row2 := 0
			var y2 := rect.position.y + 40.0 * k
			while y2 < end.y - 10.0 * k:
				var x2 := rect.position.x + 32.0 * k + (step2 * 0.5 if row2 % 2 == 1 else 0.0)
				while x2 < end.x - 4.0 * k:
					cv.draw_circle(Vector2(x2, y2), 8.0 * k, wc.darkened(0.08))
					x2 += step2
				y2 += 56.0 * k
				row2 += 1
		"clouds":
			var cy := rect.position.y + 70.0 * k
			var crow := 0
			while cy < end.y - 20.0 * k:
				var cx := rect.position.x + (80.0 if crow % 2 == 0 else 190.0) * k
				while cx < end.x:
					for part in [[-26, 6, 20], [0, -6, 28], [28, 6, 22], [0, 8, 24]]:
						cv.draw_circle(Vector2(cx + part[0] * k, cy + part[1] * k), part[2] * k, Color(1, 1, 1, 0.85))
					cx += 230.0 * k
				cy += 130.0 * k
				crow += 1
		"hearts":
			var hy := rect.position.y + 50.0 * k
			var hrow := 0
			while hy < end.y - 10.0 * k:
				var hx := rect.position.x + (50.0 if hrow % 2 == 0 else 110.0) * k
				while hx < end.x:
					var hp := PackedVector2Array()
					for i in 24:
						var ang := TAU * i / 24.0
						hp.append(Vector2(hx, hy) + Vector2(16.0 * pow(sin(ang), 3.0), -(13.0 * cos(ang) - 5.0 * cos(2.0 * ang) - 2.0 * cos(3.0 * ang) - cos(4.0 * ang))) * 0.9 * k)
					cv.draw_colored_polygon(hp, Color(1.0, 0.62, 0.74, 0.7))
					hx += 120.0 * k
				hy += 90.0 * k
				hrow += 1
		"space":
			for i in 38:
				var sx := rect.position.x + fmod(float(i) * 97.0, rect.size.x)
				var sy := rect.position.y + fmod(float(i) * 61.0 + float(i * i) * 7.0, rect.size.y)
				cv.draw_circle(Vector2(sx, sy), (2.5 + float(i % 3)) * k, Color(1, 1, 0.85, 0.85))
			cv.draw_circle(rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.3), 46.0 * k, Color("ff9b54"))
			cv.draw_arc(rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.3), 66.0 * k, 3.6, 6.1, 20, Color("ffd9a0"), 6.0 * k, true)
			cv.draw_circle(rect.position + Vector2(rect.size.x * 0.2, rect.size.y * 0.68), 26.0 * k, Color("8fd1ff"))
			cv.draw_circle(rect.position + Vector2(rect.size.x * 0.2 - 8.0 * k, rect.size.y * 0.68 - 8.0 * k), 8.0 * k, Color(1, 1, 1, 0.5))
		"rainbow":  # bandas suaves de colores y nubecitas
			var bands := [Color("ffd6d6"), Color("ffe6c7"), Color("fff6c2"), Color("d8f5d0"), Color("d4ecff"), Color("e6dcff")]
			var bh := rect.size.y / bands.size()
			for i in bands.size():
				cv.draw_rect(Rect2(rect.position.x, rect.position.y + i * bh, rect.size.x, bh + 1.0), bands[i])
			var ccx := rect.position.x + 110.0 * k
			while ccx < end.x:
				for part in [[-22, 4, 18], [0, -4, 24], [24, 4, 18]]:
					cv.draw_circle(Vector2(ccx + part[0] * k, rect.position.y + rect.size.y * 0.3 + part[1] * k), part[2] * k, Color(1, 1, 1, 0.8))
				ccx += 300.0 * k
		"stripes":
			var w := 56.0 * k
			var x3 := rect.position.x
			var n := 0
			while x3 < end.x:
				if n % 2 == 1:
					cv.draw_rect(Rect2(x3, rect.position.y, minf(w, end.x - x3), rect.size.y), wc.darkened(0.05))
				x3 += w
				n += 1


static func draw_floor(cv: CanvasItem, rect: Rect2, id: String, k := 1.0) -> void:
	var fc: Color = Catalog.color_of(id) if id != "" else DEFAULT_FLOOR
	var pattern: String = Catalog.get_item(id).get("pattern", "planks") if id != "" else "planks"
	cv.draw_rect(rect, fc)
	var seam := fc.darkened(0.12)
	var end := rect.end
	if pattern == "checker":
		var s := 90.0 * k
		var row := 0
		var y := rect.position.y
		while y < end.y:
			var x := rect.position.x
			var n := row % 2
			while x < end.x:
				if n % 2 == 0:
					cv.draw_rect(Rect2(x, y, minf(s, end.x - x), minf(s, end.y - y)), fc.darkened(0.07))
				x += s
				n += 1
			y += s
			row += 1
		return
	if pattern == "grass":
		var gy := rect.position.y + 24.0 * k
		var grow := 0
		while gy < end.y:
			var gx := rect.position.x + (10.0 if grow % 2 == 0 else 34.0) * k
			while gx < end.x:
				var gc := fc.darkened(0.18)
				cv.draw_line(Vector2(gx, gy), Vector2(gx - 6.0 * k, gy - 14.0 * k), gc, maxf(1.5, 3.0 * k))
				cv.draw_line(Vector2(gx, gy), Vector2(gx + 7.0 * k, gy - 12.0 * k), gc, maxf(1.5, 3.0 * k))
				cv.draw_line(Vector2(gx, gy), Vector2(gx, gy - 17.0 * k), gc, maxf(1.5, 3.0 * k))
				gx += 68.0 * k
			gy += 44.0 * k
			grow += 1
		return
	if pattern == "carpet":
		var inset := 14.0 * k
		cv.draw_rect(Rect2(rect.position + Vector2(inset, inset), rect.size - Vector2(inset, inset) * 2.0), fc.lightened(0.18), false, maxf(2.0, 5.0 * k))
		var dx := rect.position.x + 40.0 * k
		while dx < end.x - 20.0 * k:
			var dy := rect.position.y + 40.0 * k
			while dy < end.y - 20.0 * k:
				cv.draw_circle(Vector2(dx, dy), 6.0 * k, fc.darkened(0.08))
				dy += 56.0 * k
			dx += 56.0 * k
		return
	var ry := rect.position.y + 70.0 * k
	var r := 0
	while ry < end.y:
		cv.draw_line(Vector2(rect.position.x, ry), Vector2(end.x, ry), seam, maxf(1.0, 2.0 * k))
		var sx := rect.position.x + (90.0 if r % 2 == 0 else 20.0) * k
		var next := ry + (70.0 + r * 18.0) * k
		while sx < end.x:
			cv.draw_line(Vector2(sx, ry), Vector2(sx - r * 6.0 * k, minf(next, end.y)), seam, maxf(1.0, 2.0 * k))
			sx += (190.0 + r * 30.0) * k
		ry = next
		r += 1


# ------------------------------------------------------- muebles y deco

## Dibuja el item `id` centrado en `center` (tamano fijo de size_of(id)).
static func draw_item(cv: CanvasItem, id: String, center: Vector2) -> void:
	var size := size_of(id)
	var r := Rect2(center - size * 0.5, size)
	if PixelArt.is_art(id):
		PixelArt.draw_framed(cv, id, r)
		return
	var col := Catalog.color_of(id)
	var light := col.lightened(0.35)
	var dark := col.darkened(0.25)
	var pos := r.position
	var c := r.get_center()
	match Catalog.shape_of(id):
		"furn_bed_cloud":  # cama de nube: colchon de nubes, almohada y mantita con estrellas
			for part in [[-78, 30, 42], [-30, 18, 50], [26, 20, 48], [76, 32, 40], [0, 44, 56]]:
				_ellipse(cv, c + Vector2(part[0], part[1]), part[2], part[2] * 0.75, col.darkened(0.06))
			for part in [[-78, 24, 36], [-30, 12, 44], [26, 14, 42], [76, 26, 34], [0, 36, 50]]:
				_ellipse(cv, c + Vector2(part[0], part[1]), part[2], part[2] * 0.72, Color.WHITE, false)
			_ellipse(cv, c + Vector2(-62, -6), 34.0, 20.0, Color("fff8fb"))
			_round(cv, Rect2(c + Vector2(-34, -2), Vector2(122, 40)), Color("c8b8f5"), 18)
			for sp in [Vector2(-12, 16), Vector2(28, 10), Vector2(64, 20)]:
				_star(cv, c + sp, 7.0, Color("fff3a0"))
			_star(cv, c + Vector2(90, -38), 12.0, Color("ffe066"))
		"furn_bed":
			_round(cv, Rect2(pos + Vector2(0, 50), Vector2(r.size.x, 80)), dark, 22)
			_round(cv, Rect2(pos + Vector2(8, 28), Vector2(r.size.x - 16, 70)), col, 22)
			_round(cv, Rect2(pos + Vector2(16, 20), Vector2(52, 36)), Color("fff1d6"), 16)
			cv.draw_line(pos + Vector2(90, 40), pos + Vector2(90, 96), light, 5.0)
			cv.draw_line(pos + Vector2(116, 40), pos + Vector2(116, 96), light, 5.0)
		"furn_scratcher":
			_round(cv, Rect2(pos + Vector2(20, 112), Vector2(r.size.x - 40, 22)), dark, 12)
			_round(cv, Rect2(c + Vector2(-14, -50), Vector2(28, 166)), Color("e2c79a"), 6)
			for yy in range(-30, 100, 20):
				cv.draw_line(c + Vector2(-14, yy), c + Vector2(14, yy + 8), OUTLINE, 2.0)
			_round(cv, Rect2(c + Vector2(-56, -66), Vector2(112, 24)), col, 12)
		"furn_tunnel":
			var pts := PackedVector2Array()
			for i in 25:
				var a := PI + PI * i / 24.0
				pts.append(Vector2(c.x + cos(a) * 78.0, r.end.y - 14.0 + sin(a) * 100.0))
			cv.draw_colored_polygon(pts, col)
			pts.append(pts[0])
			cv.draw_polyline(pts, OUTLINE, 4.0, true)
			_ellipse(cv, Vector2(c.x, r.end.y - 16.0), 44.0, 52.0, Color("3d2a2a"), false)
			for kx in [-44.0, 0.0, 44.0]:
				cv.draw_line(Vector2(c.x + kx, r.end.y - 100.0 + absf(kx) * 0.4), Vector2(c.x + kx * 1.6, r.end.y - 30.0), dark, 3.0)
		"furn_swing":
			cv.draw_line(c + Vector2(-70, 60), c + Vector2(0, -62), OUTLINE, 9.0, true)
			cv.draw_line(c + Vector2(70, 60), c + Vector2(0, -62), OUTLINE, 9.0, true)
			cv.draw_line(c + Vector2(-70, 60), c + Vector2(0, -62), col, 5.0, true)
			cv.draw_line(c + Vector2(70, 60), c + Vector2(0, -62), col, 5.0, true)
			cv.draw_line(c + Vector2(-20, -40), c + Vector2(-20, 20), OUTLINE, 3.0)
			cv.draw_line(c + Vector2(20, -40), c + Vector2(20, 20), OUTLINE, 3.0)
			_round(cv, Rect2(c + Vector2(-34, 20), Vector2(68, 14)), light, 7)
		"furn_wheel":
			_round(cv, Rect2(c + Vector2(-40, 38), Vector2(80, 22)), dark, 10)
			_ellipse(cv, c + Vector2(0, -22), 56.0, 56.0, light, false)
			cv.draw_arc(c + Vector2(0, -22), 56.0, 0.0, TAU, 40, OUTLINE, 6.0, true)
			for kk in 6:
				var a2 := TAU * kk / 6.0
				cv.draw_line(c + Vector2(0, -22), c + Vector2(0, -22) + Vector2(cos(a2), sin(a2)) * 52.0, col, 3.0, true)
			cv.draw_circle(c + Vector2(0, -22), 8.0, OUTLINE)
		"furn_cushion":
			_round(cv, Rect2(pos + Vector2(10, 30), Vector2(r.size.x - 20, 84)), col, 28)
			cv.draw_circle(c + Vector2(0, -8), 8.0, light)
			for p in [Vector2(10, 30), Vector2(r.size.x - 10, 30), Vector2(10, 114), Vector2(r.size.x - 10, 114)]:
				cv.draw_circle(pos + p, 9.0, Color("ffd9a0"))
				cv.draw_arc(pos + p, 9.0, 0.0, TAU, 12, OUTLINE, 2.0)
		"furn_heat":
			cv.draw_circle(c + Vector2(20, -20), 62.0, Color(1.0, 0.8, 0.4, 0.22))
			_round(cv, Rect2(c + Vector2(-34, 52), Vector2(68, 14)), dark, 7)
			cv.draw_line(c + Vector2(0, 52), c + Vector2(0, -42), OUTLINE, 9.0)
			cv.draw_line(c + Vector2(0, 52), c + Vector2(0, -42), col.darkened(0.1), 5.0)
			_poly(cv, [c + Vector2(-8, -60), c + Vector2(48, -60), c + Vector2(66, -22), c + Vector2(-26, -22)], col)
			cv.draw_circle(c + Vector2(20, -12), 9.0, Color("fff3b0"))
		"furn_crib":  # cuna con barrotes, manta y osito
			var wood := Color("d8a56f")
			for lx in [16.0, r.size.x - 16.0]:
				cv.draw_line(pos + Vector2(lx, 114), pos + Vector2(lx, 146), OUTLINE, 11.0, true)
				cv.draw_line(pos + Vector2(lx, 114), pos + Vector2(lx, 146), wood.darkened(0.15), 6.0, true)
			_round(cv, Rect2(pos + Vector2(8, 80), Vector2(r.size.x - 16, 42)), Color("fff1f5"), 14)
			_round(cv, Rect2(pos + Vector2(40, 66), Vector2(r.size.x - 56, 38)), col, 16)
			for sx in [0.0, 1.0]:  # franjas de la manta
				cv.draw_line(pos + Vector2(58 + sx * 40.0, 72), pos + Vector2(58 + sx * 40.0, 100), light, 5.0, true)
			_ellipse(cv, pos + Vector2(30, 64), 17.0, 16.0, Color("e6b88a"))  # osito
			_ellipse(cv, pos + Vector2(18, 50), 7.0, 7.0, Color("e6b88a"))
			_ellipse(cv, pos + Vector2(42, 50), 7.0, 7.0, Color("e6b88a"))
			cv.draw_circle(pos + Vector2(26, 62), 2.2, OUTLINE)
			cv.draw_circle(pos + Vector2(35, 62), 2.2, OUTLINE)
			for i in 9:
				var bx := 24.0 + i * ((r.size.x - 48.0) / 8.0)
				cv.draw_line(pos + Vector2(bx, 26), pos + Vector2(bx, 100), OUTLINE, 8.0, true)
				cv.draw_line(pos + Vector2(bx, 26), pos + Vector2(bx, 100), wood, 4.0, true)
			_round(cv, Rect2(pos + Vector2(6, 16), Vector2(r.size.x - 12, 16)), wood, 8)
			_round(cv, Rect2(pos + Vector2(6, 96), Vector2(r.size.x - 12, 14)), wood, 7)
			_round(cv, Rect2(pos + Vector2(0, 2), Vector2(20, 124)), wood.darkened(0.08), 9)
			_round(cv, Rect2(pos + Vector2(r.size.x - 20, 2), Vector2(20, 124)), wood.darkened(0.08), 9)
		"furn_sofa":
			_round(cv, Rect2(pos + Vector2(14, 6), Vector2(r.size.x - 28, 70)), dark, 28)
			_round(cv, Rect2(pos + Vector2(0, 40), Vector2(r.size.x, 64)), col, 26)
			_round(cv, Rect2(pos + Vector2(-4, 32), Vector2(42, 84)), dark, 20)
			_round(cv, Rect2(pos + Vector2(r.size.x - 38, 32), Vector2(42, 84)), dark, 20)
			_round(cv, Rect2(pos + Vector2(50, 24), Vector2(54, 44)), light, 16)
			_round(cv, Rect2(pos + Vector2(116, 24), Vector2(54, 44)), light.lightened(0.1), 16)
			_round(cv, Rect2(pos + Vector2(16, 110), Vector2(24, 16)), OUTLINE, 6)
			_round(cv, Rect2(pos + Vector2(r.size.x - 40, 110), Vector2(24, 16)), OUTLINE, 6)
		"furn_plant":
			var green := Color("6bbf7a")
			for leaf in [[Vector2(50, 62), 14.0, 46.0, 0.0], [Vector2(30, 80), 12.0, 38.0, -0.7], [Vector2(70, 80), 12.0, 38.0, 0.7],
					[Vector2(38, 50), 12.0, 36.0, -0.35], [Vector2(62, 50), 12.0, 36.0, 0.35]]:
				_ellipse(cv, pos + leaf[0], leaf[1], leaf[2], green.darkened(0.06 * (int(leaf[3] * 10.0) % 3)), true, leaf[3])
			_poly(cv, [pos + Vector2(22, 104), pos + Vector2(78, 104), pos + Vector2(70, 148), pos + Vector2(30, 148)], Color("e0885c"))
			cv.draw_rect(Rect2(pos + Vector2(18, 98), Vector2(64, 12)), Color("e9996d"))
			cv.draw_rect(Rect2(pos + Vector2(18, 98), Vector2(64, 12)), OUTLINE, false, 4.0)
		"furn_bookshelf":
			_round(cv, Rect2(pos, r.size), col.darkened(0.1), 12)
			cv.draw_rect(Rect2(pos + Vector2(10, 10), r.size - Vector2(20, 20)), col.lightened(0.15))
			for row in 3:
				var top := 12.0 + row * 60.0
				var x := 14.0
				var n := 0
				while x < r.size.x - 34.0:
					var w := 12.0 + float((n * 7 + row * 3) % 4) * 3.0
					var h := 36.0 + float((n * 5 + row * 2) % 3) * 6.0
					cv.draw_rect(Rect2(pos + Vector2(x, top + 48.0 - h), Vector2(w, h)), BOOK_COLORS[(n + row) % BOOK_COLORS.size()])
					cv.draw_rect(Rect2(pos + Vector2(x, top + 48.0 - h), Vector2(w, h)), OUTLINE, false, 2.0)
					x += w + 3.0
					n += 1
				cv.draw_rect(Rect2(pos + Vector2(8, top + 48.0), Vector2(r.size.x - 16, 8)), col.darkened(0.2))
		"furn_table":
			for lx in [-52.0, 0.0, 52.0]:
				cv.draw_line(c + Vector2(lx, 6), c + Vector2(lx * 1.25, 52), OUTLINE, 10.0, true)
				cv.draw_line(c + Vector2(lx, 6), c + Vector2(lx * 1.25, 52), dark, 5.0, true)
			_ellipse(cv, c + Vector2(0, 0), 78.0, 22.0, col)
			_ellipse(cv, c + Vector2(-20, -18), 18.0, 14.0, Color("fff1f5"))
			_poly(cv, [c + Vector2(-4, -22), c + Vector2(10, -34), c + Vector2(8, -20)], Color("fff1f5"))
			cv.draw_circle(c + Vector2(-20, -34), 5.0, Color("ff9ecb"))
			_ellipse(cv, c + Vector2(30, -8), 11.0, 8.0, Color("fff1f5"))
		"furn_lamp":
			cv.draw_circle(c + Vector2(0, -50), 58.0, Color(1.0, 0.85, 0.5, 0.2))
			_ellipse(cv, Vector2(c.x, r.end.y - 10.0), 30.0, 9.0, dark)
			cv.draw_line(Vector2(c.x, r.end.y - 12.0), Vector2(c.x, pos.y + 70.0), OUTLINE, 9.0)
			cv.draw_line(Vector2(c.x, r.end.y - 12.0), Vector2(c.x, pos.y + 70.0), dark, 5.0)
			_poly(cv, [Vector2(c.x - 22, pos.y + 14), Vector2(c.x + 22, pos.y + 14), Vector2(c.x + 36, pos.y + 74), Vector2(c.x - 36, pos.y + 74)], col)
		"furn_fireplace":
			_round(cv, Rect2(pos + Vector2(0, 30), Vector2(r.size.x, r.size.y - 30)), col, 10)
			for by in range(44, 160, 22):
				cv.draw_line(pos + Vector2(4, by), pos + Vector2(r.size.x - 4, by), col.darkened(0.2), 2.0)
			_round(cv, Rect2(pos + Vector2(-8, 8), Vector2(r.size.x + 16, 26)), col.lightened(0.15), 8)
			var fire := Rect2(pos + Vector2(46, 70), Vector2(108, 96))
			_round(cv, fire, Color("3d2a2a"), 40)
			_poly(cv, [pos + Vector2(100, 90), pos + Vector2(126, 126), pos + Vector2(118, 160), pos + Vector2(82, 160), pos + Vector2(74, 126)], Color("ff8a3d"), false)
			_poly(cv, [pos + Vector2(100, 112), pos + Vector2(114, 138), pos + Vector2(108, 160), pos + Vector2(92, 160), pos + Vector2(86, 138)], Color("ffd23d"), false)
			_round(cv, Rect2(pos + Vector2(62, 152), Vector2(76, 12)), Color("8a5a3c"), 6)
		"furn_toybox":
			for blk in [[Vector2(36, 12), Color("ff8fb1")], [Vector2(70, 4), Color("8ecae6")], [Vector2(98, 14), Color("ffd166")]]:
				cv.draw_rect(Rect2(pos + blk[0], Vector2(26, 26)), blk[1])
				cv.draw_rect(Rect2(pos + blk[0], Vector2(26, 26)), OUTLINE, false, 3.0)
			_star(cv, pos + Vector2(70, 0), 12.0, Color("ffd33d"))
			_round(cv, Rect2(pos + Vector2(0, 34), Vector2(r.size.x, 76)), col, 14)
			_round(cv, Rect2(pos + Vector2(-6, 28), Vector2(r.size.x + 12, 22)), col.lightened(0.2), 10)
			_star(cv, c + Vector2(0, 26), 14.0, Color("fff1d6"))
		"deco_window":
			var curtain := col if Catalog.is_special(id) else Color("ffb3c8")   # la ventana magica tiene cortinas de su color
			_poly(cv, [pos + Vector2(0, 0), pos + Vector2(44, 0), pos + Vector2(36, 150), pos + Vector2(0, 150)], curtain)
			_poly(cv, [pos + Vector2(r.size.x, 0), pos + Vector2(r.size.x - 44, 0), pos + Vector2(r.size.x - 36, 150), pos + Vector2(r.size.x, 150)], curtain)
			_round(cv, Rect2(pos + Vector2(26, 8), Vector2(98, 134)), Color("fff6e6"), 10)
			for px in 2:
				for py in 2:
					var pane := Rect2(pos + Vector2(34 + px * 44, 16 + py * 60), Vector2(40, 54))
					cv.draw_rect(pane, sky)
					if night_amount > 0.4:
						_star(cv, pane.position + Vector2(12 + py * 8, 14), 5.0, Color(1, 0.97, 0.75, night_amount))
						_star(cv, pane.position + Vector2(30, 36 - px * 6), 4.0, Color(1, 0.97, 0.75, night_amount))
					else:
						cv.draw_line(pane.position + Vector2(8, 40), pane.position + Vector2(20, 14), Color(1, 1, 1, 0.6), 4.0)
			_round(cv, Rect2(pos + Vector2(18, 142), Vector2(114, 14)), Color("e9d3b4"), 6)
		"deco_picture":
			_round(cv, Rect2(pos, r.size), Color("e8b04a"), 8)
			var canvas := Rect2(pos + Vector2(12, 12), r.size - Vector2(24, 24))
			cv.draw_rect(canvas, Color("bfe3f5"))
			cv.draw_circle(canvas.position + Vector2(66, 26), 12.0, Color("ffe066"))
			_ellipse(cv, canvas.position + Vector2(24, 96), 62.0, 34.0, Color("8fd19e"), false)
			_ellipse(cv, canvas.position + Vector2(78, 108), 50.0, 30.0, Color("6bbf7a"), false)
			cv.draw_rect(canvas, OUTLINE, false, 3.0)
		"deco_clock":
			_ellipse(cv, c, 46.0, 46.0, Color("fff6e6"))
			for h in 12:
				var a3 := TAU * h / 12.0
				cv.draw_line(c + Vector2(sin(a3), -cos(a3)) * 36.0, c + Vector2(sin(a3), -cos(a3)) * 42.0, OUTLINE, 3.0)
			cv.draw_line(c, c + Vector2(sin(TAU * 10.0 / 12.0), -cos(TAU * 10.0 / 12.0)) * 22.0, OUTLINE, 5.0, true)
			cv.draw_line(c, c + Vector2(sin(TAU * 2.0 / 12.0), -cos(TAU * 2.0 / 12.0)) * 32.0, OUTLINE, 3.0, true)
			cv.draw_circle(c, 5.0, Color("ff7aa0"))
		"deco_shelf":
			_poly(cv, [pos + Vector2(20, 64), pos + Vector2(44, 64), pos + Vector2(20, 88)], dark)
			_poly(cv, [pos + Vector2(r.size.x - 20, 64), pos + Vector2(r.size.x - 44, 64), pos + Vector2(r.size.x - 20, 88)], dark)
			_round(cv, Rect2(pos + Vector2(0, 48), Vector2(r.size.x, 18)), col, 8)
			_poly(cv, [pos + Vector2(14, 48), pos + Vector2(46, 48), pos + Vector2(40, 22), pos + Vector2(20, 22)], Color("e0885c"))
			_ellipse(cv, pos + Vector2(30, 14), 20.0, 14.0, Color("6bbf7a"))
			for i in 3:
				cv.draw_rect(Rect2(pos + Vector2(70, 48 - 12 * (i + 1)), Vector2(48, 12)), BOOK_COLORS[(i * 2) % BOOK_COLORS.size()])
				cv.draw_rect(Rect2(pos + Vector2(70, 48 - 12 * (i + 1)), Vector2(48, 12)), OUTLINE, false, 2.0)
			_round(cv, Rect2(pos + Vector2(132, 24), Vector2(24, 24)), Color("fff1f5"), 6)
		"deco_garland":
			var pts2 := PackedVector2Array()
			for i in 41:
				var t := float(i) / 40.0
				pts2.append(pos + Vector2(t * r.size.x, 10.0 + sin(t * PI) * 36.0))
			cv.draw_polyline(pts2, OUTLINE, 3.0, true)
			var flag_colors := [Color("ff9ecb"), Color("ffd166"), Color("8ecae6"), Color("90be6d"), Color("b388f5")]
			for i in range(1, 10):
				var t2 := float(i) / 10.0
				var p := pos + Vector2(t2 * r.size.x, 10.0 + sin(t2 * PI) * 36.0)
				_poly(cv, [p + Vector2(-13, 0), p + Vector2(13, 0), p + Vector2(0, 28)], flag_colors[i % flag_colors.size()])
		"deco_moon":
			var outer := []
			for a in range(95, 266, 10):
				outer.append(c + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 46.0 + Vector2(-6, 0))
			var d := c + Vector2(24, 0)
			for a in range(233, 126, -10):
				outer.append(d + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 57.0)
			_poly(cv, outer, Color("ffe08a"))
			_star(cv, c + Vector2(34, -26), 10.0, Color("ffe08a"))
			_star(cv, c + Vector2(44, 20), 7.0, Color("ffe08a"))
		"furn_teddy":
			var fur := col
			_ellipse(cv, pos + Vector2(26, 98), 18.0, 14.0, fur.darkened(0.08))
			_ellipse(cv, pos + Vector2(84, 98), 18.0, 14.0, fur.darkened(0.08))
			_ellipse(cv, c + Vector2(0, 24), 40.0, 44.0, fur)
			_ellipse(cv, c + Vector2(0, 30), 24.0, 28.0, fur.lightened(0.3), false)
			_ellipse(cv, pos + Vector2(14, 66), 13.0, 22.0, fur, true, 0.5)
			_ellipse(cv, pos + Vector2(96, 66), 13.0, 22.0, fur, true, -0.5)
			for ex in [-30.0, 30.0]:
				_ellipse(cv, c + Vector2(ex, -34), 14.0, 14.0, fur)
			_ellipse(cv, c + Vector2(0, -14), 38.0, 34.0, fur)
			_ellipse(cv, c + Vector2(0, -4), 18.0, 13.0, fur.lightened(0.35), false)
			cv.draw_circle(c + Vector2(-14, -20), 3.5, OUTLINE)
			cv.draw_circle(c + Vector2(14, -20), 3.5, OUTLINE)
			_ellipse(cv, c + Vector2(0, -8), 5.0, 4.0, OUTLINE, false)
			_poly(cv, [c + Vector2(-16, 12), c + Vector2(0, 20), c + Vector2(-16, 28)], Color("ff6b8b"))
			_poly(cv, [c + Vector2(16, 12), c + Vector2(0, 20), c + Vector2(16, 28)], Color("ff6b8b"))
		"furn_beanbag":
			_ellipse(cv, Vector2(c.x, r.end.y - 12.0), 76.0, 12.0, Color(0, 0, 0, 0.12), false)
			_ellipse(cv, Vector2(c.x + 12.0, r.end.y - 70.0), 48.0, 32.0, col, true, 0.25)
			_ellipse(cv, Vector2(c.x, r.end.y - 42.0), 78.0, 42.0, col)
			cv.draw_arc(Vector2(c.x - 6.0, r.end.y - 44.0), 50.0, 0.4, 2.7, 14, col.darkened(0.22), 3.0, true)
			cv.draw_arc(Vector2(c.x + 30.0, r.end.y - 50.0), 34.0, 0.2, 2.2, 12, col.darkened(0.22), 3.0, true)
			_ellipse(cv, Vector2(c.x - 24.0, r.end.y - 56.0), 20.0, 8.0, Color(1, 1, 1, 0.45), false, -0.5)
		"furn_globe":
			_ellipse(cv, Vector2(c.x, r.end.y - 10.0), 34.0, 9.0, dark)
			cv.draw_line(Vector2(c.x, r.end.y - 12.0), Vector2(c.x, r.end.y - 44.0), OUTLINE, 9.0)
			cv.draw_line(Vector2(c.x, r.end.y - 12.0), Vector2(c.x, r.end.y - 44.0), Color("d8a56f"), 5.0)
			var gc := Vector2(c.x, pos.y + 56.0)
			_ellipse(cv, gc, 46.0, 46.0, col)
			_ellipse(cv, gc + Vector2(-14, -10), 16.0, 12.0, Color("7bd389"), false, 0.4)
			_ellipse(cv, gc + Vector2(16, 12), 14.0, 18.0, Color("7bd389"), false, -0.3)
			cv.draw_arc(gc, 46.0, 0.0, TAU, 36, OUTLINE, 4.0, true)
			cv.draw_arc(gc, 58.0, 2.2, 5.2, 24, Color("d8a56f"), 5.0, true)
			_ellipse(cv, gc + Vector2(-16, -18), 8.0, 5.0, Color(1, 1, 1, 0.5), false, -0.6)
		"furn_aquarium":
			_round(cv, Rect2(pos + Vector2(10, 108), Vector2(r.size.x - 20, 30)), Color("c9985f"), 8)
			_round(cv, Rect2(pos + Vector2(4, 16), Vector2(r.size.x - 8, 100)), Color(0.72, 0.9, 1.0, 0.85), 14)
			cv.draw_rect(Rect2(pos + Vector2(10, 22), Vector2(r.size.x - 20, 14)), Color(1, 1, 1, 0.35))
			cv.draw_rect(Rect2(pos + Vector2(10, 92), Vector2(r.size.x - 20, 18)), Color("f2dca8"))
			for px2 in [26.0, 150.0]:
				cv.draw_line(pos + Vector2(px2, 94), pos + Vector2(px2 - 4.0, 56), Color("6bbf7a"), 6.0, true)
				cv.draw_line(pos + Vector2(px2 + 10.0, 94), pos + Vector2(px2 + 14.0, 64), Color("5fae7e"), 5.0, true)
			_ellipse(cv, pos + Vector2(98, 60), 18.0, 11.0, Color("ff9b54"))
			_poly(cv, [pos + Vector2(114, 60), pos + Vector2(130, 48), pos + Vector2(130, 72)], Color("ff9b54"))
			cv.draw_circle(pos + Vector2(90, 57), 2.5, OUTLINE)
			_ellipse(cv, pos + Vector2(66, 78), 12.0, 8.0, Color("ff7aa8"))
			_poly(cv, [pos + Vector2(54, 78), pos + Vector2(44, 70), pos + Vector2(44, 86)], Color("ff7aa8"))
			cv.draw_circle(pos + Vector2(74, 40), 4.0, Color(1, 1, 1, 0.8))
			cv.draw_circle(pos + Vector2(80, 28), 3.0, Color(1, 1, 1, 0.8))
			cv.draw_rect(Rect2(pos + Vector2(4, 16), Vector2(r.size.x - 8, 100)), OUTLINE, false, 4.0)
		"furn_piano":
			_round(cv, Rect2(pos + Vector2(14, 120), Vector2(172, 12)), dark, 5)
			_round(cv, Rect2(pos + Vector2(0, 10), Vector2(r.size.x, 100)), col, 12)
			_round(cv, Rect2(pos + Vector2(12, 24), Vector2(r.size.x - 24, 42)), col.darkened(0.25), 8)
			for i in 6:
				cv.draw_line(pos + Vector2(40 + i * 24, 28), pos + Vector2(40 + i * 24, 62), Color("c2b6d4"), 2.0)
			_round(cv, Rect2(pos + Vector2(8, 70), Vector2(r.size.x - 16, 34)), Color("fffaf0"), 6)
			for i in 13:
				cv.draw_line(pos + Vector2(14 + i * 14, 70), pos + Vector2(14 + i * 14, 104), OUTLINE, 2.0)
				if i % 7 != 2 and i % 7 != 6 and i < 12:
					cv.draw_rect(Rect2(pos + Vector2(8 + i * 14, 70), Vector2(12, 20)), Color("2b2433"))
			cv.draw_line(pos + Vector2(20, 110), pos + Vector2(20, 164), OUTLINE, 9.0)
			cv.draw_line(pos + Vector2(r.size.x - 20, 110), pos + Vector2(r.size.x - 20, 164), OUTLINE, 9.0)
			cv.draw_line(pos + Vector2(20, 110), pos + Vector2(20, 164), dark, 5.0)
			cv.draw_line(pos + Vector2(r.size.x - 20, 110), pos + Vector2(r.size.x - 20, 164), dark, 5.0)
		"deco_rainbow":
			var bands := [Color("ff6b7a"), Color("ffa94d"), Color("ffe066"), Color("7bd389"), Color("5bb8f5"), Color("a98bea")]
			for i in bands.size():
				cv.draw_arc(Vector2(c.x, r.end.y - 14.0), 92.0 - i * 11.0, PI, TAU, 28, bands[i], 11.0, true)
			cv.draw_arc(Vector2(c.x, r.end.y - 14.0), 98.0, PI, TAU, 28, OUTLINE, 3.0, true)
			cv.draw_arc(Vector2(c.x, r.end.y - 14.0), 26.0, PI, TAU, 20, OUTLINE, 3.0, true)
			for sx2 in [-1.0, 1.0]:
				var cc := Vector2(c.x + sx2 * 92.0, r.end.y - 18.0)
				for part2 in [[-14, 0, 15], [4, -8, 19], [20, 2, 14]]:
					_ellipse(cv, cc + Vector2(part2[0], part2[1]), part2[2], part2[2] * 0.8, Color("ffffff"))
		"deco_balloons":
			var cols := [Color("ff7aa8"), Color("5bb8f5"), Color("ffd24d")]
			for i in 3:
				var bc := pos + Vector2(32 + i * 44, 56 + (i % 2) * 22)
				cv.draw_line(bc + Vector2(0, 38), Vector2(c.x, r.end.y - 6.0), OUTLINE, 2.5)
				_ellipse(cv, bc, 30.0, 36.0, cols[i])
				_poly(cv, [bc + Vector2(-5, 36), bc + Vector2(5, 36), bc + Vector2(0, 44)], cols[i].darkened(0.1), false)
				_ellipse(cv, bc + Vector2(-10, -14), 7.0, 11.0, Color(1, 1, 1, 0.5), false, 0.4)
		"furn_dresser":
			for lx in [18.0, r.size.x - 18.0]:
				_round(cv, Rect2(pos + Vector2(lx - 8.0, 122), Vector2(16, 28)), dark, 5)
			_round(cv, Rect2(pos + Vector2(0, 40), Vector2(r.size.x, 90)), col, 14)
			for row in 3:
				_round(cv, Rect2(pos + Vector2(12, 52 + row * 26), Vector2(r.size.x - 24, 22)), light, 8)
				cv.draw_circle(pos + Vector2(r.size.x * 0.5, 63 + row * 26), 5.0, Color("fff1d6"))
				cv.draw_arc(pos + Vector2(r.size.x * 0.5, 63 + row * 26), 5.0, 0.0, TAU, 12, OUTLINE, 2.0)
			_round(cv, Rect2(pos + Vector2(-6, 30), Vector2(r.size.x + 12, 20)), light.lightened(0.1), 9)
		"furn_desk":
			for lx in [16.0, r.size.x - 34.0]:
				_round(cv, Rect2(pos + Vector2(lx, 66), Vector2(18, 84)), dark, 6)
			_round(cv, Rect2(pos + Vector2(26, 66), Vector2(86, 62)), col, 8)
			for row in 2:
				_round(cv, Rect2(pos + Vector2(34, 74 + row * 26), Vector2(70, 22)), light, 6)
				cv.draw_circle(pos + Vector2(69, 85 + row * 26), 4.5, Color("fff1d6"))
			_round(cv, Rect2(pos + Vector2(0, 50), Vector2(r.size.x, 22)), light.lightened(0.1), 10)
		"furn_wardrobe":
			for fx in [14.0, r.size.x - 38.0]:
				_round(cv, Rect2(pos + Vector2(fx, 212), Vector2(24, 18)), dark, 6)
			_round(cv, Rect2(pos + Vector2(0, 22), Vector2(r.size.x, 196)), col, 16)
			_round(cv, Rect2(pos + Vector2(10, 36), Vector2(r.size.x * 0.5 - 14.0, 168)), light, 12)
			_round(cv, Rect2(pos + Vector2(r.size.x * 0.5 + 4.0, 36), Vector2(r.size.x * 0.5 - 14.0, 168)), light, 12)
			for kx in [-12.0, 12.0]:
				cv.draw_circle(pos + Vector2(r.size.x * 0.5 + kx, 124), 5.0, Color("fff1d6"))
				cv.draw_arc(pos + Vector2(r.size.x * 0.5 + kx, 124), 5.0, 0.0, TAU, 12, OUTLINE, 2.0)
			_star(cv, pos + Vector2(r.size.x * 0.25 + 1.0, 80), 14.0, Color("fff1d6"))
			_star(cv, pos + Vector2(r.size.x * 0.75 - 1.0, 80), 14.0, Color("fff1d6"))
			_round(cv, Rect2(pos + Vector2(-6, 10), Vector2(r.size.x + 12, 20)), dark, 9)
		"furn_stool":
			for lx in [-1.0, 1.0]:
				cv.draw_line(pos + Vector2(45.0 + lx * 26.0, 40), pos + Vector2(45.0 + lx * 34.0, 78), OUTLINE, 10.0, true)
				cv.draw_line(pos + Vector2(45.0 + lx * 26.0, 40), pos + Vector2(45.0 + lx * 34.0, 78), dark, 6.0, true)
			_round(cv, Rect2(pos + Vector2(0, 20), Vector2(r.size.x, 24)), col, 11)
			cv.draw_circle(pos + Vector2(45, 32), 6.0, light)
		"deco_shelf_long":
			for bx in [44.0, r.size.x - 44.0]:
				_poly(cv, [pos + Vector2(bx - 14, 68), pos + Vector2(bx + 14, 68), pos + Vector2(bx, 88)], dark)
			_round(cv, Rect2(pos + Vector2(0, 50), Vector2(r.size.x, 18)), col, 8)
		"deco_shelf_cloud":
			for puff in [[Vector2(48, 76), 30.0, 20.0], [Vector2(110, 82), 40.0, 22.0], [Vector2(172, 76), 30.0, 20.0]]:
				_ellipse(cv, pos + puff[0], puff[1], puff[2], col)
			_round(cv, Rect2(pos + Vector2(8, 52), Vector2(r.size.x - 16, 28)), col, 14)
			cv.draw_circle(pos + Vector2(100, 70), 3.0, OUTLINE)
			cv.draw_circle(pos + Vector2(120, 70), 3.0, OUTLINE)
			cv.draw_arc(pos + Vector2(110, 72), 7.0, 0.3, PI - 0.3, 8, OUTLINE, 2.5, true)
			cv.draw_circle(pos + Vector2(88, 76), 5.0, Color(1.0, 0.7, 0.8, 0.8))
			cv.draw_circle(pos + Vector2(132, 76), 5.0, Color(1.0, 0.7, 0.8, 0.8))
		"toy_blocks":
			for blk in [[Vector2(6, 42), Color("ff9ecb")], [Vector2(46, 42), Color("8ecae6")], [Vector2(26, 4), Color("ffd166")]]:
				_round(cv, Rect2(pos + blk[0], Vector2(38, 38)), blk[1], 6)
				_star(cv, pos + blk[0] + Vector2(19, 19), 9.0, Color("fff1d6"))
		"toy_books":
			_round(cv, Rect2(pos + Vector2(4, 40), Vector2(92, 22)), Color("e76f51"), 6)
			_round(cv, Rect2(pos + Vector2(12, 20), Vector2(78, 20)), Color("8ecae6"), 6)
			_round(cv, Rect2(pos + Vector2(6, 2), Vector2(70, 18)), Color("ffd166"), 6)
			cv.draw_line(pos + Vector2(14, 51), pos + Vector2(84, 51), Color("fff1d6"), 3.0)
			cv.draw_line(pos + Vector2(22, 30), pos + Vector2(82, 30), Color("fff1d6"), 3.0)
			_star(cv, pos + Vector2(40, 11), 6.0, Color("fff1d6"))
		"toy_vase":
			for fl in [[Vector2(18, 24), Color("ff7aa8")], [Vector2(35, 14), Color("ffd24d")], [Vector2(52, 24), Color("b388f5")]]:
				cv.draw_line(pos + Vector2(35, 54), pos + fl[0], Color("5fae7e"), 4.0, true)
				for k in 5:
					var pa := TAU * k / 5.0
					cv.draw_circle(pos + fl[0] + Vector2(cos(pa), sin(pa)) * 7.0, 5.5, fl[1])
				cv.draw_circle(pos + fl[0], 4.5, Color("fff1d6"))
			_ellipse(cv, pos + Vector2(35, 84), 27.0, 26.0, col)
			_round(cv, Rect2(pos + Vector2(25, 50), Vector2(20, 22)), col, 6)
			_ellipse(cv, pos + Vector2(26, 78), 6.0, 10.0, Color(1, 1, 1, 0.5), false, 0.3)
			cv.draw_circle(pos + Vector2(35, 88), 5.0, Color("ff9ecb"))
		"toy_cactus":
			_round(cv, Rect2(pos + Vector2(4, 24), Vector2(14, 28)), col, 7)
			_round(cv, Rect2(pos + Vector2(4, 40), Vector2(26, 12)), col, 6)
			_round(cv, Rect2(pos + Vector2(52, 16), Vector2(14, 30)), col, 7)
			_round(cv, Rect2(pos + Vector2(40, 34), Vector2(26, 12)), col, 6)
			_round(cv, Rect2(pos + Vector2(20, 8), Vector2(30, 66)), col, 15)
			cv.draw_circle(pos + Vector2(35, 8), 6.0, Color("ff7aa8"))
			cv.draw_circle(pos + Vector2(29, 40), 2.6, OUTLINE)
			cv.draw_circle(pos + Vector2(41, 40), 2.6, OUTLINE)
			cv.draw_arc(pos + Vector2(35, 43), 5.0, 0.3, PI - 0.3, 8, OUTLINE, 2.0, true)
			_poly(cv, [pos + Vector2(12, 72), pos + Vector2(58, 72), pos + Vector2(52, 100), pos + Vector2(18, 100)], Color("e0885c"))
			_round(cv, Rect2(pos + Vector2(8, 66), Vector2(54, 12)), Color("e9996d"), 4)
		"toy_cake":
			_ellipse(cv, pos + Vector2(45, 80), 42.0, 9.0, Color("fff6e8"))
			_round(cv, Rect2(pos + Vector2(10, 44), Vector2(70, 36)), col, 10)
			_round(cv, Rect2(pos + Vector2(8, 40), Vector2(74, 16)), Color("fff6e8"), 8)
			for sx in [22.0, 38.0, 54.0, 68.0]:
				cv.draw_circle(pos + Vector2(sx, 66), 2.6, Color("ffb938") if int(sx) % 2 == 0 else Color("8ecae6"))
			_round(cv, Rect2(pos + Vector2(42, 14), Vector2(6, 26)), Color("8ecae6"), 3)
			_ellipse(cv, pos + Vector2(45, 8), 4.5, 7.0, Color("ffd23d"), false)
			for cx2 in [24.0, 66.0]:
				cv.draw_circle(pos + Vector2(cx2, 36), 7.0, Color("e63950"))
				cv.draw_arc(pos + Vector2(cx2, 36), 7.0, 0.0, TAU, 12, OUTLINE, 2.0)
		"toy_frame":
			_round(cv, Rect2(pos + Vector2(20, 72), Vector2(40, 16)), dark, 5)
			_round(cv, Rect2(pos + Vector2(4, 2), Vector2(72, 74)), col, 8)
			cv.draw_rect(Rect2(pos + Vector2(12, 10), Vector2(56, 58)), Color("ffe3ec"))
			cv.draw_circle(pos + Vector2(33, 34), 9.0, Color("ff7aa8"))
			cv.draw_circle(pos + Vector2(47, 34), 9.0, Color("ff7aa8"))
			_poly(cv, [pos + Vector2(24, 38), pos + Vector2(56, 38), pos + Vector2(40, 58)], Color("ff7aa8"), false)
			cv.draw_rect(Rect2(pos + Vector2(12, 10), Vector2(56, 58)), OUTLINE, false, 3.0)
		"toy_musicbox":
			_poly(cv, [pos + Vector2(45, 8), pos + Vector2(34, 30), pos + Vector2(56, 30)], Color("ff9ecb"))
			cv.draw_circle(pos + Vector2(45, 6), 5.0, Color("ffe0cc"))
			_round(cv, Rect2(pos + Vector2(4, 32), Vector2(82, 46)), col, 10)
			_round(cv, Rect2(pos + Vector2(0, 24), Vector2(90, 16)), light, 8)
			_star(cv, pos + Vector2(45, 57), 11.0, Color("fff1d6"))
			cv.draw_circle(pos + Vector2(45, 57), 3.0, OUTLINE)
		"toy_robot":
			for lx in [22.0, 46.0]:
				_round(cv, Rect2(pos + Vector2(lx, 92), Vector2(14, 18)), dark, 5)
			_round(cv, Rect2(pos + Vector2(0, 56), Vector2(12, 28)), dark, 6)
			_round(cv, Rect2(pos + Vector2(68, 56), Vector2(12, 28)), dark, 6)
			_round(cv, Rect2(pos + Vector2(12, 50), Vector2(56, 46)), col, 10)
			cv.draw_line(pos + Vector2(40, 14), pos + Vector2(40, 4), OUTLINE, 3.0)
			cv.draw_circle(pos + Vector2(40, 4), 4.0, Color("ff7aa8"))
			_round(cv, Rect2(pos + Vector2(16, 12), Vector2(48, 38)), light, 10)
			for ex in [30.0, 50.0]:
				cv.draw_circle(pos + Vector2(ex, 28), 6.5, Color.WHITE)
				cv.draw_circle(pos + Vector2(ex, 28), 3.0, OUTLINE)
			cv.draw_arc(pos + Vector2(40, 36), 8.0, 0.4, PI - 0.4, 8, OUTLINE, 2.5, true)
			cv.draw_circle(pos + Vector2(40, 72), 8.0, Color("ff7aa8"))
			cv.draw_arc(pos + Vector2(40, 72), 8.0, 0.0, TAU, 12, OUTLINE, 2.0)
		"toy_trophy":
			cv.draw_arc(pos + Vector2(10, 30), 14.0, PI * 0.5, PI * 1.5, 12, OUTLINE, 6.0, true)
			cv.draw_arc(pos + Vector2(60, 30), 14.0, -PI * 0.5, PI * 0.5, 12, OUTLINE, 6.0, true)
			cv.draw_arc(pos + Vector2(10, 30), 14.0, PI * 0.5, PI * 1.5, 12, col, 3.0, true)
			cv.draw_arc(pos + Vector2(60, 30), 14.0, -PI * 0.5, PI * 0.5, 12, col, 3.0, true)
			_round(cv, Rect2(pos + Vector2(14, 84), Vector2(42, 16)), Color("8a5a3c"), 5)
			_round(cv, Rect2(pos + Vector2(30, 62), Vector2(10, 24)), dark, 3)
			_poly(cv, [pos + Vector2(10, 12), pos + Vector2(60, 12), pos + Vector2(54, 48), pos + Vector2(46, 64), pos + Vector2(24, 64), pos + Vector2(16, 48)], col)
			_round(cv, Rect2(pos + Vector2(6, 6), Vector2(58, 10)), light, 5)
			_star(cv, pos + Vector2(35, 36), 10.0, Color("fff1d6"))
		_:
			_round(cv, r, col)
